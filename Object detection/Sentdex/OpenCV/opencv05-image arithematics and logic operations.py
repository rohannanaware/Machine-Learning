import numpy as np
import cv2

img1 = cv2.imread('3D-Matplotlib.png')
##img2 = cv2.imread('mainsvmimage.png')
img2 = cv2.imread('mainlogo.png')

##image addition
##add1 = img1 + img2##niether image loses its opaqueness
##add2 = cv2.add(img1, img2)##adds pixel values and floors values more than 255 to 255
##weighted = cv2.addWeighted(img1, 0.6, img2, 0.4, 0)
##
##cv2.imshow('add_basic', add1)
##cv2.imshow('add_cv2', add2)
##cv2.imshow('weighted', weighted)

##impose the logo image on 3d plot while giving a trasparent background
rows, cols, channels = img2.shape
roi = img1[0:rows, 0:cols]##get the roi of image 1 identical to the size of logo

img2gray  = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)##convert the logo into grayscale image
ret, mask = cv2.threshold(img2gray, 220, 255, cv2.THRESH_BINARY_INV)##if threshold of any pixel in image2gray is above 220 then convert it to 255 else to 0, later inverse the Pixel values
mask_inv  = cv2.bitwise_not(mask)##inverse the pixel on the mask image, this will serve as background

img1_bg   = cv2.bitwise_and(roi, roi, mask = mask_inv)##create the background of the roi
img2_fg   = cv2.bitwise_or(img2, img2, mask = mask)##create the foreground of the roi

dst       = cv2.add(img1_bg, img2_fg)

img1[0:rows, 0:cols] = dst

cv2.imshow('img2gray', img2gray)
cv2.imshow('mask', mask)
cv2.imshow('mask_inv', mask_inv)
cv2.imshow('img1_bg', img1_bg)
cv2.imshow('img1', img1)

cv2.waitKey(0)
cv2.destroyAllWindows()
