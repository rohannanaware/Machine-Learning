### Procedure for setting up environmet to run retinanet

#### Clone the retinanet repository-
 - `git clone --recursive https://github.com/fizyr/keras-retinanet.git`
 
#### Install dependencies-
 - `sudo pip install . --user`
 - Note that due to inconsistencies with how tensorflow should be installed, this package does not define a dependency on tensorflow as it will try to install that (which at least on Arch Linux results in an incorrect installation). Please make sure tensorflow is installed as per your systems requirements. Also, make sure Keras 2.1.3 or higher is installed
 
#### Optinal installation
 - Optionally, install `pycocotools` if you want to train / test on the MS COCO dataset by running `pip install --user git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI`
 
