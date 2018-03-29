import cv2
import numpy as np


##Use webcam to capture video - the number indicates the webcam
cap = cv2.VideoCapture(0)
##code to save video feed
fourcc = cv2.VideoWriter_fourcc(*'XVID')
out = cv2.VideoWriter('output.avi', fourcc, 20.0, (640,480))

while True:
    ret, frame = cap.read()
    cv2.imshow('frame', frame)

    ##convert the BGR image into grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    cv2.imshow('frame_gray', gray)

    out.write(frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

##to load a video file
##cap = cv2.VideoCapture('output.avi')
