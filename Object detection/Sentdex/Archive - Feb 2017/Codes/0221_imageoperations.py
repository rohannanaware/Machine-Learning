import numpy as np
import cv2

img = cv2.imread('wrist_watch.jpg', cv2.IMREAD_COLOR)

img[200,200] = [255,255,255]
px = img[55,55]
img[100:150, 100:150] = [255,255,255]

watch_face = img[51:141, 113:213]
img[0:90,0:100] = watch_face

cv2.imshow('image', img)
cv2.waitKey(0)
cv2.destroyAllWindows()