import cv2
import tensorflow as tf
import os
import pandas as pd

# print the working directory
print('Current working directory : ', os.getcwd())

# print the folder names/ list of classes in train folder
data_dir  = os.getcwd()
train_dir = os.path.join(data_dir, 'train')
test_dir  = os.path.join(data_dir, 'test')

print('List of classes in train directory : ', os.listdir(train_dir))

# list of classes in train directory
list_class_num = os.listdir(train_dir)
list_class_dct = {'1':'Blouse',
				  '2':'Cloak',
				  '3':'Coat',
				  '4':'Jacket',
				  '5':'Jersey',
				  '6':'Long Dress',
				  '7':'Polo Shirt',
				  '8':'Robe',
				  '9':'Shirt',
				  '10':'Short Dress',
				  '11':'Suit',
				  '12':'Sweater',
				  '13':'Undergarment',
				  '14':'Uniform',
				  '15':'Waistcoat'}
print('Checking if the dictionary was defined properly : ', list_class_dct['11'])

for class_num, class_str in list_class_dct:
	print('{} images of {} class'.format(len(os.listdir(os.path.join(train_dir, class_num))), class_str))

# create a lookup file for the train & test data
train = []
for class_num, class_str in list_class_dct:
	for file in os.listdir(os.path.join(train_dir, class_num)):
		train.append(['train/{}/{}'.format(class_num, file), file, class_num, class_str])

train_df = pd.DataFrame(train, columns = ['filepath', 'file', 'class_num', 'class_str'])
print('Size of train data : ', train_df.shape)

test = []
for file in os.listdir(test_dir):
	test.append(['test/{}'.format(file), file])

test_df = pd.DataFrame(test, columns = ['filepath', 'file'])
print('Size of test data : ', test_df.shape)
