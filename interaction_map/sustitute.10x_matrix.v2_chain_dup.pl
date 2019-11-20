#!/usr/bin/perl -w
die "perl $0 <hash> <key_col> <value_col> <matrix>" unless @ARGV==4;
my $key_col = $ARGV[1]-1;
my $value_col = $ARGV[2]-1;

my %hash;
my %hash_dup;

open IN, $ARGV[0];
while (<IN>) {
		chomp;
		my @in = split /\s+/;
		if (!exists $hash{$in[$key_col]}) {
				$hash{$in[$key_col]} = $in[$value_col];
		}else{
				$hash_dup{$in[$key_col]} = $in[$value_col];
		};
};
close IN;

open IN, $ARGV[3];
while (<IN>) {
		chomp;
		my @in = split /\s+/;
		next unless (exists $hash{$in[0]} and exists $hash{$in[1]});
		print "$hash{$in[0]}\t$hash{$in[1]}\t$in[2]\n";
};
close IN;

foreach my $key (keys %hash) {
		if (exists $hash_dup{$key}) {
				$hash{$key} = $hash_dup{$key};
		};
};

#print "sep\n";
open IN, $ARGV[3];
while (<IN>) {
		chomp;
		my @in = split /\s+/;
		next unless (exists $hash{$in[0]} and exists $hash{$in[1]} and (exists $hash_dup{$in[0]} or exists $hash_dup{$in[1]}));
		print "$hash{$in[0]}\t$hash{$in[1]}\t$in[2]\n";
};
close IN;
