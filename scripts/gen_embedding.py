import numpy as np
import pandas as pd
import argparse
from pathlib import Path
import os
from sklearn.decomposition import PCA

import warnings
warnings.filterwarnings('ignore')

# Get chromosome length
def GetChrLength(chrom_size, chrom):
    tab = pd.read_table(chrom_size, header=None, sep='\t')
    tab.columns = ['chr', 'size']
    
    return np.max(tab['size'][tab['chr'] == chrom])
    
# Read file
def ReadBedFile(chrom, file, chr_size_dir):
    chr_len = GetChrLength(chr_size_dir / "hg38.chrom.sizes.txt", chrom)
    unit_info = np.zeros(chr_len)
    with open(file, 'r') as f:
        count = 0
        for l in f:
            if count == 0:
                count += 1
                continue
            line = l.strip('\n').split('\t')
            if line[0] != chrom:
                continue
            unit_info[int(line[1]):int(line[2])+1] += 1
            
            count += 1
    return unit_info

def binning_chr(unit_info, res):
	binned_unit_info = np.zeros(int(np.ceil(len(unit_info) / res)))

	for i in range(len(binned_unit_info)):
		binned_unit_info[i] = np.sum(unit_info[i * res:min((i + 1) * res, len(unit_info))])

	return binned_unit_info

def dim_reduction(X, k):
	pca = PCA(n_components=k)
	X_pca = pca.fit_transform(X)
	print("Explained variance ratio:", pca.explained_variance_ratio_)

	return X_pca

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('--data_dir', type=Path)
	parser.add_argument('--chr_size_dir', type=Path)
	parser.add_argument('--res', type=int)
	# parser.add_argument('--nsamples', type=int)

	args = parser.parse_args()
	data_dir = args.data_dir
	chr_size_dir = args.chr_size_dir
	res = args.res
	
	embed_chr = []
	chrom_list = ["chr%d"%(i+1) for i in range(22)]
	print(chrom_list)
    
	nsamples = 0
	for _ in sorted(os.listdir(data_dir)):
		nsamples += 1
	
	for chrom in chrom_list:
		embed = []
		for bedfile in sorted(os.listdir(data_dir)):
			print("Find bedfile:", bedfile)
			unit_info = ReadBedFile(chrom, data_dir / bedfile, chr_size_dir)
			binned_unit_info = binning_chr(unit_info, res)
			embed.append(binned_unit_info)
		embed_concat = np.concatenate(embed, axis=0).reshape((nsamples, len(binned_unit_info)))
		embed_pca = dim_reduction(embed_concat, 5)
		embed_chr.append(embed_pca)

	chr_features = np.concatenate(embed_chr, axis=1)
	np.save("chr_features.npy", chr_features)

