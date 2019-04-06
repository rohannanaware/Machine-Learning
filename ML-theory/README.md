## Linear regression

- [Assumptions](http://www.statisticssolutions.com/assumptions-of-linear-regression/)
  - Linear relationship
  - Multivariate normality
  - No or little multicollinearity
  - No auto-correlation
  - Homoscedasticity

## Logistic regression

[Machine Learning - (Univariate|Simple) Logistic regression](https://gerardnico.com/data_mining/simple_logistic_regression)
- The idea of logistic regression is to make linear regression produce probabilities. It's always best to predict class probabilities instead of predicting classes
- The name “logistic” comes from the transformation of this model. This is a monotone transformation. And that transformation is called:
  - the log odds
  - or the logit transformation of the probability
- To summarize, we got still a linear model but it's modeling the probabilities on a non-linear scale
  <img src = "https://gerardnico.com/_media/data_mining/logit_transform.jpg">
- [Why is logistic regression required? Why not linear regression?](https://discuss.analyticsvidhya.com/t/why-is-logistic-regression-required-why-not-linear-regression/6620/9) : Violation of assumption of linear relashionship

[FAQ: HOW DO I INTERPRET ODDS RATIOS IN LOGISTIC REGRESSION?](https://stats.idre.ucla.edu/other/mult-pkg/faq/general/faq-how-do-i-interpret-odds-ratios-in-logistic-regression/)
- !!! Log likelihood, standard error

## Decision trees

- [A Practical Guide to Tree Based Learning Algorithms](https://sadanand-singh.github.io/posts/treebasedmodels/#disqus_thread)
- [A Complete Tutorial on Tree Based Modeling from Scratch (in R & Python)](https://www.analyticsvidhya.com/blog/2016/04/complete-tutorial-tree-based-modeling-scratch-in-python/)
- [Tree-based Methods](https://lagunita.stanford.edu/c4x/HumanitiesScience/StatLearning/asset/trees.pdf)

## GBM

- [Ensembles (3): Gradient Boosting](https://www.youtube.com/watch?v=sRktKszFmSk&t=311s)
- [Gradient Boosting from scratch](https://medium.com/mlreview/gradient-boosting-from-scratch-1e317ae4587d)
- [XGBoost: A Scalable Tree Boosting System](https://arxiv.org/pdf/1603.02754v2.pdf)
- [Beginners Tutorial on XGBoost and Parameter Tuning in R](https://www.hackerearth.com/practice/machine-learning/machine-learning-algorithms/beginners-tutorial-on-xgboost-parameter-tuning-r/tutorial/)
- [Featured Talk: #1 Kaggle Data Scientist Owen Zhang](https://nycdatascience.com/blog/meetup/featured-talk-1-kaggle-data-scientist-owen-zhang/)
- [Complete Guide to Parameter Tuning in XGBoost (with codes in Python)](https://www.analyticsvidhya.com/blog/2016/03/complete-guide-parameter-tuning-xgboost-with-codes-python/)

## !!! Anova and F-tests
- [Understanding Analysis of Variance (ANOVA) and the F-test](http://blog.minitab.com/blog/adventures-in-statistics-2/understanding-analysis-of-variance-anova-and-the-f-test)
- [The Meaning of an F-Test](https://www.youtube.com/watch?v=g9pGHRs-cxc)

## Sales incrementality
- Pre-post analysis
  - [Capturing Campaign Sales Lift—Can Pre-Post Measurements Be Trusted?](http://www.marketingprofs.com/articles/2009/3195/capturing-campaign-sales-liftcan-pre-post-measurements-be-trusted)
    - Minimize impact of seasonality and other data cleaning; run ANOVA to confirm if the increment in sales was significant
  - [Measuring Statistically Significant Lift in Weekly Sales (Using T-Test)](https://stats.stackexchange.com/questions/279035/measuring-statistically-significant-lift-in-weekly-sales-using-t-test)
- A/B testing
  - [Data science you need to know! A/B testing](https://towardsdatascience.com/data-science-you-need-to-know-a-b-testing-f2f12aff619a)

- How to identify the control group
- Incrementality due to marketing vs. YoY natural growth in sales
- How to split sales into base and incremental
- Q. While measuring increment in sales due to marketing campaigns - 
  - How to conclude that the increment in sales was significant? Pre-post, test-control, YoY increase? 
  - How to remove the aspects of natural growth in sales, fact that some other marketing campaign might have been active during the same period last year? 
  - On what basis are the test control splits to be made - how to know that the splits are actually similar?

# Reference

- [ESLR](https://web.stanford.edu/~hastie/Papers/ESLII.pdf)
- [Stackoverflow](https://stackoverflow.com/questions/12146914/what-is-the-difference-between-linear-regression-and-logistic-regression?answertab=active#tab-top)
- [Learn ML in 3 months](https://github.com/llSourcell/Learn_Machine_Learning_in_3_Months)
- [QQ plots - StackExchange](https://stats.stackexchange.com/questions/52293/r-qqplot-how-to-see-whether-data-are-normally-distributed)
- [One tailed vs. two tailed test](https://stats.idre.ucla.edu/other/mult-pkg/faq/general/faq-what-are-the-differences-between-one-tailed-and-two-tailed-tests/)
- [What method do you think is the best when you are carrying out an ANalysis Of VAriance between groups?](https://www.researchgate.net/post/What_method_do_you_think_is_the_best_when_you_are_carrying_out_an_ANalysis_Of_VAriance_between_groups)

- [Probability concepts explained: Maximum likelihood estimation
](https://towardsdatascience.com/probability-concepts-explained-maximum-likelihood-estimation-c7b4342fdbb1)
- [Markov Chain](file:///C:/Users/rohan.nanaware/Downloads/(International%20Series%20in%20Operations%20Research%20&%20Management%20Science)%20Wai-Ki%20Ching,%20Ximin%20Huang,%20Michael%20K.%20Ng,%20Tak%20Kuen%20Siu-Markov%20Chains_%20Models,%20Algorithms%20and%20Applications-Springer%20(2013).pdf)
- [Why to perform variable transformation?](https://stats.stackexchange.com/questions/4831/regression-transforming-variables)
- [Why do we convert skewed data into a normal distribution?](https://datascience.stackexchange.com/questions/20237/why-do-we-convert-skewed-data-into-a-normal-distribution)
- [Statistical decision theory](https://www.youtube.com/watch?v=3BBk6XZR-bk)
- [Expected value - wiki](https://en.wikipedia.org/wiki/Expected_value)
