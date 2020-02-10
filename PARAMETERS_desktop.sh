#!/usr/bin/env bash
set -e
#Gildas Lepennetier 2018

DROPSEQ_PIPELINE_DIR="$HOME/TOOLS/dropseqpipeline/"
DROP_SEQ_TOOLS="$HOME/TOOLS/drop-seq_tools/"
DROPSEQ_jar="$HOME/TOOLS/drop-seq_tools/jar/dropseq.jar"
STAR_ALIGNER_DIR="$HOME/TOOLS/"
NB_CPU_STAR_INDEX=1
PICARD_jar="$DROP_SEQ_TOOLS/3rdParty/picard/picard.jar"
BCL2FASTQ_DIR="$HOME/TOOLS/Illunina"
BCL2FASTQ="$BCL2FASTQ_DIR/bcl2fastq"
FASTQC_DIR="$HOME/TOOLS/FastQC/FastQC/" # ! on the cluster, load module !  module load java/1.8
FASTQC="$FASTQC_DIR/fastqc"
SAMTOOLS_DIR="$HOME/TOOLS/samtools/" #not used: install was auto
SAMTOOLS="/usr/bin/samtools"
INPUTFOLDER="/media/ga94rac/DISK2/RAD_SEQUENCING/180221_NB501802_0048_AHJTTHBGX5"
OUTPUTFOLDER="/media/ga94rac/DISK2/RAD_SEQUENCING/180221/dropseq_out"
TEMP_FILES_PATH="/media/ga94rac/DISK2/RAD_SEQUENCING/180221/dropseq_tmp"
READ_1_LEN=75
READ_2_LEN=17
####################### annotations
# MOUSE
GENOME_fasta="ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M19/GRCm38.p6.genome.fa.gz"
GENOME_gtf="ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M19/gencode.vM19.basic.annotation.gtf.gz"
GENOME_path="/media/ga94rac/DISK2/GENOME/gencode/release_29/mouse/" # local storage address
GENOME_NAME="GRCm38.p6"
