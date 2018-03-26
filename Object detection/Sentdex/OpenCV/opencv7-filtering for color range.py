#input images - ginger kitten white background

import cv2
import numpy as np

img = cv2.imread('ginger_kitten_white_bg_resized.jpg')
#cv2.imshow('cat',img)

hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

lower_col = np.array([5,15,10])
upper_col = np.array([20,255,255])

mask = cv2.inRange(hsv, lower_col, upper_col)#used to filter spcific color ranges from the input image
res = cv2.bitwise_and(img, img, mask= mask)#use mask to filter out the color ranges

cv2.imshow('frame',img)
cv2.imshow('mask',mask)
cv2.imshow('res',res)

cv2.waitKey(0)
cv2.destroyAllWindows()
