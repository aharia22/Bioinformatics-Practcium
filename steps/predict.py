import numpy as np
import pandas as pd

from sklearn.model_selection import KFold, cross_val_predict
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score, confusion_matrix
# from sklearn.utils import shuffle

import matplotlib.pyplot as plt
import seaborn as sns

import argparse
import warnings
warnings.filterwarnings('ignore')

def ReadFeatureAndLabel(feature_file, label_file):
	feature = np.load(feature_file)
	label = pd.read_csv(label_file, index_col=0, header=0)
	label = label['label']
	# feature, label = shuffle(feature, label)

	return feature, label

def plot_roc_auc(fpr, tpr, roc_auc, model_name):
	sns.set_style('whitegrid')
	plt.figure(figsize=(6, 6))
	plt.plot(fpr, tpr, linewidth=2, label=f'ROC-AUC = {roc_auc:.2f}', color='#ff7f0e')
	plt.plot([0, 1], [0, 1], linestyle='--', color='grey', linewidth=2)
	plt.xlabel('False Positive Rate', fontsize=14)
	plt.ylabel('True Positive Rate', fontsize=14)
	plt.xticks(fontsize=12)
	plt.yticks(fontsize=12)
	plt.title('ROC-AUC Curve', fontsize=16)
	plt.legend(fontsize=12)
	plt.tight_layout()
	plt.savefig(model_name + ".png")
	plt.show()
	plt.close()  

def plot_cm(cm, class_labels, model_name, acc):  
	plt.figure(figsize=(6,6), dpi=500)
	sns.set(font_scale=1.4)
	sns.heatmap(cm, annot=True, fmt='d', xticklabels=class_labels, yticklabels=class_labels, cmap='Blues')
	plt.xlabel('Predicted')
	plt.ylabel('True')
	plt.title("Confusion Matrix")
	plt.savefig(model_name + "_cm.png")
	plt.close()

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
	if model_name == 'lr-l1':
		model = LogisticRegression(penalty='l1', solver='liblinear')
		print("Model: Logistic Regression with L1 penalty")
	if model_name == 'lr':
		model = LogisticRegression()
		print("Model: Logistic Regression")
	if model_name == 'svm':
		model = SVC()
		print("Model: SVM")
	if model_name == 'rf':
		model = RandomForestClassifier()
		print("Model: Random Forest")
	
	# Load Features
	X, y = ReadFeatureAndLabel(feature_file, label_file)
	# Train Models
	y_pred = cross_val_predict(model, X, y, cv=nsplit)
	acc = accuracy_score(y, y_pred)
	f1 = f1_score(y, y_pred, average='macro')
	print(f"Accuracy: {acc}")
	print(f"F1 score: {f1}")
	class_labels = np.unique(y)
	cm = confusion_matrix(y, y_pred, labels=class_labels)
	plot_cm(cm, class_labels, model_name, acc)

