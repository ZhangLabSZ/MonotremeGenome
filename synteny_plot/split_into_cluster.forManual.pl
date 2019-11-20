#!/usr/bin/perl -w
use strict;

die "perl $0 <cluster.info> <table9> <outdir>" unless @ARGV == 3;

mkdir $ARGV[2] unless(-e $ARGV[2]);

my (%hash, %h, %cluster);
open(IN, $ARGV[0]) or die $!;
$/ = "//\n";
while(<IN>){
	chomp;
	my @tmp = split /\n/;
	my $id;
	if($tmp[0] =~ /^\(/){
		$id = $tmp[0];
		$id =~ s/\(//g;
		$id =~ s/\)//g;
		$id = (split /\s+/, $id)[0];
	}
	else{
		$id = (split /\(/, $tmp[0])[0];
		$id =~ s/\s+//g;
	}
	$id = uc($id);
	$cluster{$id} = 1;
	mkdir "$ARGV[2]/cluster_$id" unless(-e "$ARGV[2]/cluster_$id");
	foreach (@tmp){
		$hash{$_} = $id;
	}
}
close IN;

open(IN, $ARGV[1]) or die $!;
$/ = "\n";
my $h = <IN>;
chomp($h);
my @h = split /\t/, $h;
for(my $i=1;$i<@h;$i+=6){
	$h{$i} = $h[$i];
}
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	next if($tmp[0] eq '');
	my $flag = 0;
	for(my $i=1;$i<@h;$i++){
		$flag = 1 if($h[$i] ne 'NA');
	}
	next if($flag == 0);
	next unless(exists $hash{$tmp[0]});

	my $id;
	if($tmp[0] =~ /^\(/){
		$id = $tmp[0];
		$id =~ s/\(//g;
		$id =~ s/\)//g;
		$id = (split /\s+/, $id)[0];
	}
	else{
		$id = (split /\(/, $tmp[0])[0];
		$id =~ s/\s+//g;
	}
	$id = uc($id);
	my $cid = $hash{$tmp[0]};
	open(OUT, ">> $ARGV[2]/cluster_$cid/cluster_$cid.gff");
	for(my $i=1;$i<@tmp;$i+=6){
		next if($tmp[$i+1] eq 'NA' or $tmp[$i+1] eq 'NON');
		my $out = join "\t", "$h[$i]#$tmp[$i+1]", 'protein_coding', 'mRNA', $tmp[$i+2], $tmp[$i+3], '.', $tmp[$i+4], '.', "ID=$id;";
		print OUT "$out\n";
	}
	close OUT;
}
close IN;

