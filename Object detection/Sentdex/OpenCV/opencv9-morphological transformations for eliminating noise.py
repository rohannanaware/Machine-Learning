#morphological transformations
#   1. Erosion - Erodes away noise
#   2. Dilation - Inflates the noise
#   3. Opening - Remove false positives
#   4. Closing - Remove false negatives

import cv2
import numpy as np

img = cv2.imread('ginger_kitten_white_bg_resized.jpg')
#cv2.imshow('cat',img)

hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

lower_col = np.array([5,15,10])
upper_col = np.array([20,255,255])

mask = cv2.inRange(hsv, lower_col, upper_col)#used to filter spcific color ranges from the input image
res = cv2.bitwise_and(img, img, mask= mask)#use mask to filter out the color ranges

kernel   = np.ones((5,5), np.uint8)
erosion  = cv2.erode(mask, kernel, iterations = 1)
dilation = cv2.dilate(mask, kernel, iterations = 1)
opening  = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
closing  = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

cv2.imshow('frame',img)
cv2.imshow('mask',mask)
cv2.imshow('res',res)
cv2.imshow('erosion',erosion)
cv2.imshow('dilation',dilation)
cv2.imshow('opening',opening)
cv2.imshow('closing',closing)

cv2.waitKey(0)
cv2.destroyAllWindows()
