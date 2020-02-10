#!/usr/bin/env bash
set -e
#Gildas Lepennetier 2018

#Installation script for dropseq pipeline

if [ $# -ne 1 ];then 
	echo "Usage: $(basename $0) <PARAMETER.sh>"
	echo "the PARAMETER.sh file will be used to get all the variables, set us the environment, install the programs, prepare the genome."
	exit
fi

cd "$(dirname $0)"

bash install_scripts/install_programs.sh $1

bash install_scripts/prepare_genome.sh $1

