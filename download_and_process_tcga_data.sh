#!/bin/bash

#need to run in interactive shell instead of sbatch!

# Set the name of the conda environment
ENV_NAME="bioinfo-env"
RAW_BW_DIR="./data/raw_bw"
BEDGRAPH_DIR="./data/bedGraph_files"
BED_DIR="./data/mountainClimber_outputs1"

if command -v conda &> /dev/null; then
    echo "conda is installed"
else
    echo "conda is not installed, you need conda to continue..."
    echo "Exiting script"
    exit 1
fi

# Check if the environment already exists
if conda env list | grep -q "^${ENV_NAME}"; then
    echo "Environment '${ENV_NAME}' already exists."
else
        # Check if requirements.txt exists in the current directory
    if [ -f "requirements.txt" ]; then
        echo "requirements.txt exists"
    else
        echo "requirements.txt does not exist"
        exit 1
    fi
    echo "Creating environment '${ENV_NAME}' from requirements.txt..."
    conda create -n "${ENV_NAME}" -c bioconda -c conda-forge --file requirements.txt
fi

#Activate bioinfo-env
source $HOME/miniconda3/etc/profile.d/conda.sh #Change to your conda path
conda activate ${ENV_NAME}
echo "conda environment '${ENV_NAME}' activated!"


#Run data_process.py
if [ ! -d "$RAW_BW_DIR" ]; then
    echo "Create folder ./data/raw_bw"  
    mkdir ./data/raw_bw
    python data_process.py
else
    echo "raw_bw files already downloaded"  
fi

#Convert bigwig files to bedgraph
if [ ! -d "$BEDGRAPH_DIR" ]; then
    echo "Create folder ./data/bedGraph_files"  
    mkdir ./data/bedGraph_files
    for file in "$RAW_BW_DIR"/*; do
        echo "Processing file: $file"
        bigWigToBedGraph $file "$BEDGRAPH_DIR"/$(basename ${file%.*}).bedGraph
    done
else
    echo "bedGraph files already converted from bigwig"  
fi

#Call MountainClimber to get Transcription units
#Convert bigwig files to bedgraph
if [ ! -d "mountainClimber" ]; then
    git clone https://github.com/gxiaolab/mountainClimber.git
else
    echo "package mountainClimber already installed"  
fi

if [ ! -d "$BED_DIR" ]; then
    echo "Create folder '$BED_DIR'"  
    mkdir $BED_DIR
    for file in "$BEDGRAPH_DIR"/*; do
        echo "Processing file: $file"
        python ./mountainClimber/src/mountainClimberTU.py -b $file -s 0 -g ./data/hg38.genome -o "$BED_DIR"/$(basename ${file%.*}).bed
    done
else
    echo "bed files already generated from mountainClimber"  
fi