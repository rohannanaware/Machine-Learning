#Author - Rohan M. Nanaware
#Date C.- 23rd Mar 2018
#Date M.- 23rd Mar 2018
#Purpose- Churn model - Logistic regression with regularisation
#Notes  -
    # Logistic regression function - 
    #     Make it work on larger matrices
    #     Modify the output to match the input of AIC for backward selection
{
  train.y =
  train.X =
  
  sigmoid <- function(z) {
      1/(1+exp(-z))
  }
  
  cost = function(theta, X, y,lambda){
      cost_gradient=list()
      h_theta=sigmoid(X%*%theta)
      cost=1/nrow(X)*sum(-y*log(h_theta)-(1-y)*log(1-h_theta))+lambda/(2*nrow(X))*sum(theta^2)
      return(cost)
  }
  
  gradient=function(theta, X, y,lambda, alpha=1){
      gradient= 1/nrow(X)*alpha*(sigmoid(t(theta)%*%t(X))-t(y))%*%X+(lambda/(nrow(X)))*c(0,theta[-1])
      return(gradient)                                                                       
  }
  
  logistic_regression <- function(theta, X, y, lambda, alpha, p_value = 0.5) {
    optimized         <- optim(par=initial_theta,X=X,#y=y,lambda = lambda,
                               fn=cost,
                               gr=gradient,
                               method="BFGS")
    # fitted_result     <- sigmoid(X%*%optimized$par)
    coeffs            <- optimized$par
    return(coeffs)
  }
  
  initial_theta <- matrix(rep(0,ncol(X)))
  fitted_result <- logistic_regression(initial_theta, X = train.X, y = train.y, 0.5, 0.1)
  train.y$fitted_result_label=ifelse(fitted_result>=0.5,1,0)
  
  accuracy=sum(train.y$Label==train.y$fitted_result_label)/nrow(train.y)
  cat("The accuracy is: ",accuracy)

}# logistic regression function

{
  library(data.table)
  library(dplyr)
  library(ggplot2)
  library(caret)
}# 01. Load libraries

{
  wd <- 'C:/Users/rohan.nanaware/Documents/Rohan(local)/1 Mu Sigma/Account/DCP/CPW CRM Churn Modelling/Codes'
  setwd(wd)
}# 02. Set working directory

{
  # data import
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- fread('MS_CPWPROP_ADS_O2_INTIME_SAMPLE.csv', header = T, stringsAsFactors = F, na.strings = c(" ","NA"))
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[complete.cases(MS_CPWPROP_ADS_O2_INTIME_SAMPLE),]
  
  # Reduce the number of factors using the results from Bivariates
  REDUCE_BIVAR <- c('PREMIUM_HANDSET',
                    'PAST_RETENTION',
                    'PREV_PP_PURCH',
                    'OTHER_CONNECTION_COUNT_HIST',
                    'PAST_UPGRADE_COUNT',
                    'PERCENT_SEASONAL_TXNS',
                    'OTHER_CONNECTION_COUNT',
                    'SIMO_PAST_MIGRATION_COUNT',
                    'PREPAY_PAST_MIGRATION_COUNT',
                    'SIMO_PURCH_INLIFE_WIN_COUNT',
                    'PREPAY_PURCH_INLIFE_WIN_COUNT'
  )
  #rm(MS_CPWPROP_ADS_O2, MS_CPWPROP_ADS_O2_INTIME)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_BIVAR, with = FALSE]
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE$NETWORK_PROVIDER_NAME <- NULL
  # filter out IDs
  REDUCE_IDs        <- c('SCV_INDIVIDUAL_KEY',
                         'TRANSACTION_NUMBER',
                         'ORDER_LINE_NUMBER',
                         'INVOICE_DATE_FORMAT',
                         'ADDRESSID')
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_IDs, with = FALSE]
  #2.b Univariates, outlier deletion, Multivariate outlier deletion, NA removal
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[complete.cases(MS_CPWPROP_ADS_O2_INTIME_SAMPLE),]
  
  # encode variables
  FLAG_RETENTION <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_INTIME_SAMPLE$FLAG_RETENTION)
  REDUCE_DEP = c("FLAG_RETENTION")
  #Filter out the dependent variable
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_DEP, with = FALSE]
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB$P_AGE_FINE <- as.character(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB$P_AGE_FINE)
  #One hot encoding on all categorical variables
  FEATURE_OHE <- c('PART_MANUFACTURER_DESCR',
                   'OUTLET_TYPE',
                   'SALES_DIVISION_DESCR',
                   'CHANNEL_TYPE',
                   'P_AGE_FINE',
                   'H_MOSAIC_UK_6_GROUP',
                   'GENDER',
                   'P_PERSONAL_INCOME_BAND_V2',
                   'P_MARITAL_STATUS',
                   'CUSTOMER_NO_MARKETING_FLG',
                   'P_AFFLUENCE_V2',
                   'P_FINANCIAL_STRESS',
                   'H_FAMILY_LIFESTAGE_2011',
                   'H_NUMBER_OF_BEDROOMS',
                   'H_RESIDENCE_TYPE_V2',
                   'H_TENURE_V2'
  )
  DUMMIES <- dummyVars(~ PART_MANUFACTURER_DESCR + 
                         OUTLET_TYPE + 
                         SALES_DIVISION_DESCR +
                         CHANNEL_TYPE +
                         P_AGE_FINE +
                         H_MOSAIC_UK_6_GROUP +
                         GENDER +
                         P_PERSONAL_INCOME_BAND_V2 +
                         P_MARITAL_STATUS +
                         CUSTOMER_NO_MARKETING_FLG +
                         P_AFFLUENCE_V2 +
                         P_FINANCIAL_STRESS +
                         H_FAMILY_LIFESTAGE_2011 +
                         H_NUMBER_OF_BEDROOMS +
                         H_RESIDENCE_TYPE_V2 +
                         H_TENURE_V2,
                       data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_OHE <- as.data.frame(predict(DUMMIES, newdata = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB))
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB     <- data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- 
    cbind(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB[,-c(which(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB) %in% FEATURE_OHE))]
          , MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_OHE)
  
}# 03. Import and process data

