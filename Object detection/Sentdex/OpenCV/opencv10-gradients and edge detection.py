import cv2
import numpy as np

frame = cv2.imread('ginger_kitten_white_bg_resized.jpg')

#edge detection techniques
laplacian = cv2.Laplacian(frame, cv2.CV_64F)
sobelx = cv2.Sobel(frame, cv2.CV_64F, 1, 0, ksize = 5)
sobely = cv2.Sobel(frame, cv2.CV_64F, 0, 1, ksize = 5)
edges  = cv2.Canny(frame, 200, 200)

cv2.imshow('originial', frame)
cv2.imshow('laplacian', laplacian)
cv2.imshow('sobelx', sobelx)
cv2.imshow('sobely', sobely)
cv2.imshow('edges', edges)

cv2.waitKey(0)
cv2.destroyAllWindows()
