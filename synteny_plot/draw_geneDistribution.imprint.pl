#!/usr/bin/perl -w
use strict;
die "Usage: <in_file> <file type[gff|solar]> <species.order> <scalar(bp)>\n" unless @ARGV >= 3;
my $fileType = $ARGV[1];
my $order = $ARGV[2];
my $scalar = $ARGV[3] if $ARGV[3];
if ($scalar) {
        die "scalar must be numeric\n" unless $scalar =~ /^\d+$/ || $scalar =~ /^\d+\.\d+$/;
}

my (%spe, %order);
my @order = split /,/, $ARGV[2];
for(my $i=0;$i<@order;$i++){
        $spe{$order[$i]} = $i;
}

my %genePos;
if ($fileType eq "gff") {
        &get_chrGene($ARGV[0], \%genePos);
} elsif ($fileType eq "solar") {
        &solar_parser($ARGV[0], \%genePos);
}

my $chr_count;
my %pos;
foreach my $chr (keys %genePos) {
        $chr_count ++;
        foreach my $p (@{$genePos{$chr}}) {
                my ($gene, $bg, $ed, $strand) = @$p;
                push @{$pos{$chr}}, ($bg, $ed);
        }
        my ($spe, $scaf) = (split /#/, $chr)[0,1];
		        $order{$chr} = $spe{$spe};
}
my @final_order = sort {$order{$a} <=> $order{$b} or $a cmp $b} keys %order;
#die @final_order;

my $height = $chr_count * 80 + 20;
my $width = 900;
my $widest = 0;
foreach my $chr (keys %pos) {
        @{$pos{$chr}} = sort {$a <=> $b} @{$pos{$chr}};
        my $len = $pos{$chr}[-1] - $pos{$chr}[0] + 1;
        $widest = $len if $widest < $len;
}
my $rate = $scalar ? $scalar/700 : $widest/700;

print  '<?xml version="1.0" standalone="no"?>', "\n";
print  '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">', "\n";
print  "<svg width=\"$width\" height=\"$height\" version=\"1.1\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\">", "\n";


my ($leftBar, $topBar) = (50, 50);
my ($line_y1) = ($topBar);
foreach my $chr (@final_order) {
        my ($chr_bg, $chr_ed) = ($pos{$chr}[0], $pos{$chr}[-1]);
        my $region_len = $pos{$chr}[-1] - $pos{$chr}[0] + 1;
        my $line_len = int($region_len/$rate);
        my $line_x1 = $leftBar - 10;
        my $line_x2 = $leftBar + $line_len + 10;
        my $line_y2 = $line_y1;
        printf '<text x="%d" y="%d" font-family="Arial" font-size="12" fill="black">%s</text>' . "\n", $line_x1, $line_y1-25, $chr,;
		print "<line x1=\"$line_x1\" y1=\"$line_y1\" x2=\"$line_x2\" y2=\"$line_y2\" style=\"stroke:rgb(99,99,99);stroke-width:1\"/>\n";

        ## draw ruler
        my $unit = 2000;
        my $unit_len = $unit * $line_len / $region_len;
        my $ruler_x1 = $line_x1;
        my $ruler_x2 = $line_x1 + $unit_len;
        my $ruler_y1 = $height - 5;
        my $ruler_y2 = $height - 5;
        print "<line x1=\"$ruler_x1\" y1=\"$ruler_y1\" x2=\"$ruler_x2\" y2=\"$ruler_y2\" style=\"stroke:rgb(99,99,99);stroke-width:1\"/>\n";
        printf '<text x="%d" y="%d" font-family="Arial" font-size="8" fill="black">%s</text>' . "\n", $ruler_x1, $ruler_y1-3, $unit;

        my $count = 1; ## use to determine the direction of arrow based on the strand of a gene
        my @store;
        for(my $i=0;$i<@{$genePos{$chr}};$i++) {
                #my $p = $genePos{$chr}[$i];
                my ($id, $bg, $ed, $strand) = @{$genePos{$chr}[$i]};
                my $block_color;
                if ($id =~ /yellow/i) {
                        $block_color = "yellow";
                } elsif ($id =~ /psi/i) {
                        $block_color = "white";
                } elsif ($id =~ /rjp/i) {
                        $block_color = "red";
                } else {
                        #$block_color = "darkblue";
                        $block_color = "red";
                }
				
                my $gene_len = ($ed - $bg + 1) / $rate;
                my ($path_x, $path_y, $h, $l_x, $l_y);
                if ($strand eq "+") {
                        $path_x = $leftBar + ($bg - $chr_bg + 1)/$rate;
                        $path_y = $line_y1;
                        $h = 0.8 * $gene_len;
                        $l_x = 0.2 * $gene_len;
                        $l_y = 6;
                } else {
                        $path_x = $leftBar + ($ed - $chr_bg + 1)/$rate;
                        $path_y = $line_y1;
                        $h = 0.8 * $gene_len * (-1);
                        $l_x = 0.2 * $gene_len * (-1);
                        $l_y = 6;
                }
                print "<path d=\"M$path_x $path_y v -3 h$h v-3 l $l_x $l_y M$path_x $path_y v 3 h$h v 3 l $l_x -$l_y \" fill=\"$block_color\" stroke=\"black\" fill-opacity=\"1\" />\n";

                my $start = $leftBar + ($bg - $chr_bg + 1)/$rate;
                my $end = $start + $gene_len - 1;
                push @store, [$start, $end];

                if($id =~ s/\*$//){
                        my $m = (($store[$i][0]-1)+($store[$i-1][1]+1))/2;
                        my ($x1, $y1, $x2, $y2) = ($m-4, $path_y+4, $m, $path_y-4);
                        print "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" style=\"stroke:rgb(99,99,99);stroke-width:1\"/>";
						($x1, $y1, $x2, $y2) = ($m, $path_y+4, $m+4, $path_y-4);
                        print "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" style=\"stroke:rgb(99,99,99);stroke-width:1\"/>";
                }

                #my $text_x = $path_x - 5;
                my $text_x = $leftBar + ($bg - $chr_bg + 1)/$rate;
                my $text_y = $count % 2 ? $path_y - 10 : $path_y + 30;
                printf '<text x="%d" y="%d" font-family="Arial" font-size="8" fill="%s">%s</text>' . "\n", $text_x, $text_y, ,"black", $id;
                $count ++;
        }
        $line_y1 += 80;


}
print  '</svg>', "\n";


## subroutine
#######################
sub get_chrGene {
        my $in_file = shift;
        my $ref1 = shift;
        my $ref2 = shift;
        my $ref3 = shift;
        open IN, $in_file;
        while (<IN>) {
                chomp;
                my @info = split /\s+/;
                next unless $info[2] eq 'mRNA';
				die unless $_ =~ /ID=(.+?);/ || $_ =~ /gene_id\s+"(\S+?)";/;
                my $gene = $1;
                push @{$ref1->{$info[0]}}, [$gene, $info[3], $info[4], $info[6]];
        }
        close IN;
        foreach my $chr (keys %$ref1) {
                my %p_to_bg;
                foreach my $p (@{$ref1->{$chr}}) {
                        my $bg = $p->[1];
                        $p_to_bg{$p} = $bg;
                }
                @{$ref1->{$chr}} = sort {$p_to_bg{$a} <=> $p_to_bg{$b}} @{$ref1->{$chr}};
                for (my $i = 0; $i < @{$ref1->{$chr}}; $i ++) {
                        my $p = $ref1->{$chr}->[$i];
                        my ($gene, $bg, $ed, $strand) = @$p;
                        my $index = $i + 1;
                        push @$p, $index;
                        $ref2->{$gene} = [$chr, $bg, $ed, $strand, $index];
                        $ref3->{$chr}{$index} = $gene;
                }
        }
}

sub solar_parser {
        my ($in_file, $ref1) = @_;
        open IN, $in_file;
        while (<IN>) {
                chomp;
                my @info = split /\s+/;
                my $gene = $info[0];
                push @{$ref1->{$info[5]}}, [$gene, $info[7], $info[8], $info[4]];
        }
		close IN;
        foreach my $chr (keys %$ref1) {
                my %p_to_bg;
                foreach my $p (@{$ref1->{$chr}}) {
                        my $bg = $p->[1];
                        $p_to_bg{$p} = $bg;
                }
                @{$ref1->{$chr}} = sort {$p_to_bg{$a} <=> $p_to_bg{$b}} @{$ref1->{$chr}};
        }
}