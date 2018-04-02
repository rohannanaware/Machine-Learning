
[Link to tutorial](https://www.youtube.com/watch?v=4eIBisqx9_g)

<h2>HOG</h2>

* Replaces each Pixel with an arrow directing the direction in which the light intensity is highest
* Later divides the whole image into smaller squares and replaces the square with the dominant direction of arrow
* Helps in creating a feature map of an object - for eg. Face

<h2>CNNs</h2>

* An image classification task usually has the object to be classified occupying the complete image
* On contrary an humans detect and classify multiple objects present in the same image / frame
* Can CNNs be used to 
  * Detect objects
  * Identify their relationship with other objects
  * Build a bounding box around that image
  
<h3>Using CNNs for Object detection</h3>

* **Brute force** - Train the model to detect a particular object. Slide the classifier across a group of Pixels across the whole image and classify every single Box and take the classifications which the model has high confidence on
