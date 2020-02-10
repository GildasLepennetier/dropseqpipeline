#!/usr/bin/env bash
set -e
#Gildas Lepennetier | Thomas 2018

echo -e "START $(basename $0)\t$(date '+%Y-%m-%d %H:%M:%S')"

if [ $# -ne 1 ];then
	echo "ERROR: not enough arguments"
	echo "usage: $(basename $0) <PARAMETER.sh>"
	exit
fi

PARAM_FILE="$1"
if [ ! -e "$PARAM_FILE" ] ;then echo "Error: cannot find parameter file @ $PARAM_FILE (use of absolut path?)"; exit 1 ; fi
source "$PARAM_FILE" #get the variables needed

if [ -z "$STAR_ALIGNER_DIR" ]; then echo "Error: STAR_ALIGNER_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$DROP_SEQ_TOOLS" ]; then echo "Error: DROP_SEQ_TOOLS variable not set in parameter file"; exit 1; fi
if [ -z "$PICARD_jar" ]; then echo "Error: PICARD_jar variable not set in parameter file"; exit 1; fi
if [ -z "$DROPSEQ_PIPELINE_DIR" ]; then echo "Error: DROPSEQ_PIPELINE_DIR variable not set in parameter file"; exit 1; fi

if [ -z "$GENOME_path" ]; then echo "Error: GENOME_path variable not set in parameter file"; exit 1; fi
if [ -z "$GENOME_NAME" ]; then echo "Error: GENOME_NAME variable not set in parameter file"; exit 1; fi

if [ -z "$TEMP_FILES_PATH" ]; then echo "Error: TEMP_FILES_PATH variable not set in parameter file"; exit 1; fi
if [ ! -d "$TEMP_FILES_PATH" ];then mkdir -p "$TEMP_FILES_PATH"; fi

cd "$TEMP_FILES_PATH"

RunName=$(cat "$TEMP_FILES_PATH/RunName.txt")
if [ -z "$RunName" ];then echo "Error: RunName empty"; exit 1; fi

if [ $(ls *'_S1_R1_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 1"; exit 1; fi
if [ $(ls *'_S1_R2_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 1"; exit 1; fi
R1=$(ls *'_S1_R1_001.fastq.gz' )
R2=$(ls *'_S1_R2_001.fastq.gz' )
echo "R1='$R1' -> will be used as ReverseRead"
echo "R2='$R2' -> will be used as ForwardRead"
ForwardRead="$R2"
ReverseRead="$R1"



if [  ];then echo -e "\n\n\t>>> Create bam file without alignment [FastqToSam]"
	LOGFILE="$TEMP_FILES_PATH/logs.FastqToSam.logs"
	echo "logfile : $LOGFILE"
	#java "-Djava.io.tmpdir=$TEMP_FILES_PATH" -jar "$PICARD_jar" FastqToSam F1="$ForwardRead" F2="$ReverseRead" O="$RunName.bam" SM="$RunName" 2> "$LOGFILE"
	#echo "Finished!" >> "$LOGFILE"
fi

if [  ];then echo -e "\n\n\t>>> Sort bam file according to read ID [SortSam]"
	LOGFILE="$TEMP_FILES_PATH/logs.SortSam.logs"
	echo "logfile : $LOGFILE"
	java -Xmx20g "-Djava.io.tmpdir=$TEMP_FILES_PATH" -jar "$PICARD_jar" SortSam I="$RunName.bam" O="$RunName"_sorted.bam SORT_ORDER=queryname 2> "$LOGFILE"
	echo "Finished!" >> "$LOGFILE"
fi


if [ 0 ];then echo "Start Dropseq tool"
	
	"$DROP_SEQ_TOOLS/Drop-seq_alignment.sh" -g "$STAR_ALIGNER_DIR" -r "$GENOME_path/$GENOME_NAME" -d "$DROP_SEQ_TOOLS" -s "$STAR_ALIGNER_DIR/STAR/STAR" "$RunName"_sorted.bam
	
	### add those options before 
	###-o "$TEMP_FILES_PATH" -t "$TEMP_FILES_PATH" 
	### see with option -p to pipe files...
	
	#"$DROP_SEQ_TOOLS/DigitalExpression" -m 30g I=star_gene_exon_tagged.bam O=DGE_Matrix.txt CELL_BARCODE_TAG=XC MOLECULAR_BARCODE_TAG=XM CELL_BC_FILE="$TEMP_FILES_PATH"/BarcodeInfo.txt
	
	
	#bash $DROPSEQ_PIPELINE_DIR/CreateSummaryTables.sh

	#Rscript "$DROPSEQ_PIPELINE_DIR/CreateReadStatistics.R" "$TEMP_FILES_PATH"/BarcodeInfo.txt

fi

echo -e "\n\nPARAMETERS were @ $PARAM_FILE"
echo "first 40 lines:"
cat "$PARAM_FILE" | grep -v "^#" | grep -ve "^$" | head -n 40
