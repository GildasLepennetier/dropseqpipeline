#!/usr/bin/env bash
set -e
#Gildas Lepennetier 2018

echo -e "\nSTARTING script $(basename $0)\t$(date '+%Y-%m-%d %H:%M:%S')\n"

source ${1} #get the variables needed

if [ -z "$STAR_ALIGNER_DIR" ]; then echo "Error: STAR_ALIGNER_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$BCL2FASTQ_DIR" ]; then echo "Error: BCL2FASTQ_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$FASTQC_DIR" ]; then echo "Error: FASTQC_DIR variable not set in parameter file"; exit 1; fi
if [ -z "$SAMTOOLS_DIR" ]; then echo "Error: SAMTOOLS_DIR variable not set in parameter file"; exit 1; fi

# you may need that
#sudo apt install gcc binutils

if [ ! -e "$STAR_ALIGNER_DIR"/STAR ];then echo -e "\n >>> installing STAR @ $STAR_ALIGNER_DIR\n"
	mkdir -p "$STAR_ALIGNER_DIR"
	cd "$STAR_ALIGNER_DIR" #main dir
	#git clone "https://github.com/alexdobin/STAR.git"
	cd STAR/source
	make STAR
	ln -s $(pwd)/STAR "$STAR_ALIGNER_DIR"/STAR
	cd ..
	wget -nc "https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf"
else
	echo "WARNING: Already exists: $STAR_ALIGNER_DIR/STAR (remove it to reinstall)"
fi

if [  ];then echo "impossible to install bcl2fastq on the cluster"
#if [ ! -e "$BCL2FASTQ_DIR/doxygen" ];then echo -e " >>> installing dowygen, required by bcl2fastq"
	mkdir -p "$BCL2FASTQ_DIR/doxygen"
	cd "$BCL2FASTQ_DIR/doxygen"
	wget -nc ftp://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.14.linux.bin.tar.gz
	tar -xf doxygen-1.8.14.linux.bin.tar.gz	
	ls $BCL2FASTQ_DIR/doxygen/doxygen-1.8.14/bin
fi
if [  ];then echo "impossible to install bcl2fastq on the cluster"
#if [ ! -e "$BCL2FASTQ_DIR/boost"  ];then echo -e " >>> installing boost_1_44_0, required by bcl2fastq"
	mkdir -p "$BCL2FASTQ_DIR/boost"
	cd "$BCL2FASTQ_DIR/boost"
	wget -nc http://sourceforge.net/projects/boost/files/boost/1.44.0/boost_1_44_0.tar.gz
	tar -xf boost_1_44_0.tar.gz
	mv boost_1_44_0 boost_1.44.0
fi

if [  ];then # -> the bcl2fastq is just wtf to install on the cluster
#if [ ! -e "$BCL2FASTQ_DIR" ];then echo -e "\n >>> installing bcl2fastq @ $BCL2FASTQ_DIR\n"
	
	echo -e "\n\n######################################\nInstallation of bcl2fastq\n######################################\n\n"
	echo "version: 1.8.4 : hardcodded, to change edit here: $0"
	
	export TMP=/tmp/ga94rac.bcl2fastq.tmpDir/
	export SOURCE=${TMP}/bcl2fastq
	export BUILD=${TMP}/bcl2fastq-build
	export INSTALL=$BCL2FASTQ_DIR/bcl2fastq

	###export BOOST_ROOT=/lrz/sys/share/modules/files/libraries/boost/1.58_gcc	
	export BOOST_ROOT="$BCL2FASTQ_DIR/boost/ #boost_1.44.0" #require 1.44.0 ?
	## ??export BOOST_LIBRARYDIR

	export DOXYGEN_EXECUTABLE=$BCL2FASTQ_DIR/doxygen/doxygen-1.8.14/bin/doxygen
	export DOXYGEN_DOT_EXECUTABLE=$BCL2FASTQ_DIR/doxygen/doxygen-1.8.14/bin/doxyindexer
	
	mkdir -p "$BCL2FASTQ_DIR"
	mkdir -p "$TMP"
	cd "$TMP"

	if [ ! -e bcl2fastq ];then 
		wget -nc ftp://webdata:webdata@ussd-ftp.illumina.com/Downloads/Software/bcl2fastq/bcl2fastq-1.8.4.tar.bz2
		tar -xjf bcl2fastq-1.8.4.tar.bz2
	fi

	mkdir -p ${BUILD}	
	cd ${BUILD}
	${SOURCE}/src/configure --prefix=${INSTALL}
	make
	make install	
	#rm -r "$TMP"
#else
#        echo "WARNING: Already exists: $BCL2FASTQ_DIR (remove it to reinstall)"	
#fi

fi

if [ ! -e "$FASTQC_DIR" ];then echo -e "\n >>> installing fastQC @ $FASTQC_DIR\n"
	mkdir -p "$FASTQC_DIR"
	cd "$FASTQC_DIR"
	wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip
	unzip fastqc_v0.11.8.zip
	chmod +x FastQC/FastQC/fastqc
else
        echo "WARNING: Already exists: $FASTQC_DIR (remove it to reinstall)"
fi



if [ 0 ];then #if [ ! -e "$SAMTOOLS_DIR" ];then echo -e "\n >>> installing samtools @ $SAMTOOLS_DIR\n"

	mkdir -p "$SAMTOOLS_DIR"
	cd "$SAMTOOLS_DIR"
	# THIS VERSION HAS THE htslib in the package, see http://www.htslib.org/download/
	wget -nc 'https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2'
	tar -xjf samtools-1.9.tar.bz2
	cd "$SAMTOOLS_DIR/samtools-1.9"
	autoheader
	autoconf -Wno-syntax
	./configure --prefix="$SAMTOOLS_DIR/samtools/" 
	make all all-htslib
	make install
else
        echo "WARNING: Already exists: $SAMTOOLS_DIR (remove it to reinstall)"
fi
