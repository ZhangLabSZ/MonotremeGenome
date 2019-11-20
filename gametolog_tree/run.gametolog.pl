#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);

die "perl $0 <dir> <outgroup-outgroup>" unless @ARGV==2;
my @outgp = split /-/,$ARGV[1];

use Cwd qw(abs_path);
use File::Spec;
use File::Basename;

opendir DIR, $ARGV[0];
my @file = readdir DIR;
my $path = abs_path($ARGV[0]);
my $base = basename($ARGV[0]);

`cat $path/*.fa | awk '{print \$1}' > $path/$base.cds`;
`cat $path/*.pep | awk '{print \$1}' > $path/$base.pep`;

`/share/app/muscle-3.8.31/bin/muscle -in $path/$base.pep -out $path/$base.pep.muscle`;
`perl $Bin/pepMfa_to_cdsMfa.pl $path/$base.pep.muscle $path/$base.cds > $path/$base.pep.muscle.cds`;
`perl $Bin/Fa2Phylip.pl $path/$base.pep.muscle.cds > $path/$base.pep.muscle.cds.phy`;
foreach my $out (@outgp) {
        `sed -i 's/$out\\S*/Hsap/g' $path/$base.pep.muscle.cds.phy`;
};
`/share/app/RAxML-8.2.4/raxmlHPC-SSE3 -o Hsap -f a -m GTRGAMMA -p 12345 -x 12345 -# 100 -s $path/$base.pep.muscle.cds.phy -n $base`;
`mv RAxML_*.$base $path`;
`perl $Bin/format.nhx.divergence.pl $path/RAxML_bipartitionsBranchLabels.$base > $path/RAxML_bipartitionsBranchLabels.$base.nhx`;
`perl $Bin/draw_tree.pl $path/RAxML_bipartitionsBranchLabels.$base.nhx > $path/RAxML_bipartitionsBranchLabels.$base.svg`;

