# template matching - apply a threshold to match the template to the whole image
#                   - not very dynamic - lighting, rotation dependant                    
# feature matching - overcomes the lack of dynamic nature from template matching

import cv2
import numpy as np
import matplotlib.pyplot as plt

img1 = cv2.imread('opencv-feature-matching-template.jpg', 0)
img2 = cv2.imread('opencv-feature-matching-image.jpg', 0)

# detector of similarities
orb = cv2.ORB_create()

# key points and detectors
kp1, des1 = orb.detectAndCompute(img1, None)
kp2, des2 = orb.detectAndCompute(img2, None)

# find the key points and discriptors with orb detector
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck = True)

# find the matches and sort them by the strength of match
matches = bf.match(des1, des2)
matches = sorted(matches, key = lambda x:x.distance)

# show the match between img1 and img2
img3 = cv2.drawMatches(img1, kp1, img2, kp2, matches[:30], None, flags = 2)
plt.imshow(img3)
plt.show()
