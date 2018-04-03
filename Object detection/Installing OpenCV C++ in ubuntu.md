# Installing OpenCV C++
- `sudo apt-get update`
- `sudo apt-get upgrade`

### Remove any previous installations of x264
- `sudo apt-get remove x264 libx264-dev`

### Install dependencies now
- `sudo apt-get install build-essential checkinstall cmake pkg-config yasm`
- `sudo apt-get install git gfortran`
- `sudo apt-get install libjpeg8-dev libjasper-dev libpng12-dev`
- If you are using Ubuntu 14.04 - 
- `sudo apt-get install libtiff4-dev`
- If you are using Ubuntu 16.04 - 
- `sudo apt-get install libtiff5-dev`

- `sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev`
- `sudo apt-get install libxine2-dev libv4l-dev`
- `sudo apt-get install libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev`
- `sudo apt-get install qt5-default libgtk2.0-dev libtbb-dev`
- `sudo apt-get install libatlas-base-dev`
- `sudo apt-get install libfaac-dev libmp3lame-dev libtheora-dev`
- `sudo apt-get install libvorbis-dev libxvidcore-dev`
- `sudo apt-get install libopencore-amrnb-dev libopencore-amrwb-dev`
- `sudo apt-get install x264 v4l-utils`

### Get OpenCV C++
- `git clone https://github.com/opencv/opencv.git`
- `git clone https://github.com/opencv/opencv_contrib.git`

### Compile and install OpenCV C++
- `cd opencv`
- `mkdir build`
- `cd build`

- `cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D INSTALL_C_EXAMPLES=ON \
      -D INSTALL_PYTHON_EXAMPLES=ON \
      -D WITH_TBB=ON \
      -D WITH_V4L=ON \
      -D WITH_QT=ON \
      -D WITH_OPENGL=ON \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules \`

#### find out number of CPU cores in your machine
- `nproc`
#### substitute 4 by output of nproc
- `make -j4`
- `sudo make install`
- `sudo sh -c 'echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf'`
- `sudo ldconfig`
