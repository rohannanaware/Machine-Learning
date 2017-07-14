#Author : Rohan M. Nanaware
#Date C : 21st Jun 2017
#Date M : 21st Jun 2017 - Chi-square, PCA
#         22nd Jun 2017 - MCA, Significance testing
#         28th Jun 2017 - Significance testing
#         03rd Jul 2017 - Significance testing
#                       - k-fold cross validation
#Purpose: CPW Customer propensity model - 1st iteration
#Excel  : 0621_prpmodel_iteration_1

{
  #  1. 1st iteration to be run for O2 customers only
  #  2. Factors analysis - Reduce the number of factors using the results from Bivariates 2.a
  #                      - Classify vars into cat, numeric, one-hot
  #                      - Univariates, outlier deletion, Multivariate outlier deletion 2.b
  #                      - Correlation matrix for dimensionality reduction, MCA, Chi-square test 2.c - Documemnt
  #                      - Latent factor detection
  #  3. Data checks      - ANOVA, Hoslem test
  #  4. Post 1st itr.    - Remove insignificant variables
  #                      - Sensitivity vs Specificity graphs and AUC
  #                      - Model validation - In sample, out of sample, k-fold, AUC
}# 01. Progress Details
{
  library(data.table)
  library(xgboost)
  library(MASS)
  library(caret)
  library(FactoMineR)
  library(ggplot2)
  #Setup ODBC - 
  library(RODBC)
  #Normalize the environment
  Sys.setenv(ODBCINI="/etc/odbc.ini")
  Sys.setenv(NZ_ODBC_INI_PATH="/etc")
}# 02. Packages
{
  #Create ODBC connection
  odbcChannel <-odbcConnect("NZSQL1")
  odbcClose(odbcChannel)
  
  #Pull data from Netezza
  MS_CPWPROP_ADS <- sqlQuery(odbcChannel, "SELECT *
                             FROM BASE_CPW_PM_ADS
                             WHERE INVOICE_DATE_FORMAT BETWEEN '2012-02-01' AND '2014-10-31'
                             AND NETWORK_PROVIDER_NAME = 'O2'",
                             stringsAsFactors = FALSE, believeNRows = FALSE)
  save(MS_CPWPROP_ADS, file = "MS_CPWPROP_ADS.RData")
  
  #Operations on fields - level reduction
  MS_CPWPROP_ADS$DAY_DIFF_2ND_LINE_PURCH[is.na(MS_CPWPROP_ADS$DAY_DIFF_2ND_LINE_PURCH)] <- 0#2nd line purchase diff
  MS_CPWPROP_ADS$PART_MANUFACTURER_DESCR <- ifelse(MS_CPWPROP_ADS$PART_MANUFACTURER_DESCR %in% c('APPLE','Samsung','Nokia','Blackberry',
                                                                                                 'HTC','Sony'),
                                                   MS_CPWPROP_ADS$PART_MANUFACTURER_DESCR,
                                                   'Others')
  MS_CPWPROP_ADS$NETWORK_PROVIDER_NAME   <- ifelse(MS_CPWPROP_ADS$NETWORK_PROVIDER_NAME %in% c('O2','Vodafone','Orange','Talkmobile',
                                                                                               'T-Mobile','EE'),
                                                   MS_CPWPROP_ADS$NETWORK_PROVIDER_NAME,
                                                   'Others')
  MS_CPWPROP_ADS$OUTLET_TYPE             <- ifelse(MS_CPWPROP_ADS$OUTLET_TYPE %in% c('High Street','Shopping Centre','Warehouse - Online',
                                                                                     'Retail Park','Warehouse - Other','Arterial Route',
                                                                                     'Regional Shopping Centre'),
                                                   MS_CPWPROP_ADS$OUTLET_TYPE,
                                                   'Others')
  MS_CPWPROP_ADS$SALES_DIVISION_DESCR    <- ifelse(MS_CPWPROP_ADS$SALES_DIVISION_DESCR %in% c('Non-retail & Support','North Division',
                                                                                              'South Division', 'Central Division', 'East Division',
                                                                                              'London Division', 'Not Open', 'Samsung Division'),
                                                   MS_CPWPROP_ADS$SALES_DIVISION_DESCR,
                                                   'Others')
  MS_CPWPROP_ADS$CHANNEL_TYPE            <- ifelse(MS_CPWPROP_ADS$CHANNEL_TYPE %in% c('Retail Branches'),
                                                   "CPW-STORE",
                                                   ifelse(MS_CPWPROP_ADS$CHANNEL_TYPE %in% c('On Line Mobiles.co.uk', 'On Line E2_OSPS Vanilla'),
                                                          "OLS",
                                                          ifelse(MS_CPWPROP_ADS$CHANNEL_TYPE %in% c('On Line Direct','On Line Web'),
                                                                 "CPW-OL",
                                                                 'Others')))
  MS_CPWPROP_ADS$P_AGE_FINE
  MS_CPWPROP_ADS$P_PERSONAL_INCOME_BAND_V2
  MS_CPWPROP_ADS$H_NUMBER_OF_ADULTS
  MS_CPWPROP_ADS$P_AFFLUENCE_V2
  MS_CPWPROP_ADS$P_FINANCIAL_STRESS
  MS_CPWPROP_ADS$H_NUMBER_OF_BEDROOMS
  MS_CPWPROP_ADS$H_RESIDENCE_TYPE_V2
  MS_CPWPROP_ADS$H_TENURE_V2
  colnames(MS_CPWPROP_ADS)[48] <- 'PREPAY_PAST_MIGRATION_FLAG'
}# 03. Data import and cleaning
{
  #Filter for O2 customers
  MS_CPWPROP_ADS_O2 <- MS_CPWPROP_ADS[MS_CPWPROP_ADS$NETWORK_PROVIDER_NAME == 'O2',]
  #Filter out data for out of time validation
  MS_CPWPROP_ADS_O2_INTIME <- MS_CPWPROP_ADS_O2[MS_CPWPROP_ADS_O2$INVOICE_DATE_FORMAT <= '2014-07-31',]
  #Work on sample, park data for out of time validation
  sample_size = 1000000
  set.seed(1007)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME[sample(1:nrow(MS_CPWPROP_ADS_O2_INTIME), size = sample_size, replace = FALSE, prob = NULL),]
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- data.table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)
}# 04. Sampling
{
  #2.a - Reduce the number of factors using the results from Bivariates
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
  #filter out IDs
  REDUCE_IDs        <- c('SCV_INDIVIDUAL_KEY',
                         'TRANSACTION_NUMBER',
                         'ORDER_LINE_NUMBER',
                         'INVOICE_DATE_FORMAT',
                         'ADDRESSID')
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_IDs, with = FALSE]
  #2.b Univariates, outlier deletion, Multivariate outlier deletion, NA removal
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[complete.cases(MS_CPWPROP_ADS_O2_INTIME_SAMPLE),]
}# 05. Variable reduction using biariates and NA imputation
{
  #2.c Correlation matrix for dimensionality reduction, MCA, chi-square test
  #    Chi-square test for dependency check
  chi_sq_matrix <- data.frame(matrix(data = NA, nrow = ncol(MS_CPWPROP_ADS_O2_INTIME_SAMPLE), ncol = ncol(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)))
  colnames(chi_sq_matrix) <- colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)
  rownames(chi_sq_matrix) <- colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)
  for (i in 1:ncol(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)) {
    for (j in 1:ncol(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)){
      tb         <- table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE[[i]], MS_CPWPROP_ADS_O2_INTIME_SAMPLE[[j]])
      chi_sq_obj <- chisq.test(tb)
      chi_sq_matrix[i, j] <-  chi_sq_obj$p.value
      print(paste("row[",i,"] col[",j,"]", sep = ""))
    }
  }
  #results - high correlation amongst all variables
}# 06. Dimensionality reduction - Chi square
{
  #Principal component analysis
  #https://www.analyticsvidhya.com/blog/2016/03/practical-guide-principal-component-analysis-python/
  #Store the dependent variable - 
  FLAG_RETENTION <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_INTIME_SAMPLE$FLAG_RETENTION)
  REDUCE_DEP = c("FLAG_RETENTION")
  #Filter out the dependent variable
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_DEP, with = FALSE]
  
  #One hot encoding on all categorical variables
  str(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP)
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
                       data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ohe <- as.data.frame(predict(DUMMIES, newdata = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP))
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP     <- data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ENC <- 
    cbind(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP[,-c(which(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP) %in% FEATURE_OHE))]
          , MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ohe)
  #encoding ends here
  
  #Divide the data into train and test
  TRAIN_SIZE <- 0.7
  PCA.TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ENC[1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ENC)),]
  PCA.TEST  <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ENC[-(1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_PRINCOMP_ENC))),]
  
  #Principal component analysis
  PR_COMP <- prcomp(PCA.TRAIN, scale. = T)
  names(PR_COMP)
  PR_COMP$rotation[1:5,1:5]#First 5 principal components
  
  #Compute the standard deviation
  ST_DEV <- PR_COMP$sdev
  PR_VAR <- ST_DEV^2
  PROPORTION_VAR <- PR_VAR/sum(PR_VAR)
  plot(PROPORTION_VAR,
       xlab = "PRINCIPAL COMPONENT",
       ylab = "PROPORTION OF VARIANCE EXPLAINED",
       type = "b")
  plot(cumsum(PROPORTION_VAR),
       xlab = "PRINCIPAL COMPONENT",
       ylab = "PROPORTION OF VARIANCE EXPLAINED",
       type = "b")
  View(data.frame(PROPORTION_VAR))
  
  #22nd Jun 2017
  
  #MCA
  rm(MS_CPWPROP_ADS_O2, MS_CPWPROP_ADS_O2_INTIME, MS_CPWPROP_ADS_O2_INTIME_SAMPLE)
  #Convert categorical fields to factors
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA <- sapply(MS_CPWPROP_ADS_O2_INTIME_SAMPLE, function(x) as.factor(x))
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA <- as.data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA)
  str(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA)
  #Store the levels of each factor
  LEVELS_MCA <- sapply(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA, function(x) nlevels(x))
  
  #Apply Multiple Correspondence Analysis
  MCA_1 <- MCA(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_MCA, graph = FALSE)
}# 07. Dimensionality reduction - PCA
{
  #Tree based significance testing
  #Store the dependent variable - 
  FLAG_RETENTION <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_INTIME_SAMPLE$FLAG_RETENTION)
  REDUCE_DEP = c("FLAG_RETENTION")
  #Filter out the dependent variable
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_DEP, with = FALSE]
  #One hot encoding on all categorical variables
  str(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB)
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
  #encoding ends here
  
  #Divide the data into train and test
  TRAIN_SIZE <- 0.7
  XGB.TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)),]
  XGB.TEST  <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[-(1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC))),]
  DEP.TRAIN <- data.frame(FLAG_RETENTION = FLAG_RETENTION[1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)),])
  DEP.TEST  <- data.frame(FLAG_RETENTION = FLAG_RETENTION[-(1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC))),])
  
  View(head(MS_CPWPROP_ADS_O2_INTIME_SAMPLE, 100))
  View(head(DEP.TRAIN, 100))
  
  #Convert fields into numeric
  XGB.TRAIN[] <- lapply(XGB.TRAIN, as.numeric)
  #XGboost - 1st iteration
  #XGBoost algorithm :
  set.seed(1007)
  XGB_1 <- xgboost(data = data.matrix(XGB.TRAIN), 
                   label = DEP.TRAIN$FLAG_RETENTION, 
                   eta = 0.3,
                   max_depth = 10,
                   nround=100, 
                   seed = 1007,
                   objective = "binary:logistic", #### binary:logistic for classification
                   # booster = "gblinear",
                   nthread = 3
                   # ,verbose = F
  )
  
  #get feature real names
  NAMES <- dimnames(data.matrix(XGB.TRAIN))[[2]]
  #compute feature importance matrix
  importance_matrix <- xgb.importance(NAMES, model = XGB_1)
  xgb.plot.importance(importance_matrix[1:20,])
  
  pred <- predict(XGB_1, data.matrix(XGB.TRAIN))
  prediction <- as.data.frame(as.numeric(pred > 0.5))
  err <- mean(as.numeric(pred > 0.5) != DEP.TRAIN$FLAG_RETENTION)
  print(paste("test-error=", err))#71%
  confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TRAIN$FLAG_RETENTION)
  
  #In time validation
  pred <- predict(XGB_1, data.matrix(XGB.TEST))
  prediction <- as.data.frame(as.numeric(pred > 0.5))
  err <- mean(as.numeric(pred > 0.5) != DEP.TEST$FLAG_RETENTION)
  print(paste("test-error=", err))#63%
  confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TEST$FLAG_RETENTION)
  
  #Re run model on significant factos - ITERATION 1 - SIGNIFICANT VARS. ONLY - TEST DATASET - INTIME VALIDATION
  importance_matrix$Gain_cumsum <- cumsum(importance_matrix$Gain)
  KEEP_INSIG <- importance_matrix$Feature[importance_matrix$Gain_cumsum <= 0.9]
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- data.table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)
  MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[, KEEP_INSIG, with = FALSE]
  #Divide the data into train and test
  TRAIN_SIZE <- 0.7
  XGB.TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)),]
  XGB.TEST  <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[-(1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC))),]
  DEP.TRAIN <- data.frame(FLAG_RETENTION = FLAG_RETENTION[1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)),])
  DEP.TEST  <- data.frame(FLAG_RETENTION = FLAG_RETENTION[-(1:as.integer(TRAIN_SIZE*nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC))),])
  
  View(head(MS_CPWPROP_ADS_O2_INTIME_SAMPLE, 100))
  View(head(DEP.TRAIN, 100))
  
  #Convert fields into numeric
  XGB.TRAIN[] <- lapply(XGB.TRAIN, as.numeric)
  #XGboost - 1st iteration
  #XGBoost algorithm :
  set.seed(1007)
  XGB_2 <- xgboost(data = data.matrix(XGB.TRAIN), 
                   label = DEP.TRAIN$FLAG_RETENTION, 
                   eta = 0.3,
                   max_depth = 10,
                   nround=100, 
                   seed = 1007,
                   objective = "binary:logistic", #### binary:logistic for classification
                   # booster = "gblinear",
                   nthread = 3
                   # ,verbose = F
  )
  
  #get feature real names
  NAMES <- dimnames(data.matrix(XGB.TRAIN))[[2]]
  #compute feature importance matrix
  importance_matrix <- xgb.importance(NAMES, model = XGB_2)
  xgb.plot.importance(importance_matrix[1:20,])
  
  pred <- predict(XGB_2, data.matrix(XGB.TRAIN))
  prediction <- as.data.frame(as.numeric(pred > 0.5))
  err <- mean(as.numeric(pred > 0.5) != DEP.TRAIN$FLAG_RETENTION)
  print(paste("test-error=", err))#71%
  confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TRAIN$FLAG_RETENTION)
  
  #In time validation
  pred <- predict(XGB_2, data.matrix(XGB.TEST))
  prediction <- as.data.frame(as.numeric(pred > 0.5))
  err <- mean(as.numeric(pred > 0.5) != DEP.TEST$FLAG_RETENTION)
  print(paste("test-error=", err))#63%
  confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TEST$FLAG_RETENTION)
  
  #Sensitivity vs specificity
  library(ROCR)
  pred <- data.frame(pred)
  colnames(pred)
  pred <- prediction(pred$pred, DEP.TRAIN$FLAG_RETENTION)
  ss <- performance(pred, "sens", "spec")
  plot(ss)
  ss@alpha.values[[1]][which.max(ss@x.values[[1]]+ss@y.values[[1]])]
  
}# 08. Modelling technique - XBGoost
{
  #Lift /gain chart
  pred <- predict(XGB_2, data.matrix(XGB.TEST))
  PREDICTION <- data.frame(PROPENSITY = pred)
  LIFT.TEST <- data.frame(cbind(XGB.TEST, PREDICTION$PROPENSITY, DEP.TEST$FLAG_RETENTION))
  colnames(LIFT.TEST)
  colnames(LIFT.TEST)[81] <- "PROPENSITY"
  colnames(LIFT.TEST)[82] <- "FLAG_RETENTION"
  LIFT.TEST.ORD <- LIFT.TEST[with(LIFT.TEST, order(-PROPENSITY)),]
  LIFT.TEST.ORD$ROW.NUM <- NULL
  LIFT.TEST.ORD$ROW.NUM <- row_number(-LIFT.TEST.ORD$PROPENSITY)
  LIFT.TEST.ORD$DECILE <- with(LIFT.TEST.ORD, factor(
    findInterval( ROW.NUM, c(-Inf,
                             quantile(ROW.NUM, probs=c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9)), Inf)), 
    labels=c("1","2","3","4","5","6","7","8","9","10") 
  ))
  View(head(LIFT.TEST.ORD))
  
  LIFT.TEST.ORD <- data.table(LIFT.TEST.ORD)
  GAIN_TABLE    <- LIFT.TEST.ORD[, list(N.CASES   = length(FLAG_RETENTION),
                                        N.RESPONSES = sum(FLAG_RETENTION)),
                                 by = 'DECILE']
}# 09. Gain chart - XGBoost
{
  # 28th Jun 2017
  # Ensemble significance testing and dimensionality reduction
  
  {#Random forest
    colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE)
    MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE
    {
      # MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) == 'P_AGE_FINE' |
      #                                      (sapply(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF, class) == 'character' &
      #                                         !(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) %in% c('SCV_INDIVIDUAL_KEY', 
      #                                                                                               'TRANSACTION_NUMBER', 
      #                                                                                               'ORDER_LINE_NUMBER', 
      #                                                                                               'ADDRESSID')))] <- 
      #   data.frame(
      #     sapply(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) == 'P_AGE_FINE' |
      #                                                 (sapply(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF, class) == 'character' &
      #                                                    !(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) %in% c('SCV_INDIVIDUAL_KEY', 
      #                                                                                                          'TRANSACTION_NUMBER', 
      #                                                                                                          'ORDER_LINE_NUMBER', 
      #                                                                                                          'ADDRESSID')))],
      #            function(x) as.factor(x))
      #   )
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$OUTLET_TYPE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SALES_DIVISION_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CHANNEL_TYPE)
      #MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SEASONAL_PURCHASE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AGE_FINE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$GENDER)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_MARITAL_STATUS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUST_EMAIL_PRESENT)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AFFLUENCE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_FINANCIAL_STRESS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_TENURE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION)
    }#convert categorical to factors
    RAGER_1 <- ranger(FLAG_RETENTION~., data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF, importance = 'impurity', num.trees = 500)
    print(RAGER_1)
    View(data.frame(importance(RAGER_1)))
    rm(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF)
  }#Random forest
  {#Logistic regression
    MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE
    {
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$OUTLET_TYPE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SALES_DIVISION_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CHANNEL_TYPE)
      #MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SEASONAL_PURCHASE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AGE_FINE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$GENDER)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_MARITAL_STATUS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AFFLUENCE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_FINANCIAL_STRESS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_TENURE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION)
    }#Convert to factor
    LOG_1 <- glm(formula = FLAG_RETENTION ~ ., family = "binomial", data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG)
    temp <- summary(LOG_1)
    View(data.frame(temp$coefficients))
    REDUCE_DEP <- 'FLAG_RETENTION'
    PREDICTION.RESULTS <- predict(LOG_1, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG[, !REDUCE_DEP, with = FALSE])
    PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
    table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION)
  }#Logistic regression
  {#XGboost
    #Store the dependent variable - 
    FLAG_RETENTION <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_INTIME_SAMPLE$FLAG_RETENTION)
    REDUCE_DEP = c("FLAG_RETENTION")
    #Filter out the dependent variable
    MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[, !REDUCE_DEP, with = FALSE]
    #One hot encoding on all categorical variables
    str(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB)
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
    #encoding ends here
    #Divide the data into train and test
    XGB.TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC
    DEP.TRAIN <- data.frame(FLAG_RETENTION = FLAG_RETENTION)
    #Convert fields into numeric
    XGB.TRAIN[] <- lapply(XGB.TRAIN, as.numeric)
    #XGboost - 1st iteration
    #XGBoost algorithm :
    set.seed(1007)
    XGB_1 <- xgboost(data = data.matrix(XGB.TRAIN), 
                     label = DEP.TRAIN$FLAG_RETENTION, 
                     eta = 0.3,
                     max_depth = 10,
                     nround=100, 
                     seed = 1007,
                     objective = "binary:logistic", #### binary:logistic for classification
                     # booster = "gblinear",
                     nthread = 3
                     # ,verbose = F
    )
    #get feature real names
    NAMES <- dimnames(data.matrix(XGB.TRAIN))[[2]]
    #compute feature importance matrix
    importance_matrix <- xgb.importance(NAMES, model = XGB_1)
    xgb.plot.importance(importance_matrix)
    View(data.frame(importance_matrix))
  }#XGBoost
  
}# 10. Variable significance - Multiple techniques
{
  #Model only on the significant varables
  #K - fold cross validation
  #Out of sample validation
  #Select the best modelling technique from XGB, RF, Logistic
  #Results - 
  #          1. XGBoost - 
  #          2. Random forest - 
  #          3. Logistic regression - 
  
  {
    {
      #Store the dependent variable - 
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
      #encoding ends here
      #head(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)
    }#Encoding and seperating the dependent variable
    
    {
      KEEP_SIG <- c('CUST_EMAIL_PRESENT',
                    
                    'OUTLET_TYPEWarehouse - Other',
                    'SALES_DIVISION_DESCRSouth Division',
                    'H_TENURE_V22',
                    'H_RESIDENCE_TYPE_V24',
                    'P_FINANCIAL_STRESS4',
                    
                    'DAY_DIFF_2ND_LINE_PURCH',
                    'PREV_PP_RET',
                    'PREV_2NDLINE',
                    'PREV_PP_PURCH_FLAG',
                    'FLAG_2NDLINE',
                    'SEASONAL_PURCHASE',
                    'OUTLET_TYPEWarehouse - Online',
                    'CHANNEL_TYPECPW-OL',
                    'SALES_DIVISION_DESCRLondon Division',
                    'PREV_PP_RET_COUNT',
                    'OTHER_CONNECTION_FLAG',
                    'H_RESIDENCE_TYPE_V20',
                    'PAST_UPGRADE_FLAG',
                    'H_TENURE_V20',
                    'P_AFFLUENCE_V200',
                    'SALES_DIVISION_DESCRNon-retail & Support',
                    'P_AGE_FINE3',
                    'P_AGE_FINE4',
                    'P_AGE_FINE5',
                    'H_RESIDENCE_TYPE_V21',
                    'SIMO_PAST_MIGRATION_FLAG',
                    'PART_MANUFACTURER_DESCRSamsung',
                    'P_FINANCIAL_STRESS2',
                    'H_TENURE_V21',
                    'P_AFFLUENCE_V201',
                    'P_AGE_FINE6',
                    'GENDERF',
                    'H_RESIDENCE_TYPE_V23',
                    'PART_MANUFACTURER_DESCRAPPLE',
                    'P_AGE_FINE0',
                    'PART_MANUFACTURER_DESCRNokia',
                    'PART_MANUFACTURER_DESCRBlackberry',
                    'P_AGE_FINE2',
                    'ONE_NETOWORK_STUCK_FLAG',
                    'ANY_PREVIOUS_PURCHASE_FLAG',
                    'P_AGE_FINE7',
                    'P_FINANCIAL_STRESS3',
                    'NETWORK_SPIN_FLAG',
                    'H_NUMBER_OF_BEDROOMS2',
                    'P_AFFLUENCE_V216',
                    'P_AFFLUENCE_V214',
                    'PREPAY_INLIFE_PURCHASE_FLAG',
                    'P_AFFLUENCE_V215',
                    'SIMO_INLIFE_PURCHASE_FLAG',
                    'SALES_DIVISION_DESCREast Division',
                    'P_AFFLUENCE_V209',
                    'P_AFFLUENCE_V202',
                    'P_AFFLUENCE_V213',
                    'P_AFFLUENCE_V203',
                    'H_NUMBER_OF_ADULTS',
                    'P_AFFLUENCE_V211',
                    'CONNECTION_QUANTITY',
                    'P_AGE_FINE8',
                    'H_RESIDENCE_TYPE_V22',
                    'OUTLET_TYPERetail Park',
                    'H_FAMILY_LIFESTAGE_201110',
                    'OUTLET_TYPEArterial Route',
                    'H_FAMILY_LIFESTAGE_201109',
                    'H_FAMILY_LIFESTAGE_201106',
                    'H_MOSAIC_UK_6_GROUPA',
                    'H_FAMILY_LIFESTAGE_201102',
                    'H_FAMILY_LIFESTAGE_201111',
                    'CHANNEL_TYPEOLS',
                    'P_MARITAL_STATUS0',
                    'OUTLET_TYPEHigh Street',
                    'P_PERSONAL_INCOME_BAND_V23',
                    'H_NUMBER_OF_BEDROOMS3',
                    'CUSTOMER_NO_MARKETING_FLGF',
                    'P_FINANCIAL_STRESS0',
                    'OTHER_CONNECTION_HIST_FLAG'
      )
    }#List of significant factors
    
    {#Filter in significant variables
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- data.table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC[,
                                                                                         KEEP_SIG,
                                                                                         with = FALSE]
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC <- data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC)
      #Divide the data into train and test
      XGB.TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_XGB_ENC
      DEP.TRAIN <- data.frame(FLAG_RETENTION = FLAG_RETENTION)
      XGB.TRAIN[] <- lapply(XGB.TRAIN, as.numeric)
    }#Filter in significant variables and create train dataset
    
    {
      {
        k = 5
        #Divide the data into train and test
        XGB.TRAIN$ID <- sample(1:k, nrow(XGB.TRAIN), replace = T)
        DEP.TRAIN$ID <- XGB.TRAIN$ID
        error        <- numeric()
        for (i in 1:k){
          TRAIN.F <- XGB.TRAIN[XGB.TRAIN$ID != i,][,!(colnames(XGB.TRAIN) == "ID")]
          TEST.F  <- XGB.TRAIN[XGB.TRAIN$ID == i,][,!(colnames(XGB.TRAIN) == "ID")]
          TRAIN.L <- data.frame(FLAG_RETENTION = DEP.TRAIN[DEP.TRAIN$ID != i,][,!(colnames(DEP.TRAIN) == "ID")])
          TEST.L  <- data.frame(FLAG_RETENTION = DEP.TRAIN[DEP.TRAIN$ID == i,][,!(colnames(DEP.TRAIN) == "ID")])
          #XGBoost algorithm :
          set.seed(1007)
          XGB_1 <- xgboost(data = data.matrix(TRAIN.F), 
                           label = TRAIN.L$FLAG_RETENTION, 
                           eta = 0.1,
                           max_depth = 5,
                           nround=100, 
                           seed = 1007,
                           objective = "binary:logistic", #### binary:logistic for classification
                           # booster = "gblinear",
                           nthread = 3,
                           verbose = 0
                           # ,verbose = F
          )
          pred       <- predict(XGB_1, data.matrix(TEST.F))
          prediction <- as.data.frame(as.numeric(pred > 0.5))
          error[i]        <- mean(as.numeric(pred > 0.5) != TEST.L$FLAG_RETENTION)
          print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
        }
        bias     <- mean(error)
        variance <- sd(error)
        #print(error)
        print(paste("Bias = ", bias, " & Variance = ", variance))
      }#Validation loop
      
      {
        # [1] "Progress = 20%"
        # [1] "Progress = 40%"
        # [1] "Progress = 60%"
        # [1] "Progress = 80%"
        # [1] "Progress = 100%"
        # [1] 0.3575937 0.3573548 0.3569354 0.3581356 0.3588444
        # [1] "Bias =  0.357772792457247  & Variance =  0.00073959707642969"
      }#Results
      
    }#k-fold validation
    
    {#XGBoost algorithm :
      set.seed(1007)
      XGB_1 <- xgboost(data = data.matrix(XGB.TRAIN), 
                       label = DEP.TRAIN$FLAG_RETENTION, 
                       eta = 0.1,
                       max_depth = 5,
                       nround=100, 
                       seed = 1007,
                       objective = "binary:logistic", #### binary:logistic for classification
                       # booster = "gblinear",
                       nthread = 3,
                       verbose = 0
                       # ,verbose = F
      )
      #get feature real names
      NAMES <- dimnames(data.matrix(XGB.TRAIN))[[2]]
      #compute feature importance matrix
      importance_matrix <- xgb.importance(NAMES, model = XGB_1)
      #xgb.plot.importance(importance_matrix[1:20,])
      pred <- predict(XGB_1, data.matrix(XGB.TRAIN))
      prediction <- as.data.frame(as.numeric(pred > 0.5))
      err <- mean(as.numeric(pred > 0.5) != DEP.TRAIN$FLAG_RETENTION)
      print(paste("test-error=", err))#35.3%
      confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TRAIN$FLAG_RETENTION)
    }#XGBoost model trained on complete sample
    
    {
      
      {
        #Time period for out of time validation
        #Filter for O2 customers
        MS_CPWPROP_ADS_O2 <- MS_CPWPROP_ADS[MS_CPWPROP_ADS$NETWORK_PROVIDER_NAME == 'O2',]
        #Filter in data for out of time validation
        MS_CPWPROP_ADS_O2_OUTIME <- MS_CPWPROP_ADS_O2[MS_CPWPROP_ADS_O2$INVOICE_DATE_FORMAT > '2014-07-31',]
        #Work on sample, park data for out of time validation
        sample_size = 300000
        set.seed(1008)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE <- MS_CPWPROP_ADS_O2_OUTIME[sample(1:nrow(MS_CPWPROP_ADS_O2_OUTIME), size = sample_size, replace = FALSE, prob = NULL),]
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE <- data.table(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE)
      }#Filter out of time validation set
      
      {
        #2.a - Reduce the number of factors using the results from Bivariates
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
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE[, !REDUCE_BIVAR, with = FALSE]
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE$NETWORK_PROVIDER_NAME <- NULL
        #filter out IDs
        REDUCE_IDs        <- c('SCV_INDIVIDUAL_KEY',
                               'TRANSACTION_NUMBER',
                               'ORDER_LINE_NUMBER',
                               'INVOICE_DATE_FORMAT',
                               'ADDRESSID')
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE[, !REDUCE_IDs, with = FALSE]
        #2.b Univariates, outlier deletion, Multivariate outlier deletion, NA removal
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE[complete.cases(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE),]
      }#Remove variables based on bivariate results, filter out NAs
      
      {
        
        #Store the dependent variable - 
        FLAG_RETENTION <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_OUTIME_SAMPLE$FLAG_RETENTION)
        REDUCE_DEP = c("FLAG_RETENTION")
        #Filter out the dependent variable
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE[, !REDUCE_DEP, with = FALSE]
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB$P_AGE_FINE <- as.character(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB$P_AGE_FINE)
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
                             data = MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_OHE <- as.data.frame(predict(DUMMIES, newdata = MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB))
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB     <- data.frame(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- 
          cbind(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB[,-c(which(colnames(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB) %in% FEATURE_OHE))]
                , MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_OHE)
        #encoding ends here
        
      }#Encoding
      
      {
        KEEP_SIG <- c('CUST_EMAIL_PRESENT',
                      
                      'OUTLET_TYPEWarehouse - Other',
                      'SALES_DIVISION_DESCRSouth Division',
                      'H_TENURE_V22',
                      'H_RESIDENCE_TYPE_V24',
                      'P_FINANCIAL_STRESS4',
                      
                      'DAY_DIFF_2ND_LINE_PURCH',
                      'PREV_PP_RET',
                      'PREV_2NDLINE',
                      'PREV_PP_PURCH_FLAG',
                      'FLAG_2NDLINE',
                      'SEASONAL_PURCHASE',
                      'OUTLET_TYPEWarehouse - Online',
                      'CHANNEL_TYPECPW-OL',
                      'SALES_DIVISION_DESCRLondon Division',
                      'PREV_PP_RET_COUNT',
                      'OTHER_CONNECTION_FLAG',
                      'H_RESIDENCE_TYPE_V20',
                      'PAST_UPGRADE_FLAG',
                      'H_TENURE_V20',
                      'P_AFFLUENCE_V200',
                      'SALES_DIVISION_DESCRNon-retail & Support',
                      'P_AGE_FINE3',
                      'P_AGE_FINE4',
                      'P_AGE_FINE5',
                      'H_RESIDENCE_TYPE_V21',
                      'SIMO_PAST_MIGRATION_FLAG',
                      'PART_MANUFACTURER_DESCRSamsung',
                      'P_FINANCIAL_STRESS2',
                      'H_TENURE_V21',
                      'P_AFFLUENCE_V201',
                      'P_AGE_FINE6',
                      'GENDERF',
                      'H_RESIDENCE_TYPE_V23',
                      'PART_MANUFACTURER_DESCRAPPLE',
                      'P_AGE_FINE0',
                      'PART_MANUFACTURER_DESCRNokia',
                      'PART_MANUFACTURER_DESCRBlackberry',
                      'P_AGE_FINE2',
                      'ONE_NETOWORK_STUCK_FLAG',
                      'ANY_PREVIOUS_PURCHASE_FLAG',
                      'P_AGE_FINE7',
                      'P_FINANCIAL_STRESS3',
                      'NETWORK_SPIN_FLAG',
                      'H_NUMBER_OF_BEDROOMS2',
                      'P_AFFLUENCE_V216',
                      'P_AFFLUENCE_V214',
                      'PREPAY_INLIFE_PURCHASE_FLAG',
                      'P_AFFLUENCE_V215',
                      'SIMO_INLIFE_PURCHASE_FLAG',
                      'SALES_DIVISION_DESCREast Division',
                      'P_AFFLUENCE_V209',
                      'P_AFFLUENCE_V202',
                      'P_AFFLUENCE_V213',
                      'P_AFFLUENCE_V203',
                      'H_NUMBER_OF_ADULTS',
                      'P_AFFLUENCE_V211',
                      'CONNECTION_QUANTITY',
                      'P_AGE_FINE8',
                      'H_RESIDENCE_TYPE_V22',
                      'OUTLET_TYPERetail Park',
                      'H_FAMILY_LIFESTAGE_201110',
                      'OUTLET_TYPEArterial Route',
                      'H_FAMILY_LIFESTAGE_201109',
                      'H_FAMILY_LIFESTAGE_201106',
                      'H_MOSAIC_UK_6_GROUPA',
                      'H_FAMILY_LIFESTAGE_201102',
                      'H_FAMILY_LIFESTAGE_201111',
                      'CHANNEL_TYPEOLS',
                      'P_MARITAL_STATUS0',
                      'OUTLET_TYPEHigh Street',
                      'P_PERSONAL_INCOME_BAND_V23',
                      'H_NUMBER_OF_BEDROOMS3',
                      'CUSTOMER_NO_MARKETING_FLGF',
                      'P_FINANCIAL_STRESS0',
                      'OTHER_CONNECTION_HIST_FLAG'
        )
      }#List of significant factors
      
      {#Filter in significant variables
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- data.table(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC[,
                                                                                           KEEP_SIG,
                                                                                           with = FALSE]
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- data.frame(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC)
        #Divide the data into train and test
        XGB.TEST <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC
        DEP.TEST <- data.frame(FLAG_RETENTION = FLAG_RETENTION)
        XGB.TEST[] <- lapply(XGB.TEST, as.numeric)
      }#Filter in significant variables and create validation dataset
      
      #Train model on complete data
      
      {
        #get feature real names
        NAMES <- dimnames(data.matrix(XGB.TEST))[[2]]
        #compute feature importance matrix
        importance_matrix <- xgb.importance(NAMES, model = XGB_1)
        #xgb.plot.importance(importance_matrix[1:20,])
        pred <- predict(XGB_1, data.matrix(XGB.TEST))
        prediction <- as.data.frame(as.numeric(pred > 0.5))
        err <- mean(as.numeric(pred > 0.5) != DEP.TEST$FLAG_RETENTION)
        print(paste("test-error=", err))#38.0%
        confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TEST$FLAG_RETENTION)
        
      }#Test model on out of time validation set
      
      {
        # [1] "test-error= 0.380301138728105"
      }#Results
      
    }#Out of time validation
    
  }#XGBoost
  
  {
    {
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$OUTLET_TYPE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SALES_DIVISION_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CHANNEL_TYPE)
      #MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$SEASONAL_PURCHASE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AGE_FINE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$GENDER)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_MARITAL_STATUS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_AFFLUENCE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$P_FINANCIAL_STRESS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$H_TENURE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG <- data.table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG)
    }#Data massaging
    
    {
      
      {
        k = 5
        set.seed(1007)
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$ID <- sample(1:k, nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG), replace = T)
        error <- numeric()
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG    <- data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG)
        for (i in 1:k){
          TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG[MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$ID != i,][, colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG) != 'ID']
          TEST  <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG[MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$ID == i,][, colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG) != 'ID']
          LOG_1 <- glm(formula = FLAG_RETENTION ~ ., family = "binomial", data = TRAIN)
          REDUCE_DEP <- 'FLAG_RETENTION'
          PREDICTION.RESULTS <- predict(LOG_1, TEST[, colnames(TEST) != REDUCE_DEP])
          PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
          table_ <- table(PREDICTION.RESULTS, TEST$FLAG_RETENTION)
          #print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
          error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
          print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
        }
        bias <- mean(error)
        variance <- sd(error)
        print(paste("Bias = ", bias, " & Variance = ", variance))
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$ID <- NULL
      }#Validation loop
      
      {
        # [1] "Progress = 20% | Accuracy = 60.73%"
        # [1] "Progress = 40% | Accuracy = 60.91%"
        # [1] "Progress = 60% | Accuracy = 60.95%"
        # [1] "Progress = 80% | Accuracy = 61.07%"
        # [1] "Progress = 100% | Accuracy = 60.96%"
        # [1] "Bias =  0.390763514589897  & Variance =  0.00123603360933688"
      }#Results
      
      {
        PREDICTION.RESULTS <- predict(LOG_1, TRAIN[, !REDUCE_DEP, with = FALSE])
        PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
        table_ <- table(PREDICTION.RESULTS, TEST$FLAG_RETENTION)
        print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        # [1] 0.6095534
      }#Train accuracy
      
    }#k - fold cross validation
    
    {
      
      LOG_1 <- glm(formula = FLAG_RETENTION ~ ., family = "binomial", data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG)
      #STATSL<- summary(LOG_1)
      REDUCE_DEP <- 'FLAG_RETENTION'
      PREDICTION.RESULTS <- predict(LOG_1, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG[, !REDUCE_DEP, with = FALSE])
      PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
      table_ <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION)
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
      
      {
        # [1] 0.6093555
      }#Results
      
    }#Logistic regression model trained on complete dataset
    
    {
      #From XGB - Filtering and variable reduction
      MS_CPWPROP_ADS_O2_OUTIME_SAMPLE
      
      #Train model on complete data
      
      {
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$PART_MANUFACTURER_DESCR)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$OUTLET_TYPE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$SALES_DIVISION_DESCR)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CHANNEL_TYPE)
        #MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$SEASONAL_PURCHASE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_AGE_FINE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_MOSAIC_UK_6_GROUP)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$GENDER)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_PERSONAL_INCOME_BAND_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_MARITAL_STATUS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CUSTOMER_NO_MARKETING_FLG)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$CUST_EMAIL_PRESENT)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_AFFLUENCE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$P_FINANCIAL_STRESS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_FAMILY_LIFESTAGE_2011)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_NUMBER_OF_BEDROOMS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_RESIDENCE_TYPE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$H_TENURE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$FLAG_RETENTION)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG <- data.table(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG)
      }#Data massaging
      
      {
        
        REDUCE_DEP <- 'FLAG_RETENTION'
        PREDICTION.RESULTS <- predict(LOG_1, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG[, !REDUCE_DEP, with = FALSE])
        PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
        table_ <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$FLAG_RETENTION)
        print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        
      }#Test model on validation set
      
      {
        
      }#Results
      
    }#Out of time validation
    
  }#Logistic regression
  
  {
    {
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$OUTLET_TYPE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SALES_DIVISION_DESCR)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CHANNEL_TYPE)
      #MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$SEASONAL_PURCHASE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AGE_FINE)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$GENDER)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_MARITAL_STATUS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$CUST_EMAIL_PRESENT)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_AFFLUENCE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$P_FINANCIAL_STRESS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$H_TENURE_V2)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION)
      
    }#Data massaging
    
    {
      RAGER_1 <- ranger(FLAG_RETENTION~., data = MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF, importance = 'impurity', num.trees = 100)
      print(RAGER_1)
      MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF <- data.table(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF)
      REDUCE_DEP = 'FLAG_RETENTION'
      PREDICTION.RESULTS <- predict(RAGER_1, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[, !REDUCE_DEP, with = FALSE])
      PREDICTION.RESULTS1<- PREDICTION.RESULTS$predictions
      table_ <- table(PREDICTION.RESULTS1, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION)
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
      {
        # Type:                             Classification 
        # Number of trees:                  100 
        # Sample size:                      528844 
        # Number of independent variables:  38 
        # Mtry:                             6 
        # Target node size:                 1 
        # Variable importance mode:         impurity 
        # OOB prediction error:             36.33 % 
      }#Results
      
    }#Fit model on complete dataset
    
    {
      
      {
        k = 5
        set.seed(1007)
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$ID <- sample(1:k, nrow(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF), replace = T)
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF    <- data.frame(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF)
        error <- numeric()
        for (i in 1:k){
          TRAIN <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$ID != i,][,!(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) == "ID")]
          TEST  <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$ID == i,][,!(colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF) == "ID")]
          RAGER_1 <- ranger(FLAG_RETENTION~., data = TRAIN, importance = 'impurity', num.trees = 100)
          REDUCE_DEP <- 'FLAG_RETENTION'
          PREDICTION.RESULTS <- predict(RAGER_1, TEST[, colnames(TEST) != REDUCE_DEP])
          PREDICTION.RESULTS1<- PREDICTION.RESULTS$predictions
          table_ <- table(PREDICTION.RESULTS1, TEST$FLAG_RETENTION)
          #print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
          error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
          print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
        }
        bias <- mean(error)
        variance <- sd(error)
        print(paste("Bias = ", bias, " & Variance = ", variance))
        MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$ID <- NULL
      }#Validation loop
      
      {
        # [1] "Progress = 20% | Accuracy = 64.12%"
        # [1] "Progress = 40% | Accuracy = 63.97%"
        # [1] "Progress = 60% | Accuracy = 64.12%"
        # [1] "Progress = 80% | Accuracy = 63.94%"
        # [1] "Progress = 100% | Accuracy = 64.01%"
        # [1] "Bias =  0.359675137132799  & Variance =  0.000840317681076342"
      }#Result
      
    }#k-fold cross validation
    
    {
      #From XGB - Filter and variable removal module
      MS_CPWPROP_ADS_O2_OUTIME_SAMPLE
      
      #Train model on complete data
      
      {
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF                         <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$PART_MANUFACTURER_DESCR)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$OUTLET_TYPE             <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$OUTLET_TYPE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$SALES_DIVISION_DESCR    <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$SALES_DIVISION_DESCR)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CHANNEL_TYPE            <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CHANNEL_TYPE)
        #MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$SEASONAL_PURCHASE      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$SEASONAL_PURCHASE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_AGE_FINE              <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_AGE_FINE)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP     <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_MOSAIC_UK_6_GROUP)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$GENDER                  <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$GENDER)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2 <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_PERSONAL_INCOME_BAND_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_MARITAL_STATUS        <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_MARITAL_STATUS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CUSTOMER_NO_MARKETING_FLG)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CUST_EMAIL_PRESENT      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$CUST_EMAIL_PRESENT)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_AFFLUENCE_V2          <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_AFFLUENCE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_FINANCIAL_STRESS      <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$P_FINANCIAL_STRESS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011 <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_FAMILY_LIFESTAGE_2011)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS    <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_NUMBER_OF_BEDROOMS)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2     <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_RESIDENCE_TYPE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_TENURE_V2             <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$H_TENURE_V2)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$FLAG_RETENTION          <- as.factor(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$FLAG_RETENTION)
        MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF <- data.table(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF)
      }#Data massaging
      
      {
        REDUCE_DEP <- 'FLAG_RETENTION'
        PREDICTION.RESULTS <- predict(RAGER_1, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF[, !REDUCE_DEP, with = FALSE])
        PREDICTION.RESULTS <- PREDICTION.RESULTS$predictions
        table_ <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$FLAG_RETENTION)
        print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        
      }#Test model on validation set
      
      {
        # [1] 0.6401441
      }#Results
      
    }#Out of time validation
    
  }#Random forest
  
  {
    
  }#Naive bayes
  
}# 11. Model performance improvement and validation
{
  {
    #XGBoost trained on complete sample - XGB_stack
    #Random forest trained on complltes sample - RF_STACK
    #Logistic trained on complete stack - LOG_STACK
  }#List of models
  
  {
    #Sample dataset
    MS_CPWPROP_ADS_O2_INTIME_SAMPLE_L <- MS_CPWPROP_ADS_O2_INTIME_SAMPLE[,colnames(MS_CPWPROP_ADS_O2_INTIME_SAMPLE) != 'FLAG_RETENTION']
    FLAG_RETENTION                    <- data.frame(FLAG_RETENTION = MS_CPWPROP_ADS_O2_INTIME_SAMPLE$FLAG_RETENTION)
  }#Sample dataset
  
  {
    XGB_stack <- XGB_1
    PREDICT.XGB_STACK <- predict(XGB_stack, data.matrix(XGB.TRAIN))
    PREDICT.XGB_STACK <- as.data.frame(PROPENSITY <- as.numeric(PREDICT.XGB_STACK > 0.5))
    ERROR.XGB_STACK   <- mean(PREDICT.XGB_STACK$PROPENSITY != DEP.TRAIN$FLAG_RETENTION)
    print(paste("test-error=", ERROR.XGB_STACK))#35.54%
    confusionMatrix(PREDICT.XGB_STACK$PROPENSITY,FLAG_RETENTION$FLAG_RETENTION)
  }#XGB_STACK in sample stats
  {
    # $positive
    # [1] "0"
    # 
    # $table
    # Reference
    # Prediction      0      1
    # 0 218647 102240
    # 1  85747 122210
    # 
    # $overall
    # Accuracy          Kappa  AccuracyLower  AccuracyUpper   AccuracyNull AccuracyPValue  McnemarPValue 
    # 6.445322e-01   2.653496e-01   6.432404e-01   6.458224e-01   5.755837e-01   0.000000e+00  1.397418e-316 
    # 
    # $byClass
    # Sensitivity          Specificity       Pos Pred Value       Neg Pred Value            Precision               Recall 
    # 0.7183026            0.5444865            0.6813832            0.5876696            0.6813832            0.7183026 
    # F1           Prevalence       Detection Rate Detection Prevalence    Balanced Accuracy 
    # 0.6993560            0.5755837            0.4134433            0.6067706            0.6313946 
    # 
    # $mode
    # [1] "sens_spec"
    # 
    # $dots
    # list()
    # 
    # attr(,"class")
    # [1] "confusionMatrix"
  }#Output
  
  {
    RF_STACK <- RAGER_1
    REDUCE.DEP.RF_STACK<- 'FLAG_RETENTION'
    PREDICT.RF_STACK   <- predict(RF_STACK, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF[, !REDUCE.DEP.RF_STACK, with = FALSE])
    PREDICT.RF_STACK   <- PREDICT.RF_STACK$predictions
    table_             <- table(PREDICT.RF_STACK, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_RF$FLAG_RETENTION)
    print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    confusionMatrix(PREDICT.RF_STACK, FLAG_RETENTION$FLAG_RETENTION)
  }#RF_STACK in sample stats
  {
    # [1] "0"
    # 
    # $table
    # Reference
    # Prediction      0      1
    # 0 294080  16344
    # 1  10314 208106
    # 
    # $overall
    # Accuracy          Kappa  AccuracyLower  AccuracyUpper   AccuracyNull AccuracyPValue  McnemarPValue 
    # 9.495919e-01   8.964609e-01   9.489989e-01   9.501801e-01   5.755837e-01   0.000000e+00  1.772833e-298 
    # 
    # $byClass
    # Sensitivity          Specificity       Pos Pred Value       Neg Pred Value            Precision               Recall 
    # 0.9661163            0.9271820            0.9473494            0.9527790            0.9473494            0.9661163 
    # F1           Prevalence       Detection Rate Detection Prevalence    Balanced Accuracy 
    # 0.9566408            0.5755837            0.5560808            0.5869860            0.9466491 
    # 
    # $mode
    # [1] "sens_spec"
    # 
    # $dots
    # list()
    # 
    # attr(,"class")
    # [1] "confusionMatrix"
  }#Ouptut
  
  {
    LOG_STACK            <- LOG_1
    REDUCE.DEP.LOG_STACK <- 'FLAG_RETENTION'
    PREDICT.LOG_STACK    <- predict(LOG_STACK, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG[, !REDUCE.DEP.LOG_STACK, with = FALSE])
    PREDICT.LOG_STACK    <- ifelse(PREDICT.LOG_STACK > 0.5, 1, 0)
    table_               <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_INTIME_SAMPLE_LOG$FLAG_RETENTION)
    print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    confusionMatrix(PREDICT.LOG_STACK, FLAG_RETENTION$FLAG_RETENTION)
  }#LOG_STACK in sample stats
  {
    # $positive
    # [1] "0"
    # 
    # $table
    # Reference
    # Prediction      0      1
    # 0 292139 194335
    # 1  12255  30115
    # 
    # $overall
    # Accuracy          Kappa  AccuracyLower  AccuracyUpper   AccuracyNull AccuracyPValue  McnemarPValue 
    # 0.6093555      0.1051091      0.6080390      0.6106708      0.5755837      0.0000000      0.0000000 
    # 
    # $byClass
    # Sensitivity          Specificity       Pos Pred Value       Neg Pred Value            Precision               Recall 
    # 0.9597397            0.1341724            0.6005234            0.7107623            0.6005234            0.9597397 
    # F1           Prevalence       Detection Rate Detection Prevalence    Balanced Accuracy 
    # 0.7387807            0.5755837            0.5524105            0.9198819            0.5469561 
    # 
    # $mode
    # [1] "sens_spec"
    # 
    # $dots
    # list()
    # 
    # attr(,"class")
    # [1] "confusionMatrix"
  }#Output
  
  {
    COLLATED.PREDICTIONS       <- cbind(PREDICT.XGB_STACK, PREDICT.RF_STACK, PREDICT.LOG_STACK, FLAG_RETENTION)
    COLLATED.PREDICTIONS[]     <- lapply(COLLATED.PREDICTIONS, as.numeric)
    str(COLLATED.PREDICTIONS)
    COLLATED.PREDICTIONS$PREDICT.RF_STACK <- ifelse(COLLATED.PREDICTIONS$PREDICT.RF_STACK == 2, 1, 0)
    confusionMatrix(COLLATED.PREDICTIONS$`PROPENSITY <- as.numeric(PREDICT.XGB_STACK > 0.5)`, COLLATED.PREDICTIONS$PREDICT.RF_STACK)
    XGB_META                   <- xgboost(data = data.matrix(COLLATED.PREDICTIONS),
                                          label = as.numeric(FLAG_RETENTION$FLAG_RETENTION),
                                          eta = 0.1,
                                          max_depth = 5,
                                          nround=100, 
                                          seed = 1007,
                                          objective = "binary:logistic",
                                          nthread = 3,
                                          verbose = 0
                                          )
    PREDICT.XGB_META <- predict(XGB_META, data.matrix(COLLATED.PREDICTIONS))
    PREDICT.XGB_META <- as.data.frame(PROPENSITY <- as.numeric(PREDICT.XGB_META > 0.5))
    ERROR.XGB_META   <- mean(PREDICT.XGB_META$PROPENSITY != DEP.TRAIN$FLAG_RETENTION)
    print(paste("test-error=", ERROR.XGB_META))#35.54%
    confusionMatrix(PREDICT.XGB_META$PROPENSITY,FLAG_RETENTION$FLAG_RETENTION)
    
    {
      k = 10
      set.seed(1007)
      TRAIN.XGB_META    <- COLLATED.PREDICTIONS
      DEP.XGB_META      <- FLAG_RETENTION
      TRAIN.XGB_META$ID <- sample(1:k, nrow(TRAIN.XGB_META), replace = T)
      DEP.XGB_META$ID   <- TRAIN.XGB_META$ID
      error             <- numeric()
      for (i in 1:k) {
        TRAIN.F <- TRAIN.XGB_META[TRAIN.XGB_META$ID != i,][,!(colnames(TRAIN.XGB_META) == "ID")]
        TEST.F  <- TRAIN.XGB_META[TRAIN.XGB_META$ID == i,][,!(colnames(TRAIN.XGB_META) == "ID")]
        TRAIN.L <- data.frame(FLAG_RETENTION = DEP.XGB_META[DEP.XGB_META$ID != i,][,!(colnames(DEP.XGB_META) == "ID")])
        TEST.L  <- data.frame(FLAG_RETENTION = DEP.XGB_META[DEP.XGB_META$ID == i,][,!(colnames(DEP.XGB_META) == "ID")])
        #XGBoost algorithm :
        set.seed(1007)
        XGB_META_K <- xgboost(data = data.matrix(TRAIN.F), 
                          label = TRAIN.L$FLAG_RETENTION, 
                          eta = 0.1,
                          max_depth = 5,
                          nround=100, 
                          seed = 1007,
                          objective = "binary:logistic",
                          nthread = 3,
                          verbose = 0
        )
        PREDICT.XGB_META_K <- predict(XGB_META_K, data.matrix(TEST.F))
        PREDICT.XGB_META_K <- as.data.frame(as.numeric(PREDICT.XGB_META_K > 0.5))
        error[i]        <- mean(PREDICT.XGB_META_K$`as.numeric(PREDICT.XGB_META_K > 0.5)` != TEST.L$FLAG_RETENTION)
        print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
      }
      bias     <- mean(error)
      variance <- sd(error)
      #print(error)
      print(paste("Bias = ", bias, " & Variance = ", variance))
}#
      
      
    }#k - fold cross validation
  
  {
    
    {#Filter in significant variables
      MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- data.table(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC)
      MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC[,
                                                                                         KEEP_SIG,
                                                                                         with = FALSE]
      MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC <- data.frame(MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC)
      #Divide the data into train and test
      XGB.TEST <- MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_XGB_ENC
      DEP.TEST <- data.frame(FLAG_RETENTION = FLAG_RETENTION)
      XGB.TEST[] <- lapply(XGB.TEST, as.numeric)
    }#Filter in significant variables and create validation dataset
    #Train model on complete data - XGB_STACK
    {
      #get feature real names
      NAMES <- dimnames(data.matrix(XGB.TEST))[[2]]
      #compute feature importance matrix
      #importance_matrix <- xgb.importance(NAMES, model = XGB_1)
      #xgb.plot.importance(importance_matrix[1:20,])
      pred <- predict(XGB_stack, data.matrix(XGB.TEST))
      prediction <- as.data.frame(as.numeric(pred > 0.5))
      err <- mean(as.numeric(pred > 0.5) != DEP.TEST$FLAG_RETENTION)
      print(paste("test-error=", err))#38.0%
      confusionMatrix(prediction$`as.numeric(pred > 0.5)`,DEP.TEST$FLAG_RETENTION)
      
    }#Test model on out of time validation set
    
    {
      REDUCE_DEP <- 'FLAG_RETENTION'
      PREDICTION.RESULTS <- predict(LOG_STACK, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG[, !REDUCE_DEP, with = FALSE])
      PREDICTION.RESULTS <- ifelse(PREDICTION.RESULTS > 0.5, 1, 0)
      table_ <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_LOG$FLAG_RETENTION)
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    }#lOG
    
    {
      REDUCE_DEP <- 'FLAG_RETENTION'
      PREDICTION.RESULTS <- predict(RF_STACK, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF[, !REDUCE_DEP, with = FALSE])
      PREDICTION.RESULTS <- PREDICTION.RESULTS$predictions
      table_ <- table(PREDICTION.RESULTS, MS_CPWPROP_ADS_O2_OUTIME_SAMPLE_RF$FLAG_RETENTION)
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    }#Ranger
    
    {
      COLLATED.PREDICTIONS       <- cbind(PREDICT.XGB_STACK, PREDICT.RF_STACK, FLAG_RETENTION)
      COLLATED.PREDICTIONS[]     <- lapply(COLLATED.PREDICTIONS, as.numeric)
      str(COLLATED.PREDICTIONS)
      COLLATED.PREDICTIONS$PREDICT.RF_STACK <- ifelse(COLLATED.PREDICTIONS$PREDICT.RF_STACK == 2, 1, 0)
      confusionMatrix(COLLATED.PREDICTIONS$`PROPENSITY <- as.numeric(PREDICT.XGB_STACK > 0.5)`, COLLATED.PREDICTIONS$PREDICT.RF_STACK)
      XGB_META                   <- xgboost(data = data.matrix(COLLATED.PREDICTIONS),
                                            label = as.numeric(FLAG_RETENTION$FLAG_RETENTION),
                                            eta = 0.1,
                                            max_depth = 5,
                                            nround=100, 
                                            seed = 1007,
                                            objective = "binary:logistic",
                                            nthread = 3,
                                            verbose = 0
      )
      PREDICT.XGB_META <- predict(XGB_META, data.matrix(COLLATED.PREDICTIONS))
      PREDICT.XGB_META <- as.data.frame(PROPENSITY <- as.numeric(PREDICT.XGB_META > 0.5))
      ERROR.XGB_META   <- mean(PREDICT.XGB_META$PROPENSITY != DEP.TRAIN$FLAG_RETENTION)
      print(paste("test-error=", ERROR.XGB_META))#35.54%
      confusionMatrix(PREDICT.XGB_META$PROPENSITY,FLAG_RETENTION$FLAG_RETENTION)
      
      {
        k = 10
        set.seed(1007)
        TRAIN.XGB_META    <- COLLATED.PREDICTIONS
        DEP.XGB_META      <- FLAG_RETENTION
        TRAIN.XGB_META$ID <- sample(1:k, nrow(TRAIN.XGB_META), replace = T)
        DEP.XGB_META$ID   <- TRAIN.XGB_META$ID
        error             <- numeric()
        for (i in 1:k) {
          TRAIN.F <- TRAIN.XGB_META[TRAIN.XGB_META$ID != i,][,!(colnames(TRAIN.XGB_META) == "ID")]
          TEST.F  <- TRAIN.XGB_META[TRAIN.XGB_META$ID == i,][,!(colnames(TRAIN.XGB_META) == "ID")]
          TRAIN.L <- data.frame(FLAG_RETENTION = DEP.XGB_META[DEP.XGB_META$ID != i,][,!(colnames(DEP.XGB_META) == "ID")])
          TEST.L  <- data.frame(FLAG_RETENTION = DEP.XGB_META[DEP.XGB_META$ID == i,][,!(colnames(DEP.XGB_META) == "ID")])
          #XGBoost algorithm :
          set.seed(1007)
          XGB_META_K <- xgboost(data = data.matrix(TRAIN.F), 
                                label = TRAIN.L$FLAG_RETENTION, 
                                eta = 0.1,
                                max_depth = 5,
                                nround=100, 
                                seed = 1007,
                                objective = "binary:logistic",
                                nthread = 3,
                                verbose = 0
          )
          PREDICT.XGB_META_K <- predict(XGB_META_K, data.matrix(TEST.F))
          PREDICT.XGB_META_K <- as.data.frame(as.numeric(PREDICT.XGB_META_K > 0.5))
          error[i]        <- mean(PREDICT.XGB_META_K$`as.numeric(PREDICT.XGB_META_K > 0.5)` != TEST.L$FLAG_RETENTION)
          print(paste('Progress = ', round(i/k,2)*100,"%", ' | Accuracy = ', round(1-error[i],4)*100, "%", sep = ""))
        }
        bias     <- mean(error)
        variance <- sd(error)
        #print(error)
        print(paste("Bias = ", bias, " & Variance = ", variance))
      }#
      
      
    }#k - fold cross validation
    
    
    
    
  }#Out of time validation
  
  }#Stack output of each technique
