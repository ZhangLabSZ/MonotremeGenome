awk '{print $1"\t"$2"\t"$3"\t"$4-1"\t"$5}' Oana08.gff.pos > Oana08.gff.pos-1
perl ../bin/chain2pos.pl all_sort.chain > all_sort.chain.tpos 2> all_sort.chain.qpos # all_sort.chain is from lastz
perl ../findOverlap_new.pl Oana08.gff.pos-1 all_sort.chain.tpos > Oana08.gff.pos-1.overlap
perl ../convert_overlap.v1.pl Oana08.gff.pos-1.overlap all_sort.chain.tpos all_sort.chain.qpos query.sizes > Oana08.gff.pos-1.overlap.conv1 2> err1 # query.size is from lastz
awk '{print $1"\t"$2"\t"$3"\t"$4+1"\t"$5}' Oana08.gff.pos-1.overlap.conv1 | awk '!/^#/' > Oana08.gff.pos-1.overlap.conv1.pos
perl ../findOverlap_sameStrand.pl Oana08.gff.pos-1.overlap.conv1.pos Oana.gff1.pos | sort -k2,2 -k4,4n > Oana08.gff.pos-1.overlap.conv1.pos.overlap
perl ../classify_genes.pl Oana08.gff.pos-1.overlap.conv1.pos.overlap > Oana08.gff.pos-1.overlap.conv1.pos.overlap.classified


