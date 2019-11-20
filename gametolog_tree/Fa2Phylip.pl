#!/usr/bin/perl -w
use strict;
use Data::Dumper;

my $fa=shift;

my $flag=0;
my $line=`grep -c ">" $fa`;
chomp $line;
open FA,$fa;
$/=">";<FA>;$/="\n";
while(<FA>){
    my $id=$1 if(/(\S+)/);
    #$id=~s/_/-/g; #modify by leegene

    $/=">";
    my $seq=<FA>;
    chomp $seq;
    $seq=~s/\s+//g;
    $/="\n";
    my $len=length $seq;
    print " $line $len\n" if($flag <1);
    print "$id      $seq\n";
    $flag++;
}
close FA;

