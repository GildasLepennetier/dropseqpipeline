#!/usr/bin/env bash
set -e
#Gildas Lepennetier 2018

echo -e "\nSTARTING script $(basename $0)\t$(date '+%Y-%m-%d %H:%M:%S')"

source ${1} #get the variables needed

if [ -z "$GENOME_NAME" ]; then echo "Error: GENOME_NAME variable not set in parameter file"; exit 1; fi
if [ -z "$GENOME_path" ]; then echo "Error: GENOME_path variable not set in parameter file"; exit 1; fi
if [ -z "$GENOME_gtf" ]; then  echo "Error: GENOME_gtf variable not set in parameter file"; exit 1; fi
if [ -z "$PICARD_jar" ]; then  echo "Error: PICARD_jar variable not set in parameter file"; exit 1; fi
if [ -z "$DROP_SEQ_TOOLS" ]; then  echo "Error: DROP_SEQ_TOOLS variable not set in parameter file"; exit 1; fi
if [ -z "$STAR_ALIGNER_DIR" ]; then  echo "Error: STAR_ALIGNER_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$NB_CPU_STAR_INDEX" ]; then  echo "Error: NB_CPU_STAR_INDEX variable not set in parameter file"; exit 1; fi


# # #
REFERENCE_FA=$GENOME_NAME.fa
REFERENCE_GTF=$GENOME_NAME.gtf
PICARD_SEQ_DICT=$GENOME_NAME.dict
PICARD_REFFLAT=$GENOME_NAME.refFlat
STAR_OUTPUT=${GENOME_path}/STAR_index


# ### genome sequence and annotations
echo -e "\n>>> Downloading reference genome"
mkdir -p ${GENOME_path}
cd ${GENOME_path}

if [ ! -e ${REFERENCE_FA} ];then
	wget -nc ${GENOME_fasta}
	zcat $(basename ${GENOME_fasta}) > ${REFERENCE_FA}
else
	echo "WARNING: Already exists: ${REFERENCE_FA} (remove it to reinstall)"
fi

if [ ! -e ${REFERENCE_GTF} ];then
	wget -nc ${GENOME_gtf}
	zcat $(basename ${GENOME_gtf}) > ${REFERENCE_GTF}
else
	echo "WARNING: Already exists: ${REFERENCE_GTF} (remove it to reinstall)"
fi


echo -e "\n>>> CreateSequenceDictionary picard"
cd ${GENOME_path}

if [ ! -e ${GENOME_path}/${PICARD_SEQ_DICT} ];then
	java -jar ${PICARD_jar} CreateSequenceDictionary REFERENCE=${GENOME_path}/${REFERENCE_FA} OUTPUT=${GENOME_path}/${PICARD_SEQ_DICT}
else
	echo "WARNING: Already exists: ${GENOME_path}/${PICARD_SEQ_DICT} (remove it to reinstall)"
fi

if [ ! -e ${GENOME_path}/$PICARD_REFFLAT ];then
	${DROP_SEQ_TOOLS}/ConvertToRefFlat ANNOTATIONS_FILE=${GENOME_path}/$REFERENCE_GTF SEQUENCE_DICTIONARY=${GENOME_path}/$PICARD_SEQ_DICT OUTPUT=${GENOME_path}/$PICARD_REFFLAT 2> ${GENOME_path}/Error.ConvertToRefFlat.log
else
	echo "WARNING: Already exists: ${GENOME_path}/$PICARD_REFFLAT (remove it to reinstall)"
fi

if [ ! -e ${STAR_OUTPUT} ];then
	mkdir -p ${STAR_OUTPUT}
	${STAR_ALIGNER_DIR}/STAR/STAR --runMode genomeGenerate --genomeDir ${STAR_OUTPUT} --genomeFastaFiles ${GENOME_path}/${REFERENCE_FA} --runThreadN $NB_CPU_STAR_INDEX
else
	echo "WARNING: Already exists: ${STAR_OUTPUT} (remove it to reinstall)"
fi

