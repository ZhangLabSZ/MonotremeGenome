perl ../hic.generate.bed.v1.pl hic_results/matrix/proximo/raw/100000/proximo_100000_abs.bed select.chr > new.bed
awk 'BEGIN {i=1} {print $0"\t"i;i++}' new.bed > new.bed.add
perl ../sustitute.10x_matrix.v2_chain_dup.pl new.bed.add 4 6 hic_results/matrix/proximo/iced/100000/proximo_100000_iced.matrix > new.matrix
Rscript ../HiC_map.R

