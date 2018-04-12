# Setting up pyyolo to train and test on customer data

# Steps involved and clarification required
* Understand the pyyolo module and what arguments are taken by it
  * Where is the pyyolo module?
  * How is the pyyolo module calling YOLO model? How is initialization done?
* Prepare the input data for yolo
  * What should the structure for YOLO input file need to be?
  * What is the format of input data required by YOLO
  * What should go into the parser that converts input images into a format that YOLO can use?
* Training in python
  * Can I change the version of YOLO that needs to be trained using pyyolo library

# Reference links
* [Training YOLO to detect custom objects](https://timebutt.github.io/static/how-to-train-yolov2-to-detect-custom-objects/)
* [Location of python modules](https://stackoverflow.com/questions/269795/how-do-i-find-the-location-of-python-module-sources)
 * For a pure python module you can find the source by looking at `themodule.__file__`
