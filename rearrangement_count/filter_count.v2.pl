#!/usr/bin/perl -w
use strict;

die "perl $0 <Mammalia_PQTREE_BAB.seg_tab.add.add.add.link.add_Oana.cut> <Mamm_Oana.link.txt.out>" unless @ARGV == 2;

my (%hash, %count, %store, %bk);
open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my ($ancl, $anc, $idx) = (split /\t/)[0,1,6];
	$hash{$idx} = [$ancl, $anc];
}
close IN;

open(IN, $ARGV[1]) or die $!;
$/ = "\nStep "; <IN>;
my $origin = <IN>;
my @tmp = split /\n/, $origin;
shift @tmp;
pop @tmp if($tmp[-1] =~ /Step/);
for(my $i=0;$i<@tmp;$i++){
	$tmp[$i] =~ s/\s+\$$//;
	my @temp = split /\s+/, $tmp[$i];
	for(my $j=0;$j<@temp;$j++){
		$temp[$j] =~ s/^-//;
		$store{$temp[$j]} = [$#temp, $j];
	}
}
while(<IN>){
	chomp;
	/^\d+: Chrom\. (\d+), gene \d+ \[-?(\d+)\] through chrom\. (\d+), gene \d+ \[-?(\d+)\]: (\S+)/ or die "regex fail: $_";
	my ($chr1, $idx1, $chr2, $idx2, $type) = ($1, $2, $3, $4, $5);
	my @tmp = split /\n/;
	if($type eq 'Reversal'){
		die $_ if($chr1 ne $chr2);
		if($idx1 eq $idx2){
		}
		else{
			unless($hash{$idx1}[0] eq $hash{$idx2}[0] && $hash{$idx1}[1] ne $hash{$idx2}[1]){
				$count{$type}++;
				my $num = $store{$idx1}[0];
				my ($pos1, $pos2) = ($store{$idx1}[1], $store{$idx2}[1]) or die "##$idx1\t$idx2\n";
				if($pos1 == 0 or $pos2 == 0 or $pos1 == $num or $pos2 == $num){
					$bk{$type}++;
				}
				else{
					$bk{$type} += 2;
				}
			}
			else{
				print STDERR "Step $tmp[0]\n@{$hash{$idx1}}\n@{$hash{$idx2}}\n";
			}
		}
	}
	else{
		$count{$type}++;
		if($type eq 'Fission'){
			$bk{$type}++;
		}
		elsif($type eq 'Translocation'){
			$bk{$type} += 2;
		}
	}
	shift @tmp;
	pop @tmp if($tmp[-1] =~ /Step/);
	for(my $i=0;$i<@tmp;$i++){
		$tmp[$i] =~ s/\s+\$$//;
		my @temp = split /\s+/, $tmp[$i];
		for(my $j=0;$j<@temp;$j++){
			$temp[$j] =~ s/^-//;
			$store{$temp[$j]} = [$#temp, $j];
		}
	}
}
close IN;

foreach my $type (sort keys %count){
	$bk{$type} = 0 unless(exists $bk{$type});
	print "$type\t$count{$type}\t$bk{$type}\n";
}

