#!/usr/bin/perl -w
use strict;

die "perl $0 <Oana08.gff.CDS.pos-1.overlap.conv1.pos.overlap> <Oana08.gff.pos-1.overlap.conv1.pos.overlap>" unless @ARGV == 2;

my %hash;
open(IN, $ARGV[0]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	my $cds = $tmp[0];
	$cds =~ s/_CDS(\d+)$//;
	my $idx = $1;
	next if($tmp[6] == 0);
	for(my $i=7;$i<@tmp;$i++){
		my ($cds1, $ovl) = (split /,/, $tmp[$i])[0,3];
		$cds1 =~ s/_CDS\d+$//;
		if(exists $hash{$cds}{$cds1}){
			$hash{$cds}{$cds1}[0]++;
			$hash{$cds}{$cds1}[2] = $idx;
			$hash{$cds}{$cds1}[3] += $ovl;
		}
		else{
			$hash{$cds}{$cds1} = [1, $idx, $idx, $ovl];
		}
	}	
}
close IN;

open(IN, $ARGV[1]) or die $!;
while(<IN>){
	chomp;
	my @tmp = split /\t/;
	if($tmp[6] == 0 or $tmp[6] == 1){
		print "$_\n";
	}
	else{
		my @query = sort {$hash{$tmp[0]}{$b}[0] <=> $hash{$tmp[0]}{$a}[0]} keys %{$hash{$tmp[0]}};
		my @temp = @tmp[0..5];
		if(@query == 0){
			my $out = join "\t", @temp;
			print "$out\t0\n";
		}
		elsif(@query == 1){
			for(my $i=7;$i<@tmp;$i++){
				my $query = (split /,/, $tmp[$i])[0];
				if($query[0] eq $query){
					push @temp, 1, $tmp[$i];
				}
			}
			my $out;
			if(@temp == 6){
				#die "*$_";
				$out = join "\t", @temp, 0;
			}
			else{
				$out = join "\t", @temp;
			}
			print "$out\n";
		}
		else{
			my @temp = @tmp[0..6];
			for(my $i=7;$i<@tmp;$i++){
				my $query = (split /,/, $tmp[$i])[0];
				if(exists $hash{$tmp[0]}{$query}){
					push @temp, $tmp[$i];
				}
			}
			$temp[6] = $#temp-6;
			my $out = join "\t", @temp;
			if($temp[6] == 0 or $temp[6] == 1){
				print "$out\n";
			}
			else{
				print STDERR "$out\n";
			}
		}
	}
}
close IN;

