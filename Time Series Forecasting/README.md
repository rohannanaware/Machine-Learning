
- Reference:
  - [AnalyticsVidhya](https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/)
  - [Duke ARIMA](https://people.duke.edu/~rnau/411arim.htm)

- **ARIMA(p,d,q) forecasting equation:** Most statistical forecasting methods are based on the assumption that the time series can be rendered approximately stationary (i.e., "stationarized") through the use of mathematical transformations
- A stationary series has no trend, its variations around its mean have a constant amplitude, and it wiggles in a consistent fashion, i.e., its short-term random time patterns always look the same in a statistical sense
- An ARIMA model can be viewed as a “filter” that tries to separate the signal from the noise, and the signal is then extrapolated into the future to obtain forecasts
- The ARIMA forecasting equation for a stationary time series is a **linear (i.e., regression-type) equation in which the predictors consist of lags of the dependent variable and/or lags of the forecast errors**
- The acronym ARIMA stands for **Auto-Regressive Integrated Moving Average.** Lags of the stationarized series in the forecasting equation are called "autoregressive" terms, lags of the forecast errors are called "moving average" terms, and a time series which needs to be differenced to be made stationary is said to be an "integrated" version of a stationary series. Random-walk and random-trend models, autoregressive models, and exponential smoothing models are all special cases of ARIMA models.
- A nonseasonal ARIMA model is classified as an "ARIMA(p,d,q)" model, where:
  - p is the number of autoregressive terms,
  - d is the number of nonseasonal differences needed for stationarity, and
  - q is the number of lagged forecast errors in the prediction equation
- To identify the appropriate ARIMA model for Y, you begin by **determining the order of differencing (d)** needing to stationarize the series and remove the gross features of seasonality, perhaps in conjunction with a variance-stabilizing transformation such as logging or deflating. If you stop at this point and predict that the differenced series is constant, you have merely fitted a random walk or random trend model.  However, the stationarized series may still **have autocorrelated errors, suggesting that some number of AR terms (p ≥ 1) and/or some number MA terms (q ≥ 1) are also needed in the forecasting equation**

