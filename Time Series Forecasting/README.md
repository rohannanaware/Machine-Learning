# Time Series Forecasting content summary

- [Duke University](#duke-university)
- [Reference](#reference)

# Duke University

## [Notes on nonseasonal ARIMA models](http://people.duke.edu/~rnau/Notes_on_nonseasonal_ARIMA_models--Robert_Nau.pdf)

 - The construction of a non-seasonal ARIMA model and its forecasts proceeds in the following steps :
    1. Determine whether your original time series needs any **nonlinear transformation(s)** such as logging and/or deflating and/or raising-to-some-power in order to be converted to a form where its **local random variations are consistent** over time and generally symmetric in appearance
    2. Let Y denote the time series you end up with after step 1. If Y is still “nonstationary” at this point, i.e., if it has a linear trend or a nonlinear or randomly-varying trend or exhibits random-walk behavior, then **apply a first-difference transformation**, i.e., construct a new variable that consists of the period-to-period changes in Y
    *How do I determine if a series is stationary or not? Mean, Variance, Auto-correlation?* - [Ref](https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/)
    3. If it STILL looks non-stationary after a first-difference transformation, which may be the case if Y was a relatively smoothly-varying series to begin with, then **apply another first-difference transformation** i.e., take the first-difference-of-the-first difference
        - Let “d” denote the **total number of differences** that were applied in getting to this point, which will be either 0, 1, or 2
    4. Let y denote the **“stationarized”** time series you have at this stage. **A stationarized time series has no trend, a constant variance over time, and constant “wiggliness” over time**. Then the **ARIMA equation** for predicting y takes the following form: 
        - `Forecast for y at time t = constant + weighted sum of the last p values of y + weighted sum of the last q forecast error`
        -   …where “p” and “q” are small integers and the weights (coefficients) may be positive or negative. In most cases either p is zero or q is zero, and p+q is less than or equal to 3, so there aren’t very many terms on the right-hand-side of this equation
        - The lagged values of y that appear in the equation are called **“autoregressive” (AR) terms**, and the lagged values of the forecast errors are called **“moving-average”** (MA) terms
    5. The forecast for the original series at period t, based on data observed up to period t-1, is obtained from the forecast for y by **undoing the various transformations that were applied along the way**, i.e., undifferencing, unlogging, undeflating, and/or unpowering, as the case may be
- The resulting model is called an **“ARIMA(p,d,q)”** model if the constant is assumed to be zero, and it is an **“ARIMA(p,d,q)+constant”** model if the constant is not zero. Thus, an ARIMA model is completely specified by **three small integers**—p, d, and q—and the presence or absence of a constant in the equation
- The term ARIMA is composed of “AR”, “I”, and “MA”, where the “I” stands for “integrated.” The rationale for the latter term is that a **time series that needs to be differenced in order to be made stationary is called an “integrated” series**
*(first you make the series stationary - non-linear trans., differencing etc., then you determine the weights for p and q terms amd the value of constant term)*
- The tricky step in this procedure is step 4, in which you **determine the values of p and q** that should be used in the equation for predicting the stationarized series y. One way is to use some **standard combinations of p and q** that come with practice, other systematic way is to look at the **plots of autocorrelations and partial autocorrelations of y**
    - **Autocorrelation** - The autocorrelation of y at lag k is the correlation between y and itself lagged by k periods, i.e., it is the correlation between yt and yt-k
    - **Partial autocorrelation** - The partial autocorrelation of y at lag k is the **coefficient of y_LAGk** in a regression of y on y_LAG1, y_LAG2, up to y_LAGk. (*Thus, the partial autocorrelation of y at lag 1 is the same as the autocorrelation of y at lag 1.???*)
        - The way to interpret the partial autocorrelation at lag k is that it is the **amount of correlation between y and y_LAGk that is not explained by lower-order autocorrelations** - lower order meaning t-1 upto t-k+1 - y_LAG1, y_LAG2, up to y_LAGk-1 - [Ref](https://en.wikipedia.org/wiki/Partial_autocorrelation_function). **Given a time series z_{t}, the partial autocorrelation of lag k, denoted alpha(k), is the autocorrelation between z_{t} and z_{{t+k}} with the linear dependence of z_{t} on z_{{t+1}} through z_{t+k-1} removed; equivalently, it is the autocorrelation between z_{t} and z_{{t+k}} that is not accounted for by lags 1 to k − 1, inclusive**-
- **Rules for determining p & q from autocorrelation and partial autocorrelation plots** : [Ref](https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/)
*Why is moving average series called moving average if it just looks at the error(term) between previous prediction and actual?*
  1. If the ACF plot “cuts off sharply” at lag k (i.e., if the autocorrelation is **significantly different from zero at lag k and extremely low in significance at the next higher lag** and the ones that follow), while there is a more **gradual “decay” in the PACF plot** (i.e. if the dropoff in significance beyond lag k is more gradual), then **set q=k and p=0**. This is a so-called “MA(q) signature”
  *How is the threshold determined over which ACF/ PACF value is significantly different than zero?*
  2. On the other hand, if the **PACF plot cuts off sharply at lag k while there is a more gradual decay in the ACF plot**, then set p=k and q=0. This is a so-called “AR(p) signature”
  3. If there is a single spike at lag 1 in both the ACF and PACF plots, then set p=1 and q=0 if it is positive (this is an AR(1) signature), and set p=0 and q=1 if it is negative (this is an MA(1) signature)
  *Need more details on the intuition of these rules*
        
        
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


# Reference
  - [AnalyticsVidhya](https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/)
  - [Duke ARIMA](https://people.duke.edu/~rnau/411arim.htm)
  - [Forecasting for the Pharmaceutical Industry - Models for New Product and In-Market Forecasting and How to Use Them](http://www.sadrabiotech.com/catalog/GOOD%20Forecasting%20for%20the%20Pharmaceutical%20Industry.pdf)
  - ATAR model

