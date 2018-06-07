# Clustering / Similarity measurement algorithms

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
    
- The objects are assigned into clusters by considering the **dissimilarity measure** -
  - 
