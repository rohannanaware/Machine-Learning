
- Reference:
  - [AnalyticsVidhya](https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/)
  - [Duke ARIMA](https://people.duke.edu/~rnau/411arim.htm)
  - [Forecasting for the Pharmaceutical Industry - Models for New Product and In-Market Forecasting and How to Use Them](http://www.sadrabiotech.com/catalog/GOOD%20Forecasting%20for%20the%20Pharmaceutical%20Industry.pdf)
  - ATAR model

## Introduction to ARIMA: nonseasonal models

- **ARIMA(p,d,q) forecasting equation:** 
  - Most statistical forecasting methods are based on the assumption that the time series can be rendered approximately stationary (i.e., "stationarized") through the use of mathematical transformations
  - A stationary series has no trend, its variations around its mean have a constant amplitude, and it wiggles in a consistent fashion, i.e., its short-term random time patterns always look the same in a statistical sense
  - An ARIMA model can be viewed as a “filter” that tries to separate the signal from the noise, and the signal is then extrapolated into the future to obtain forecasts
  - The ARIMA forecasting equation for a stationary time series is a **linear (i.e., regression-type) equation in which the predictors consist of lags of the dependent variable and/or lags of the forecast errors**
  - The acronym ARIMA stands for **Auto-Regressive Integrated Moving Average.** Lags of the stationarized series in the forecasting equation are called "autoregressive" terms, lags of the forecast errors are called "moving average" terms, and a time series which needs to be differenced to be made stationary is said to be an "integrated" version of a stationary series. Random-walk and random-trend models, autoregressive models, and exponential smoothing models are all special cases of ARIMA models.
  - A nonseasonal ARIMA model is classified as an "ARIMA(p,d,q)" model, where:
    - p is the number of autoregressive terms
    - d is the number of nonseasonal differences needed for stationarity
    - q is the number of lagged forecast errors in the prediction equation
  - To identify the appropriate ARIMA model for Y, you begin by **determining the order of differencing (d)** needing to stationarize the series and remove the gross features of seasonality, perhaps in conjunction with a variance-stabilizing transformation such as logging or deflating. If you stop at this point and predict that the differenced series is constant, you have merely fitted a random walk or random trend model.  However, the stationarized series may still **have autocorrelated errors, suggesting that some number of AR terms (p ≥ 1) and/or some number MA terms (q ≥ 1) are also needed in the forecasting equation**
    - [Homescedasticity](https://www.statisticssolutions.com/homoscedasticity/) vs. [Heteroscedasticity](http://www.statsmakemecry.com/smmctheblog/confusing-stats-terms-explained-heteroscedasticity-heteroske.html)
  - **What’s the best way to correct for autocorrelation: adding AR terms or adding MA terms?**: 
    - [Positive autocorrelation](http://www.dummies.com/education/economics/econometrics/patterns-of-autocorrelation/) : AR term
    - Negative autocorrelation : MA term
    - <img src = "http://d2r5da613aq50s.cloudfront.net/wp-content/uploads/415047.image3.jpg">

## Identifying the order of differencing in an ARIMA model

- **Rule 1: If the series has positive autocorrelations out to a high number of lags, then it probably needs a higher order of differencing**
  - Differencing tends to introduce negative correlation
- **Rule 2: If the lag-1 autocorrelation is zero or negative, or the autocorrelations are all small and patternless, then the series does not need a higher order of  differencing. If the lag-1 autocorrelation is -0.5 or more negative, the series may be overdifferenced.  BEWARE OF OVERDIFFERENCING!!**
- **Rule 3: The optimal order of differencing is often the order of differencing at which the standard deviation is lowest**
- **Rule 4: A model with no orders of differencing assumes that the original series is stationary (mean-reverting). A model with one order of differencing assumes that the original series has a constant average trend (e.g. a random walk or SES-type model, with or without growth). A model with two orders of total differencing assumes that the original series has a time-varying trend (e.g. a random trend or LES-type model)**
- **Rule 5: A model with no orders of differencing normally includes a constant term (which allows for a non-zero mean value). A model with two orders of total differencing normally does not include a constant term. In a model with one order of total differencing, a constant term should be included if the series has a non-zero average trend**
