#!/usr/bin/env bash
set -e
#Gildas Lepennetier | Thomas 2018

echo -e "START $(basename $0)\t$(date '+%Y-%m-%d %H:%M:%S')"

if [ $# -ne 1 ];then
	echo "ERROR: not enough arguments"
	echo "usage: $(basename $0) <PARAMETER.sh>"
	exit
fi

STARTTIME_1=$SECONDS
STARTTIME=$SECONDS
PARAM_FILE=$(realpath "$1")

if [ ! -e "$PARAM_FILE" ] ;then echo "Error: cannot find parameter file @ $PARAM_FILE (use of absolut path?)"; exit 1 ; fi
source "$PARAM_FILE" #get the variables needed

if [ -z "$STAR_ALIGNER_DIR" ]; then echo "Error: STAR_ALIGNER_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$DROP_SEQ_TOOLS" ]; then echo "Error: DROP_SEQ_TOOLS variable not set in parameter file"; exit 1; fi
if [ -z "$PICARD_jar" ]; then echo "Error: PICARD_jar variable not set in parameter file"; exit 1; fi
if [ -z "$DROPSEQ_jar" ]; then echo "Error: DROPSEQ_jar variable not set in parameter file"; exit 1; fi
if [ -z "$DROPSEQ_PIPELINE_DIR" ]; then echo "Error: DROPSEQ_PIPELINE_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$SAMTOOLS" ]; then echo "Error: SAMTOOLS variable not set in parameter file"; exit 1; fi
if [ -z "$GENOME_path" ]; then echo "Error: GENOME_path variable not set in parameter file"; exit 1; fi
if [ -z "$GENOME_NAME" ]; then echo "Error: GENOME_NAME variable not set in parameter file"; exit 1; fi
if [ -z "$TEMP_FILES_PATH" ]; then echo "Error: TEMP_FILES_PATH variable not set in parameter file"; exit 1; fi
if [ ! -d "$TEMP_FILES_PATH" ];then mkdir -p "$TEMP_FILES_PATH"; fi
if [ -z "$OUTPUTFOLDER" ]; then echo "Error: OUTPUTFOLDER variable not set in parameter file"; exit 1; fi
if [ ! -d "$OUTPUTFOLDER" ];then mkdir -p "$OUTPUTFOLDER"; fi

#check genome extension.
# NOTE : extension is .fa if the person used the installation scripts.
# But may be different.
EXT="fa"
if [ ! -e "$GENOME_path/$GENOME_NAME.$EXT" ];then 
	EXT="fasta"
	echo "INFO: genome extention unexpected (not .fa), trying with .fasta"
fi
if [ ! -e "$GENOME_path/$GENOME_NAME.$EXT" ];then 
	echo "ERROR: genome extention should be .fa or .fasta."
	echo "Please check your \$GENOME_path/\$GENOME_NAME @ $GENOME_path/$GENOME_NAME "
	exit 1
fi

cd "$TEMP_FILES_PATH"


RunName=$(cat "$TEMP_FILES_PATH/RunName.txt")
if [ -z "$RunName" ];then echo "Warning: RunName.txt empty, using alternative annotation 'unnamed_sample'"; RunName="unnamed_sample"; fi
# Also possible to use RunName="unnamed_sample" and not exit

