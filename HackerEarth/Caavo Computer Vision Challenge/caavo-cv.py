import cv2
import tensorflow as tf
import os

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

for key, class_str in list_class_dct:
	print('{} images of {} class'.format(len(os.listdir(os.path.join))))
