#Author : Rohan M. Nanaware
#Date C.: 24th Feb 2018
#Date M.: 24th Feb 2018
#Purpose: Demand Forecast Model for AbInBev - https://datahack.analyticsvidhya.com/contest/data-science-talent-hunt-hackathon/lb
#Updates:
{
  
}
{
  #Time series forecasting
  #   https://www.analyticsvidhya.com/blog/2015/12/complete-tutorial-time-series-modeling/
}#00. Reference
{
  library(tibble)
  library(data.table)
  library(xgboost)
  library(dplyr)
}#01. Load required packages and helper functions
{
  wd <- "E:/Delivery/1 Active/AnalyticsVidhya/ABInBev Data Science Talent Hunt Hackathon"
  setwd(wd)
  demographics <- as.tibble(fread("./train_OwBvO8W/demographics.csv", 
                                   header = T, 
                                   stringsAsFactors = F,
                                   na.strings = c(NA, "NA","")))
  event_calendar <- as.tibble(fread("./train_OwBvO8W/event_calendar.csv", 
                                  header = T, 
                                  stringsAsFactors = F,
                                  na.strings = c(NA, "NA","")))
  historical_volume <- as.tibble(fread("./train_OwBvO8W/historical_volume.csv", 
                                    header = T, 
                                    stringsAsFactors = F,
                                    na.strings = c(NA, "NA","")))
  industry_soda_sales <- as.tibble(fread("./train_OwBvO8W/industry_soda_sales.csv", 
                                    header = T, 
                                    stringsAsFactors = F,
                                    na.strings = c(NA, "NA","")))
  industry_volume <- as.tibble(fread("./train_OwBvO8W/industry_volume.csv", 
                                    header = T, 
                                    stringsAsFactors = F,
                                    na.strings = c(NA, "NA","")))
  price_sales_promotion <- as.tibble(fread("./train_OwBvO8W/price_sales_promotion.csv", 
                                    header = T, 
                                    stringsAsFactors = F,
                                    na.strings = c(NA, "NA","")))
  weather <- as.tibble(fread("./train_OwBvO8W/weather.csv", 
                                    header = T, 
                                    stringsAsFactors = F,
                                    na.strings = c(NA, "NA","")))
  }#02. Data import
{
  
  summary(price_sales_promotion)
  quantile(price_sales_promotion$Price, probs = c(0,
                                                  0.05,
                                                  0.25,
                                                  0.5,
                                                  0.75,
                                                  0.95,
                                                  1))
  summary(historical_volume)#outlier treatment
  summary(weather)
  summary(industry_soda_sales)
  summary(event_calendar)
  summary(industry_volume)#need moere details on what the volumes in this dataset mean
  summary(demographics)
  
}#03. Data checks
{
  
}#04. Creating train data
