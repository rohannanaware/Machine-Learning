import cv2
import tensorflow as tf
import os
import pandas as pd
import keras
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix


# Process flow - 
'''
- View on number and size of images in each class
- Read in images
    - Convert to grayscale and resize as required
    - Perform sampling
- Define the CNN structure
- Train, optimize the model
- Test on validation set
    - k-fold
- Predict for test data
'''

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

# Update - 25th Apr 2018

# function to read images
def read_image(filepath, target_size = (28, 28)):
    img = cv2.imread(os.path.join(data_dir, filepath), cv2.IMREAD_GRAYSCALE)
    img = cv2.resize(img.copy(), target_size, interpolation = cv2.INTER_AREA)
    return img

if False:
    train_df['image_heigth'] = 0
    train_df['image_width'] = 0

    #get all image shapes
    for i in range(len(train_df)):
        img = read_image(train_df.filepath.values[i])
        train_df.loc[i,'image_heigth'] = img.shape[0]
        train_df.loc[i,'image_width'] = img.shape[1]

    test_df['image_heigth'] = 0
    test_df['image_width'] = 0

    # get all image shapes
    for i in range(len(test_df)):
        img = read_image(test_df.filepath.values[i])
        test_df.loc[i,'image_heigth'] = img.shape[0]
        test_df.loc[i,'image_width'] = img.shape[1]

    # get details on the size of train and test images
    print(train_df.describe())
    print(test_df.describe())
    
    train_df.head()
    test_df.head()

# sampling train data

# number of images per class
class_sample_size = 100

train_df =  pd.concat([train_df[train_df['class_str'] == class_str][:class_sample_size]
                               for class_num, class_str in list_class_dct])

# read in all images in the sample

X_train = []
Y_train = []
for i in train_df.shape[0]:
    img = read_image(train_df[i, 'filepath'], (28, 28))
    X_train.append(img)
    Y_train.append(train_df[i, 'class_num'])
    
# split the data into train and validation set
random_seed = 1993
X_train, X_val, Y_train, Y_val = train_test_split(X_train, 
                                                  Y_train, 
                                                  test_size = 0.2, 
                                                  random_state = random_seed)

# define model architecture

model = keras.models.Sequential()

model.add(Conv2D(filters = 32,
                 kernel_size = (5,5),
                 padding = 'Same',
                 activation = 'relu',
                 input_shape = (28, 28, 1)))
model.add(Conv2D(filters = 32,
                 kernel_size = (5,5),
                 padding = 'Same',
                 activation = 'relu'))
model.add(MaxPool2D(pool_size = (2,2)))
model.add(Dropout(0.25))

model.add(Conv2D(filters = 64,
                 kernel_size = (3,3),
                 padding = 'Same',
                 activation = 'relu'))
model.add(Conv2D(filters = 64,
                 kernel_size = (3,3),
                 padding = 'Same',
                 activation = 'relu'))
model.add(MaxPool2D(pool_size = (2,2),
                    strides = (2,2)))
model.add(Dropout(0.25))

model.add(Flatten())
model.add(Dense(256, activation = 'relu'))
model.add(Dropout(0.5))
model.add(Dense(10, activation = 'softmax'))
