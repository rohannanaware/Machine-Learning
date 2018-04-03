[Source - digitalbrain github](https://github.com/digitalbrain79/pyyolo)

# Installing pyyolo
#### Get the code
- `git clone --recursive https://github.com/thomaspark-pkj/pyyolo.git`

#### Modify Makefile as needed
- Set GPU to 0 & CUDNN to 0 if running on CPU
- Don't set OpenCV to 1. There is some issue, therefore the package doesn't find OpenCV even if it is installed

#### Run few commands
- `cd pyyolo`
- `make`
- `rm -rf build`
- `python3 setup.py build` (use setup_gpu.py for GPU)
- `sudo python setup.py install`

#### Test the installation
- `python example.py`
- If you the general pyyolo output then it worked!
