#!/usr/bin/perl -w
use strict;
open(IN,"$ARGV[0]")||die "can not open gff\n";
my %gene;
while(<IN>){
	chomp;
	my @line=split /\t/;
	my $gid;
	if($line[8]=~ /ID=(\S+)\.(\d+)_(\S+);/){
		$gid="$1_$3";
	}elsif($line[8]=~ /ID=(\S+);/){
		$gid=$1;
	}
	push @{$gene{$gid}},"$line[0]\t$line[6]\t$line[3]\t$line[4]";
}
close IN;
foreach my $name(keys %gene){
	my $num=@{$gene{$name}};
	if($num==1){
		print "${$gene{$name}}[0]\t-\t-\t-\t-\t$name\n";
	}elsif($num==2){
		print "${$gene{$name}}[0]\t${$gene{$name}}[1]\t$name\n";	
	}else{
		for(my $j=0;$j<$num;$j++){
			for(my $i=0;$i<@{$gene{$name}};$i++){
				print "${$gene{$name}}[$j]\t${$gene{$name}}[$i]\t$name\n";
			}
		}
	}
}
