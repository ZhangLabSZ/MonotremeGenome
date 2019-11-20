#!/usr/bin/perl -w
use strict;

die "perl $0 <gff> <max_intergenic_len>" unless @ARGV == 2;

my %hash;
open(IN, $ARGV[0]) or die $!;
while(<IN>){
        chomp;
        my ($chr, $bg, $ed) = (split /\t/)[0,3,4];
        push @{$hash{$chr}}, [$bg, $ed, $_];
}
close IN;

foreach my $chr (sort keys %hash){
        my $n = @{$hash{$chr}};
        if($n == 1){
                my $out = $hash{$chr}[0][2];
                print "$out\n";
        }
        else{
                my @sort = sort {$a->[0] <=> $b->[0]} @{$hash{$chr}};
                print "$sort[0][2]\n";
                my ($start, $end) = ($sort[0][0], $sort[0][1]);
                for(my $i=1;$i<$n;$i++){
                        my $dist = ($sort[$i][0]-1)-($sort[$i-1][1]+1)+1;
                        my $d = $dist > $ARGV[1] ? $ARGV[1]+1 : $dist+1;
                        my $flag = 0;
                        $flag = 1 if($dist > $ARGV[1]);
                        my $bg = $end+$d;
						my $ed = $bg+$sort[$i][1]-$sort[$i][0];
                        my $out = $sort[$i][2];
                        $out =~ s/\t$sort[$i][0]\t/\t$bg\t/;
                        $out =~ s/\t$sort[$i][1]\t/\t$ed\t/;
                        $out =~ s/;$/\*;/ if($flag == 1);
                        print "$out\n";
                        $end = $ed;
                }
        }
}
