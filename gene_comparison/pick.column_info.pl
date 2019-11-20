#!/usr/bin/perl -w
use strict;
use Getopt::Long;
die "<file1> <file2> [file1.column] [file2.column] --t [same|diff] --s1 [\\t] --s2 [\\t]\n" unless @ARGV>=4;
my $t ||= "same";
my $s1 ||= "\t";
my $s2 ||= "\t";
GetOptions(
		"t:s"=>\$t,
		"s1:s"=>\$s1,
		"s2:s"=>\$s2,
		);
my %hash;
my $col1=$ARGV[2]-1;
my $col2=$ARGV[3]-1;
if($ARGV[0]=~/\.gz$/){
	open IN,"gunzip -c $ARGV[0] |" or die $!;
}else{
	open IN,"$ARGV[0]" or die $!;
}
while(<IN>){
	chomp;
	next if $_=~/^#/;
	next if($_ eq '');
	my @A=split /$s1/;
	$hash{$A[$col1]}=1;
}
close IN;

if($ARGV[1]=~/\.gz$/){
	open IN,"gunzip -c $ARGV[1] |" or die $!;
}else{
	open IN,"$ARGV[1]" or die $!;
}
while(<IN>){
	chomp;
	next if $_=~/^#/;
	my @A=split /$s2/;
	if(exists $hash{$A[$col2]} && $t eq "same"){
		print "$_\n";
	}elsif(!exists $hash{$A[$col2]} && $t eq "diff"){
		print "$_\n";
	}
}
close IN;

