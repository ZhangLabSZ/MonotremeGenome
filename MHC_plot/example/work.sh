perl ../equal_distribute.pl example.gff 500 100 > example.equal.gff # set gene length and intergenic length to 500 and 100

perl ../gff2aln.pl example.equal.gff > example.equal.aln # generate link, could be ortholog or alignment

sed 's/_ClassI$/_ClassI\tred/' example.equal.aln |sed 's/_ClassII$/_ClassII\tblue/' | sed 's/_ClassIII$/_ClassIII\tgreen/' | sed 's/_Framework$/_Framework\torange/' | sed 's/_Ext.ClassI$/_Ext.ClassI\tpink/' | sed 's/_Ext.ClassII$/_Ext.ClassII\tyellow/' | sed 's/_Antigen-processing$/_Antigen_processing\tpurple/' | cut -f1-8,10 > example.equal.addColour.aln # add color to link

sed 's/_ClassI;/_ClassI;color=red;/' example.equal.gff | sed 's/_ClassII;/_ClassII;color=blue;/' | sed 's/_ClassIII;/_ClassIII;color=green;/' | sed 's/_Framework;/_Framework;color=orange;/' | sed 's/_Ext.ClassI;/_Ext.ClassI;color=pink;/' | sed 's/_Ext.ClassII;/_Ext.ClassII;color=yellow;/' | sed 's/_Antigen-processing;/_Antigen_processing;color=purple;/' > example.equal.addColour.gff # add color to gene

python3 plot_geneDistribute.py config example.equal.addColour.gff example.equal.addColour.aln 100 out.svg # plot

