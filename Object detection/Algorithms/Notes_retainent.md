
# RetinaNet

[Focal Loss for Dense Object Detection](https://arxiv.org/abs/1708.02002)

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
