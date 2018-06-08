# Clustering / Similarity measurement algorithms

- This is an extension for the [Time Series Forecasting work](https://github.com/rohan193/Machine-Learning/tree/master/Time%20Series%20Forecasting)
  - Overall market sizing using Time Series Forecasting
  - **Analogue identification using clustering or similarity measurement techniques**
  - Forecasting share of market that the analogue can capture using Time Series Forecasting
    
# Index
- [Cosine similarity](#cosine-similarity)
- [K-Prototype in Clustering](#k-prototype-in-clustering)
- [K-means clustering](#k-means-clustering)

## Cosine similarity

- Reference:
  - [Wiki](https://en.wikipedia.org/wiki/Cosine_similarity)

## K-Prototype in Clustering

- Reference:
  - [Medium](https://medium.com/@Chamanijks/k-prototype-in-clustering-mixed-attributes-e6907db91914)
- Clustering or Cluster Analysis is an Unsupervised Learning technique which bears the task of **grouping a set of objects considering their similarity**
- Popular numerical data clustering methods/ algorithms
  - Representative based clustering-> K Means clustering algorithm
  - Hierarchical clustering ->Agglomerative clustering
  - Density based clustering->DBSCAN
  - Spectral and graph clustering->Spectral clustering
  - Gaussian Mixtures
- Popular categorical data clustering methods/ algorithms
  - K-modes algorithm (Gower’s similarity coefficient)
  - Squeezer
  - LIMBO
  - GAClast
  - Cobweb algorithm
  - STIRR , ROCK, CLICK
  - CACTUS,COOLCAT, CLOPE
- **If both numerical and categorical values are present in data**
  -  K-Prototype is a simple combination of K-Means and K-Modes and is used for clustering mixed attributes. Steps involved - 
    - Select k initial prototypes from the dataset X. It must be one for each cluster
    - Allocate each object in X to a cluster whose prototype is the nearest to it. This allocation is done with considering the dissimilarity measure which is described next
    - After all objects have been allocated to a cluster, retest the similarity of objects against the current prototypes. If you find that an object is found such that its nearest to another cluster prototype, update the prototypes of both the clusters
    - Repeat above step until no object changes its cluster
    
- The objects are assigned into clusters by considering the **dissimilarity measure**
    <img src = "https://cdn-images-1.medium.com/max/800/1*HxkHjH647N_9wKjqUBeJiw.png">
    
# K-means clustering

- K-means clustering technique working
  - Reference
    - [Wikipedia](https://en.wikipedia.org/wiki/K-means_clustering#Standard_algorithm)
    - [Stackoverflow](https://stats.stackexchange.com/questions/77850/assign-weights-to-variables-in-cluster-analysis)
    - [Stanford - Feature weighting in K-means clustering](https://link.springer.com/content/pdf/10.1023%2FA%3A1024016609528.pdf)
    - [AnalyticsVidhya](https://www.analyticsvidhya.com/blog/2013/11/getting-clustering-right/)
    <img src = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/K-means_convergence.gif/220px-K-means_convergence.gif">

- **Weighted clustering in k-means**  
  - The **choice of measurement units gives rise to relative weights of the variables.** Expressing a variable in smaller units will lead to a larger range for that variable, which will then have a large effect on the resulting structure. On the other hand, by standardizing one attempts to give all variables an equal weight, in the hope of achieving objectivity
  - Procedure to add importance of variables during clustering
    - **First standardize all variables (e.g. by their range). Then multiply each standardized variable with their weight. Then do the cluster analysis**
