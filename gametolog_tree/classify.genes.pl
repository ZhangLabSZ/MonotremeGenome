#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <indir> <list> <outdir> <pep/cds> \n" unless @ARGV == 4;

my %hash;
my ($indir,$list,$outdir,$flag) = @ARGV;
my @files = `find $indir/*$flag`;
foreach my $file (@files) {
	chomp $file;
	open (IN,$file) or die $!;
	$/ = ">";
	<IN>;
	while (<IN>) {
		chomp;
		my ($string,$id,$species,$chr);
		if (/(\S+)/) {
			$string = $1;
			($species,$id,$chr) = (split /\./,$string);
		}
		s/.+\n//;
		my $Gene_id = join ".",$species,$chr;
		my $ID = join "_",$species,$id;
		push @{$hash{$ID}},">$Gene_id\n$_";
	}
	close IN;
	$/ = "\n";
}


my %record;
open (IN,$list) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\t/;
	if (exists $hash{$info[0]}) {
		$record{$info[0]} = 1;
		open (OT,">$outdir/$info[0].$flag.fa") or die $!;
		my $line = join "",@{$hash{$info[0]}};
		print OT "$line";
		for (my $i=6;$i<90;$i +=6) {
			next if ($info[$i] eq "NA");
			if (exists $hash{$info[$i]}) {
	#			print STDERR "$info[0]\t$info[$i]\n";
				$record{$info[$i]} = 1;
				my $line = join "",@{$hash{$info[$i]}};
				print OT "$line";
			}
		}
		close OT;
		system "/share/app/muscle3.8.31/muscle3.8.31_i86linux64 -in $outdir/$info[0].pep.fa -out $outdir/$info[0].pep.fa.muscle" if ($flag eq "pep");
		system "perl pepMfa_to_cdsMfa.pl $outdir/$info[0].pep.fa.muscle $outdir/$info[0].cds.fa > $outdir/$info[0].pep.fa.muscle.cds" if ($flag eq "pep");
	}
}
close IN;

foreach my $id (keys %hash) {
	if (exists $record{$id}) {
		next;
	} else {
	#	my $line = join "",@{$hash{$id}};
		print "$id\n";
	}
}
