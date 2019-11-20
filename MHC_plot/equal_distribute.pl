#!/usr/bin/perl -w
use strict;

die "perl $0 <gff> <gene_len> <intergenic_len>" unless @ARGV == 3;

open(IN, $ARGV[0]) or die $!;
my $last_chr;
my $last_bg = 1;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	$last_chr = $tmp[0] unless(defined $last_chr);
	$last_bg = 1 if($last_chr ne $tmp[0]);
	my $ed = $last_bg+$ARGV[1]-1;
	my $out = join "\t", @tmp[0..2], $last_bg, $ed, @tmp[5..8];
	print "$out\n";
	$last_bg = $ed+$ARGV[2]+1;
	$last_chr = $tmp[0];
}
close IN;

