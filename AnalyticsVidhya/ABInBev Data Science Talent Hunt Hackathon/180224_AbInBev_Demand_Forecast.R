#Author : Rohan M. Nanaware
#Date C.: 24th Feb 2018
#Date M.: 02nd Jul 2018
#Purpose: Demand Forecast Model for AbInBev - https://datahack.analyticsvidhya.com/contest/data-science-talent-hunt-hackathon/lb
#             a. Forecast the demand volume for Jan’18 of all agency-SKU combination
#Updates:
{
  # 02nd Jul 2018 :
  #   1. Updates to module 3
  #       a. Added summary for historical volume data
  #       !  Read up more on ggplot
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
  library(ggplot2)
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
  # Historical volumes data
  summary(historical_volume)
  sapply(historical_volume, function(x) sum(is.na(x)))
  
}#03. Data checks
{
  
  {
    
    historical_volume <- as.data.table(historical_volume)
    
    # read up more on ggplot
    ggplot(data = historical_volume, aes(x = YearMonth, y = Volume, group = 1)) + 
      geom_line() + 
      geom_point()
    
    volume_forecast <- historical_volume[historical_volume$YearMonth == '201712']
    volume_forecast$YearMonth <- NULL
    write.csv(volume_forecast, '180702_volume_forecast_v1.csv', row.names = F)
    
    # Results - The historical volume data has sales only for select few SKUs within each agency, meaning all SKUs are not sold in every agency
    #           In such scenario how do we go about predicting sales for products that are not sold in that Agency?
      
  }# Method 1 - Forecast for 2018 Jan is the same as Dec 2017, Jan 2017
  
}#04. Approach 1 - Use only historical volume to forecast demand
