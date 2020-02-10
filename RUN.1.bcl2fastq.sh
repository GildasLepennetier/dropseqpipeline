#!/usr/bin/env bash
set -e
#Gildas Lepennetier | Thomas 2018

echo -e "START $(basename $0)\t$(date '+%Y-%m-%d %H:%M:%S')"

if [ $# -ne 1 ];then
	echo "ERROR: wrong usage of the function, check require argument"
	echo "usage: $(basename $0) PARAMETER.sh"
	exit
fi

PARAM_FILE="$1"
if [ ! -e "$PARAM_FILE" ] ;then echo "Error: cannot find parameter file @ $PARAM_FILE (use of absolut path?)"; exit 1 ; fi
source "$PARAM_FILE" #get the variables needed

###### check parameters
if [ -z "$INPUTFOLDER" ]; then echo "Error: INPUTFOLDER variable not set in parameter file"; exit 1; fi
if [ ! -d "$INPUTFOLDER" ];then echo "Error: wrong parameter: the input folder does dot exist at $INPUTFOLDER"; exit 1; fi
if [ -z "$TEMP_FILES_PATH" ]; then echo "Error: TEMP_FILES_PATH variable not set in parameter file"; exit 1; fi
if [ ! -d "$TEMP_FILES_PATH" ];then mkdir -p "$TEMP_FILES_PATH"; fi
if [ -z "$RUN_DATE" ]; then echo "Error: RUN_DATE variable not set in parameter file"; exit 1; fi
if [ -z "$READ_1_LEN" ]; then echo "Error: READ_1_LEN variable not set in parameter file"; exit 1; fi
if [ -z "$READ_2_LEN" ]; then echo "Error: READ_2_LEN variable not set in parameter file"; exit 1; fi

###### parse some informations
if [ -e "$INPUTFOLDER/RunParameters.xml" ];then
	cp -v "$INPUTFOLDER/RunParameters.xml" "$TEMP_FILES_PATH/RunParameters.xml"
	RunName=$(grep '<ExperimentName>' "$INPUTFOLDER/RunParameters.xml" | sed 's/  <ExperimentName>//g ; s/<\/ExperimentName>//g ;  s/[^[:print:]\t]//g')
	LibID=$(grep '<LibraryID>' "$INPUTFOLDER/RunParameters.xml" | sed 's/  <LibraryID>//g ; s/<\/LibraryID>//g ;  s/[^[:print:]\t]//g')
	echo "$RunName" > "$INPUTFOLDER/RunName.txt"
	echo "$LibID" > "$INPUTFOLDER/LibID.txt"
else
	echo "Error: RunParameters.xml not found in \$INPUTFOLDER $INPUTFOLDER"
	exit 1
fi
###### BarcodeInfo.txt
if [ -e "$INPUTFOLDER/BarcodeInfo.txt" ];then 
	echo "BarcodeInfo.txt already exist, not overwriting"
else
	echo -e 'AAAACT\nATATAG\nGTTTAT\nTGTTTA\nGCTAGA\nCCCACG\nCGGTGG\nGCTCGC\nAAAGTT\nATCAAA\nTAAAGT\nTTAATC\nGGGATT\nCCCCGT\nCGTGGG\nGGAGCC\nAAATTG\nATGAAT\nTAAGAT\nTTAGTT\nGTTCGA\nCCCTGG\nCTGCGG\nGGCCAC\nAAGATT\nATTACT\nTAATGA\nTTATTG\nTCTGCA\nCCGGAC\nGACCGC\nGGCGTC\nAATACA\nATTCTA\nTACTAT\nTTGAAA\nCCAACC\nCCGTCG\nGAGCGG\nGGGCAG\nAATCTT\nATTTCA\nTAGTAA\nTTTACA\nGTACCG\nCCTGGC\nGCACGG\nGGGGAC\nAATTCT\nCAAATA\nTATAGA\nTTTCTT\nACCGGC\nCGAGGC\nGCCAGG\nGGGTCG\nACAATA\nCATTAT\nTATGAA\nTTTTGA\nACGGGG\nCGCCCT\nGCCCTC\nGGTGGC\nACTTAT\nCTATAT\nTATTGT\nAGACCT\nAGCGGG\nCGCGCA\nGCCGTG\nGTGCGC\nAGATTA\nCTTTAA\nTCATAT\nCACCAA\nAGGGGC\nCGCTGC\nGCGAGC\nTCCCGC\nATAAAC\nGATAAT\nTCTTAA\nCCACAT\nCACGGC\nCGGCCA\nGCGCTG\nTCGGGC\nATACAA\nGTAATA\nTGATTT\nCTAGTG\nCAGGGG\nCGGGCT\nGCGGTC\nTGGCCG' > "$INPUTFOLDER/BarcodeInfo.txt"
	
fi
###### SampleSheet.csv
if [ -e "$INPUTFOLDER/SampleSheet.csv" ];then 
	echo "SampleSheet.csv already exist, not overwriting"
else
	echo -e '[Header]\nIEMFileVersion,4\nExperiment Name,'$RunName'\nDate,'$RUN_DATE'\nWorkflow,GenerateFASTQ\nApplication,NextSeq FASTQ Only\nAssay,TruSeq HT\nDescription,Chemistry,Default\n\n[Reads]\n'$READ_1_LEN'\n'$READ_2_LEN'\n\n[Settings]\n\n[Data]\nSample_ID,Sample_Name,Sample_Plate,Sample_Well,Sample_Project,Description\n'$LibID','$RunName',,,,' > "$INPUTFOLDER/SampleSheet.csv"
fi
###### check input files
if [ $( find "$INPUTFOLDER" -maxdepth 1 -name "*fastq.gz" | wc -l) -ne 0 ]; then 
	echo "Warning: files in *fastq.gz already exist at $TEMP_FILES_PATH. Aborded. Remove & run again after removing files:"
	find "$INPUTFOLDER" -maxdepth 1 -name "*fastq.gz"
	exit
fi

###### copy useful files
cp -v "$INPUTFOLDER/SampleSheet.csv" "$INPUTFOLDER/BarcodeInfo.txt" "$INPUTFOLDER/RunName.txt" "$INPUTFOLDER/LibID.txt" "$TEMP_FILES_PATH/"

######  RUN
echo "Running $BCL2FASTQ"
LOGFILE="$TEMP_FILES_PATH/logs.bcl2fastq.logs"
echo "logfile : $LOGFILE"
$BCL2FASTQ --runfolder-dir "$INPUTFOLDER" --output-dir "$TEMP_FILES_PATH" --no-lane-splitting --mask-short-adapter-reads=13 2> "$LOGFILE"
echo "Finished!" >> "$LOGFILE"

echo -e "\n\nPARAMETERS were @ $PARAM_FILE"
echo "first 40 lines:"
cat "$PARAM_FILE" | grep -v "^#" | grep -ve "^$" | head -n 40

