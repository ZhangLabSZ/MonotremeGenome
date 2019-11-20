#!/usr/bin/perl -w
use strict;
use Data::Dumper;
$Data::Dumper::Indent = 0;

die "perl $0 <overlap> <all_sort.chain.tpos> <all_sort.chain.qpos> <qlen>" unless @ARGV == 4;

my (%hash, %len);
for(my $i=1;$i<=2;$i++){
	open(IN, $ARGV[$i]) or die $!;
	while(<IN>){
		chomp;
		my ($info, $chr, $strand, $bg, $ed) = (split /\t/)[0,1,2,3,4];
		my ($id, $idx, $score) = (split /_/, $info)[0,1,2];
		my $type = $i == 1 ? 't' : 'q';
		$hash{$info}{$type} = [$chr, $strand, $bg, $ed];
	}
	close IN;
}

open(IN, $ARGV[3]) or die $!;
while(<IN>){
	chomp;
	my ($id, $len) = (split /\t/)[0,1];
	$len{$id} = $len;
}
close IN;

open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	if($tmp[6] > 0){
		my (%tmp, %store);
		for(my $i=7;$i<@tmp;$i++){
			my ($id1, $strand, $len, $olp) = (split /,/, $tmp[$i])[0,1,2,3];
			my ($id, $idx, $score) = (split /_/, $id1)[0,1,2];
			$tmp{$id}{$idx} = [$score, $strand, $len, $olp];
		}
		foreach my $id (sort keys %tmp){
			my ($score, $ovl) = (0, 0);
			foreach my $idx (sort keys %{$tmp{$id}}){
				$score = $tmp{$id}{$idx}[0];
				$ovl += $tmp{$id}{$idx}[3];
			}
			$store{$id} = [$score, $ovl];
		}
		my @id_score = (sort {$store{$b}[1] <=> $store{$a}[1]} keys %store)[0];
		my @id_ovl = (sort {$store{$b}[0] <=> $store{$a}[0]} keys %store)[0];
		if($id_score[0] ne $id_ovl[0]){
			if($store{$id_score[0]}[0] != $id_ovl[0]){
				print STDERR Dumper(%store);
				print STDERR "\n$_\n\n";
			}
		}
		my @idx = sort {$a<=>$b} keys %{$tmp{$id_score[0]}};
		my $start = join "_", $id_score[0], $idx[0], $tmp{$id_score[0]}{$idx[0]}[0];
		my $end = join "_", $id_score[0], $idx[-1], $tmp{$id_score[0]}{$idx[-1]}[0];
		my $tbg = $hash{$start}{t}[2];
		my $ted = $hash{$end}{t}[3];
		my $other = '';
		if($tmp[3] < $tbg){
			my $l = $tbg-$tmp[3];
			$other .= "$l:$tmp[3]-\>$tbg;";
			$tmp[3] = $tbg;
		}
		if($tmp[4] > $ted){
			my $l = $tmp[4]-$ted;
			$other .= "$l:$tmp[4]-\>$ted;";
			$tmp[4] = $ted;
		}
		$other = 'NA' if($other eq '');
		$other =~ s/;$//;
		my $qbg = $hash{$start}{q}[2]+$tmp[3]-$tbg;
		my $qed = $hash{$end}{q}[3]-($ted-$tmp[4]);
		my $qstrand;
		if($tmp{$id_score[0]}{$idx[0]}[1] eq $tmp[2]){
			$qstrand = $hash{$start}{q}[1];
		}
		else{
			$qstrand = $hash{$start}{q}[1] eq '+' ? '-' : '+';
		}
		if($hash{$end}{q}[1] eq '-'){
			my $len = $qed-$qbg;
			$qed = $len{$hash{$start}{q}[0]}-$qbg;
			$qbg = $qed-$len;
		}
		my $out = join "\t", $tmp[0], $hash{$start}{q}[0], $qstrand, $qbg, $qed;
		print "$out\t$other\n";
	}
	else{
		my $out = join "\t", @tmp[0..4];
		print "#$out\tNA\n";
	}
}
close IN;

