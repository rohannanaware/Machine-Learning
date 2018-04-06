<h2>Object detection and tracking</h2>


<h3>Using mobile phone as an IP camera</h3>

* Go to your app store and install IP Webcam
* Open the app, Press “Start server” and note the IP address mentioned at the bottom of the screen
* Connect both your phone and your laptop to the same network, maybe using a mobile 
* Follow this [link](https://www.hackster.io/peter-lunk/how-to-use-the-android-ip-webcam-app-with-python-opencv-45f28f) to create your python code



<h3>Workflow for human and baggage detection</h3>

**Human**
* **Video Capture** - OpenCV
* **Detection** - Reinspect, HAAR, HOG
* **Tracking** - HOG, MHT

**Baggage**
* **Detection** - Reinspect, YOLO(Single-/ Multi - class)

<h3>Action items</h3> 
* Research upon

  * [**RNNs**](https://wiki.tum.de/display/lfdv/Recurrent+Neural+Networks+-+Combination+of+RNN+and+CNN)
  * [RNNs and LSTM](https://en.wikipedia.org/wiki/Recurrent_neural_network)
  * [RCNNs](https://towardsdatascience.com/learn-rcnns-with-this-toy-dataset-be19dce380ec)
  * RNN vs CNN vs RCNN
  * [**Darknet**](https://pjreddie.com/darknet/)
  * [Detectron](https://github.com/facebookresearch/Detectron)
  * 2 stage vs. single stage object detection(RNNs vs YOLO)
  * [An Intuitive Guide to Deep Network Architectures](https://towardsdatascience.com/an-intuitive-guide-to-deep-network-architectures-65fdc477db41)

* Setup YOLO by researching on the codes
* Read up on OpenCV documentation
* Introduction to computer vision courese Udacity
* What is a weak learner? How does learning process actually happen in tree based techniques? What is updated by the learning rate?


<h3>Important links</h3>

* [Link to download videos](https://www.videezy.com/)
* [Object recognition process](https://www.quora.com/Computer-Vision-What-are-the-fastest-object-recognition-algorithms-in-Python)
* [Retinanet](https://www.youtube.com/watch?v=44tlnmmt3h0)


<h3>Fun ideas</h3>

* **Automated tagging**
  * Use detection algorithm to generate tags - percept creates an annotations.dll file to create list of tags
