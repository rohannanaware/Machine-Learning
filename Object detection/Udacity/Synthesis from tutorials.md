<h3>Lesson 1 : 1A-L1</h3>

* Computer vision and Computer Photography
    * Computer photography - Capturing light from a scene to record a photograph
    * Image analysis - Supports the capture in novel ways
    * Computer vision - Interpreting and analysis of the scene
    
* Introduction to computer vision

* What is computer vision?
    * Image goes in and somthing meaningful or interpretable comes out
    * Understanding what is in the image
    
 * How can we make a computer recognize actions like movement, flapping like a bird, etc.
 
 * Object recognition - 
    * Evolution robotics - LaneHawk

<h3>Lesson 2 : 2A-L1 Images as functions</h3>

* Images as functions - Part 1
   * I(x, y)
      * x, y = co-ordinates of a grayscaled image
      * I = intensity
   * Image processing side of computer vision is taking images and creating new functions or getting some information out
      * Smoothening the function/ blurring the image

* Images as functions - Part 2
   * We can think of images as functions that map R2 to R:
      * f(x,y) gives intensity or value at position (x, y)
   * For color images f:R2-->R3
   
* Digital images
   * In computer vision we work on digital(discrete) images

* Image operations
   * Addition
   * Averaging
   * Scalar multiplication
   * Blending
   
* Common types of Noise
   * I'(x, y) = I(x, y) + noise(x, y)
   * Salt and pepper noise - Random black and white pixels
   * Impulse noise - random occurences of white pixels
   * Gaussian noise - Variations in intensity drawn from a Gaussian normal distribution

* Applying Gaussian Noise
   * Gaussian noise is derieved from Gaussian distribution, mean = 0, std. dev = 1
   * Multoplying the Gaussian dist. with a contanst changes the spread of dist. since frequency remains unchanged

<h3>Lesson 2 : 2A-L2 Filtering</h3>

<img src = "http://www.gergltd.com/cse486/project2/GaussianNoise.jpg"
     alt = "Gaussian Noise"
     style = "float: right; margin-right: 40px;"
     />

* Gaussian Noise
   * Smoothening the pixel intensity can reduce noise of the Pixel. Take average of surrounding Pixels and assign to that Pixel
   
* Weighted moving average
   * Closer pixels are more likely to be similar in intensity to the given Pixel. Hence more nearby the Pixel the more weight it should have
   
* Moving Average in 2D
   * An average of the matrix of values whose size is lower than the size of image
   
* Correlation Filtering
   * Use of kernels to assign non-uniform weights to be multiplied to each of the Pixel before being averaged out
   * kernel is a matrix of weights wherein the innermost entries have highest value
   
* Gaussian filter
   * Nearest neighbouring pixels have the most influence
   * The Gaussian kernel is an approximation of the [Gaussian function](https://en.wikipedia.org/wiki/Gaussian_function)
   * <img src = "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Normal_Distribution_PDF.svg/360px-Normal_Distribution_PDF.svg.png"
     alt = "Gaussian Noise"
     style = "float: right; margin-right: 40px;"
     />
   * <img src = "https://lh6.googleusercontent.com/sD9KLYLY7Hne9YlCzYgKw7-FaE_Dh201JlO0I1czRc3fBXyRVV7in5Jfq5QEoyJFoypOgPV8_bLHdWdQ0bUGa03B544STlFSksMDTTLIADNsyM4JStM"
     alt = "Gaussian Noise"
     style = "float: right; margin-right: 40px;"
     />
     
* Variance or standard deviation
   * Gaussian is isotropic meaning circularly symmetric. It had only one parameter(sigma), higher the sigma larger the blur
   * Variance in Gaussian filters determines the extent of smoothening
   * Kernels with same size and different sigma
   * For kernels with different size but same sigma, the one with larger size tends to perform better as it is smoother
   * Details on effect of kernel size and sigma on the quality of [smoothening](https://classroom.udacity.com/courses/ud810/lessons/3417359075/concepts/34235689660923)
   * *Why do I need to apply smoothening? - To remove random noise in the image*
   
