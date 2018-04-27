# Object detection and tracking algorithms

* [Using CNN for object detection](#using-cnn-for-object-detection)
* [Multi - class vs. multi - label classification](#multi-class-vs-multi-label-classification)
* [Object detection techniques](#object-detection-techniques)
* [Questions/ further exploration](#questions)

# Using CNN for object detection

* Reference links - 
  * [Link - Zero to Hero: Guide to Object Detection using Deep Learning: Faster R-CNN,YOLO,SSD](http://cv-tricks.com/object-detection/faster-r-cnn-yolo-ssd/)
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

# CNN architecture

* LeNet, AlexNet, GoogleNet, etc.

# Multi class vs multi label classification

* Reference links
  - [Stackexchange](https://stats.stackexchange.com/questions/11859/what-is-the-difference-between-multiclass-and-multilabel-problem)
  - [Scikit-learn](http://scikit-learn.org/stable/modules/multiclass.html)
  - [Measure of accracy for multi-label model](https://stats.stackexchange.com/questions/12702/what-are-the-measure-for-accuracy-of-multilabel-data)
  - [Solving Multi-Label Classification problems (Case studies included)](https://www.analyticsvidhya.com/blog/2017/08/introduction-to-multi-label-classification/)
  - [Ml-knn: A Lazy Learning Approach to Multi-Label Learning](https://cs.nju.edu.cn/zhouzh/zhouzh.files/publication/pr07.pdf)

* **Multiclass classification** means a classification task with more than two classes; e.g., classify a set of images of fruits which may be oranges, apples, or pears. Multiclass classification makes the assumption that each sample is assigned to one and only one label: a fruit can be either an apple or a pear but not both at the same time
* **Multilabel classification** assigns to each sample a set of target labels. This can be thought as predicting properties of a data-point that are not mutually exclusive, eg. an image of cat and dog together
* **Multioutput-multiclass classification and multi-task classification** means that a single estimator has to handle several joint classification tasks. This is both a generalization of the multi-label classification task, which only considers binary classification, as well as a generalization of the multi-class classification task. The output format is a 2d numpy array or sparse matrix
  * The set of labels can be different for each output variable. For instance, a sample could be assigned “pear” for an output variable that takes possible values in a finite set of species such as “pear”, “apple”; and “blue” or “green” for a second output variable that takes possible values in a finite set of colors such as “green”, “red”, “blue”, “yellow”…
  * This means that any classifiers handling multi-output multiclass or multi-task classification tasks, support the multi-label classification task as a special case. Multi-task classification is similar to the multi-output classification task with different model formulations. For more information, see the relevant estimator documentation

# Object detection techniques

* **Object detection is modelled as a classification problem where we take windows of fixed sizes from input image at all possible locations and feed these patches into an image classifier**
* The location of the objects is given by the location of the image patches where the class probability returned by the object recognition algorithm is high
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/Sliding-window.gif"/>
* How to determine the size of window - 
  * Idea is that we resize the image at multiple scales and we count on the fact that our chosen window size will completely contain the object in one of these resized images
  * Image pyramid is created by scaling the image:
  * <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/pyramid-269x300.png"/>
* How do we deal with aspect ratio - person sitting vs. standing?
* **[Region Proposal Algorithms](https://www.learnopencv.com/selective-search-for-object-detection-cpp-python/)**
  * Takes an image as the input and output **bounding boxes corresponding to all patches in an image that are most likely to be objects**
  * <img src = "https://www.learnopencv.com/wp-content/uploads/2017/10/object-recognition-false-positives-true-positives.jpg"/>
  * These region proposals can be noisy, overlapping and may not contain the object perfectly but amongst these region proposals, there will be a proposal which will be very close to the actual object in the image
  * The region proposals are furhter classified using any classification model and the one with **highest probability score is used to identify the location of the object**
  * Unlike the sliding window approach where we are looking for the object at all pixel locations and at all scales, region proposal algorithm work by **grouping pixels into a smaller number of segments(segmentation)**. This reduces the number of image patches we have to classify
  * In segmentation, we group adjacent regions which are similar to each other based on some criteria such as color, texture etc
  * The idea is to have a **high recall** at the cost of false positives as they can be eliminated using filtering based on probability score in the object classification stage. Approaches used - 
    1. [Objectness](http://groups.inf.ed.ac.uk/calvin/objectness/)
    2. [Constrained Parametric Min-Cuts for Automatic Object Segmentation](http://www.maths.lth.se/matematiklth/personal/sminchis/code/cpmc/index.html)
    3. [Category Independent Object Proposals](http://vision.cs.uiuc.edu/proposals/)
    4. [Randomized Prim](http://www.vision.ee.ethz.ch/~smanenfr/rp/index.html)
    5. [Selective Search](http://koen.me/research/selectivesearch/)
  * **Selective Search for Object Recognition**
    * Reference links - 
      * [Link - Stanford](http://vision.stanford.edu/teaching/cs231b_spring1415/slides/ssearch_schuyler.pdf)
      * [Link - research paper](https://koen.me/research/pub/uijlings-ijcv2013-draft.pdf)
    * Selective Search is a region proposal algorithm that computes hierarchical grouping of similar regions based on color, texture, size and shape compatibility
    * Selective Search starts by **over-segmenting the image based on intensity of the pixels using a graph-based [segmentation method](http://cs.brown.edu/~pff/segment/) by Felzenszwalb and Huttenlocher**. The image on the right contains segmented regions represented using solid colors:
    * <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/breakfast-300x200.jpg"/> <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/breakfast_fnh-300x200.jpg"/>
    * These segments can't be directly used to create region proposals since -
      1. Most of the actual objects in the original image contain 2 or more segmented parts
      2. Region proposals for occluded objects such as the plate covered by the cup or the cup filled with coffee cannot be generated using this method
    * Selective search uses oversegments from Felzenszwalb and Huttenlocher’s method as an initial seed. An oversegmented image looks like this:
    * <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/breakfast_oversegment-300x200.jpg"/>
    * Selective Search algorithm takes these oversegments as initial input and performs the following steps - 
      1. Add all bounding boxes corresponding to segmented parts to the list of regional proposals
      2. Group adjacent segments based on similarity
      3. Repeat
    * This image shows the initial, middle and last step of the **hierarchical segmentation process**:
      * <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/hierarchical-segmentation-1.jpg"/>
    * How is similarity calculated?
      * Selective Search uses 4 similarity measures based on **color, texture, size and shape compatibility**
        * **Color similarity**:
          * A color histogram of 25 bins is calculated for each channel of the image and histograms for all channels are concatenated to obtain a color descriptor resulting into a 25×3 = 75-dimensional color descriptor
          * Color similarity of two regions is based on histogram intersection and can be calculated as:
            * <img src = "https://www.learnopencv.com/wp-content/ql-cache/quicklatex.com-3a99604c3b9fc1664b0ebd9b16aa190c_l3.png"/>
          * c^k_i is the histogram value for k^{th} bin in color descriptor
        * **Texture Similarity**
          * Texture features are calculated by extracting Gaussian derivatives at 8 orientations for each channel. For each orientation and for each color channel, a 10-bin histogram is computed resulting into a 10x8x3 = 240-dimensional feature descriptor
          * Texture similarity of two regions is also calculated using histogram intersections:
            * <img src = "https://www.learnopencv.com/wp-content/ql-cache/quicklatex.com-169d419080f56b69f9645cd13ee5b0ac_l3.png"/>
          * t^k_i is the histogram value for k^{th} bin in texture descriptor
        * **Size Similarity**
          * We want small regions to merge into larger ones, to create a balanced hierarchy
          * Size similarity encourages smaller regions to merge early. It ensures that region proposals at all scales are formed at all parts of the image
          * If this similarity measure is not taken into consideration a single region will keep gobbling up all the smaller adjacent regions one by one and hence region proposals at multiple scales will be generated at this location only
          * Size similarity is defined as:
            * <img src = "https://www.learnopencv.com/wp-content/ql-cache/quicklatex.com-ed6bd32a9661aa84228d1ca1c75f5d29_l3.png"/>
          * where size(im) is size of image in pixels
        * **Shape Compatibility**
          * Shape compatibility measures how well two regions (r_i and r_j) fit into each other. If r_i fits into r_j we would like to merge them in order to fill gaps and if they are not even touching each other they should not be merged
          * Shape compatibility is defined as:
            * <img src = "https://www.learnopencv.com/wp-content/ql-cache/quicklatex.com-9a3fdf638488b3c77915b9b83bf2f3e1_l3.png"/>
          * where size(BB{ij}) is a bounding box around r_i and r_j
        * **Final Similarity**
          * The final similarity between two regions is defined as a linear combination of aforementioned 4 similarities:
            * <img src = "https://www.learnopencv.com/wp-content/ql-cache/quicklatex.com-67a3c5c3f45a9407ee513056c759f095_l3.png"/>
          * where r_i and r_j are two regions or segments in the image and a_i \in {0, 1} denotes if the similarity measure is used or not
        * **Results**
          * Selective Search implementation in OpenCV gives thousands of region proposals arranged in decreasing order of objectness. For clarity, we are sharing results with top 200-250 boxes drawn over the image. In general 1000-1200 proposals are good enough to get all the correct region proposals
          * <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/dogs-golden-retriever-top-250-proposals.jpg"/> <img src = "https://www.learnopencv.com/wp-content/uploads/2017/09/breakfast-top-200-proposals-300x200.jpg"/>

# 1. Object detection using Hog features

* Reference links:
  * [Link - wiki](https://en.wikipedia.org/wiki/Histogram_of_oriented_gradients)
  * [Link - filtering and Enhancing Images](https://courses.cs.washington.edu/courses/cse576/book/ch5.pdf)
  * [Link - learnopencv](https://www.learnopencv.com/histogram-of-oriented-gradients/)
* <img src = "http://cdn-ak.f.st-hatena.com/images/fotolife/c/cool_on/20160122/20160122182347.png"/>v <img src = "http://cdn-ak.f.st-hatena.com/images/fotolife/c/cool_on/20160122/20160122182350.png"/>
* **Feature descriptor** : A feature descriptor is a representation of an image or an image patch that simplifies the image by extracting useful information and throwing away extraneous information
* Typically, a feature descriptor converts an image of size width x height x 3 (channels ) to a feature vector / array of length n. In the case of the HOG feature descriptor, the input image is of size 64 x 128 x 3 and the output feature vector is of length 3780
* The feature vector produced by these algorithms when fed into an image classification algorithms like Support Vector Machine (SVM) produce good results
* On each window obtained from running the sliding window on the pyramid, we calculate Hog Features which are fed to an SVM(Support vector machine) to create classifiers
* The technique counts occurrences of gradient orientation in localized portions of an image
* The essential thought behind the histogram of oriented gradients descriptor is that local **object appearance and shape within an image** can be described by the distribution of **intensity gradients or edge directions**
* The image is divided into small connected regions called **cells**, and for the pixels within each cell, a **histogram of gradient directions** is compiled. The descriptor is the concatenation of these histograms
* For improved accuracy, the local histograms can be contrast-normalized by calculating **a measure of the intensity across a larger region of the image**, called a block, and then using this value to normalize all cells within the block. This normalization results in better **invariance to changes in illumination and shadowing**
* Advantages:
  * Invariant to geometric or photometric transformations(since it operates on localized cells)
* Disadvantages:
  * Prone to change in object orientation
* Questions:
  * *Q. How is object orientation change different than geometric transformations*
  * *Q. What is the difference between the HOG approach from HAAR cascades?*
* Next steps:
  * [Read theory from other links](https://www.learnopencv.com/histogram-of-oriented-gradients/)
  * Read up more on the implementation part
 
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
   * [Local Features and Bag of Words Models with Spatial pyramid](http://web.iitd.ac.in/~sumeet/16.pdf)
* An SPP layer is added on top of the last convolutional layer
* The SPP layer pools the features and generates fixedlength outputs, which are then fed into the fullyconnected layers (or other classifiers)
*  In other words, we perform some information “aggregation” at a deeper stage of the network hierarchy (between convolutional layers and fully-connected layers) to avoid the need for cropping or warping at the beginning
  * The convolutional layers accept arbitrary input sizes, but they produce outputs of variable sizes
  * The classifiers (SVM/softmax) or fully-connected layers require fixed-length vectors
  * Such  vectors  can  be  generated by the Bag-of-Words(BoW) approach that pools the features together
  * Spatial  pyramid  pooling, improves BoW in that it can maintain spatial information by pooling in local spatial bins
  * These spatial bins have sizes proportional to the image size, so the number of bins is fixed regardless of the image size
  * To adopt the deep network for images of arbitrary sizes, we replace the last pooling layer
  * In each spatial bin, we pool the responses  of  each filter
  * The  outputs  of  the  spatial  pyramid  pooling  are kM-dimensional vectors with the number of bins denoted as M(k is the number of  filters  in  the  last  convolutional layer). The fixed-dimensional vectors are the input to the fully-connected layer
* <img src = "http://cv-tricks.com/wp-content/uploads/2016/12/CNN.png"/>

  * A network structure with a spatial pyramid pooling  layer. Here  256  is  the  filter  number  of  the conv5 layer, and conv5 is the last convolutional layer
* Major drawback is that it's difficult to perform back propogation through the spatial pooling layer
* Using SPP-net, we compute the feature maps from the entire
image only once, and then pool features in arbitrary regions (sub-images) to generate fixed-length representations for training
the detectors
* *Needs more research*
  * *On what basis are the pixels in the original image mappped with Pixels in the final convoluted image?*
  * *How is a portion of the Pixels selected and converted to a fixed size to be sent into the classification layers?*
  * *Why is back-propogation difficult?*

# 4. Fast R-CNN

* Reference links:
  * [Link - arxiv](https://arxiv.org/abs/1504.08083)
  * [Link - github](https://github.com/rbgirshick/fast-rcnn)
* Need more research on how this is different than SPP-net

# 5. Faster R-CNN

* Slowest part in Fast RCNN was **Selective Search or Edge boxes**. Faster RCNN replaces selective search with a very small convolutional network called **Region Proposal Network** to generate regions of Interests
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/Faster-RCNN-CV-Tricks-1.jpg"/>
* At each location, the original paper uses 3 kinds of **anchor boxes** for scale 128x 128, 256×256 and 512×512. Similarly, for aspect ratio, it uses three aspect ratios 1:1, 2:1 and 1:2. So, In total at each location, we have 9 boxes on which RPN predicts the probability of it being background or foreground
* RPN gives out bounding boxes of various sizes with the corresponding probabilities of each class

# 6. Mask R-CNN
* Reference links:
  * [Link - arxiv](https://arxiv.org/abs/1703.06870)

# Regression-based object detectors
* Classification based object detectors first generate object proposals which are later sent into classification or regression heads
* Few methods pose detection as a regression problem. Two of the most popular ones are YOLO and SSD

# 7. YOLO(You only Look Once)
* Reference links - 
  * [How to train yolov2-to detect custom objects?](https://timebutt.github.io/static/how-to-train-yolov2-to-detect-custom-objects/)
  * [Link - arxiv](https://arxiv.org/pdf/1506.02640.pdf)
  * [Link - Standford](http://cs229.stanford.edu/proj2016/report/BuhlerLambertVilim-CS229FinalProjectReport.pdf)
* YOLO divides each image into a grid of S x S and each grid predicts N bounding boxes and confidence
* The confidence reflects the accuracy of the bounding box and whether the bounding box actually contains an object(regardless of class)
* YOLO also predicts the classification score for each box for every class in training. You can combine both the classes to calculate the probability of each class being present in a predicted box
* <img src = "http://cv-tricks.com/wp-content/uploads/2017/12/model2-1024x280.jpg"/>

* **1. Introduction**
  * <img src = "https://lh5.googleusercontent.com/wruU7oqG8qUityMNHvl6gyADe3V-_s5mws9jkCSVjE2WANKK3SPfelHQDgDHqh76VqyYm5Bxc5p74yiXGppG7nmTjY2_gebDsI_9vXqEr-GcSTq-_m1xlwE2pTdo4Mp2Vo3FYnpr"/>
  * **Figure 1**:The YOLO Detection System. Processing images with YOLO is simple and straightforward. Our system (1) resizes the input image to 448×448, (2) runs a single convolutional net-work on the image, and (3) thresholds the resulting detections by
the model’s confidence
  * Object detection is reframed as a single regression problem,  straight  from  image  pixels  to  bounding  box  coordinates and class probabilities
  * A  single  convolutional  network  simultaneously  predicts  multiple bounding boxes and class probabilities for those boxes
  * **Since we frame detection as a regression problem we don’t need a complex pipeline***Why?*
* **2. Unified Detection**
  * Our  network  uses  features from the entire image to predict each bounding box. It also predicts  all  bounding  boxes  across  all  classes  for  an  image simultaneously
  * Our system divides the input image into an S×S grid. If the center of an object falls into a grid cell, that grid cell is responsible for detecting that object
  * Each grid cell predicts B bounding boxes and confidence scores for those boxes. These confidence scores reflect how confident the model is that the box contains an object and also how accurate it thinks the box is that it predicts
  * Formally we define confidence as Pr(Object)∗IOU_truth_pred. If no object exists in that cell,  the confidence scores should be zero.  Otherwise we want the confidence score to equal the intersection  over  union  (IOU)  between  the  predicted  box
and the ground truth
  * Each bounding box consists of 5 predictions:x,y,w,h,and confidence. The (x,y) coordinates represent the center of the box relative to the bounds of the grid cell. The width and height are predicted relative to the whole image. Finally the confidence prediction represents the IOU between the predicted box and any ground truth box
  * Each grid cell also predicts C conditional class probabilities, Pr(Class(i) | Object). These probabilities are conditioned on the grid cell containing an object. We only predict one set of class probabilities per grid cell, regardless of the number of boxes B
  * At test time we multiply the conditional class probabilities and the individual box confidence predictions,
    * ` Pr(Class(i)|Object)∗Pr(Object)∗IOU_truth_pred = Pr(Class(i))∗IOU_truth_pred`
  * which  gives  us  class-specific  confidence  scores  for  each box.  These scores encode both the probability of that class appearing in the box and how well the predicted box fits the object
  * <img src = "http://cfile3.uf.tistory.com/image/2327094158E5EDD5118443"/>
    * Figure 2: The Model. Our system models detection as a regression problem. It divides the image into an S × S grid and for each grid cell predicts B bounding boxes, confidence for those boxes, and C class  probabilities.   These  predictions  are  encoded  as  an S × S × (B ∗ 5 + C) tensor

# 8. Single Shot Multi Box Detector(SSD)

* SSD runs a convolutional network on input image only once and calculates a feature map

# 9. RetinaNet
* Reference links
  * [RetinaNet github page](https://github.com/fizyr/keras-retinanet)
  * [Focal Loss for Dense Object Detection](https://arxiv.org/abs/1708.02002)
* The highest accuracy object detectors to date are based on a **two-stage approach popularized by R-CNN**, where a classifier is applied to a sparse set of candidate object locations
* In contrast, one-stage detectors that are applied over a regular, dense sampling of possible object locations have the potential to be faster and simpler, but have trailed the accuracy of two-stage detectors thus far
* In this paper(2nd link), we investigate why this is the case - 
  * We discover that the **extreme foreground-background class imbalance** encountered during training of dense detectors is the central cause
* We propose to address this class imbalance by reshaping the **standard cross entropy loss** such that it down-weights the loss assigned to well-classified examples
* Our novel Focal Loss focuses training on a **sparse set of hard examples** and prevents the vast number of easy negatives from **overwhelming the detector** during training
* To evaluate the effectiveness of our loss, we design and train a simple dense detector we call **RetinaNet**
* **Our results show that when trained with the focal loss, RetinaNet is able to match the speed of previous one-stage detectors while surpassing the accuracy of all existing state-of-the-art two-stage detector**

# 10. HAAR Cascades

* [Summary](https://pdfs.semanticscholar.org/0f1e/866c3acb8a10f96b432e86f8a61be5eb6799.pdf)
* [Haar-like feature](https://en.wikipedia.org/wiki/Haar-like_feature)
* [Face Detection using Haar Cascades ](https://docs.opencv.org/3.4.1/d7/d8b/tutorial_py_face_detection.html)
* [Cascade Classifier Training ](https://docs.opencv.org/3.4.1/dc/d88/tutorial_traincascade.html)

# 11. Residual nets

- Reference - 
  - [Link - arxiv](https://arxiv.org/abs/1512.03385)
  - [Why ResNets Are A Major Breakthrough In Image Processing](https://analyticsindiamag.com/why-resnets-are-a-major-breakthrough-in-image-processing/)

# Questions
- Mean average predcision calculation


