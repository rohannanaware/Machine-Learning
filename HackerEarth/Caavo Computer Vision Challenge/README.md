
- [Link](https://www.hackerearth.com/challenge/hiring/caavo-software-engineer-hiring-challenge/problems/)

# End date

- `22nd Apr 2018`

# Read up
- Optimization and annealing in neural networks
- How to come up with structure of a neural network for our specific problem
- Dropout
- Categorical crossentropy : Used to measure loss/ error in observed and predicted for multi - class
- 
# Reference

- [Tutorial: Optimizing Neural Networks using Keras (with Image recognition case study)](https://www.analyticsvidhya.com/blog/2016/10/tutorial-optimizing-neural-networks-using-keras-with-image-recognition-case-study/) 
- [Dropout in NNs](https://medium.com/@amarbudhiraja/https-medium-com-amarbudhiraja-learning-less-to-learn-better-dropout-in-deep-machine-learning-74334da4bfc5)
- [An Introduction to Implementing Neural Networks using TensorFlow](https://www.analyticsvidhya.com/blog/2016/10/an-introduction-to-implementing-neural-networks-using-tensorflow/)
- Cross entropy - 
  - [Machine Learning: Should I use a categorical cross entropy or binary cross entropy loss for binary predictions?](https://stats.stackexchange.com/questions/260505/machine-learning-should-i-use-a-categorical-cross-entropy-or-binary-cross-entro)
  - [A Friendly Introduction to Cross-Entropy Loss](http://rdipietro.github.io/friendly-intro-to-cross-entropy-loss/)

## [Tutorial: Optimizing Neural Networks using Keras (with Image recognition case study)](https://www.analyticsvidhya.com/blog/2016/10/tutorial-optimizing-neural-networks-using-keras-with-image-recognition-case-study/) 

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

# Cross-entropy

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

#### [Difference between probabilty and likelihood](https://stats.stackexchange.com/questions/2641/what-is-the-difference-between-likelihood-and-probability)
