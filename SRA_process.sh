#!/bin/bash

# Download and Unzip reference genome
if [ ! -e "GRCh38.primary_assembly.genome.fa" ]; then
    wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_38/GRCh38.primary_assembly.genome.fa.gz
    gzip -d GRCh38.primary_assembly.genome.fa.gz
fi

# Build HISAT2 index
index_dir="./data/SRA/GRCh38_idx"
mkdir -p "${index_dir}"

if [ ! -e "${index_dir}/GRCh38_index.1.ht2" ]; then
    hisat2-build GRCh38.primary_assembly.genome.fa "${index_dir}/GRCh38_index"
fi

# Replace SRRXXXXXX with the actual SRA accession number
fastq_dir="./data/SRA/fastq"
sam_output_dir="./data/SRA/SAM"
bam_output_dir="./data/SRA/BAM"
mkdir -p "${sam_output_dir}"
mkdir -p "${bam_output_dir}"

# Install Samtools if not installed
if ! command -v samtools &> /dev/null; then
    conda install -c bioconda samtools
fi

for fastq_file in "${fastq_dir}"/*_1.fastq.gz; do
    sra_accession=$(basename "${fastq_file}" _1.fastq.gz)

    # Run HISAT2 alignment
    if [ ! -e "${sam_output_dir}/${sra_accession}.sam" ]; then
        echo "Working on HISAT2 alignment for ${sra_accession}..."
        hisat2 --dta-cufflinks --no-softclip --no-mixed --no-discordant -k 100 -x "${index_dir}/GRCh38_index" -1 "${fastq_dir}/${sra_accession}_1.fastq.gz" -2 "${fastq_dir}/${sra_accession}_2.fastq.gz" -S "${sam_output_dir}/${sra_accession}.sam"
        echo "Finish HISAT2 alignment for ${sra_accession}..."
    fi

done


for sam_file in "${sam_output_dir}"/*.sam; do
    sra_accession=$(basename "${sam_file}" .sam)
    # Convert SAM to BAM
    if [ ! -e "${bam_output_dir}/${sra_accession}.bam" ]; then
        echo "Working on BAM file conversion and sorting for ${sra_accession}..."
        samtools view -bS "${sam_output_dir}/${sra_accession}.sam" > "${bam_output_dir}/${sra_accession}.bam"
        samtools sort ${bam_output_dir}/${sra_accession}.bam -o ${bam_output_dir}/${sra_accession}_sorted.bam
        echo "Finish file conversion and sorting for ${sra_accession}..."
    fi

done

echo "Processing complete!"
