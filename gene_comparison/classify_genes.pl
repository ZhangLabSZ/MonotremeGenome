#!/usr/bin/perl -w
use strict;

die "perl $0 <Oana08.gff.pos-1.overlap.conv1.pos.overlap.select>" unless @ARGV == 1;

my (%hash, %tag);
open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	next if($tmp[6] == 0);
	for(my $i=0;$i<@tmp;$i++){
		my $id = (split /,/, $tmp[$i])[0];
		$hash{$id}{$tmp[0]} = 1;
		if(@tmp == 7){
			if(exists $tag{$id}){
				die $_ if($tag{$id} ne 'unique');
			}
			else{
				$tag{$id} = 'unique';
			}
		}
		else{
			if(exists $tag{$id}){
				die $_ if($tag{$id} ne 'multiple');
			}
			else{
				$tag{$id} = 'multiple';
			}
		}
	}
}
close IN;

open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	if($tmp[6] == 0){
		print "$_\t1vs0\n";
	}
	elsif($tmp[6] > 1){
		print "$_\t1vsN\n";
	}
	else{
		my $id = (split /,/, $tmp[7])[0];
		my $n = keys %{$hash{$id}};
		my $tag = $n > 1 ? 'Nvs1' : '1vs1';
		print "$_\t$tag\n";
	}
}
close IN;