if [ $(ls *'_S1_R1_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 1"; exit 1; fi
if [ $(ls *'_S1_R2_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 1"; exit 1; fi
R1=$(ls *'_S1_R1_001.fastq.gz' )
R2=$(ls *'_S1_R2_001.fastq.gz' )
echo "R1='$R1' -> will be used as ReverseRead"
echo "R2='$R2' -> will be used as ForwardRead"
ForwardRead="$R2"
ReverseRead="$R1"


STARTTIME=$SECONDS
if [ ! -e "unaligned_reads.bam" ]; then echo -e "\n\n\t>>> Create bam file without alignment [FastqToSam]"
	LOGFILE="$OUTPUTFOLDER/logs.FastqToSam.logs"
	echo "logfile : $LOGFILE"
	java "-Djava.io.tmpdir=$TEMP_FILES_PATH" -jar "$PICARD_jar" FastqToSam F1="$ForwardRead" F2="$ReverseRead" O="unaligned_reads.bam" SM="$RunName" 2> "$LOGFILE"
	echo "Finished!" >> "$LOGFILE"
else
	echo -e "\nALREADY EXISTS: unaligned_reads.bam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."


STARTTIME=$SECONDS
if [ ! -e "unaligned_reads.sorted.bam" ]; then echo -e "\n\n\t>>> Sort bam file according to read ID [SortSam]"
	LOGFILE="$OUTPUTFOLDER/logs.SortSam.logs"
	echo "logfile : $LOGFILE"
	java "-Djava.io.tmpdir=$TEMP_FILES_PATH" -jar "$PICARD_jar" SortSam I="unaligned_reads.bam" O="unaligned_reads.sorted.bam" SORT_ORDER=queryname 2> "$LOGFILE"
	echo "Finished!" >> "$LOGFILE"
else
	echo -e "\nALREADY EXISTS: unaligned_reads.sorted.bam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."


echo -e "\n\n\t>>>Start Dropseq tool"
### original workflow: "$DROP_SEQ_TOOLS/Drop-seq_alignment.sh" -g "$STAR_ALIGNER_DIR" -r "$GENOME_path/$GENOME_NAME" -d "$DROP_SEQ_TOOLS" -s "$STAR_ALIGNER_DIR/STAR/STAR" "$RunName.sorted.bam"
CPU=$( nproc ) #24, 16, ...

refflat=$(dirname "$GENOME_path/$GENOME_NAME")/$(basename "$GENOME_path/$GENOME_NAME" .fasta).refFlat #basename remove the suffix.fasta, replace by refFlat
unmapped_bam="$TEMP_FILES_PATH/unaligned_reads.sorted.bam"
tagged_unmapped_bam="$TEMP_FILES_PATH/unaligned_mc_tagged_polyA_filtered.bam"
aligned_sam="$TEMP_FILES_PATH/star.Aligned.out.sam"
tagged_bam="$TEMP_FILES_PATH/star_gene_exon_tagged.bam"
aligned_sorted_bam="$TEMP_FILES_PATH/aligned.sorted.bam"

#echo "\$refflat: $refflat"
#echo "\$unmapped_bam: $unmapped_bam"
#echo "\$tagged_unmapped_bam: $tagged_unmapped_bam"
#echo "\$aligned_sam: $aligned_sam"
#echo "\$aligned_sorted_bam: $aligned_sorted_bam"

STARTTIME=$SECONDS
# Stage 1
if [ ! -e "$tagged_unmapped_bam" ];then echo -e "\n>>>> Stage 1: tag_cells 1-6 > tag_molecules 7-16 > filter_bam REJECT=XQ > trim adapt > trim polyA"
	#-Xmx 4g 
	java -jar "$DROPSEQ_jar" TagBamWithReadSequenceExtended \
	SUMMARY="$OUTPUTFOLDER"/unaligned_tagged_Cellular.bam_summary.txt BASE_RANGE=1-6 \
	BASE_QUALITY=10 BARCODED_READ=1 DISCARD_READ=false TAG_NAME=XC \
	NUM_BASES_BELOW_QUALITY=1 \
	INPUT="$unmapped_bam" \
	OUTPUT=/dev/stdout COMPRESSION_LEVEL=0 | \
	java -jar "$DROPSEQ_jar" TagBamWithReadSequenceExtended \
	SUMMARY="$OUTPUTFOLDER"/unaligned_tagged_Molecular.bam_summary.txt BASE_RANGE=7-16 \
	BASE_QUALITY=10 BARCODED_READ=1 DISCARD_READ=true TAG_NAME=XM \
	NUM_BASES_BELOW_QUALITY=1 \
	INPUT=/dev/stdin OUTPUT=/dev/stdout COMPRESSION_LEVEL=0 | \
	java -jar "$DROPSEQ_jar" FilterBAM \
	TAG_REJECT=XQ \
	INPUT=/dev/stdin OUTPUT=/dev/stdout COMPRESSION_LEVEL=0 | \
	java -jar "$DROPSEQ_jar" TrimStartingSequence \
	OUTPUT_SUMMARY="$OUTPUTFOLDER"/adapter_trimming_report.txt \
	SEQUENCE=AAGCAGTGGTATCAACGCAGAGTGAATGGG MISMATCHES=0 NUM_BASES=5 \
	INPUT=/dev/stdin OUTPUT=/dev/stdout COMPRESSION_LEVEL=0 | \
	java -jar "$DROPSEQ_jar" PolyATrimmer \
	OUTPUT="$tagged_unmapped_bam" \
	OUTPUT_SUMMARY="$OUTPUTFOLDER"/polyA_trimming_report.txt \
	MISMATCHES=0 NUM_BASES=6 \
	INPUT=/dev/stdin
else
	echo -e "\nALREADY EXISTS:  $tagged_unmapped_bam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."

STARTTIME=$SECONDS
# Stage 2
if [ ! -e "$aligned_sam" ] ;then echo -e "\n>>>> Stage 2: bam > fastq > STAR"
	#FASTQ="$TEMP_FILES_PATH"/unaligned_mc_tagged_polyA_filtered.fastq 
	#--readFilesIn "$TEMP_FILES_PATH"/unaligned_mc_tagged_polyA_filtered.fastq
	LOGFILE="$TEMP_FILES_PATH/logs.BamToFastq.logs"
	echo "logfile : $LOGFILE"
	java -Djava.io.tmpdir="$TEMP_FILES_PATH" -jar $PICARD_jar SamToFastq \
	INPUT="$tagged_unmapped_bam" \
	FASTQ=/dev/stdout | \
	"$STAR_ALIGNER_DIR/STAR/STAR" --genomeDir "$GENOME_path"/STAR_index/ \
	--runThreadN $CPU --outFileNamePrefix "$TEMP_FILES_PATH"/star. \
	--readFilesIn /dev/stdin 2> "$LOGFILE"
	echo "Finished!" >> "$LOGFILE"
else
	echo -e "\nALREADY EXISTS:  $aligned_sam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."


STARTTIME=$SECONDS
# Stage 3
if [ ! -e "$aligned_sorted_bam" ]; then echo -e "\n>>>> Stage 3: sort sam"
	java -Djava.io.tmpdir="$TEMP_FILES_PATH" \
	-jar "$PICARD_jar" SortSam \
	INPUT="$aligned_sam" \
	OUTPUT="$aligned_sorted_bam" \
	SORT_ORDER=queryname \
	TMP_DIR="$TEMP_FILES_PATH"
else
	echo -e "\nALREADY EXISTS:  $aligned_sorted_bam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."


STARTTIME=$SECONDS
# Stage 4
if [ ! -e "$tagged_bam" ]; then echo -e "\n>>>> Stage 4 Merge Bam > TagReadWithGeneExon"
	java -Djava.io.tmpdir="$TEMP_FILES_PATH" \
	-jar "$PICARD_jar" MergeBamAlignment \
	REFERENCE_SEQUENCE="$GENOME_path/$GENOME_NAME.$EXT" \
	UNMAPPED_BAM="$tagged_unmapped_bam" \
	ALIGNED_BAM="$aligned_sorted_bam" \
	INCLUDE_SECONDARY_ALIGNMENTS=false PAIRED_RUN=false \
	OUTPUT=/dev/stdout COMPRESSION_LEVEL=0 | \
	java -jar "$DROPSEQ_jar" TagReadWithGeneExon \
	O="$tagged_bam" \
	ANNOTATIONS_FILE="$refflat" \
	TAG=GE CREATE_INDEX=true \
	I=/dev/stdin
else
	echo -e "\nALREADY EXISTS:  $tagged_bam"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."


STARTTIME=$SECONDS
if [ ! -e "$OUTPUTFOLDER/DGE_Matrix.txt" ]; then echo -e "\n>>>> Stage 5: DigitalExpression"
	java -Djava.io.tmpdir="$TEMP_FILES_PATH" -jar "$DROPSEQ_jar" DigitalExpression \
	I="$tagged_bam" \
	O="$OUTPUTFOLDER/DGE_Matrix.txt" \
	CELL_BARCODE_TAG=XC \
	MOLECULAR_BARCODE_TAG=XM \
	CELL_BC_FILE="$TEMP_FILES_PATH"/BarcodeInfo.txt

else
	echo -e "\nALREADY EXISTS:  $OUTPUTFOLDER/DGE_Matrix.txt"
fi
ELAPS=$(( $SECONDS - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."




echo ">>>> End of workflow: making $OUTPUTFOLDER/Summary(Table).txt"

#### - - bash $DROPSEQ_PIPELINE_DIR/CreateSummaryTables.sh - -
"$SAMTOOLS" view "$tagged_bam" | egrep 'INTERGENIC|INTRONIC|UTR|CODING' | cut -f12,13 | sed 's/GE:Z.\+/XF:Z:EXONIC/' > "$OUTPUTFOLDER/SummaryTable.txt"
sort -nk 1 "$OUTPUTFOLDER/SummaryTable.txt" | uniq -c > "$OUTPUTFOLDER/Summary.txt"

echo "NOT DONE: UnfilteredReadCount.txt & BarcodeInfo.txt"
# to do this, I would have to divide the Stage 1 and output the unaligned_tagged_CellMolecular.bam file.
#"$SAMTOOLS" view unaligned_tagged_CellMolecular.bam | cut -f12 | sort | uniq -c > "$OUTPUTFOLDER/UnfilteredReadCount.txt"

#Rscript "$DROPSEQ_PIPELINE_DIR/CreateReadStatistics.R" "$OUTPUTFOLDER/BarcodeInfo.txt"

echo -e "\n\nPARAMETERS were @ $PARAM_FILE"
echo "first 40 lines:"
cat "$PARAM_FILE" | grep -v "^#" | grep -ve "^$" | head -n 40


echo -e "\nEND: $(date)"
ELAPS=$(( $STARTTIME_1 - $STARTTIME ))
echo "$(($ELAPS / 3600))hour $((($ELAPS / 60) % 60))min $(($ELAPS % 60))sec elapsed."
