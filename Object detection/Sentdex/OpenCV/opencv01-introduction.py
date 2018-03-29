'''
Reference - https://opencv.org/
https://stackoverflow.com/questions/1810743/how-to-set-the-current-working-directory
'''

import cv2
import numpy as np
import matplotlib.pyplot as plt
import os

##os.chdir('D:\\Delivery\01 Active\Python\Object detection and analysis')

img = cv2.imread('wrist_watch.jpg', cv2.IMREAD_GRAYSCALE)
'''
Any image has an RGB and alpha(to indicate the opacity)
Other arguments that can be given to imread -
    IMREAD_COLOR(1) = Reads BGR
    IMREAD_UNCHANGED(-1) = Reads BGR with alpha
'''

##display image using opencv
cv2.imshow('image',img)
cv2.waitKey(0)
cv2.destroyAllWindows()

####display image using matplotlib
##plt.imshow(img, cmap = 'gray', interpolation = 'bicubic')
####plot on the image
##plt.plot([50, 100], [80,100], 'c', linewidth = 5)
##plt.show()

##save the image
cv2.imwrite('watchgray.png', img)
