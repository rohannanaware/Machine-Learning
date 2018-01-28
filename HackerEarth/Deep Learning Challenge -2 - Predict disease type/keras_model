'''
Author : Rohan M. Nanaware
Purpose: 1. Learn basics of building NN, document challenges faced, areas that need improvement
         2. Learn basics of building image classifier
         3. Help Baymax!
Date C.: 29th Jan 2018
Date M.: 29th Jan 2018

Ref.   :

1. Simple Image Classification using CNN - using keras
   https://becominghuman.ai/building-an-image-classifier-using-deep-learning-in-python-totally-from-a-beginners-perspective-be8dbaf22dd8
2. Types of activation functions
   https://towardsdatascience.com/activation-functions-neural-networks-1cbd9f8d91d6
'''

#Import required libraries
from keras.models import Sequential
from keras.layers import Conv2D
from keras.layers import MaxPooling2D
from keras.layers import Flatten
from keras.layers import Dense

classifier = Sequential()
classifier.add(Conv2D(32,
                      (3,3),
                      input_shape = (64,64,3),
                      activation = 'relu'))
classifier.add(MaxPooling2D(pool_size = (2,2)))
classifier.add(Flatten())
#nodes and activation function for hidden layer
classifier.add(Dense(units = 128, activation = 'relu'))
#output layer
classifier.add(Dense(units = 14, activation = 'sigmoid'))