{
  DATA <- cbind(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC, FLAG_RETENTION)
  set.seed(1007)
  sample <- sample.int(n = nrow(DATA),
                       size = floor(0.75*nrow(DATA)),
                       replace = F)
  TRAIN.X <- DATA[sample,!(colnames(DATA) == 'FLAG_RETENTION')]
  TRAIN.Y <- DATA[sample,colnames(DATA) == 'FLAG_RETENTION']
  TEST.X  <- DATA[-sample,!(colnames(DATA) == 'FLAG_RETENTION')]
  TEST.Y  <- DATA[-sample,colnames(DATA) == 'FLAG_RETENTION']
  
  DATA <- data.table(DATA)
  TRAIN.X <- DATA[sample,!'FLAG_RETENTION', with = FALSE]
  TRAIN.Y <- DATA[sample,'FLAG_RETENTION',with = FALSE]
  TEST.X  <- DATA[-sample,!(colnames(DATA) == 'FLAG_RETENTION')]
  TEST.Y  <- DATA[-sample,colnames(DATA) == 'FLAG_RETENTION']
  
  
  
}# 04. Split the train and test data

{
  # model output needs to be an equation and not propensity scores
  # currently the model is being retrained on whatever data is proided as an input
  
  initial_theta <- matrix(rep(0), ncol(TRAIN.X))
  coeffs <- logistic_regression(theta = initial_theta,
                                X = as.matrix(TRAIN.X),
                                y = TRAIN.Y,
                                lambda = 0.5)
  
  PROPENSITY_SCORES <- sigmoid(as.matrix(TRAIN.X)%*%coeffs)
  ACCURACY_TRAIN <- sum(as.integer(as.integer(PROPENSITY_SCORES > 0.5) == TRAIN.Y))/length(TRAIN.Y)
  PROPENSITY_SCORES <- sigmoid(as.matrix(TEST.X)%*%coeffs)
  ACCURACY_TEST  <- sum(as.integer(as.integer(PROPENSITY_SCORES > 0.5) == TEST.Y))/length(TEST.Y)
  
  
  for (lambda in c(0, 0.25, 0.5, 0.75, 1.0)) {
    coeffs <- logistic_regression(theta = initial_theta,
                                X = as.matrix(TRAIN.X),
                                y = TRAIN.Y,
                                lambda = lambda)
    PROPENSITY_SCORES <- sigmoid(as.matrix(TRAIN.X)%*%coeffs)
    ACCURACY_TRAIN <- sum(as.integer(as.integer(PROPENSITY_SCORES > 0.5) == TRAIN.Y))/length(TRAIN.Y)
    PROPENSITY_SCORES <- sigmoid(as.matrix(TEST.X)%*%coeffs)
    ACCURACY_TEST  <- sum(as.integer(as.integer(PROPENSITY_SCORES > 0.5) == TEST.Y))/length(TEST.Y)
    print(paste("Lambda : ", lambda, " Train accuracy : ", round(ACCURACY_TRAIN,4)*100, "% Test accuracy : ",round(ACCURACY_TEST,4)*100,"%"))
  }
  
}# 05. Fit a log reg model

{
  library(glmnet)
  
  # fit a glmnet
  fit = glmnet(x = as.matrix(TRAIN.X), 
               y = TRAIN.Y, 
               family = "binomial")
  
  # plot
  # predict(fit, newx = x[1:5,], type = "class", s = c(0.05, 0.01))
  
  system.time(cvfit <- cv.glmnet(x = as.matrix(TRAIN.X),
                                 y = TRAIN.Y,
                                 family = "binomial",
                                 type.measure = "class"))
  
  plot(cvfit)
  
  cvfit$lambda.min # value of lambda that gives mimimum cross validation error
  # cvfit$lambda.1se # largest value of lambda such that error is within one standard deviation of minimum
  
  coef(cvfit, s = "lambda.min") # coefficients
  
  predictions <- predict(cvfit, as.matrix(TRAIN.X), s = "lambda.min", type = "response")
  confusionMatrix(TRAIN.Y, as.numeric(predictions > 0.5))
  
  predictions <- predict(cvfit, as.matrix(TEST.X), s = "lambda.min", type = "response")
  confusionMatrix(TEST.Y, as.numeric(predictions > 0.5))
  
}# 06. Regularisation using glmnet
