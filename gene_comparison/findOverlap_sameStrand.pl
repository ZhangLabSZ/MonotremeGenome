#!/usr/bin/perl -w
use strict;

if (@ARGV != 2) {
	print <<"Usage End.";

Description:

	The two input files can be in pos format or first five Columns corresponding to pos format.

	The format of output file: [example]
	ame.Group1.64	scaffold107	+	1149772 1150322 551	2	ame.Group4.17,+,326,209	ame.Group16.8,+,72,72
	Column 1: the query ID;
	Column 2: chromosome ID;
	Column 3: the query strand;
	Column 4: the query start;
	Column 5: the query end;
	Column 6: the query size;
	Column 7: number of blocks overlapped with ame.Group1.64;
	Column 8: the first subject block ame.Group4.17 overlapped with ame.Group1.64, + is the strand of ame.Group4.17, 326 is its own size, 209 is the overlapped size;
	Column 9: the second subject block ame.Group16.8 overlapped with ame.Group1.64, + is the strand of ame.Group16.8, numbers has the same meaning as last column;

Version:
	
	Author: jinlijun, jinlijun\@genomics.org.cn
	Version: 1.0,  Date: 2011-05-18

Usage
	
	perl findOverlap.pl <ref> [pre]

Example:
	
	perl findOverlap_sameStrand.pl a.pos b.pos >a.pos.overlap

Usage End.

	exit;
}

my $ref_file = shift;
my $pre_file = shift;

my %pre;
if ($pre_file =~ /\S+\.gz$/) {
	open (PE,"zcat $pre_file |") or die $!;
} else {
	open PE, $pre_file;
}
while (<PE>) {
	chomp;
	#my ($pid, $scaf, $strand, $beg, $end) = (split /\s+/)[0,1,2,3,4];
	my ($pid, $scaf, $strand, $beg, $end) = (split /\t/)[0,1,2,3,4];
	push @{$pre{$scaf}{$strand}}, [$pid, $beg, $end];
}
close PE;


if ($ref_file =~ /\S+\.gz$/) {
	open (RE,"zcat $ref_file |") or die $!;
} else {
	open RE, $ref_file;
}
while (<RE>) {
	chomp;
	#my ($id, $scaf, $strand, $beg, $end) = (split /\s+/)[0,1,2,3,4];
	my ($id, $scaf, $strand, $beg, $end) = (split /\t/)[0,1,2,3,4];
	my $leng = $end - $beg + 1;
	print "$id\t$scaf\t$strand\t$beg\t$end\t$leng\t";
	unless ($pre{$scaf}{$strand}) {
		print "0\n";
		next;
	}
	my %over;
	foreach my $p (@{$pre{$scaf}{$strand}}) {
		my ($id0, $beg0, $end0) = @$p;
		my $overlen;
		my $len = $end0 - $beg0 + 1;
		if ($beg0 <= $beg && $end0 >= $beg) {
			if ($end0 >= $end) {
				$overlen = $end - $beg + 1; 
			} else {
				$overlen = $end0 - $beg + 1;
			}
		} elsif ($beg0 > $beg && $beg0 <= $end) {
			if ($end0 >= $end) {
				$overlen = $end - $beg0 + 1;
			} else {
				$overlen = $end0 - $beg0 + 1;
			}
		}
		if ($overlen) {
			$over{$id0} = [$len, $overlen];
		}
	}
	my $overnum = keys %over;
	print "$overnum\t";
	foreach my $k (keys %over) {
		my ($length, $ovlen) = @{$over{$k}};
		my $out = "$k,$strand,$length,$ovlen";
		print "$out\t";
	}
	print "\n";
}
close RE;

