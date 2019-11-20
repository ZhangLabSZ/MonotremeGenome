#!/usr/bin/perl
use strict;

=head1 Usage

 perl draw_tree.pl <infile> [options]
  <infile>	input nhx format;
  -del		delete the root branch of tree of figure;

=head1 Example

 perl draw_tree.pl test.nhx > test.svg
 perl draw_tree.pl test.nhx -del > test.svg

=cut

use FindBin qw($Bin);
use lib $Bin;
use lib "$Bin/lib";
#BEGIN{push @INC,'/public/home/wangzj/pipeline/Animal/02.phylogeny_v1.1/lib'}
use Tree::nhx_svg;
use Getopt::Long;

my ($del,$help);
GetOptions(
	"del" 	=> \$del,
	"help"	=> \$help
);
die `pod2text $0` if ( @ARGV < 1 || $help );
my $innhx = shift;

open (IN,"$innhx") or die "Can't open: $innhx\n";
$/ = ";";
my $str = <IN>;
my $nhx = Tree::nhx_svg->new('show_B',1,'show_ruler',1,'show_W',0,
	'c_line',"#000000",'line_width',1,'c_W',"#5050D0",'right_margin',"120",
	'c_B',"#5050D0",'fsize',15,'skip',30,'fsize2',12, 'width', "500");

$nhx->parse($str);
#print $nhx->plot();
my $new = $nhx->plot();
if($del){
	foreach(split /\n/,$new){(/x1=\"30\"/) ? next : print "$_\n";}
}else{
	print $new;
}
close IN;

