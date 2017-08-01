#Author : Rohan M. Nanaware
#Date C.: 07th Jul 2017
#Date M.: 07th Jul 2017
#Purpose: Accurate fraud detection | Study prediction in case of highly unbalance datasets

{
  library(data.table)
  library(Matrix)
  library(rpart)
  library(xgboost)
  library(readr)
  library(stringr)
  library(caret)
  library(car)
  library(data.table)
  library(randomForest)
  library(ROCR)
}#01. Load required packages
{
  wd <- "E:/Delivery/1 Active/Kaggle/Credit Card Fraud Detection"
  setwd(wd)
}#02. Set working directory
{
  CREDITCARD.TOTAL <- fread(input = "creditcard.csv", header = T, sep = ",", stringsAsFactors = F, quote = "\"")
  str(CREDITCARD.TOTAL)
  summary(CREDITCARD.TOTAL$Time)
  summary(CREDITCARD.TOTAL$Amount)#Outlier treatment required
  quantile(CREDITCARD.TOTAL$Amount, probs = c(0.05,0.1,0.25,0.5,0.75,0.9,0.95,0.96,0.97,0.98,0.99))
  
}#03. Load data
{
  #Outlier treatment
  CREDITCARD.TOTAL$Amount[CREDITCARD.TOTAL$Amount > quantile(CREDITCARD.TOTAL$Amount, probs = c(0.95))] <- as.numeric(quantile(CREDITCARD.TOTAL$Amount, probs = c(0.95)))
  #Remove time stamp
  CREDITCARD.TOTAL <- data.frame(CREDITCARD.TOTAL)
  CREDITCARD.TOTAL <- CREDITCARD.TOTAL[ ,!(colnames(CREDITCARD.TOTAL) == "Time")]
  str(CREDITCARD.TOTAL)
  CREDITCARD.TOTAL$Class <- as.numeric(CREDITCARD.TOTAL$Class)
}#04. Data massaging
{
  XGB_1 <- xgboost(data = data.matrix(CREDITCARD.TOTAL[,!(colnames(CREDITCARD.TOTAL) == "Class")]),
                   label = CREDITCARD.TOTAL$Class,
                   eta = 0.01,
                   max_depth = 5,
                   nrounds = 100,
                   seed = 1007,
                   objective = "binary:logistic",
                   nthread = 3
                   #verbose = F
                   )
  PREDICTION.TEST <- predict(XGB_1, data.matrix(CREDITCARD.TOTAL[,!(colnames(CREDITCARD.TOTAL) == "Class")]))
  pred <- prediction(PREDICTION.TEST, CREDITCARD.TOTAL$Class)
  PR <- performance(pred, "prec", "rec")
  plot(PR)
  PR@alpha.values[[1]][which.max(PR@x.values[[1]]+PR@y.values[[1]])]
  #[1] 0.5568833
  PREDICTION.TEST <- data.frame(Fraud = as.numeric(PREDICTION.TEST > 0.5))
  cf <- confusionMatrix(PREDICTION.TEST$Fraud, CREDITCARD.TOTAL$Class)
  #Precision and Recall
  cf$table
  {
    # Reference
    # Prediction      0      1
    #             0 284298     88
    #             1     17    404
  }
  #Precision = tp/(tp+fp)
  Precision <- cf$table[2,2]/(cf$table[2,1] + cf$table[2,2])
  #Recall    = tp/(tp+fn)
  Recall    <- cf$table[2,2]/(cf$table[1,2] + cf$table[2,2])
  print(paste0("Precision = ",round(Precision,4)*100, "% | Recall = ", round(Recall, 4)*100, "%"))
  names <- dimnames(CREDITCARD.TOTAL[,!(colnames(CREDITCARD.TOTAL) == "Class")])[[2]]
  importance_matrix <- xgb.importance(names, model = XGB_1)
  xgb.plot.importance(importance_matrix)
  {
    k = 10
    Precision <- numeric()
    Recall    <- numeric()
    set.seed(1007)
    CREDITCARD.TOTAL$ID   <- sample(1:k, nrow(CREDITCARD.TOTAL), replace = T)
    CREDITCARD.TOTAL$ID   <- CREDITCARD.TOTAL$ID
    error        <- numeric()
    for (i in 1:k) {
      TRAIN <- CREDITCARD.TOTAL[CREDITCARD.TOTAL$ID != i,][,!(colnames(CREDITCARD.TOTAL) == "ID")]
      TEST  <- CREDITCARD.TOTAL[CREDITCARD.TOTAL$ID == i,][,!(colnames(CREDITCARD.TOTAL) == "ID")]
      set.seed(1007)
      XGB_1 <- xgboost(data = data.matrix(TRAIN[,!(colnames(TRAIN) == "Class")]),
                       label = TRAIN$Class,
                       eta = 0.01,
                       max_depth = 5,
                       nrounds = 100,
                       seed = 1007,
                       objective = "binary:logistic",
                       nthread = 3,
                       verbose = F
      )
      PREDICTION.TEST <- predict(XGB_1, data.matrix(TEST[,!(colnames(TEST) == "Class")]))
      PREDICTION.TEST <- data.frame(Fraud = as.numeric(PREDICTION.TEST > 0.5))
      cf <- confusionMatrix(PREDICTION.TEST$Fraud, TEST$Class)
      #Precision = tp/(tp+fp)
      Precision[i] <- cf$table[2,2]/(cf$table[2,1] + cf$table[2,2])
      #Recall    = tp/(tp+fn)
      Recall[i]    <- cf$table[2,2]/(cf$table[1,2] + cf$table[2,2])
      print(paste0("Precision = ",round(Precision[i],4)*100, "% | Recall = ", round(Recall[i], 4)*100, "%"))
    }
    
  }#k fold cross validation
}#05. Modelling technique - XGBoost
