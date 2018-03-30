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
  # merge dataframes
  # https://stackoverflow.com/questions/1299871/how-to-join-merge-data-frames-inner-outer-left-right
}# Reference
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
  #     3. Check variable importance plots - remove or merge features
  
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
                "xgboost",
                "sqldf")
  ipak(packages)
}# 01. Load libraries
{
  
  wd <- "E:/Delivery/1 Active/AnalyticsVidhya/Lord of the Machines- Data Science Hackathon"
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
}# 05. Process data - **for module 7**
{
  # str(data)
  ohe_vars <- dummyVars(~ communication_type,
                        data = data)
  data_ohe <- as.data.table(predict(ohe_vars, newdata = data))
  # head(data_ohe)
  data_enc <- cbind(data[, !'communication_type', with = F], data_ohe)
  train_data <- data_enc[df_flag == 'train', !'df_flag', with = F]
  test_data  <- data_enc[df_flag == 'test', !'df_flag', with = F]
  
  {
    
    train <- campaign_data[train, on = 'campaign_id']
    
    train <- train[, !c("campaign_id",
                        "email_body",
                        "subject",
                        "email_url",
                        "id",
                        "user_id",
                        "send_date",
                        "is_open"),
                   with = F]
    
    ohe_vars <- dummyVars(~ communication_type,
                          data = train)
    train_ohe <- as.data.table(predict(ohe_vars, newdata = train))
    # head(data_ohe)
    train_enc <- cbind(train[, !c('communication_type'), with = F], train_ohe)
    train_data <- train_enc
    #test_data  <- data_enc[df_flag == 'test', !'df_flag', with = F]
    
  }# run ohe only on train data **run post the feature enginnering - click, open, sent, click-open pc**
  
}# 06. Prepare ADS - **for module 7**
{
  k = 10
  #Divide the data into train and test
  set.seed(1007)
  train_data$ID <- sample(1:k, nrow(train_data), replace = T)
  dep_train     <- data.table('is_click' = train_data$is_click)
  dep_train$ID  <- train_data$ID
  error         <- numeric()
  precision     <- numeric()
  recall        <- numeric()
  for (i in 1:k){
    TRAIN.F <- train_data[train_data$ID != i,!c("is_click", "ID"), with = F]
    TEST.F  <- train_data[train_data$ID == i,!c("is_click", "ID"), with = F]
    TRAIN.L <- data.frame(is_click = dep_train[dep_train$ID != i,!"ID", with = F])
    TEST.L  <- data.frame(is_click = dep_train[dep_train$ID == i,!"ID", with = F])
    #XGBoost algorithm :
    set.seed(1007)
    XGB_click <- xgboost(data = data.matrix(TRAIN.F), 
                         label = TRAIN.L$is_click, 
                         eta = 0.01,
                         max_depth = 5,
                         nround=100, 
                         seed = 1007,
                         objective = "binary:logistic",
                         nthread = 3,
                         verbose = F
    )
    pred       <- predict(XGB_click, data.matrix(TEST.F))
    # hist(pred)
    confusionMatrix(as.numeric(pred > 0.197), TEST.L$is_click)
    error[i]        <- mean(as.numeric(pred > 0.194) != TEST.L$is_click)
    print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
  }
  bias     <- mean(error)
  variance <- sd(error)
  #print(error)
  print(paste("Bias = ", round(bias,4)*100, "% ", " & Variance = ", round(variance, 4)))
  
}# 07. Train an XGB classifier - **cross validation**
{
  {
    submission <- data.frame('id' = test$id, 
                             'is_click' = 0)
    head(submission)
    write.csv(submission, '180325_sub_1_all_zeros.csv', row.names = F)
  }# submissions with all zeros
  {
    pred       <- predict(XGB_click, data.matrix(test_data))
    submission <- data.frame('id' = test$id, 
                             'is_click' = as.numeric(pred > 0.21))
    write.csv(submission, '180325_sub_1_all_zeros_2.csv', row.names = F)
  }# XGB based submission - Module #7
  {
    pred       <- predict(XGB_click, data.matrix(test_data))
    submission <- data.frame('id' = test$id, 
                             'is_click' = as.numeric(pred > 0.19128))
    write.csv(submission, '180325_sub_3.csv', row.names = F)
  }# XGB based submission - Module #7 - with max(sens + spec)
  {
    pred       <- predict(XGB_click, data.matrix(test_data))
    submission <- data.frame('id' = test$id, 
                             'is_click' = as.numeric(pred > 0.22))
    write.csv(submission, './submissions/180327_sub_fe_2.csv', row.names = F)
  }# XGB based submission - with feature engineerung - Module #10
  {
    test_data$is_open_propensity <- predict(XGB_open, as.matrix(test_data))
    test_data$is_click           <- predict(XGB_click, as.matrix(test_data))
    
    test_data$is_click           <- as.numeric(test_data$is_click > 0.21)
    submission <- data.frame('id' = test$id,
                             'is_click' = test_data$is_click)
    write.csv(submission, './submissions/180330_sub_sfe_1.csv', row.names = F)
  }# XGB based submission - with is_open as predictor
  {
    train <- data.table(train)
    train_email_response <- train[, list(emails_sent    = max(emails_sent),
                                         emails_opened  = max(emails_opened),
                                         emails_clicked = max(emails_clicked),
                                         click_pec      = max(emails_clicked)/max(emails_opened),
                                         open_pc        = max(emails_opened)/max(emails_sent)
                                        ),
                                  by = 'user_id']
    test_data <- train_email_response[test, on = 'user_id']
    # sapply(test_data, function(x) sum(is.na(x)))
    # length(unique(test_data$user_id))
    # length(unique(test_data$user_id[!is.na(test_data$emails_sent)]))
    
    test_data$emails_sent[is.na(test_data$emails_sent)] = 0
    test_data$emails_opened[is.na(test_data$emails_opened)] = 0
    test_data$emails_clicked[is.na(test_data$emails_clicked)] = 0
    test_data$click_pec[is.na(test_data$click_pec)] = 0
    test_data$open_pc[is.na(test_data$open_pc)] = 0
    
    test_data <- campaign_data[test_data, on = 'campaign_id']
    
    test_data <- test_data[, !c("campaign_id",
                                "email_body",
                                "subject",
                                "email_url",
                                "id",
                                "user_id",
                                "send_date"),
                           with = F]
    
    ohe_vars <- dummyVars(~ communication_type,
                          data = test_data)
    test_data_ohe <- as.data.table(predict(ohe_vars, newdata = test_data))
    # head(data_ohe)
    test_data_enc <- cbind(test_data[, !c('communication_type'), with = F], test_data_ohe)
    test_data <- test_data_enc
    pred       <- predict(XGB_click, data.matrix(test_data))
    submission <- data.frame('id' = test$id, 
                             'is_click' = as.numeric(pred > 0.197))
    write.csv(submission, './submissions/180331_sub_fe_5.csv', row.names = F)
    
  }# XBG based submission - with feature engineering(email response details)
  
}# 08. Create submission
{
  #Sensitivity vs specificity
  library(ROCR)
  pred       <- predict(XGB_click, data.matrix(TEST.F))
  pred <- data.frame(pred)
  colnames(pred)
  pred <- prediction(pred$pred, TEST.L$is_click)
  ss <- performance(pred, "sens", "spec")
  plot(ss)
  ss@alpha.values[[1]][which.max(ss@x.values[[1]]+ss@y.values[[1]])]
}# 09. Identify the threshold for p giving maximum spec and sens
{
  {
    data <- rbind(cbind(train[, !c("is_open","is_click"), with = F], "train"), 
                  cbind(test, "test"))
    colnames(data)[5] <- 'df_flag'
    data <- campaign_data[data, on = "campaign_id"]
    # convert date character into timestamp
    data$send_date  <- as.Date(strptime(data$send_date, "%d-%m-%Y %H:%S"), 
                               format = "%Y-%m-%d")
    train$send_date <- as.Date(strptime(train$send_date, "%d-%m-%Y %H:%S"), 
                               format = "%Y-%m-%d")
    test$send_date  <- as.Date(strptime(test$send_date, "%d-%m-%Y %H:%S"), 
                               format = "%Y-%m-%d")
    
  }#data processing - merge train/test, convert send date from char to date
  
  {
    
    #Effect of sending emails, customer opening emails on click through rate
    
    {
      # emails_sent <- train[, list(sent = length(unique(id))),
      #                      by = 'user_id']
      # # emails_sent <- emails_sent[, list(cust_count = length(unique(user_id))),
      # #                            by = 'sent']
      # train_emails_sent <- emails_sent[train, on = 'user_id']
      # emails_open_sent  <- train_emails_sent[, list(open = length(unique(id[is_open == 1])),
      #                                               click = length(unique(id[is_click == 1]))),
      #                                        by = 'sent']
      # emails_open_sent$click_tr <- round(emails_open_sent$click / emails_open_sent$open, 4)*100
      # View(emails_open_sent)
      
      # temp <- unique(merge(train, train, by = 'user_id')[send_date.x > sent_date.y,
      #                                               list(emails_sent_td = length(unique(id.y))),
      #                                               by = 'id.x'])
      train <- sqldf('SELECT a.*,
                     count(distinct b.id) as emails_sent
                     --b.id as right_id
                     --a.id, a.user_id, count(distinct b.id)
                     FROM train a
                     LEFT JOIN
                     train b
                     ON a.user_id = b.user_id and
                     a.send_date > b.send_date
                     GROUP BY a.id, a.user_id, a.campaign_id, a.send_date, a.is_open, a.is_click
                     ')
      
      test <- sqldf('SELECT a.*,
                    count(distinct b.id) as emails_sent
                    --b.id as right_id
                    --a.id, a.user_id, count(distinct b.id)
                    FROM test a
                    LEFT JOIN
                    test b
                    ON a.user_id = b.user_id and
                    a.send_date > b.send_date
                    GROUP BY a.id, a.user_id, a.campaign_id, a.send_date
                    ')
      
      data_emails_sent_count <- sqldf('SELECT a.id,
                                      count(distinct b.id) as emails_sent
                                      --b.id as right_id
                                      --a.id, a.user_id, count(distinct b.id)
                                      FROM data a
                                      LEFT JOIN
                                      data b
                                      ON a.user_id = b.user_id and
                                      a.send_date > b.send_date
                                      GROUP BY a.id
                                      --a.communication_type, a.total_links, 
                                      --a.no_of_internal_links, a.no_of_images, a.no_of_sections,
                                      --a.email_body, a.subject, a.email_url, a.id, a.user_id,
                                      --a.send_date, a.df_flag
                                      ')
      
      data_emails_sent_count <- data.table(data_emails_sent_count)
      data <- data_emails_sent_count[data, on = 'id']
      nrow(data)
      
      # temp <- sqldf('SELECT * 
      #               FROM train a
      #               inner join
      #               test b
      #               on a.user_id = b.user_id')
      # View(temp)
      
      # re-run module 6, 7
    }# count of emails sent of a customer till date
    
    {
      train$send_date <- as.Date(strptime(train$send_date, "%d-%m-%Y %H:%S"), 
                                 format = "%Y-%m-%d")
      train <- sqldf('SELECT a.*,
                     count(distinct case when b.is_click = 1 then b.id end) as emails_clicked,
                     count(distinct case when b.is_open = 1 then b.id end) as emails_opened,
                     count(distinct b.id) as emails_sent
                     --b.id as right_id
                     --a.id, a.user_id, count(distinct b.id)
                     FROM train a
                     LEFT JOIN
                     train b
                     ON a.user_id = b.user_id and
                     a.send_date > b.send_date
                     GROUP BY a.id, a.user_id, a.campaign_id, a.send_date, a.is_open, a.is_click
                     ')
      train$click_pec <- ifelse(train$emails_opened != 0, 
                                train$emails_clicked / train$emails_opened, 
                                0)
      train$open_pc <- ifelse(train$emails_sent != 0, 
                              train$emails_opened / train$emails_sent,
                              0)
      
    }# count of emails sent, opened, clicked by a customer till date, email open %, email click %
    {
      
      train <- campaign_data[train, on = 'campaign_id']
      
      train <- train[, !c("campaign_id",
                          "email_body",
                          "subject",
                          "email_url",
                          "id",
                          "user_id",
                          "send_date",
                          "is_open"),
                     with = F]
      
      ohe_vars <- dummyVars(~ communication_type,
                            data = train)
      train_ohe <- as.data.table(predict(ohe_vars, newdata = train))
      # head(data_ohe)
      train_enc <- cbind(train[, !c('communication_type'), with = F], train_ohe)
      train_data <- train_enc
      
    }# run ohe only on train data **run post the feature enginnering - click, open, sent, click-open pc**
    
  }#email response details
  
}# 10. Feature engineering
{
  {
    sum(train$is_open)/nrow(train)
    # [1] 0.1004602
    
    {
      data <- rbind(cbind(train[, !c("is_open","is_click"), with = F], "train"), 
                    cbind(test, "test"))
      colnames(data)[5] <- 'df_flag'
      # merge data with campaign details
      data <- campaign_data[data, on = "campaign_id"]
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
      dep_train     <- data.table('is_open' = train$is_open)
      dep_train$ID  <- train_data$ID
      error         <- numeric()
      precision     <- numeric()
      recall        <- numeric()
      for (i in 1:k){
        TRAIN.F <- train_data[train_data$ID != i,!"ID", with = F]
        TEST.F  <- train_data[train_data$ID == i,!"ID", with = F]
        TRAIN.L <- data.frame(is_open = dep_train[dep_train$ID != i,!"ID", with = F])
        TEST.L  <- data.frame(is_open = dep_train[dep_train$ID == i,!"ID", with = F])
        #XGBoost algorithm :
        set.seed(1007)
        XGB_click <- xgboost(data = data.matrix(TRAIN.F), 
                             label = TRAIN.L$is_open, 
                             eta = 0.01,
                             max_depth = 5,
                             nround=100, 
                             seed = 1007,
                             objective = "binary:logistic",
                             nthread = 3,
                             verbose = F
        )
        pred       <- predict(XGB_click, data.matrix(TEST.F))
        # hist(pred)
        confusionMatrix(as.numeric(pred > 0.2665438), TEST.L$is_open)
        error[i]        <- mean(as.numeric(pred > 0.2665438) != TEST.L$is_open)
        print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
      }
      bias     <- mean(error)
      variance <- sd(error)
      #print(error)
      print(paste("Bias = ", round(bias,4)*100, "% ", " & Variance = ", round(variance, 4)))
      
    }# 07. Train an XGB classifier - **cross validation**
    {
      #add is_open propensity as a prediction variable
      train_data$is_open_propensity = predict(XGB_open, data.matrix(train_data[, !'ID', with = FALSE]))
      
      {
        k = 5
        #Divide the data into train and test
        train_data$ID <- sample(1:k, nrow(train_data), replace = T)
        dep_train     <- data.table('is_click' = train$is_click)
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
          XGB_open <- xgboost(data = data.matrix(TRAIN.F), 
                              label = TRAIN.L$is_click, 
                              eta = 0.01,
                              max_depth = 5,
                              nround=100, 
                              seed = 1007,
                              objective = "binary:logistic",
                              nthread = 3,
                              verbose = F
          )
          pred       <- predict(XGB_open, data.matrix(TEST.F))
          # hist(pred)
          confusionMatrix(as.numeric(pred > 0.1917), TEST.L$is_click)
          error[i]        <- mean(as.numeric(pred > 0.191646) != TEST.L$is_click)
          print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
        }
        bias     <- mean(error)
        variance <- sd(error)
        #print(error)
        print(paste("Bias = ", round(bias,4)*100, "% ", " & Variance = ", round(variance, 4)))
        
      }# 07. Train an XGB classifier - **cross validation**
      
      
      
    }# Check performance on is_click as dependent variable
    
  }#Create a prediction model for customer to open an email 
  
  {
    colnames(test_data)
    
    test_data$is_open_propensity <- predict(XGB_open, as.matrix(test_data))
    test_data$is_click           <- predict(XGB_click, as.matrix(test_data))
    
    test_data$is_click           <- as.numeric(test_data$is_click > 0.21)
    
  }#apply XGB_open and XGB_click on test data
}# 11. Feature engineering
