samtools view star_gene_exon_tagged.bam | egrep 'INTERGENIC|INTRONIC|UTR|CODING' | cut -f12,13 > SummaryTable.txt
sed -i 's/GE:Z.\+/XF:Z:EXONIC/' SummaryTable.txt
sort -nk 1 SummaryTable.txt | uniq -c > Summary.txt
samtools view unaligned_tagged_CellMolecular.bam | cut -f12 | sort | uniq -c > UnfilteredReadCount.txt
