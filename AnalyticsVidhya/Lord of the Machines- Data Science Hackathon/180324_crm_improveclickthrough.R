{
  #Author - Rohan M. Nanaware
  #Date C.- 24th Mar 2018
  #Date M.- 24th Mar 2018
  #Purpose- Model the propensity of a customer to open and click through an email. This will later
  #         feed into identiying the drivers of click through and optimizing CRM based on the learnings
  #         https://datahack.analyticsvidhya.com/contest/lord-of-the-machines/
  #         Competition start-end date - 24th Mar to 01st Apr 2018
  #Updates-
}# Code brief

{
  
  # Hypothesis driven
  #     1. Run a quick and dirty iteration using gradient boost. Achieve as good accuracy as possible
  #     2. Perform basic EDA - 
  #         a. Drivers of click through - Email attributes, Customer attributes, external factors
  #         b. Email attributes - Structure and content, header, subject, does the address contain the name of user?,
  #                               Time of day and day of week, etc.
  #         c. Cust. attributes - No. of emails sent/opened/clicked by the customer, frequency of engagement,
  #                               Affinity to a given type of email, etc.
  #         d. Ext. factors     - Time of year, holiday season, prize associated, etc.
  #     3. Feature engineering based on the findings from EDA
  #     4. Rerun model iteration
  #     5. Model hypertuning

  # Stats driven
  #     1. Create a new prediction model with email open as dependent. 
  #     2. Use the email open propensity as an input to predict click propensity

}# Approach

{
  # install and/ or load packages
  ipak <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new.pkg)) 
      install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
  }
  
}# 00. Helper functions
{
  packages <- c("data.table",
                "caret",
                "ggplot2",
                "dplyr",
                "xgboost")
  ipak(packages)
}# 01. Load libraries
{
  
  wd <- "D:/Delivery/01 Active/AnalyticsVidhya/Lord of the Machines- Data Science Hackathon"
  setwd(wd)

}# 02. Set working directory
{
  train <- fread("./input data/train.csv", header = T, stringsAsFactors = F)
  test  <- fread("./input data/test.csv", header = T, stringsAsFactors = F)
  campaign_data <- fread("./input data/campaign_data.csv", header = T, stringsAsFactors = F)
}# 03. Read data
{
  
  nrow(train)
  str(train)
  sapply(train, function(x) sum(is.na(x)))
  sapply(train, function(x) length(unique(x)))
  # each email sent is captured as seperate line item
  # multiple emails have been sent to a single customer - 
  length(unique(train$id))/length(unique(train$user_id))
  # [1] 6.081879 - one email per customer per month
  table(train$is_open)[2]/sum(table(train$is_open))
  # overall open rate - 10%
  table(train$is_click)[2]/sum(table(train$is_click))
  # overall click through rate - 1.25%
  # data has a high class bias
  table(train$is_open, train$is_click)# as expected unopened emails havent been clicked through
  
  nrow(test)
  str(test)
  length(unique(test$id))/length(unique(test$user_id))
  # [1] 3.904056 - higher email count

  str(campaign_data)
  View(head(campaign_data))
  
}# 04. Understand the data - **not needed to run**
{
  data <- rbind(cbind(train[, !c("is_open","is_click"), with = F], "train"), 
                cbind(test, "test"))
  colnames(data)[5] <- 'df_flag'
  # str(data)
  # merge data with campaign details
  data <- campaign_data[data, on = "campaign_id"]
  # sapply(data, function(x) sum(is.na(x)))
  # sapply(data, function(x) length(unique(x)))
  # str(data)
  # table(data$communication_type)
  
  # convert date character into timestamp
  data$send_date <- as.Date(strptime(data$send_date, "%d-%m-%Y %H:%S"), 
                           format = "%Y-%m-%d")
  data <- data[, c("communication_type",
                   "total_links",
                   "no_of_internal_links",
                   "no_of_images",
                   "no_of_sections",
                   "df_flag"),
               with = F]
}# 05. Process data
{
  # str(data)
  ohe_vars <- dummyVars(~ communication_type,
                        data = data)
  data_ohe <- as.data.table(predict(ohe_vars, newdata = data))
  # head(data_ohe)
  data_enc <- cbind(data[, !'communication_type', with = F], data_ohe)
  train_data <- data_enc[df_flag == 'train', !'df_flag', with = F]
  test_data  <- data_enc[df_flag == 'test', !'df_flag', with = F]

}# 06. Prepare ADS
{
    k = 5
    #Divide the data into train and test
    train_data$ID <- sample(1:k, nrow(train_data), replace = T)
    dep_train     <- train[, 'is_click', with = F]
    dep_train$ID  <- train_data$ID
    error         <- numeric()
    precision     <- numeric()
    recall        <- numeric()
    for (i in 1:k){
      TRAIN.F <- train_data[train_data$ID != i,!"ID", with = F]
      TEST.F  <- train_data[train_data$ID == i,!"ID", with = F]
      TRAIN.L <- data.frame(is_click = dep_train[dep_train$ID != i,!"ID", with = F])
      TEST.L  <- data.frame(is_click = dep_train[dep_train$ID == i,!"ID", with = F])
      #XGBoost algorithm :
      set.seed(1007)
      XGB_click <- xgboost(data = data.matrix(TRAIN.F), 
                           label = TRAIN.L$is_click, 
                           eta = 0.1,
                           max_depth = 5,
                           nround=100, 
                           seed = 1007,
                           objective = "binary:logistic",
                           nthread = 3,
                           verbose = 0
      )
      pred       <- predict(XGB_click, data.matrix(TEST.F))
      prediction <- as.data.frame(as.numeric(pred > 0.012))
      precision[i]        <- sum(as.numeric(pred > 0.012) == TEST.L$is_click)/sum(as.numeric(pred < 0.012))
      recall[i]           <- sum(as.numeric(pred > 0.012) == TEST.L$is_click)/sum(TEST.L$is_click)
      print(paste('Progress = ', round(i/k,2)*100,"%", ' | Precision = ', round(precision[i],4)*100, "%", ' | Recall = ', round(recall[i],4)*100, "%", sep = ""))
    }
    bias     <- mean(error)
    variance <- sd(error)
    #print(error)
    print(paste("Bias = ", bias, " & Variance = ", variance))
}# 07. Train an XGB classifier
{
  
}# 08. Create submission


#Sensitivity vs specificity
library(ROCR)
pred       <- predict(XGB_click, data.matrix(TEST.F))
pred <- data.frame(pred)
colnames(pred)
pred <- prediction(pred$pred, TEST.L$is_click)
ss <- performance(pred, "sens", "spec")
plot(ss)
ss@alpha.values[[1]][which.max(ss@x.values[[1]]+ss@y.values[[1]])]
