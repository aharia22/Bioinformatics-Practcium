#!/bin/bash

output_dir="./data/SRA/fastq"
mkdir -p "${output_dir}"

# install the lastest version of SRA toolkit from
# Since we are using centOS on  https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/3.0.2/sratoolkit.3.0.2-centos_linux64.tar.gz

# add the bin(enviroment variable) to your bashrc/zshrc file
for i in {48..75}; do
    SRR_ID="SRR107598${i}"
    FASTQ_FILE_1="${output_dir}/${SRR_ID}_1.fastq.gz"
    FASTQ_FILE_2="${output_dir}/${SRR_ID}_2.fastq.gz"

    if [[ ! -e "${FASTQ_FILE_1}" || ! -e "${FASTQ_FILE_2}" ]]; then
        echo "Running fastq-dump for ${SRR_ID}..."
        fastq-dump --gzip --split-files --outdir "${output_dir}" "${SRR_ID}"
        echo "Finish fastq-dump for ${SRR_ID}!"
    else
        echo "Fastq files for ${SRR_ID} already exist. Skipping..."
    fi
done