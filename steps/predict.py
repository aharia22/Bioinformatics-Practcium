import numpy as np
import pandas as pd

from sklearn.model_selection import KFold
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

import argparse
import warnings
warnings.filterwarnings('ignore')

def ReadFeatureAndLabel(feature_file, label_file):
	feature = np.load(feature_file)
	label = pd.read_csv(label_file, index_col=0, header=0)
	label = label['label']

	return feature, label     

if __name__ == "__main__":
	parser = argparse.ArgumentParser()
	parser.add_argument('--feature_file', type=str)
	parser.add_argument('--label_file', type=str)
	parser.add_argument('--model_name', type=str)
	parser.add_argument('--nsplit', type=int)

	args = parser.parse_args()
	feature_file = args.feature_file
	label_file = args.label_file
	model_name = args.model_name
	nsplit = args.nsplit

	kf = KFold(n_splits=5)
	if model_name == 'lr':
		model = LogisticRegression()
	if model_name == 'svm':
		model = SVC()
	if model_name == 'rf':
		model = RandomForestClassifier()
	
	# Load feature
	X, y = ReadFeatureAndLabel(feature_file, label_file)
	
	accuracies = []
	for train_index, test_index in kf.split(X):
		X_train, X_test = X[train_index], X[test_index]
		y_train, y_test = y[train_index], y[test_index]
		model.fit(X_train, y_train)
		y_pred = model.predict(X_test)
		accuracy = accuracy_score(y_test, y_pred)
		accuracies.append(accuracy)
	
	print(f"{nsplit} fold cross validation")
	print(f"Accuracy: {sum(accuracies) / len(accuracies)}")

