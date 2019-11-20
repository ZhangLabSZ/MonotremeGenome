#!/usr/bin/perl -w
use strict;

die "perl $0 <Oana08.gff.pos-1.overlap.conv1.pos.overlap.err1>" unless @ARGV == 1;

open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	my $out = join "\t", @tmp[0..5];
	my $overlap;
	my $per = 0;
	my $ovlen = 0;
	for(my $i=7;$i<@tmp;$i++){
		my ($id, $len, $ovl) = (split /,/, $tmp[$i])[0,2,3];
		if($per < $ovl/$len){
			$overlap = $tmp[$i];
			$per = $ovl/$len;
			$ovlen = $ovl;
		}
		elsif($ovlen < $ovl){
			$overlap = $tmp[$i];
			$ovlen = $ovl;
		}
	}
	print "$out\t1\t$overlap\n";
}
close IN;

