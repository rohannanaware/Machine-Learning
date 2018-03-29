#removing background noise/ false detections using -
#   1. Filters
#   2. Gaussian blur

import cv2
import numpy as np

img = cv2.imread('ginger_kitten_white_bg_resized.jpg')
#cv2.imshow('cat',img)

hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

lower_col = np.array([5,15,10])
upper_col = np.array([20,255,255])

mask = cv2.inRange(hsv, lower_col, upper_col)#used to filter spcific color ranges from the input image
res = cv2.bitwise_and(img, img, mask= mask)#use mask to filter out the color ranges

kernel = np.ones((15,15), np.float32)/255#create an average of a 15*15 roi
smoothened = cv2.filter2D(res, -1, kernel)#apply the kernel on the result image

blur = cv2.GaussianBlur(res, (5,5), 0)
median = cv2.medianBlur(res, 5)
bilateral = cv2.bilateralFilter(res, 15, 75, 75)

cv2.imshow('frame',img)
cv2.imshow('mask',mask)
cv2.imshow('res',res)
#cv2.imshow('smoothened',smoothened )#removes noise but makes the image blurred
cv2.imshow('gaussian_blur',blur)
cv2.imshow('median',median)#top performer
cv2.imshow('bilateral',bilateral)

cv2.waitKey(0)
cv2.destroyAllWindows()
