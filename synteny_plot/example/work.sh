mkdir out.manual_check
perl ../split_into_cluster.forManual.pl cluster.info example.tab out.manual_check/
ls out.manual_check/*/*.gff| while read i
do
	perl ../shorten.pl $i 100000 > $i.shorten.gff
	perl ../draw_geneDistribution.imprint.pl $i.shorten.gff gff HUMAN,MOUSE,OPOSSUM,PACBIO_PLATYPUS,v08_platypus,tacu,CHICKEN,ANOLE 10000 > $i.shorten.gff.svg
done

