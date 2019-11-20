#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <AxML_bipartitionsBranchLabels*> \n" unless @ARGV == 1;

open (IN,$ARGV[0]) or die $!;
while (<IN>) {
        chomp;
        $_ =~ s/\[/\[\&\&NHX:B=/g;
        $_ =~ s/:\d+\.\d+//g;
        print "$_\n";
}
close IN;
