
- [Link](https://www.hackerearth.com/challenge/hiring/caavo-software-engineer-hiring-challenge/problems/)

# End date

- `22nd Apr 2018`

# Read up
- Optimization and annealing in neural networks
  - Optimization using RMSprop
- How to come up with structure of a neural network for our specific problem
- Dropout
- Keras - official documentation
- Categorical crossentropy : Used to measure loss/ error in observed and predicted for multi - class

# Reference

1. [Tutorial: Optimizing Neural Networks using Keras (with Image recognition case study)](https://www.analyticsvidhya.com/blog/2016/10/tutorial-optimizing-neural-networks-using-keras-with-image-recognition-case-study/) 
2. [Dropout in NNs](https://medium.com/@amarbudhiraja/https-medium-com-amarbudhiraja-learning-less-to-learn-better-dropout-in-deep-machine-learning-74334da4bfc5)
3. [An Introduction to Implementing Neural Networks using TensorFlow](https://www.analyticsvidhya.com/blog/2016/10/an-introduction-to-implementing-neural-networks-using-tensorflow/)
4. Categorical cross entropy - 
    - [Machine Learning: Should I use a categorical cross entropy or binary cross entropy loss for binary predictions?](https://stats.stackexchange.com/questions/260505/machine-learning-should-i-use-a-categorical-cross-entropy-or-binary-cross-entro)
    - [A Friendly Introduction to Cross-Entropy Loss](http://rdipietro.github.io/friendly-intro-to-cross-entropy-loss/)
5. Kaggle kernels
    - [Kaggle - Plant Seedlings Classification](https://www.kaggle.com/raoulma/plants-xception-90-06-test-accuracy)
    - [Kaggle - Digit recognizer](https://www.kaggle.com/yassineghouzam/introduction-to-cnn-keras-0-997-top-6)
6. [An overview of gradient descent optimization algorithms](http://ruder.io/optimizing-gradient-descent/)
7. Categorical crossentropy
    - [Stackexchange](https://stats.stackexchange.com/questions/260505/machine-learning-should-i-use-a-categorical-cross-entropy-or-binary-cross-entro)

## 1. [Tutorial: Optimizing Neural Networks using Keras (with Image recognition case study)](https://www.analyticsvidhya.com/blog/2016/10/tutorial-optimizing-neural-networks-using-keras-with-image-recognition-case-study/) 

#### Keras : Overview

The key features of Keras are:
- **Modularity** : Modules necessary for building a neural network are included in a simple interface so that Keras is easier to use for the end user
- **Minimalistic** : Implementation is short and concise
- **Extensibility** : It’s very easy to write a new module for Keras and makes it suitable for advance research

#### General way to solve problems with Neural Networks

- Check if it is a problem where Neural Network gives you uplift over traditional algorithms (refer to the checklist in the section above)
- Do a survey of which Neural Network architecture is most suitable for the required problem
- Define Neural Network architecture through whichever language / library you choose.
- Convert data to right format and divide it in batches
- Pre-process the data according to your needs
- Augment Data to increase size and make better trained models
- Feed batches to Neural Network
- Train and monitor changes in training and validation data sets
- Test your model, and save it for future use

# 7. Cross-entropy

## [Machine Learning: Should I use a categorical cross entropy or binary cross entropy loss for binary predictions?](https://stats.stackexchange.com/questions/260505/machine-learning-should-i-use-a-categorical-cross-entropy-or-binary-cross-entro)

Binomial cross-entropy loss is a special case of multinomial cross-entropy loss for m=2.

- <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">
  <mrow class="MJX-TeXAtom-ORD">
    <mi class="MJX-tex-caligraphic" mathvariant="script">L</mi>
  </mrow>
  <mo stretchy="false">(</mo>
  <mi>&#x03B8;<!-- θ --></mi>
  <mo stretchy="false">)</mo>
  <mo>=</mo>
  <mo>&#x2212;<!-- − --></mo>
  <mfrac>
    <mn>1</mn>
    <mi>n</mi>
  </mfrac>
  <munderover>
    <mo>&#x2211;<!-- ∑ --></mo>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mo>=</mo>
      <mn>1</mn>
    </mrow>
    <mi>n</mi>
  </munderover>
  <mrow>
    <mo>[</mo>
    <msub>
      <mi>y</mi>
      <mi>i</mi>
    </msub>
    <mi>log</mi>
    <mo>&#x2061;<!-- ⁡ --></mo>
    <mo stretchy="false">(</mo>
    <msub>
      <mi>p</mi>
      <mi>i</mi>
    </msub>
    <mo stretchy="false">)</mo>
    <mo>+</mo>
    <mo stretchy="false">(</mo>
    <mn>1</mn>
    <mo>&#x2212;<!-- − --></mo>
    <msub>
      <mi>y</mi>
      <mi>i</mi>
    </msub>
    <mo stretchy="false">)</mo>
    <mi>log</mi>
    <mo>&#x2061;<!-- ⁡ --></mo>
    <mo stretchy="false">(</mo>
    <mn>1</mn>
    <mo>&#x2212;<!-- − --></mo>
    <msub>
      <mi>p</mi>
      <mi>i</mi>
    </msub>
    <mo stretchy="false">)</mo>
    <mo>]</mo>
  </mrow>
  <mo>=</mo>
  <mo>&#x2212;<!-- − --></mo>
  <mfrac>
    <mn>1</mn>
    <mi>n</mi>
  </mfrac>
  <munderover>
    <mo>&#x2211;<!-- ∑ --></mo>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mo>=</mo>
      <mn>1</mn>
    </mrow>
    <mi>n</mi>
  </munderover>
  <munderover>
    <mo>&#x2211;<!-- ∑ --></mo>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>j</mi>
      <mo>=</mo>
      <mn>1</mn>
    </mrow>
    <mi>m</mi>
  </munderover>
  <msub>
    <mi>y</mi>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mi>j</mi>
    </mrow>
  </msub>
  <mi>log</mi>
  <mo>&#x2061;<!-- ⁡ --></mo>
  <mo stretchy="false">(</mo>
  <msub>
    <mi>p</mi>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mi>j</mi>
    </mrow>
  </msub>
  <mo stretchy="false">)</mo>
</math>

Where <math xmlns="http://www.w3.org/1998/Math/MathML">
  <mi>i</mi>
</math> indexes samples/observations and jj indexes classes, and yy is the sample label (binary for LSH, one-hot vector on the RHS) and <math xmlns="http://www.w3.org/1998/Math/MathML">
  <msub>
    <mi>p</mi>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mi>j</mi>
    </mrow>
  </msub>
  <mo>&#x2208;<!-- ∈ --></mo>
  <mo stretchy="false">(</mo>
  <mn>0</mn>
  <mo>,</mo>
  <mn>1</mn>
  <mo stretchy="false">)</mo>
  <mo>:</mo>
  <munder>
    <mo>&#x2211;<!-- ∑ --></mo>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>j</mi>
    </mrow>
  </munder>
  <msub>
    <mi>p</mi>
    <mrow class="MJX-TeXAtom-ORD">
      <mi>i</mi>
      <mi>j</mi>
    </mrow>
  </msub>
  <mo>=</mo>
  <mn>1</mn>
  <mi mathvariant="normal">&#x2200;<!-- ∀ --></mi>
  <mi>i</mi>
  <mo>,</mo>
  <mi>j</mi>
</math> is the prediction for a sample

## [A Friendly Introduction to Cross-Entropy Loss](http://rdipietro.github.io/friendly-intro-to-cross-entropy-loss/)

- #### [Difference between probabilty and likelihood](https://stats.stackexchange.com/questions/2641/what-is-the-difference-between-likelihood-and-probability)
- #### [StatQuest: Probability vs Likelihood](https://www.youtube.com/watch?v=pYxNSUDSFH4)


# 6. [An overview of gradient descent optimization algorithms](http://ruder.io/optimizing-gradient-descent/)

Gradient descent is a way to minimize an objective function J(θ) parameterized by a model's parameters θ∈Rd by updating the parameters in the opposite direction of the gradient of the objective function ∇θJ(θ) w.r.t. to the parameters. The learning rate η determines the size of the steps we take to reach a (local) minimum. In other words, we follow the direction of the slope of the surface created by the objective function downhill until we reach a valley

### Gradient descent variants

There are three variants of gradient descent, which differ in how much data we use to compute the gradient of the objective function :
- Batch
- Stochaistic
- Mini-batch

#### Batch gradient descent :

- Vanilla gradient descent, aka batch gradient descent, computes the gradient of the cost function w.r.t. to the parameters θθ for the entire training dataset:
- θ = θ − η ⋅ ∇θJ(θ)
- Batch gradient  code 
```python 
for i in range(nb_epochs):
params_grad = evaluate_gradient(loss_function, data, params)
params = params - learning_rate * params_grad
```
- As we need to calculate the gradients for the whole dataset to perform just one update, batch gradient descent can be very slow and is intractable for datasets that don't fit in memory. Batch gradient descent also doesn't allow us to update our model online, i.e. with new examples on-the-fly

#### Stochastic gradient descent :

- Stochastic gradient descent (SGD) in contrast performs a parameter update for each training example x(i) and label y(i):
- θ = θ − η ⋅ ∇θJ(θ; x(i); y(i))
- Batch gradient descent performs redundant computations for large datasets, as it recomputes gradients for similar examples before each parameter update. SGD does away with this redundancy by performing one update at a time. It is therefore usually much faster and can also be used to learn online
- SGD performs frequent updates with a high variance that cause the objective function to fluctuate heavily
- While batch gradient descent converges to the minimum of the basin the parameters are placed in, SGD's fluctuation, on the one hand, enables it to jump to new and potentially better local minima
```python
for i in range(nb_epochs):
  np.random.shuffle(data)
  for example in data:
    params_grad = evaluate_gradient(loss_function, example, params)
    params = params - learning_rate * params_grad
```

#### Mini-batch gradient descent : 

- Mini-batch gradient descent finally takes the best of both worlds and performs an update for every mini-batch of n training examples:
- θ=θ−η⋅∇θJ(θ;x(i:i+n);y(i:i+n))
- This way, it
    a. reduces the variance of the parameter updates and 
    b. can make use of highly optimized matrix optimizations
```python
for i in range(nb_epochs):
  np.random.shuffle(data)
  for batch in get_batches(data, batch_size=50):
    params_grad = evaluate_gradient(loss_function, batch, params)
    params = params - learning_rate * params_grad
```

### Challenges

Vanilla mini - batch gradient descent challenges - 

- Choosing a proper learning rate can be difficult
- Learning rate schedules try to adjust the learning rate during training by e.g. **annealing**, i.e. reducing the learning rate according to a **pre-defined schedule** or when the **change in objective between epochs falls below a threshold**. These schedules and thresholds, however, have to be defined in advance and are thus unable to adapt to a dataset's characteristics
- Additionally, the same learning rate applies to all parameter updates. If our data is sparse and our features have very different frequencies, we might not want to update all of them to the same extent, but perform a larger update for rarely occurring features
- Another key challenge of minimizing highly non-convex error functions common for neural networks is avoiding getting trapped in their numerous suboptimal local minima

### Gradient descent optimization algorithms

- Momentum[#momentum]
- Nesterov accelerated gradient[#nesterov-accelerated-gradient]
- Adagrad[#adagrad]
- Adadelta[#adadelta]
- RMSprop[#rmsprop]
- Adam[#adam]
- AdaMax
- Nadam
- AMSGrad
- Visualization of algorithms[#visualization-of-algorithms]
- Which optimizer to choose?

#### Momentum
- SGD has trouble navigating ravines, i.e. areas where the surface curves much more steeply in one dimension than in another [1], which are common around local optima. In these scenarios, SGD oscillates across the slopes of the ravine while only making hesitant progress along the bottom towards the local optimum
- <img src = "http://ruder.io/content/images/2015/12/without_momentum.gif"/> <img src = "http://ruder.io/content/images/2015/12/with_momentum.gif"/>

- `vtθ = γ . vt − 1 + η . ∇θJ(θ)`
- `θ = θ − vt`
- Essentially, when using momentum, we push a ball down a hill. The ball accumulates momentum as it rolls downhill, becoming faster and faster on the way (until it reaches its terminal velocity if there is air resistance, i.e. γ<1γ<1). The same thing happens to our parameter updates: The momentum term increases for dimensions whose gradients point in the same directions and reduces updates for dimensions whose gradients change directions. As a result, we gain faster convergence and reduced oscillation

- [Why Momentum Really Works](https://distill.pub/2017/momentum/)
  -  Pathological curvature is, simply put, regions of ff which aren’t scaled properly. The landscapes are often described as valleys, trenches, canals and ravines. The iterates either jump between valleys, or approach the optimum in small, timid steps. Progress along certain directions grind to a halt. In these unfortunate regions, gradient descent fumbles
  - Original gradient descent equation
    - `z(k+1) = ∇f(w(k))`
    - `w(k+1) = w(k) - α.z(k+1)`
  - Update proposed in Momentum approach
    - `z(k+1) = β.z(k) + ∇f(w(k))`
    - `w(k+1) = w(k) - α.z(k+1)`
    - if the previous change in loss(β.z(k)) and current change(∇f(w(k))) is in the same direction then the momentum increases
  - *need to read up more on the derivation part*
  
#### Nesterov accelerated gradient

- Nesterov accelerated gradient is a way to give our momentum prescience(update the weights on the basis on future value of loss than the current)
- We know that we will use our momentum term γ.vt−1 to move the parameters θ. Computing θ−γ.vt−1 thus gives us an approximation of the next position of the parameters (the gradient is missing for the full update), a rough idea where our parameters are going to be. We can now effectively look ahead by **calculating the gradient not w.r.t. to our current parameters θθ but w.r.t. the approximate future position of our parameters**
- `vtθ = γ.v(t−1) + η.∇θJ(θ−γ.v(t−1))`
- `θ = θ − vt`
- *did not understand the last part explaining below image*
- <img src = "http://ruder.io/content/images/2016/09/nesterov_update_vector.png"/>

#### Adagrad

- Adagrad adapts the learning rate to the parameters, performing larger updates for infrequent and smaller updates for frequent parameters
  - For this reason, it is well-suited for dealing with sparse data
- Previously, we performed an update for all parameters θ at once as every parameter θi used the same learning rate η. As Adagrad uses a different learning rate for every parameter θi at every time step t
- For brevity, we set g(t,i) to be the gradient of the objective function w.r.t. to the parameter θi at time step  t
- The SGD update for every parameter θi at each time step t then becomes:
- θ(t+1,i) = θ(t,i) − η ⋅ g(t,i)
- In its update rule, Adagrad modifies the general learning rate η at each time step t for every parameter θi based on the past gradients that have been computed for θi:
- θ(t+1,i) = θ(t,i) − [η . √(G(t) + ϵ)] . g(t,i)
- Gt∈Rd×d here is a diagonal matrix where each diagonal element i,i is the sum of the squares of the gradients w.r.t. θi up to time step t, while ϵ is a smoothing term that avoids division by zero (usually on the order of 1e−8). Interestingly, without the square root operation, the algorithm performs much worse
- Adagrad eliminates the need to manually tune the learning rate
- Adagrad's main weakness is its accumulation of the squared gradients in the denominator: Since every added term is positive, the accumulated sum keeps growing during training. This in turn causes the learning rate to shrink and eventually become infinitesimally small, at which point the algorithm is no longer able to acquire additional knowledge

#### Adadelta

- Adadelta is an extension of Adagrad that seeks to reduce its aggressive, monotonically decreasing learning rate. Instead of accumulating all past squared gradients, Adadelta restricts the window of accumulated past gradients to some fixed size w
- Instead of inefficiently storing ww previous squared gradients, the sum of gradients is recursively defined as a decaying average of all past squared gradients. The running average E[g2]t at time step t then depends (as a fraction γ similarly to the Momentum term) only on the previous average and the current gradient
- `E[g2]t = γ . E[g2]t−1 + (1−γ) . g2t`
- `Δθt  = − (RMS[Δθ]t−1) / (RMS[g]t) . gt`
- `θt+1 = θt+Δθt`

#### RMSprop

- RMSprop and Adadelta have both been developed independently around the same time stemming from the need to resolve Adagrad's radically diminishing learning rates. RMSprop in fact is identical to the first update vector of Adadelta that we derived above:
- E[g2]t = 0.9 . E[g2]t−1 + 0.1 . g2t
- θt+1 = θt − η . sqrt(E[g2]t+ϵ) . gt

#### Adam

- Adaptive Moment Estimation (Adam) is another method that computes adaptive learning rates for each parameter
- In addition to storing an exponentially decaying average of past squared gradients `vt` like Adadelta and RMSprop, Adam also keeps an exponentially decaying average of past gradients `mt`, similar to momentum
- `mt = β1 . mt−1 + (1−β1) . gt`
- `vt = β2 . vt−1 + (1−β2) . g2t`
- mt  and vt are estimates of the first moment (the mean) and the second moment (the uncentered variance) of the gradients respectively, hence the name of the method
- As mt and vt are initialized as vectors of 0's, the authors of Adam observe that they are biased towards zero, especially during the initial time steps, and especially when the decay rates are small (i.e. β1 and β2 are close to 1)
- They counteract these biases by computing bias-corrected first and second moment estimates:
- `m^t = mt / (1−β1^t)`
- `v^t = vt / (1−β2^t)`
- Parameter update - 
  - `θt+1 = θt − η / sqrt(v^t + ϵ) * m^t`


#### Visualization of algorithms

- Below images show the behaviour of the algorithms at a saddle point, i.e. a point where one dimension has a positive slope, while the other dimension has a negative slope, which pose a difficulty for SGD as we mentioned before. Notice here that SGD, Momentum, and NAG find it difficulty to break symmetry, although the two latter eventually manage to escape the saddle point, while Adagrad, RMSprop, and Adadelta quickly head down the negative slope.
- <img src = "http://ruder.io/content/images/2016/09/contours_evaluation_optimizers.gif"/> <img src = "http://ruder.io/content/images/2016/09/saddle_point_evaluation_optimizers.gif"/>
- The adaptive learning-rate methods, i.e. Adagrad, Adadelta, RMSprop, and Adam are most suitable and provide the best convergence for these scenarios

#### Which optimizer to use?

- RMSprop is an extension of Adagrad that deals with its radically diminishing learning rates. It is identical to Adadelta, except that Adadelta uses the RMS of parameter updates in the numinator update rule. Adam, finally, adds bias-correction and momentum to RMSprop. Insofar, RMSprop, Adadelta, and Adam are very similar algorithms that do well in similar circumstances.Bias-correction helps Adam slightly outperform RMSprop towards the end of optimization as gradients become sparser. Insofar, Adam might be the best overall choice
