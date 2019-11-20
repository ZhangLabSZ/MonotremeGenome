#aln format
species1	strand1	start1	end1	species2	strand2	start2	end2	color
Hsapchr6        +       78601   79100   Mdomchr2        -       48601   49100   blue
Hsapchr6        -       66001   66500   Hsapchr6        -       66001   66500   green
Hsapchr6        -       66001   66500   Mdomchr2        -       46801   47300   green
Hsapchr6        -       66001   66500   Mmuschr17       +       19801   20300   green
Hsapchr6        -       66001   66500   OanachrX5_1     +       36601   37100   green
Mdomchr2        -       46801   47300   Hsapchr6        -       66001   66500   green
Mdomchr2        -       46801   47300   Mdomchr2        -       46801   47300   green
Mdomchr2        -       46801   47300   Mmuschr17       +       19801   20300   green
Mdomchr2        -       46801   47300   OanachrX5_1     +       36601   37100   green
Mmuschr17       +       19801   20300   Hsapchr6        -       66001   66500   green
Mmuschr17       +       19801   20300   Mdomchr2        -       46801   47300   green
Mmuschr17       +       19801   20300   Mmuschr17       +       19801   20300   green

#gff format (do not need exon information), colors are specified in the last column

Ggalchr16       protein_coding  mRNA    1       500     .       +       .       ID=TNXB_ClassIII;color=green;
Ggalchr16       protein_coding  mRNA    601     1100    .       -       .       ID=CYP21A2_ClassIII;color=green;
Ggalchr16       protein_coding  mRNA    1201    1700    .       -       .       ID=C4B_ClassIII;color=green;

#config format
## there are three blocks in the config file
[range]
#row	scaf	start	end

[gene]
#row	ID

[aln]
#row1	row2	scaf1	scaf2	orient1	orient2
