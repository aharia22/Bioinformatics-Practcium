import pandas as pd
import requests
# Load the CSV file into a pandas DataFrame
df = pd.read_csv("./data/BigWig_list_human_tcga_BRCA.csv")
# Loop through each row of the DataFrame and download the corresponding BigWig file
for index, row in df.iterrows():
    if index > 49:
        break
    url = row['BigWigURL']
    # Use the external ID as the filename
    filename = "./data/raw_bw/"+row['external_id'] + ".bw"
    response = requests.get(url)
    with open(filename, "wb") as f:
        f.write(response.content)
    print("file"+str(index+1)+" Downloaded!")
