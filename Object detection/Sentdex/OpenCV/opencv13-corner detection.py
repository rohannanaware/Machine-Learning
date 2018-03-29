#Applications of corner detection - 
#   1. 3-dimensional recreation - detect corners and later recreate the object
#   2. Motion tracking - track the object via the coordiantes of its corners
#   3. Character recognition - redraw the character using its corners

import cv2
import numpy as np

img = cv2.imread('opencv-corner-detection-sample.jpg')
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
gray = np.float32(gray)

corners = cv2.goodFeaturesToTrack(gray, 60, 0.01, 10)
corners = np.int0(corners)

for corner in corners:
    x, y = corner.ravel()
    cv2.circle(img, (x, y), 3, 255, -1)
    
cv2.imshow('Corner', img)
cv2.waitKey(0)
cv2.destroyAllWindows()
