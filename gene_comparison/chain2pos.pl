#!/usr/bin/perl -w
use strict;

die "perl $0 <all_sort.chain>" unless @ARGV == 1;

open(IN, $ARGV[0]) or die $!;
$/ = "\n\n";
while(<IN>){
	chomp;
	my @tmp = split /\n/;
	my $h = shift @tmp;
	my ($score, $tchr, $tstrand, $tbg, $ted, $qchr, $qstrand, $qbg, $qed, $idx) = (split /\s+/, $h)[1,2,4,5,6,7,9,10,11,12];
	my ($tbg1, $ted1, $qbg1, $qed1) = ($tbg, $tbg, $qbg, $qbg);
	for(my $i=0;$i<@tmp;$i++){
		my $id = join "_", $idx, $i, $score;
		my ($size, $td, $qd) = (split /\s+/, $tmp[$i])[0,1,2];
		$ted1 = $tbg1+$size;
		$qed1 = $qbg1+$size;
		my $tout = join "\t", $id, $tchr, $tstrand, $tbg1, $ted1;
		my $qout = join "\t", $id, $qchr, $qstrand, $qbg1, $qed1;
		print "$tout\n";
		print STDERR "$qout\n";
		next unless(defined $td);
		$tbg1 = $ted1+$td;
		$qbg1 = $qed1+$qd;

	}
	if($ted1 != $ted or $qed1 != $qed){
		die "$_\n";
	}
}
close IN;

