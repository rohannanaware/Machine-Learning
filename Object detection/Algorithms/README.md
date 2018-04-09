# HAAR Cascades

* [Summary](https://pdfs.semanticscholar.org/0f1e/866c3acb8a10f96b432e86f8a61be5eb6799.pdf)
* [Haar-like feature](https://en.wikipedia.org/wiki/Haar-like_feature)
* [Face Detection using Haar Cascades ](https://docs.opencv.org/3.4.1/d7/d8b/tutorial_py_face_detection.html)
* [Cascade Classifier Training ](https://docs.opencv.org/3.4.1/dc/d88/tutorial_traincascade.html)


# RetinaNet

* Reference links
  * [RetinaNet github page](https://github.com/fizyr/keras-retinanet)
  * [Focal Loss for Dense Object Detection](https://arxiv.org/abs/1708.02002)

* The highest accuracy object detectors to date are based on a **two-stage approach popularized by R-CNN**, where a classifier is applied to a sparse set of candidate object locations
* In contrast, one-stage detectors that are applied over a regular, dense sampling of possible object locations have the potential to be faster and simpler, but have trailed the accuracy of two-stage detectors thus far
* In this paper, we investigate why this is the case - 
  * We discover that the **extreme foreground-background class imbalance** encountered during training of dense detectors is the central cause
* We propose to address this class imbalance by reshaping the **standard cross entropy loss** such that it down-weights the loss assigned to well-classified examples
* Our novel Focal Loss focuses training on a **sparse set of hard examples** and prevents the vast number of easy negatives from **overwhelming the detector** during training
* To evaluate the effectiveness of our loss, we design and train a simple dense detector we call **RetinaNet**
* **Our results show that when trained with the focal loss, RetinaNet is able to match the speed of previous one-stage detectors while surpassing the accuracy of all existing state-of-the-art two-stage detector**

# Using CNN for object detection

[Link](http://cv-tricks.com/object-detection/faster-r-cnn-yolo-ssd/)

* An image classifier can tell whether an image is cat or dog. If both are present in the same image then we use a multi-label classifier to assign multiple labels to the image. This does not tell the location of the image
* Identifying the location of an object(given the class) in an image is called as **localization**. If the object class is not known, we have to not only determine the location but also predict the class of each object
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/detection-vs-classification-300x220.png"/>
* **Predicting the location of the object along with the class is called object Detection**
* For an object we will be predicting - 
  * class_name
  * bounding_box_top_left_x_coordinate
  * bounding_box_top_left_y_coordinate
  * bounding_box_width
  * bounding_box_height
* Just like multi-label image classification problems, we can have multi-class object detection problem where we detect multiple kinds of objects in a single image: 
  * <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/Multi-class-object-detection.png"/>
  
# Multi - class vs. multi - label classification

- [Link - stackexchange](https://stats.stackexchange.com/questions/11859/what-is-the-difference-between-multiclass-and-multilabel-problem)
- [Link - scikit-learn](http://scikit-learn.org/stable/modules/multiclass.html)

* **Multiclass classification** means a classification task with more than two classes; e.g., classify a set of images of fruits which may be oranges, apples, or pears. Multiclass classification makes the assumption that each sample is assigned to one and only one label: a fruit can be either an apple or a pear but not both at the same time
* **Multilabel classification** assigns to each sample a set of target labels. This can be thought as predicting properties of a data-point that are not mutually exclusive, eg. an image of cat and dog together
* **Multioutput-multiclass classification and multi-task classification** means that a single estimator has to handle several joint classification tasks. This is both a generalization of the multi-label classification task, which only considers binary classification, as well as a generalization of the multi-class classification task. The output format is a 2d numpy array or sparse matrix
  * The set of labels can be different for each output variable. For instance, a sample could be assigned “pear” for an output variable that takes possible values in a finite set of species such as “pear”, “apple”; and “blue” or “green” for a second output variable that takes possible values in a finite set of colors such as “green”, “red”, “blue”, “yellow”…
  * This means that any classifiers handling multi-output multiclass or multi-task classification tasks, support the multi-label classification task as a special case. Multi-task classification is similar to the multi-output classification task with different model formulations. For more information, see the relevant estimator documentation

# Object detection techniques

* **Object detection is modelled as a classification problem where we take windows of fixed sizes from input image at all possible locations and feed these patches into an image classifier**
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/Sliding-window.gif"/>
* How to determine the size of window - 
  * Idea is that we resize the image at multiple scales and we count on the fact that our chosen window size will completely contain the object in one of these resized images
  * Image pyramid is created by scaling the image:
  * <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/pyramid-269x300.png"/>
* How do we deal with aspect ratio?

# 1. Object detection using Hog features

* On each window obtained from running the sliding window on the pyramid, we calculate Hog Features which are fed to an SVM(Support vector machine) to create classifiers
* Reference links:
 * [Wiki](https://en.wikipedia.org/wiki/Histogram_of_oriented_gradients)
 
# 2. Region-based Convolutional Neural Networks(R-CNN)

* As the object detection is modelled to be classification problem the success will be measured in terms of classification accuracy
* Deeplearning algorithms generally perform better than Hog features, although techniques like CNN take large computational power and time.It's impossible to run CNNs on so many patches generated by sliding window detector
* R-CNN solves this problem by using an object proposal algorithm called **Selective Search** which reduces the number of bounding boxes that are fed to the classifier to close to 2000 region proposals
* Selective search uses local cues like texture, intensity, color and/or a measure of insideness etc to generate all the possible locations of the object. These locations/ boxes can be fed into CNN based classifier
* **Remember, fully connected part of CNN takes a fixed sized input so, we resize(without preserving aspect ratio) all the generated boxes to a fixed size (224×224 for VGG) and feed to the CNN part. Hence, there are 3 important parts of R-CNN:**
  * Run Selective Search to generate probable objects
  * Feed these patches to CNN, followed by SVM to predict the class of each patch
  * Optimize patches by training bounding box regression separately
  * <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/RCNN-e1514378306435.jpg"/>
  
# 3. Spatial Pyramid Pooling(SPP-net)

* **With SPP-net, we calculate the CNN representation for entire image only once and can use that to calculate the CNN representation for each patch generated by Selective Search**
* Reference links - 
 * [Spatial Pyramid Pooling in Deep Convolutional - Networks for Visual Recognition arxiv](https://arxiv.org/pdf/1406.4729.pdf)
  * An SPP layer is added on top of the last convolutional layer
  * The SPP layer pools the features and generates fixedlength outputs, which are then fed into the fullyconnected layers (or other classifiers)
  *  In other words, we perform some information “aggregation” at a deeper stage of the network hierarchy (between convolutional layers and fully-connected layers) to avoid the need for cropping or warping at the beginning
  
 * <img src = "http://cv-tricks.com/wp-content/uploads/2016/12/CNN.png"/>
 * Major drawback is that it's difficult to perform back propogation through the spatial pooling layer

# 4. Fast R-CNN

# 5. Faster R-CNN

# Regression-based object detectors
* Classification based object detectors first generate object proposals which are later sent into classification or regression heads
* Few methods pose detection as a regression problem. Two of the most popular ones are YOLO and SSD

# 6. YOLO(You only Look Once)
* YOLO divides each image into a grid of S x S and each grid predicts N bounding boxes and confidence
* The confidence reflects the accuracy of the bounding box and whether the bounding box actually contains an object(regardless of class)
* YOLO also predicts the classification score for each box for every class in training. You can combine both the classes to calculate the probability of each class being present in a predicted box
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/model2-1024x280.jpg"/>

# 7. Single Shot Detector(SSD)

* SSD runs a convolutional network on input image only once and calculates a feature map
