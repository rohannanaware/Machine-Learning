import numpy as np
import cv2

img = cv2.imread('wrist_watch.jpg', cv2.IMREAD_COLOR)

##draw on the image - arguments(image, start, end, color, width/fill)
cv2.line(img, (0, 0), (150, 150), (255,255,255), 5)
cv2.rectangle(img, (0, 0), (150, 150), (255,0,0), 5)
cv2.circle(img, (100, 100), 50, (0,255,0), -1)##-1 indicates fill

##add polylines
pts = np.array([[0,0],[0,100],[100,100],[50,50], [100,0]], np.int32)
cv2.polylines(img, [pts], True, (0,0,255), 5)

##add font into the image
font = cv2.FONT_HERSHEY_SIMPLEX
#arguments(image, text, origin, font style, fint size, color, width, anti annotation(?))
cv2.putText(img, 'OpenCV tutorial', (0, 130), font, 1, (0, 0, 0), 5, cv2.LINE_AA)

cv2.imshow('image', img)
cv2.waitKey(0)
cv2.destroyAllWindows()
