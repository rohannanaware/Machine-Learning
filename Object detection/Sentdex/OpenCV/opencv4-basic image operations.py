import numpy as np
import cv2

'''
Flow of any image analysis -
    1. Import image
    2. Convert to grayscale
    3. Perform analysis - Find coordinates of a face, etc.
    4. Deploy on the color image - Draw the rectangle etc. on the color image
'''

img = cv2.imread('wrist_watch.jpg', cv2.IMREAD_COLOR)

##get the value of pixel by its coordinates
px = img[55,55]
print(px)
##[150 152 152]

##modify a pixel
img[55,55] = [255,255,255]
px = img[55,55]
##[255 255 255]
print(px)
##cv2.imshow('image',img)
##cv2.waitKey(0)
##cv2.destroyAllWindows()

''''
RoI - Region of an image
'''
roi = img[100:150, 100:250]
print(roi)
##img[100:150, 100:250] = [255,255,255]

##copy and paste a RoI
watch_face = img[37:111, 107:194]##region of image
img[0:74, 0:87] = watch_face
##cv2.imshow('image',img)
##cv2.waitKey(0)
##cv2.destroyAllWindows()
