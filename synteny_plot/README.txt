#### tab file format ####
Gene_name	spe_id	spe_chr	spe_start	spe_end	spe_strand	spe_alignRate(%)
#The orthologs in different species should be place in the same line. Each species should contain six columns (id,chromosome,start,end,strand,alignRate(%)) and be split by tab.

#### cluster infor file format #####
each line represents a gene; clusters are separated by a line with "//"

#### how to run ####
mkdir out.manual_check
perl split_into_cluster.forManual.pl <cluster.info> <tab> <output_dir>
ls out.manual_check/*/*.gff| while read i
do
        perl shorten.pl $i 100000 > $i.shorten.gff
        perl draw_geneDistribution.imprint.pl $i.shorten.gff <lable> <species,species> <scale> > $i.shorten.gff.svg
done

#if you only have one cluster genes, you just need to run the shorten.pl and draw_geneDistribution.imprint.pl command; otherwise, you can follow a work.sh operation.

#You might need to manually modify the SVG according to your needs (such as color, species order, etc.)
 
