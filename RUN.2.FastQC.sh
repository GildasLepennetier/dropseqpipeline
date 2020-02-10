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

if [ -z "$TEMP_FILES_PATH" ]; then echo "Error: TEMP_FILES_PATH variable not set in parameter file"; exit 1; fi
if [ ! -d "$TEMP_FILES_PATH" ];then echo "Error: missing directory at: $TEMP_FILES_PATH"; exit 1; fi

cd "$TEMP_FILES_PATH"

if [ $(ls *'_R1_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 1"; exit 1; fi
if [ $(ls *'_R2_001.fastq.gz' | wc -l ) -gt 1 ];then echo "Error: several read 2"; exit 1; fi
R1=$(ls *'_R1_001.fastq.gz' )
R2=$(ls *'_R2_001.fastq.gz' )
echo "R1='$R1' -> will be used as ReverseRead"
echo "R2='$R2' -> will be used as ForwardRead"
ForwardRead="$R2"
ReverseRead="$R1"

mkdir -p "$TEMP_FILES_PATH/QC"

echo "running $FASTQC"

"$FASTQC" "$ForwardRead" "$ReverseRead" --outdir="$TEMP_FILES_PATH/QC"

echo -e "\n\nPARAMETERS were @ $PARAM_FILE"
echo "first 40 lines:"
cat "$PARAM_FILE" | grep -v "^#" | grep -ve "^$" | head -n 40