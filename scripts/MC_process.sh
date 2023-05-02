#!/bin/bash

# Define output directories, file paths, and the mountainClimber repo directory
bam_output_dir="./data/SRA/BAM"
mtnClbOut_dir="./data/mountainClimberOutput"
mtnClb_junc_dir="${mtnClbOut_dir}/junctions"
mtnClb_bedgraph_dir="${mtnClbOut_dir}/bedgraph"
mtnClb_tu_dir="${mtnClbOut_dir}/mountainClimberTU"
mtnClb_repo_dir="./mountainClimber"
hg38_chrom_fpath="./data/hg38.chrom_sizes"

# Download hg38 gene sizes if not already present
if [ ! -f "$hg38_chrom_fpath" ]; then
    wget --timestamping -O "$hg38_chrom_fpath" ftp://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.chrom.sizes
fi

# Clone the mountainClimber repository if not already present
if [ ! -d "$mtnClb_repo_dir" ]; then
    git clone https://github.com/gxiaolab/mountainClimber.git
fi

# Create necessary output directories
mkdir -p "${mtnClbOut_dir}"
mkdir -p "${mtnClb_junc_dir}"
mkdir -p "${mtnClb_bedgraph_dir}"
mkdir -p "${mtnClb_tu_dir}"

# Get junction reads for each bam file
for bam_file in "${bam_output_dir}"/*_sorted.bam; do
    sra_accession=$(basename "${bam_file}" _sorted.bam)
    if [ ! -e "${mtnClb_junc_dir}/${sra_accession}_jxn.bed" ]&& [ ! -e "${mtnClb_junc_dir}/${sra_accession}_jxn.bed.tmp" ]; then
        echo "Get junction counts for ${sra_accession}..."
        python "${mtnClb_repo_dir}/src/get_junction_counts.py" -i "${bam_output_dir}/${sra_accession}_sorted.bam" -s fr-unstrand -o "${mtnClb_junc_dir}/${sra_accession}_jxn.bed"
        echo "Finish junction counts generation for ${sra_accession}..."
    fi
done

# Generate bedgraphs for each bam file
for bam_file in "${bam_output_dir}"/*_sorted.bam; do
    sra_accession=$(basename "${bam_file}" _sorted.bam)
    if [ ! -e "${mtnClb_bedgraph_dir}/${sra_accession}.bedgraph" ]; then
        echo "Generate bedgraphs for ${sra_accession}..."
        bedtools genomecov -trackline -bg -split -ibam "${bam_output_dir}/${sra_accession}_sorted.bam" -g "$hg38_chrom_fpath" > "${mtnClb_bedgraph_dir}/${sra_accession}.bedgraph"
        echo "Finish bedgraphs generation for ${sra_accession}..."
    fi

done

# Keep only rows starting with 'chr' for each junc_file
for junc_file in "${mtnClb_junc_dir}"/*_jxn.bed; do
    sra_accession=$(basename "${junc_file}" _jxn.bed)
    if [ ! -e "${mtnClb_junc_dir}/${sra_accession}_jxn_trim.bed" ]; then
        grep '^chr' "$junc_file" > "${mtnClb_junc_dir}/${sra_accession}_jxn_trim.bed"
    fi
done

# Sort the hg38 chromosome sizes file
sorted_genome="./data/hg38.chrom_sizes.sorted"
echo "Start sorting for hg38_chroms..."
if [ ! -f "$sorted_genome" ]; then
    sort -k1,1 $hg38_chrom_fpath > "${sorted_genome}.sorted"
fi
echo "Finish sorting for hg38_chrom!"

# Sort all junction files
echo "Start sorting for all junction files..."
for junc_file in "${mtnClb_junc_dir}"/*_jxn_trim.bed; do
    sra_accession=$(basename "${junc_file}" _jxn_trim.bed)
    if [ ! -e "${mtnClb_junc_dir}/${sra_accession}_jxn_sorted.bed" ]; then
        sort -k1,1 -k2,2n $junc_file > "${mtnClb_junc_dir}/${sra_accession}_jxn_sorted.bed"
    fi
done
echo "Finish sorting for all junction files!"

# Sort all bedgraph files
echo "Start sorting for all bedgraph files..."
for bg_file in "${mtnClb_bedgraph_dir}"/*.bedgraph; do
    sra_accession=$(basename "${bg_file}" .bedgraph)
    if [ ! -e "${mtnClb_bedgraph_dir}/${sra_accession}_sorted.bedgraph" ] && [[ ! "${bg_file}" =~ _sorted\.bedgraph$ ]]; then
        sort -k1,1 -k2,2n $bg_file > "${mtnClb_bedgraph_dir}/${sra_accession}_sorted.bedgraph"
    fi
done
echo "Finish sorting for all bedgraph files!"


#Run mountainCliber TU!!
# Iterate over all bedgraph files in the mtnClb_bedgraph_dir directory
for bedgraph_file in "${mtnClb_bedgraph_dir}"/*_sorted.bedgraph; do
    # Extract the file's base name without extension
    sra_accession=$(basename "$bedgraph_file" _sorted.bedgraph)

    # Define the corresponding jxn.bed file and output file paths
    jxn_file="${mtnClb_junc_dir}/${sra_accession}_jxn_sorted.bed"
    mountainClimber_output="${mtnClb_tu_dir}/${sra_accession}_tu.bed"

    # Check if the output file does not exist
    if [ ! -f "$mountainClimber_output" ]; then
        # Run mountainClimberTU.py with the bedgraph and jxn.bed files
        echo "Processing files: $bedgraph_file and $jxn_file"
        python "${mtnClb_repo_dir}/src/mountainClimberTU.py" -b "$bedgraph_file" -j "$jxn_file" -s 0 -g "${hg38_chrom_fpath}.sorted" -o "$mountainClimber_output"
    fi
done

