import sys
import os

dir_name = "E:/Delivery/1 Active/Halite"
test = os.listdir(dir_name)

for item in test:
    if item.endswith(".hlt"):
        os.remove(os.path.join(dir_name, item))