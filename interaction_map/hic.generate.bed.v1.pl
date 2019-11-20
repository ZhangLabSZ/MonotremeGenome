#!/usr/bin/perl -w
die "perl $0 <bed> <sort.chr>" unless @ARGV==2;
my %hash;
open IN, $ARGV[1];
while (<IN>) {
		chomp;
		my @in = split /\s+/;
		$hash{$in[0]}++;
		if ($in[5] eq "+" or $in[5] eq "?") {
				open IN2, $ARGV[0];
				while (<IN2>) {
						chomp;
						my @in2 = split /\s+/;
						next unless (exists $hash{$in2[0]});
						next unless ($in2[1]>=$in[3]-1 and $in2[2] <= $in[4]);
						print "$_\t$in[2]\n";
				};
				close IN2;
				%hash=();
		}elsif($in[5] eq "-"){
				#print "$in[0]\n";
				$/ = "\n";
				open(IN2, "/usr/bin/tac $ARGV[0] |");
				while (<IN2>) {
						chomp;
						my @in2 = split /\s+/;
						#print "$in2[0]\n";
						next unless (exists $hash{$in2[0]});
						next unless ($in2[1]>=$in[3]-1 and $in2[2] <= $in[4]);
						print "$_\t$in[2]\n";
				};
				close IN2;
				%hash=();
		}else{
				%hash=();
		};
};
close IN;


