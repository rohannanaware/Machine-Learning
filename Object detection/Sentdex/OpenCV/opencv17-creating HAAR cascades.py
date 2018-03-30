#Steps to create a HAAR cascade for image and object classification 
#	1. Collect negative or background images - 
#			- Any image will do, just make sure your objet is not present in them
#	2. Collect or create positive images - 
#			- Thousands of images of your object. Can make these based on one image, or mannualy create them
#			- Ideally these should be twice as the negative images
#	3. Create a positive vector file by stiching together all positives
#			- This is done with OpenCV command
#	4. Train cascade
#			- Done with OpenCV command

#	Negative and positive images need description files - 
#		Negative images - 
#			- Generally a bg.txt file that contains the path to each image by line
#			- Example line - neg/1.jpg
#		Positive images - 
#			- Sometimes called "info", pos.txt, or somethinf of this sort. Contains path to each image, by line, alongwith how many objectct and where they are located
#			- Example line - pos/1.jpg 1 0 0 50 50

#	You want negative images larger than positive images generally, if you are goinf to "create samples" rather than collect and label positives.
#	Try to use small images 100 x 100 for negatives and 50 x 50 for positives
#	Will get even smaller when it comes to training
#	Have twice as many positive images as negative images



# Setting up the working directory - 

	# Change directory to server's root, or wherever you want to place your workspace

	# cd ~

	# sudo apt-get update

	# sudo apt-get upgrade

	# First, let's make ourselves a nice workspace directory:

	# mkdir opencv_workspace

	# cd opencv_workspace

	# Now that we're in here, let's grab OpenCV:

	# sudo apt-get install git

	# git clone https://github.com/Itseez/opencv.git

	# We've cloned the latest version of OpenCV here. Now let's get some essentials:

	# Compiler: sudo apt-get install build-essential

	# Libraries: sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev

	# Python bindings and such: sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

	# Finally, let's grab the OpenCV development library:

	# sudo apt-get install libopencv-dev
