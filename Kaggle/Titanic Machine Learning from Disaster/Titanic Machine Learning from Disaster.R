#Author : Rohan M. Nanaware
#Date C.: 25th Jun 2017
#Date M.: 25th Jun 2017
#       : 28th Jun 2017 - Random forest 1st iteration with NA imputation
#       : 29th Jun 2017 - XGBoost - NA imputation, adjusted eta, depth and iterations. Ran model only on significant factors 
#       : 30th Jun 2017 - Feature engineering | List of features added - 
#       : 01st Jul 2017 - Random forest | Run on the feature engineered dataset
#                       - Understand the reason why XGBoost iteration failed
#       : 04th Jul 2017 - K fold cross validation of XGBoost - Need more feature engineering for model performance improvement
#       : 06th Jul 2017 - Stacking - no improvement in accuracy, need to validate the process
#Purpose: Check quality of ML knowledge using the Titanic dataset | Leaderbard score on Kaggle

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
}#01. Load required packages
{
wd <- "E:/Delivery/1 Active/Kaggle/Titanic Machine Learning from Disaster"
setwd(wd)
}#02. Set working directory
{
  train <- read.csv("train.csv", header = T, stringsAsFactors = F)
  test  <- read.csv("test.csv", header = T, stringsAsFactors = F)
  RMS.TOTAL <- rbind(train[!colnames(train) %in% c("Survived")], test)
  sum(!complete.cases(RMS.TOTAL))#Rows with NAs - 264
  sapply(RMS.TOTAL, function(x) sum(is.na(x)))#Age - 263, Fare - 1
}#03. Load data
{
  #View(head(RMS.TOTAL))
  #Impute Age by prediction
  summary(RMS.TOTAL$Age, na.rm = T)
  PREDICT_AGE <- rpart(Age ~ Pclass+Sex+SibSp+Parch+Fare+Embarked,
                       data = RMS.TOTAL[complete.cases(RMS.TOTAL),],
                       method = "anova")
  RMS.TOTAL$Age[is.na(RMS.TOTAL$Age)] <- predict(PREDICT_AGE, RMS.TOTAL[is.na(RMS.TOTAL$Age),])
  summary(RMS.TOTAL$Age, na.rm = T)
  #Impute fare by mean
  summary(RMS.TOTAL$Fare)
  RMS.TOTAL <- data.table(RMS.TOTAL)
  FARE.EM.CLASS <- RMS.TOTAL[, (MEAN_FARE = median(Fare, na.rm = T)),
                             by = 'Pclass'] 
  RMS.TOTAL$Pclass[is.na(RMS.TOTAL$Fare)]
  RMS.TOTAL$Fare[is.na(RMS.TOTAL$Fare)] = FARE.EM.CLASS$V1[FARE.EM.CLASS$Pclass == RMS.TOTAL$Pclass[is.na(RMS.TOTAL$Fare)]]
  summary(RMS.TOTAL$Fare)
  sapply(RMS.TOTAL, function(x) sum(is.na(x)))
  #check for presence of quotes in any of the factors
  nrow(RMS.TOTAL[RMS.TOTAL$Embarked == "" ])
  #Cabin    - 1014
  #Embarked - 2
  #Based on secondary research - Miss Rose Amélie Icard &  Mrs George Nelson Stone 
  #travelled on Mrs Stone's ticket (#113572). They embarked at Southampton
  RMS.TOTAL$Embarked[RMS.TOTAL$Embarked == "" ] <- "S"
  rm(PREDICT_AGE, FARE.EM.CLASS)
}#04. Impute NAs
{
  RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
  RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
  colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == "V2"] <- 'Survived'
  RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
  RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]
}#05. Split up train and test data
{
RMS.TRAIN$Pclass   <- as.factor(RMS.TRAIN$Pclass)
RMS.TRAIN$Sex      <- as.factor(RMS.TRAIN$Sex)
RMS.TRAIN$Embarked <- as.factor(RMS.TRAIN$Embarked)
RMS.TRAIN$Survived <- as.factor(RMS.TRAIN$Survived)
RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]
RF_1        <- randomForest(Survived ~ Pclass+
                              Sex+
                              Age+
                              SibSp+
                              Parch+
                              Fare+
                              Embarked,
                            data = data.frame(RMS.TRAIN.7),
                            importance = T,
                            ntree = 1000)
PREDICTION <- data.frame(Survived = predict(RF_1, RMS.TRAIN.7))
table(PREDICTION$Survived, RMS.TRAIN.7$Survived)#82%
varImpPlot(RF_1)
#Test
PREDICTION.3 <- data.frame(Survived = predict(RF_1, RMS.TRAIN.3))
table(PREDICTION.3$Survived, RMS.TRAIN.3$Survived)#82%
varImpPlot(RF_1)
#ITERATION 2 - Only considered significant variables on complete training dataset
RF_2        <- randomForest(Survived ~ Pclass+
                              Sex+
                              Age+
                              SibSp+
                              #Parch+
                              Fare,
                            #Embarked,
                            data = RMS.TRAIN,
                            importance = T,
                            ntree = 1000)
PREDICTION <- data.frame(Survived = predict(RF_2, RMS.TRAIN))
RF_2$confusion
varImpPlot(RF_2)
#Prediction on test data
PREDICTION.TEST <- data.frame(Survived = predict(RF_2, RMS.TRAIN.3))
table(PREDICTION.TEST$Survived, RMS.TRAIN.3$Survived)

#Kaggle test data
test$Pclass   <- as.factor(test$Pclass)
test$Sex      <- as.factor(test$Sex)
test$Embarked <- as.factor(test$Embarked)
RMS.TEST$Pclass   <- as.factor(RMS.TEST$Pclass)
RMS.TEST$Sex      <- as.factor(RMS.TEST$Sex)
RMS.TEST$Embarked <- as.factor(RMS.TEST$Embarked)

PREDICTION.TEST <- data.frame(Survived = predict(RF_2, RMS.TEST))
RESULT <- data.frame(PassengerId = RMS.TEST$PassengerId, Survived = PREDICTION.TEST$Survived)
write.csv(RESULT, "170628_RMS_ITER1.csv", row.names = F)
#Train accuracy - 82.15%
#Rank - 3741
}#06. Modelling technique - Random forest
{
  sapply(RMS.TRAIN.7, function(x) length(unique(x)))
  #Filter out unrequired columns - 
  REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
  RMS.TRAIN.7 <- data.table(RMS.TRAIN.7)
  RMS.TRAIN.7 <- RMS.TRAIN.7[, !REDUCE_COLS, with = FALSE] 
  FEATURES_OHE<- c("Pclass",
                   "Sex",
                   "SibSp",
                   "Embarked")
  DUMMIES     <- dummyVars(~ Pclass+
                             Sex+
                             SibSp+
                             Embarked,
                             data = RMS.TRAIN.7)
  RMS.TRAIN.7.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.7))
  RMS.TRAIN.7     <- data.frame(RMS.TRAIN.7)
  RMS.TRAIN.7.ENC <- cbind(RMS.TRAIN.7[,-c(which(colnames(RMS.TRAIN.7) %in% FEATURES_OHE))], RMS.TRAIN.7.OHE)
  RMS.TRAIN.7.ENC[] <- lapply(RMS.TRAIN.7.ENC, as.numeric)
  RMS.TRAIN.7.ENC$Survived <- ifelse(RMS.TRAIN.7.ENC$Survived == 1, 0, 1)
  RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC[,which(colnames(RMS.TRAIN.7.ENC) != "Survived")] 
  #RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC.F[, c(colnames(RMS.TRAIN.7.ENC.F) %in% FILTER_COLS)]
  #Run XGB
  set.seed(1007)
  XGB_1 <- xgboost(data = data.matrix(RMS.TRAIN.7.ENC.F),
                   label = RMS.TRAIN.7.ENC$Survived,
                   eta = 0.01,
                   max_depth = 3,
                   nround = 2000,
                   seed = 1007,
                   objective = "binary:logistic",
                   nthread = 2
                   )
  #test
  REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
  RMS.TRAIN.3 <- data.table(RMS.TRAIN.3)
  RMS.TRAIN.3 <- RMS.TRAIN.3[, !REDUCE_COLS, with = FALSE] 
  FEATURES_OHE<- c("Pclass",
                   "Sex",
                   "SibSp",
                   "Embarked")
  DUMMIES     <- dummyVars(~ Pclass+
                             Sex+
                             SibSp+
                             Embarked,
                           data = RMS.TRAIN.3)
  RMS.TRAIN.3.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.3))
  RMS.TRAIN.3     <- data.frame(RMS.TRAIN.3)
  RMS.TRAIN.3.ENC <- cbind(RMS.TRAIN.3[,-c(which(colnames(RMS.TRAIN.3) %in% FEATURES_OHE))], RMS.TRAIN.3.OHE)
  RMS.TRAIN.3.ENC[] <- lapply(RMS.TRAIN.3.ENC, as.numeric)
  RMS.TRAIN.3.ENC$Survived <- ifelse(RMS.TRAIN.3.ENC$Survived == 1, 0, 1)
  RMS.TRAIN.3.ENC.F <- RMS.TRAIN.3.ENC[,which(colnames(RMS.TRAIN.3.ENC) != "Survived")] 
  
  PREDICTION <- predict(XGB_1, data.matrix(RMS.TRAIN.3.ENC.F))
  PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
  confusionMatrix(PREDICTION$PREDICTION, RMS.TRAIN.3.ENC$Survived)
  
  library(ROCR)
  data("ROCR.simple")
  data(RM)
  PREDICTION <- data.frame(PREDICTION = predict(XGB_1, data.matrix(RMS.TRAIN.7.ENC.F)))
  pred <- prediction(PREDICTION$PREDICTION, RMS.TRAIN.7.ENC$Survived)
  ss <- performance(pred, "sens", "spec")
  plot(ss)
  ss@alpha.values[[1]][which.max(ss@x.values[[1]]+ss@y.values[[1]])]
  #[1] 0.3934746
  PREDICTION <- predict(XGB_1, data.matrix(RMS.TRAIN.7.ENC.F))
  PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.39))
  confusionMatrix(PREDICTION$PREDICTION, RMS.TRAIN.7.ENC$Survived)
  
  #Train on complete sample
  sapply(RMS.TRAIN, function(x) length(unique(x)))
  
  #Filter out unrequired columns - 
  REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
  RMS.TRAIN <- data.table(RMS.TRAIN)
  RMS.TRAIN <- RMS.TRAIN[, !REDUCE_COLS, with = FALSE] 
  FEATURES_OHE<- c("Pclass",
                   "Sex",
                   "SibSp",
                   "Embarked")
  DUMMIES     <- dummyVars(~ Pclass+
                             Sex+
                             SibSp+
                             Embarked,
                           data = RMS.TRAIN)
  RMS.TRAIN.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN))
  RMS.TRAIN     <- data.frame(RMS.TRAIN)
  RMS.TRAIN.ENC <- cbind(RMS.TRAIN[,-c(which(colnames(RMS.TRAIN) %in% FEATURES_OHE))], RMS.TRAIN.OHE)
  RMS.TRAIN.ENC[] <- lapply(RMS.TRAIN.ENC, as.numeric)
  RMS.TRAIN.ENC$Survived <- ifelse(RMS.TRAIN.ENC$Survived == 1, 0, 1)
  RMS.TRAIN.ENC.F <- RMS.TRAIN.ENC[,which(colnames(RMS.TRAIN.ENC) != "Survived")] 
  
  #Run XGB
  set.seed(1007)
  XGB_2 <- xgboost(data = data.matrix(RMS.TRAIN.ENC.F),
                   label = RMS.TRAIN.ENC$Survived,
                   eta = 0.01,
                   max_depth = 5,
                   nround = 1000,
                   seed = 1007,
                   objective = "binary:logistic",
                   nthread = 2
  )
  
  PREDICTION <- predict(XGB_2, data.matrix(RMS.TRAIN.ENC.F))
  PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
  confusionMatrix(PREDICTION$PREDICTION, RMS.TRAIN.ENC$Survived)
  
  #Kaggle test data
  REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
  RMS.TEST <- data.table(RMS.TEST)
  RMS.TEST <- RMS.TEST[, !REDUCE_COLS, with = FALSE] 
  FEATURES_OHE<- c("Pclass",
                   "Sex",
                   "SibSp",
                   "Embarked")
  DUMMIES     <- dummyVars(~ Pclass+
                             Sex+
                             SibSp+
                             Embarked,
                           data = RMS.TEST)
  RMS.TEST.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TEST))
  RMS.TEST     <- data.frame(RMS.TEST)
  RMS.TEST.ENC <- cbind(RMS.TEST[,-c(which(colnames(RMS.TEST) %in% FEATURES_OHE))], RMS.TEST.OHE)
  RMS.TEST.ENC[] <- lapply(RMS.TEST.ENC, as.numeric)
  RMS.TEST.ENC$Survived <- ifelse(RMS.TEST.ENC$Survived == 1, 0, 1)
  RMS.TEST.ENC.F <- RMS.TEST.ENC[,which(colnames(RMS.TEST.ENC) != "Survived")] 
  
  PREDICTION <- predict(XGB_2, data.matrix(RMS.TEST.ENC.F))
  PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
  RESULT     <- cbind(PassengerId = RMS.TEST$PassengerId, Survived = PREDICTION$PREDICTION)
  write.csv(RESULT, "170629_RMS_ITER2.csv", row.names = F)
  
  #Train accuracy - 90.68%
  #Leaderboard rank - 2347
  
  names <- dimnames(data.matrix(RMS.TRAIN.3.ENC.F))[[2]]
  importance_matrix <- xgb.importance(names, model = XGB_1)
  xgb.plot.importance(importance_matrix)
  FILTER_COLS <- importance_matrix$Feature[cumsum(importance_matrix$Gain) <= 0.99]
  RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC.F[, c(colnames(RMS.TRAIN.7.ENC.F) %in% FILTER_COLS)]

  {
    {
      #Module 05
      REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
      RMS.TRAIN <- data.table(RMS.TRAIN)
      RMS.TRAIN <- RMS.TRAIN[, !REDUCE_COLS, with = FALSE] 
      FEATURES_OHE<- c("Pclass",
                       "Sex",
                       "SibSp",
                       "Embarked")
      DUMMIES     <- dummyVars(~ Pclass+
                                 Sex+
                                 SibSp+
                                 Embarked,
                               data = RMS.TRAIN)
      RMS.TRAIN.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN))
      RMS.TRAIN     <- data.frame(RMS.TRAIN)
      RMS.TRAIN.ENC <- cbind(RMS.TRAIN[,-c(which(colnames(RMS.TRAIN) %in% FEATURES_OHE))], RMS.TRAIN.OHE)
      RMS.TRAIN.ENC[] <- lapply(RMS.TRAIN.ENC, as.numeric)
      RMS.TRAIN.ENC$Survived <- ifelse(RMS.TRAIN.ENC$Survived == 1, 0, 1)
      RMS.TRAIN.ENC.F <- RMS.TRAIN.ENC[,which(colnames(RMS.TRAIN.ENC) != "Survived")]
  }#Data massage
    {
      k = 10
      RMS.TRAIN.ENC.F$ID <- sample(1:k, nrow(RMS.TRAIN), replace = T)
      RMS.TRAIN.ENC$ID   <- RMS.TRAIN.ENC.F$ID
      error        <- numeric()
      for (i in 1:k) {
        TRAIN <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID != i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
        TEST  <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID == i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
        TRAIN.DEP <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID != i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
        TEST.DEP  <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID == i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
        set.seed(1007)
        XGB_1 <- xgboost(data = data.matrix(TRAIN),
                         label = TRAIN.DEP$Survived,
                         eta = 0.01,
                         max_depth = 5,
                         nround = 2000,
                         seed = 1007,
                         objective = "binary:logistic",
                         nthread = 2,
                         print_every_n = 2000,
                         verbose = F
        )
        PREDICTION.TEST <- predict(XGB_1, data.matrix(TEST))
        PREDICTION.TEST <- data.frame(Survived = as.numeric(PREDICTION.TEST > 0.5))
        #confusionMatrix(PREDICTION$PREDICTION, TEST.DEP$Survived)
        table_ = as.matrix(table(PREDICTION.TEST$Survived, TEST.DEP$Survived))#93.9%
        print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
      }
      bias <- mean(error)
      variance <- sd(error)
      print(paste("Bias = ", bias, " & Variance = ", variance))
  }#k fold cross validation loop
    {
      # [1] 0.7979798
      # [1] 0.8505747
      # [1] 0.8658537
      # [1] 0.9466667
      # [1] 0.8350515
      # [1] 0.7692308
      # [1] 0.7850467
      # [1] 0.8375
      # [1] 0.7866667
      # [1] 0.8705882
      # [1] "Bias =  0.1654841217618  & Variance =  0.0531893089133854"
    }#Output
    
  }#k fold cross validation

}#07. Modelling technique - XGBoost
{
sapply(RMS.TOTAL, function(x) sum(is.na(x)))
head(RMS.TOTAL)

#Get the surnames
RMS.TOTAL$Surname <- sapply(as.character(RMS.TOTAL$Name), FUN = 
                              function(x) {strsplit(x, '[,.]')}[[1]][1])
#Compute ticket, fare and cabin frequencies
RMS.TOTAL$T.FREQ  <- ave(seq(nrow(RMS.TOTAL)), RMS.TOTAL$Ticket, FUN = length)
RMS.TOTAL$F.FREQ  <- ave(seq(nrow(RMS.TOTAL)), RMS.TOTAL$Fare, FUN = length)
RMS.TOTAL$C.FREQ  <- ave(seq(nrow(RMS.TOTAL)), RMS.TOTAL$Cabin, FUN = length)

#Define group IDs
RMS.TOTAL$GRP.ID <- rep(NA, nrow(RMS.TOTAL))
MAX.GRP          <- 12
for (i in 1:nrow(RMS.TOTAL)) {
  if (RMS.TOTAL$SibSp[i] + RMS.TOTAL$Parch[i] > 0){#Doe he have any relatives
    RMS.TOTAL$GRP.ID[i] <- paste0(RMS.TOTAL$Surname[i], RMS.TOTAL$SibSp[i] + RMS.TOTAL$Parch[i])
  }
  else {
    if (RMS.TOTAL$T.FREQ[i] > 1 & is.na(RMS.TOTAL$GRP.ID[i])){#shares ticket
      RMS.TOTAL$GRP.ID[i] <- RMS.TOTAL$Ticket[i]
    }
    else {
      if(RMS.TOTAL$C.FREQ[i] > 1 & RMS.TOTAL$C.FREQ[i] < MAX.GRP & is.na(RMS.TOTAL$GRP.ID[i])){
        RMS.TOTAL$GRP.ID[i] <- RMS.TOTAL$Cabin[i]#shares cabin
      }
      else {
        if(RMS.TOTAL$F.FREQ[i] > 1 & RMS.TOTAL$F.FREQ[i] < MAX.GRP & is.na(RMS.TOTAL$GRP.ID[i])){
          RMS.TOTAL$GRP.ID[i] <- RMS.TOTAL$Fare[i]#shares fare
        }
        else {
          RMS.TOTAL$GRP.ID[i] <- "Single"
        }
      }
    }
  }
}
View(RMS.TOTAL[RMS.TOTAL$GRP.ID == '6.75'])

#Define fare per person for people sharing tickets
RMS.TOTAL$FARE.SCALED <- RMS.TOTAL$Fare/RMS.TOTAL$T.FREQ

#Check the reliability of age information across pclass
age_plot <- ggplot(RMS.TOTAL, aes(Pclass, fill = !is.na(Age))) + 
  geom_bar(position = 'dodge')+
  labs(title = 'Passenger has age', fill = 'His Age')
#define log likelihood and penalize or reawrd passengers
}#08. Feature engineering 1
{
  #Extract title - 
  RMS.TOTAL$Title <- gsub('(.*, )|(\\..*)', '', RMS.TOTAL$Name)
  table(RMS.TOTAL$Title, RMS.TOTAL$Sex)
  #combine titles with low cell counts
  RARE.TITLE <- c('Dona', 'Lady', 'the Countess', 'Capt',
                  'Col','Don', 'Dr', 'Major', 'Rev', 'Sir',
                  'Jonkheer')
  RMS.TOTAL$Title[RMS.TOTAL$Title == 'Mlle'] = 'Miss'
  RMS.TOTAL$Title[RMS.TOTAL$Title == 'Ms']   = 'Miss'
  RMS.TOTAL$Title[RMS.TOTAL$Title == 'Mme']  = 'Mrs'
  RMS.TOTAL$Title[RMS.TOTAL$Title %in% RARE.TITLE] = 'Rare'
  table(RMS.TOTAL$Title, RMS.TOTAL$Sex)
  #Add ethnicity details using surname?
  RMS.TOTAL$Surname <- sapply(as.character(RMS.TOTAL$Name), FUN = 
                                function(x) {strsplit(x, '[,.]')}[[1]][1])
  RMS.TOTAL$F.SIZE  <- RMS.TOTAL$SibSp + RMS.TOTAL$Parch + 1
  RMS.TOTAL$Family  <- paste(RMS.TOTAL$Surname, RMS.TOTAL$F.SIZE, sep = "_")
  RMS.TOTAL$F.SIZE.B[RMS.TOTAL$F.SIZE == 1] <- 'Singleton'
  RMS.TOTAL$F.SIZE.B[RMS.TOTAL$F.SIZE < 5 & RMS.TOTAL$F.SIZE > 1] <- 'Small'
  RMS.TOTAL$F.SIZE.B[RMS.TOTAL$F.SIZE >= 5] <- 'Large'
  #Create a deck variable
  RMS.TOTAL$DECK <- sapply(RMS.TOTAL$Cabin, FUN = function(x) {strsplit(x, NULL)}[[1]][1])
  #RMS.TOTAL$DECK <- NULL
  RMS.TOTAL$CHILD[RMS.TOTAL$Age < 18] <- 'Child'
  RMS.TOTAL$CHILD[RMS.TOTAL$Age >= 18] <- 'Adult'
  RMS.TOTAL$MOTHER <- 'Not Mother' 
  RMS.TOTAL$MOTHER[RMS.TOTAL$Sex == 'female' & RMS.TOTAL$Age > 18 & 
                     RMS.TOTAL$Parch > 0 & RMS.TOTAL$Title != 'Miss'] <- 'Mother'
  colnames(RMS.TOTAL)
  RMS.TOTAL$Surname <- NULL
  #RMS.TOTAL$F.SIZE  <- NULL
  RMS.TOTAL$Family  <- NULL
  RMS.TOTAL$DECK    <- NULL
  rm(RARE.TITLE)
}#09. Feature engineering 2
{
#Split up train and test data
RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == 'V2'] <- 'Survived'

RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]

#Filter out unrequired columns - 
REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin","Surname","Family")
RMS.TRAIN.7 <- data.table(RMS.TRAIN.7)
RMS.TRAIN.7 <- RMS.TRAIN.7[, !REDUCE_COLS, with = FALSE] 
FEATURES_OHE<- c("Pclass",
                 "Sex",
                 "Embarked",
                 "Title",
                 "F.SIZE.B",
                 "CHILD",
                 "MOTHER"
)
DUMMIES     <- dummyVars(~ Pclass+
                           Sex+
                           Embarked+
                           Title+
                           F.SIZE.B+
                           CHILD+
                           MOTHER,
                         data = RMS.TRAIN.7)
RMS.TRAIN.7.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.7))
RMS.TRAIN.7     <- data.frame(RMS.TRAIN.7)
RMS.TRAIN.7.ENC <- cbind(RMS.TRAIN.7[,-c(which(colnames(RMS.TRAIN.7) %in% FEATURES_OHE))], RMS.TRAIN.7.OHE)
RMS.TRAIN.7.ENC[] <- lapply(RMS.TRAIN.7.ENC, as.numeric)
RMS.TRAIN.7.ENC$Survived <- ifelse(RMS.TRAIN.7.ENC$Survived == 1, 0, 1)
RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC[,which(colnames(RMS.TRAIN.7.ENC) != "Survived")] 
names <- dimnames(data.matrix(RMS.TRAIN.ENC.F))[[2]]
importance_matrix <- xgb.importance(names, model = XGB_3)
FILTER_COLS <- importance_matrix$Feature[cumsum(importance_matrix$Gain) <= 0.99]
RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC.F[, c(colnames(RMS.TRAIN.7.ENC.F) %in% FILTER_COLS)]
#Run XGB
set.seed(1007)
XGB_3 <- xgboost(data = data.matrix(RMS.TRAIN.7.ENC.F),
                 label = RMS.TRAIN.7.ENC$Survived,
                 eta = 0.01,
                 max_depth = 5,
                 nround = 2000,
                 seed = 1007,
                 objective = "binary:logistic",
                 nthread = 2
)
#test
RMS.TRAIN.3 <- data.table(RMS.TRAIN.3)
RMS.TRAIN.3 <- RMS.TRAIN.3[, !REDUCE_COLS, with = FALSE] 
DUMMIES     <- dummyVars(~ Pclass+
                           Sex+
                           Embarked+
                           Title+
                           F.SIZE.B+
                           CHILD+
                           MOTHER,
                         data = RMS.TRAIN.3)
RMS.TRAIN.3.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.3))
RMS.TRAIN.3     <- data.frame(RMS.TRAIN.3)
RMS.TRAIN.3.ENC <- cbind(RMS.TRAIN.3[,-c(which(colnames(RMS.TRAIN.3) %in% FEATURES_OHE))], RMS.TRAIN.3.OHE)
RMS.TRAIN.3.ENC[] <- lapply(RMS.TRAIN.3.ENC, as.numeric)
RMS.TRAIN.3.ENC$Survived <- ifelse(RMS.TRAIN.3.ENC$Survived == 1, 0, 1)
RMS.TRAIN.3.ENC.F <- RMS.TRAIN.3.ENC[,which(colnames(RMS.TRAIN.3.ENC) != "Survived")] 
FILTER_COLS <- importance_matrix$Feature[cumsum(importance_matrix$Gain) <= 0.99]
RMS.TRAIN.3.ENC.F <- RMS.TRAIN.3.ENC.F[, c(colnames(RMS.TRAIN.3.ENC.F) %in% FILTER_COLS)]
PREDICTION <- predict(XGB_3, data.matrix(RMS.TRAIN.3.ENC.F))
PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
confusionMatrix(PREDICTION$PREDICTION, RMS.TRAIN.3.ENC$Survived)

#Train on complete data
#Split up train and test data
RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == 'V2'] <- 'Survived'
#Filter out unrequired columns - 
REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin","Surname","Family")
RMS.TRAIN <- data.table(RMS.TRAIN)
RMS.TRAIN <- RMS.TRAIN[, !REDUCE_COLS, with = FALSE] 
FEATURES_OHE<- c("Pclass",
                 "Sex",
                 "Embarked",
                 "Title",
                 "F.SIZE.B",
                 "CHILD",
                 "MOTHER"
)
DUMMIES     <- dummyVars(~ Pclass+
                           Sex+
                           Embarked+
                           Title+
                           F.SIZE.B+
                           CHILD+
                           MOTHER,
                         data = RMS.TRAIN)
RMS.TRAIN.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN))
RMS.TRAIN     <- data.frame(RMS.TRAIN)
RMS.TRAIN.ENC <- cbind(RMS.TRAIN[,-c(which(colnames(RMS.TRAIN) %in% FEATURES_OHE))], RMS.TRAIN.OHE)
RMS.TRAIN.ENC[] <- lapply(RMS.TRAIN.ENC, as.numeric)
RMS.TRAIN.ENC$Survived <- ifelse(RMS.TRAIN.ENC$Survived == 1, 0, 1)
RMS.TRAIN.ENC.F <- RMS.TRAIN.ENC[,which(colnames(RMS.TRAIN.ENC) != "Survived")] 
RMS.TRAIN.ENC.F$Embarked <- NULL
#Run XGB
set.seed(1007)
XGB_3 <- xgboost(data = data.matrix(RMS.TRAIN.ENC.F),
                 label = RMS.TRAIN.ENC$Survived,
                 eta = 0.01,
                 max_depth = 3,
                 nround = 2000,
                 seed = 1007,
                 objective = "binary:logistic",
                 nthread = 2
)
#test
RMS.TEST <- data.table(RMS.TEST)
RMS.TEST <- RMS.TEST[, !REDUCE_COLS, with = FALSE] 
DUMMIES     <- dummyVars(~ Pclass+
                           Sex+
                           Embarked+
                           Title+
                           F.SIZE.B+
                           CHILD+
                           MOTHER,
                         data = RMS.TEST)
RMS.TEST.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TEST))
RMS.TEST     <- data.frame(RMS.TEST)
RMS.TEST.ENC <- cbind(RMS.TEST[,-c(which(colnames(RMS.TEST) %in% FEATURES_OHE))], RMS.TEST.OHE)
RMS.TEST.ENC[] <- lapply(RMS.TEST.ENC, as.numeric)
RMS.TEST.ENC.F <- RMS.TEST.ENC 
PREDICTION <- predict(XGB_3, data.matrix(RMS.TEST.ENC.F))
PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
RESULT     <- cbind(PassengerId = as.data.frame(RMS.TOTAL[-(1:nrow(train)),])$PassengerId, Survived = PREDICTION$PREDICTION)
write.csv(RESULT, "170630_RMS_ITER3.csv", row.names = F)
}#10. Modelling technique - XGBoost - 2
{
  #rm(list = ls())
  gc()
  #Module 03, 04, 09, 05
  #Train model
  #Prepare train data
  head(RMS.TRAIN.7)
  #Covert categorical to factors
  colnames(RMS.TRAIN.7)
  RMS.TRAIN.7[, colnames(RMS.TRAIN.7) == 'Pclass' |
                (sapply(RMS.TRAIN.7, class) == 'character' &
                   !(colnames(RMS.TRAIN.7) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
    data.frame(
    sapply(RMS.TRAIN.7[, colnames(RMS.TRAIN.7) == 'Pclass' |
                          (sapply(RMS.TRAIN.7, class) == 'character' &
                          !(colnames(RMS.TRAIN.7) %in% c('Name','PassengerId','Ticket','Cabin')))],
           function(x) as.factor(x)
    ))
  RMS.TRAIN.7$Survived <- as.factor(RMS.TRAIN.7$Survived)
  RMS.TRAIN.7$CHILD  <- as.numeric(RMS.TRAIN.7$CHILD)
  RMS.TRAIN.7$MOTHER <- as.numeric(RMS.TRAIN.7$MOTHER) 
  RF_1        <- randomForest(Survived ~ Pclass+
                                Sex+
                                Age+
                                #SibSp+
                                #Parch+
                                Fare+
                                Embarked+
                                Title+
                                F.SIZE+
                                #F.SIZE.B
                                CHILD+
                                MOTHER
                                ,
                              data = data.frame(RMS.TRAIN.7),
                              importance = T,
                              ntree = 1000,
                              #tuning
                              nodesize = 20
                              #mtry = ncol(RMS.TRAIN.7)/2
                              )
  PREDICTION <- predict(RF_1, RMS.TRAIN.7)
  varImpPlot(RF_1)
  table(PREDICTION, RMS.TRAIN.7$Survived)#91% - 93.1% after removing Child, mother and family bucket size---overfit?  ### - TEST - ###
  #Prepare test data
  head(RMS.TRAIN.3)
  #Covert categorical to factors
  colnames(RMS.TRAIN.3)
  RMS.TRAIN.3[, colnames(RMS.TRAIN.3) == 'Pclass' |
                (sapply(RMS.TRAIN.3, class) == 'character' &
                   !(colnames(RMS.TRAIN.3) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
    data.frame(
      sapply(RMS.TRAIN.3[, colnames(RMS.TRAIN.3) == 'Pclass' |
                           (sapply(RMS.TRAIN.3, class) == 'character' &
                              !(colnames(RMS.TRAIN.3) %in% c('Name','PassengerId','Ticket','Cabin')))],
             function(x) as.factor(x)
      ))
  RMS.TRAIN.3$Survived <- as.factor(RMS.TRAIN.3$Survived)
  RMS.TRAIN.3$CHILD  <- as.numeric(RMS.TRAIN.3$CHILD)
  RMS.TRAIN.3$MOTHER <- as.numeric(RMS.TRAIN.3$MOTHER) 
  PREDICTION.3 <- data.frame(Survived = predict(RF_1, RMS.TRAIN.3))
  table(PREDICTION.3$Survived, RMS.TRAIN.3$Survived)#83.9%
  #ITERATION 2 - Only considered significant variables on complete training dataset
  #Prepare test data
  head(RMS.TRAIN)
  #Covert categorical to factors
  colnames(RMS.TRAIN)
  RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                (sapply(RMS.TRAIN, class) == 'character' &
                   !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
    data.frame(
      sapply(RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                           (sapply(RMS.TRAIN, class) == 'character' &
                              !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))],
             function(x) as.factor(x)
      ))
  RMS.TRAIN$Survived <- as.factor(RMS.TRAIN$Survived)
  RMS.TRAIN$CHILD  <- as.numeric(RMS.TRAIN$CHILD)
  RMS.TRAIN$MOTHER <- as.numeric(RMS.TRAIN$MOTHER) 
  RF_2        <- randomForest(Survived ~ Pclass+
                                Sex+
                                Age+
                                SibSp+
                                Parch+
                                Fare+
                                Embarked+
                                Title+
                                CHILD+
                                MOTHER+
                                F.SIZE,
                              data = data.frame(RMS.TRAIN),
                              importance = T,
                              ntree = 1000,
                              nodesize = 15)
  PREDICTION <- data.frame(Survived = predict(RF_2, RMS.TRAIN))
  PREDICTION.TEST <- data.frame(Survived = predict(RF_2, RMS.TRAIN))
  table(PREDICTION.TEST$Survived, RMS.TRAIN$Survived)#93.9%
  #Kaggle test data
  #Prepare test data
  head(RMS.TEST)
  #Covert categorical to factors
  colnames(RMS.TEST)
  RMS.TEST[, colnames(RMS.TEST) == 'Pclass' |
              (sapply(RMS.TEST, class) == 'character' &
                 !(colnames(RMS.TEST) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
    data.frame(
      sapply(RMS.TEST[, colnames(RMS.TEST) == 'Pclass' |
                         (sapply(RMS.TEST, class) == 'character' &
                            !(colnames(RMS.TEST) %in% c('Name','PassengerId','Ticket','Cabin')))],
             function(x) as.factor(x)
      ))
  RMS.TEST$CHILD  <- as.numeric(RMS.TEST$CHILD)
  RMS.TEST$MOTHER <- as.numeric(RMS.TEST$MOTHER) 
  PREDICTION.TEST <- data.frame(Survived = predict(RF_1, RMS.TEST))
  RESULT <- data.frame(PassengerId = RMS.TEST$PassengerId, Survived = PREDICTION.TEST$Survived)
  write.csv(RESULT, "170701_RMS_ITER5.csv", row.names = F)
  #Train accuracy - 93.9%
  #Leaderboard score - 0.78469 ITER 1
  #                  - 0.78947 ITER 2 - Included Mother and Child
  #Rank - 2289
  
  {
    leaf_sizes <- c(5,10,15,20,30,50,100,200)
    for (leaf_size in c(2,3,4,5,6)) {
      RF_2        <- randomForest(Survived ~ Pclass+
                                    Sex+
                                    Age+
                                    SibSp+
                                    Parch+
                                    Fare+
                                    Embarked+
                                    Title+
                                    CHILD+
                                    MOTHER+
                                    F.SIZE,
                                  data = data.frame(RMS.TRAIN),
                                  importance = T,
                                  ntree = 1000,
                                  mtry = as.integer(ncol(RMS.TRAIN)/leaf_size),
                                  nodesize = 15
                                  )
      #print(RF_2$confusion)
      PREDICTION.TEST <- data.frame(Survived = predict(RF_2, RMS.TRAIN))
      table_ = as.matrix(table(PREDICTION.TEST$Survived, RMS.TRAIN$Survived))#93.9%
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    }
  }#Paramter tuning
  
  #Tune mtry and node size for better results    
  RF_2        <- randomForest(Survived ~ Pclass+
                                Sex+
                                Age+
                                SibSp+
                                Parch+
                                Fare+
                                Embarked+
                                Title+
                                CHILD+
                                MOTHER+
                                F.SIZE,
                              data = data.frame(RMS.TRAIN),
                              importance = T,
                              ntree = 1000,
                              #Tuning
                              #mtry = as.integer(ncol(RMS.TRAIN)/2),
                              nodesize = 15
  )
  PREDICTION.TEST <- data.frame(Survived = predict(RF_2, RMS.TEST))
  RESULT <- data.frame(PassengerId = RMS.TEST$PassengerId, Survived = PREDICTION.TEST$Survived)
  write.csv(RESULT, "170701_RMS_ITER3.csv", row.names = F)
  
  {
    set.seed(007)
    k = 10
    RMS.TRAIN$ID <- sample(1:k, nrow(RMS.TRAIN), replace = T)
    error        <- numeric()
    for (i in 1:k) {
      TRAIN <- RMS.TRAIN[RMS.TRAIN$ID != i,][,!(colnames(RMS.TRAIN) == "ID")]
      TEST  <- RMS.TRAIN[RMS.TRAIN$ID == i,][,!(colnames(RMS.TRAIN) == "ID")]
      RF_2        <- randomForest(Survived ~ Pclass+
                                    Sex+
                                    Age+
                                    SibSp+
                                    Parch+
                                    Fare+
                                    Embarked+
                                    Title+
                                    F.SIZE+
                                    F.SIZE.B+
                                    CHILD+
                                    MOTHER+
                                    F.SIZE,
                                  data = data.frame(TRAIN),
                                  importance = T,
                                  ntree = 1000,
                                  #Tuning
                                  #mtry = as.integer(ncol(TRAIN)/2),
                                  nodesize = 15
      )
      PREDICTION.TEST <- data.frame(Survived = predict(RF_2, TEST))
      table_ = as.matrix(table(PREDICTION.TEST$Survived, TEST$Survived))
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
      error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
    }
    bias <- mean(error)
    variance <- sd(error)
    print(paste("Bias = ", bias, " & Variance = ", variance))
    #[1] "Bias =  0.163865568838648  & Variance =  0.0131583755083429"
  }#K fold validation
  
}#11. Modelling technique - Random forest - 2
{
  k = 10
  RMS.TRAIN$ID <- sample(1:k, nrow(RMS.TRAIN), replace = T)
  error        <- numeric()
  for (i in 1:k) {
    TRAIN <- RMS.TRAIN[RMS.TRAIN$ID != i,][,!(colnames(RMS.TRAIN) == "ID")]
    TEST  <- RMS.TRAIN[RMS.TRAIN$ID == i,][,!(colnames(RMS.TRAIN) == "ID")]
    RF_2        <- randomForest(Survived ~ Pclass+
                                  Sex+
                                  Age+
                                  SibSp+
                                  Parch+
                                  Fare+
                                  Embarked+
                                  Title+
                                  CHILD+
                                  MOTHER+
                                  F.SIZE,
                                data = data.frame(TRAIN),
                                importance = T,
                                ntree = 2000,
                                #Tuning
                                #mtry = as.integer(ncol(TRAIN)/2),
                                nodesize = 20
    )
    PREDICTION.TEST <- data.frame(Survived = predict(RF_2, TEST))
    table_ = as.matrix(table(PREDICTION.TEST$Survived, TEST$Survived))#93.9%
    print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
    error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
  }
  bias <- mean(error)
  variance <- sd(error)
  print(paste("Bias = ", bias, " & Variance = ", variance))
}#12. K fold cross validation
{
  #Module 01, 02, 03, 04, 09, 05
  {
    #Filter out unrequired columns - 
    REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin","F.SIZE.B")
    RMS.TRAIN.7 <- data.table(RMS.TRAIN.7)
    RMS.TRAIN.7 <- RMS.TRAIN.7[, !REDUCE_COLS, with = FALSE] 
    FEATURES_OHE<- c("Pclass",
                     "Sex",
                     "Embarked",
                     "Title",
                     "CHILD",
                     "MOTHER"
    )
    DUMMIES     <- dummyVars(~ Pclass+
                               Sex+
                               Embarked+
                               Title+
                               CHILD+
                               MOTHER,
                             data = RMS.TRAIN.7)
    RMS.TRAIN.7.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.7))
    RMS.TRAIN.7     <- data.frame(RMS.TRAIN.7)
    RMS.TRAIN.7.ENC <- cbind(RMS.TRAIN.7[,-c(which(colnames(RMS.TRAIN.7) %in% FEATURES_OHE))], RMS.TRAIN.7.OHE)
    RMS.TRAIN.7.ENC[] <- lapply(RMS.TRAIN.7.ENC, as.numeric)
    RMS.TRAIN.7.ENC.F <- RMS.TRAIN.7.ENC[,which(colnames(RMS.TRAIN.7.ENC) != "Survived")] 
    #Run XGB
    set.seed(1007)
    XGB_1 <- xgboost(data = data.matrix(RMS.TRAIN.7.ENC.F),
                     label = RMS.TRAIN.7.ENC$Survived,
                     eta = 0.01,
                     max_depth = 5,
                     nround = 2000,
                     seed = 1007,
                     objective = "binary:logistic",
                     nthread = 2
    )
    #test
    RMS.TRAIN.3 <- data.table(RMS.TRAIN.3)
    RMS.TRAIN.3 <- RMS.TRAIN.3[, !REDUCE_COLS, with = FALSE] 
    FEATURES_OHE<- c("Pclass",
                     "Sex",
                     "Embarked",
                     "Title",
                     "CHILD",
                     "MOTHER"
    )
    DUMMIES     <- dummyVars(~ Pclass+
                               Sex+
                               Embarked+
                               Title+
                               CHILD+
                               MOTHER,
                             data = RMS.TRAIN.3)
    RMS.TRAIN.3.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN.3))
    RMS.TRAIN.3     <- data.frame(RMS.TRAIN.3)
    RMS.TRAIN.3.ENC <- cbind(RMS.TRAIN.3[,-c(which(colnames(RMS.TRAIN.3) %in% FEATURES_OHE))], RMS.TRAIN.3.OHE)
    RMS.TRAIN.3.ENC[] <- lapply(RMS.TRAIN.3.ENC, as.numeric)
    PREDICTION <- predict(XGB_1, data.matrix(RMS.TRAIN.3.ENC))
    PREDICTION <- data.frame(PREDICTION = as.numeric(PREDICTION > 0.5))
    confusionMatrix(PREDICTION$PREDICTION, RMS.TRAIN.3.ENC$Survived)
  }#XGboost iteration on 70:30 partition
  {
    REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
    RMS.TRAIN <- data.table(RMS.TRAIN)
    RMS.TRAIN <- RMS.TRAIN[, !REDUCE_COLS, with = FALSE] 
    FEATURES_OHE<- c("Pclass",
                     "Sex",
                     "Embarked",
                     "Title",
                     "F.SIZE.B",
                     "CHILD",
                     "MOTHER"
    )
    DUMMIES     <- dummyVars(~ Pclass+
                               Sex+
                               Embarked+
                               Title+
                               F.SIZE.B+
                               CHILD+
                               MOTHER,
                             data = RMS.TRAIN)
    RMS.TRAIN.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN))
    RMS.TRAIN     <- data.frame(RMS.TRAIN)
    RMS.TRAIN.ENC <- cbind(RMS.TRAIN[,-c(which(colnames(RMS.TRAIN) %in% FEATURES_OHE))], RMS.TRAIN.OHE)
    RMS.TRAIN.ENC[] <- lapply(RMS.TRAIN.ENC, as.numeric)
    RMS.TRAIN.ENC.F <- RMS.TRAIN.ENC[,which(colnames(RMS.TRAIN.ENC) != "Survived")]
  }#Data massaging
  {
    k = 10
    RMS.TRAIN.ENC.F$ID <- sample(1:k, nrow(RMS.TRAIN), replace = T)
    RMS.TRAIN.ENC$ID   <- RMS.TRAIN.ENC.F$ID
    error        <- numeric()
    for (i in 1:k) {
      TRAIN <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID != i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
      TEST  <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID == i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
      TRAIN.DEP <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID != i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
      TEST.DEP  <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID == i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
      set.seed(1007)
      XGB_1 <- xgboost(data = data.matrix(TRAIN),
                       label = TRAIN.DEP$Survived,
                       eta = 0.01,
                       max_depth = 3,
                       nround = 2000,
                       seed = 1007,
                       objective = "binary:logistic",
                       nthread = 3,
                       verbose = F
      )
      PREDICTION.TEST <- predict(XGB_1, data.matrix(TEST))
      PREDICTION.TEST <- data.frame(Survived = as.numeric(PREDICTION.TEST > 0.5))
      #confusionMatrix(PREDICTION$PREDICTION, TEST.DEP$Survived)
      table_ = as.matrix(table(PREDICTION.TEST$Survived, TEST.DEP$Survived))#93.9%
      print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
      error[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
    }
    
    bias <- mean(error)
    variance <- sd(error)
    print(paste("Bias = ", bias, " & Variance = ", variance))
  }#k fold cross validation
  {
    # [1] 0.8019802
    # [1] 0.8767123
    # [1] 0.7878788
    # [1] 0.8351648
    # [1] 0.7888889
    # [1] 0.7857143
    # [1] 0.8666667
    # [1] 0.8648649
    # [1] 0.8863636
    # [1] 0.7790698
    # [1] "Bias =  0.172669574022925  & Variance =  0.0430488818098331"
  }#Output
  
}#13. Modelling technique - XGBoost - 3
{
  
}#14. Feature engineering 3
{
  #Module 1,2,3,4,9,5
  #Stack XGBoost, Randomforest, Logistic &/ Naive bayes
  
  {
    {
      RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
      RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
      colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == "V2"] <- 'Survived'
      RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
      RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]
    }#05. Split up train and test data
    #Filter out unrequired columns - 
    REDUCE_COLS <- c("PassengerId","Name","Ticket","Cabin")
    RMS.TRAIN <- data.table(RMS.TRAIN)
    RMS.TRAIN <- RMS.TRAIN[, !REDUCE_COLS, with = FALSE] 
    FEATURES_OHE<- c("Pclass",
                     "Sex",
                     "Embarked",
                     "Title",
                     "F.SIZE.B",
                     "CHILD",
                     "MOTHER"
    )
    DUMMIES     <- dummyVars(~ Pclass+
                               Sex+
                               Embarked+
                               Title+
                               F.SIZE.B+
                               CHILD+
                               MOTHER,
                             data = RMS.TRAIN)
    RMS.TRAIN.OHE <- as.data.frame(predict(DUMMIES, newdata = RMS.TRAIN))
    RMS.TRAIN     <- data.frame(RMS.TRAIN)
    RMS.TRAIN.ENC <- cbind(RMS.TRAIN[,-c(which(colnames(RMS.TRAIN) %in% FEATURES_OHE))], RMS.TRAIN.OHE)
    RMS.TRAIN.ENC[] <- lapply(RMS.TRAIN.ENC, as.numeric)
    #RMS.TRAIN.ENC$Survived <- ifelse(RMS.TRAIN.ENC$Survived == 1, 0, 1)
    RMS.TRAIN.ENC.F <- RMS.TRAIN.ENC[,which(colnames(RMS.TRAIN.ENC) != "Survived")] 
    #RMS.TRAIN.ENC.F$Embarked <- NULL
    #Run XGB
    set.seed(1007)
    XGB_STACK <- xgboost(data = data.matrix(RMS.TRAIN.ENC.F),
                         label = RMS.TRAIN.ENC$Survived,
                         eta = 0.01,
                         max_depth = 3,
                         nround = 2000,
                         seed = 1007,
                         objective = "binary:logistic",
                         nthread = 2,
                         verbose = F
                         
          )
    PREDICT <- predict(XGB_STACK, data.matrix(RMS.TRAIN.ENC.F))
    confusionMatrix(as.numeric(PREDICT > 0.5), RMS.TRAIN$Survived)
    PREDICTION.XGB_STACK <- data.frame(Survived = as.numeric(PREDICT > 0.5))
    {
     #    Confusion Matrix and Statistics
     #    
     #    Reference
     #    Prediction   0   1
     #    0 522  58
     #    1  27 284
     #    
     #    Accuracy : 0.9046          
     #    95% CI : (0.8834, 0.9231)
     #    No Information Rate : 0.6162          
     #    P-Value [Acc > NIR] : < 2.2e-16       
     #    
     #    Kappa : 0.7948          
     #    Mcnemar's Test P-Value : 0.001138        
     #                                        
     #          Sensitivity : 0.9508          
     #          Specificity : 0.8304          
     #       Pos Pred Value : 0.9000          
     #       Neg Pred Value : 0.9132          
     #           Prevalence : 0.6162          
     #       Detection Rate : 0.5859          
     # Detection Prevalence : 0.6510          
     #    Balanced Accuracy : 0.8906          
     #                                        
     #     'Positive' Class : 0  
    }#Output
    
  }#XGBoost
  {
    {
      RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
      RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
      colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == "V2"] <- 'Survived'
      RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
      RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]
    }#05. Split up train and test data
    RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                (sapply(RMS.TRAIN, class) == 'character' &
                   !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
      data.frame(
        sapply(RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                           (sapply(RMS.TRAIN, class) == 'character' &
                              !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))],
               function(x) as.factor(x)
        ))
    RMS.TRAIN$Survived <- as.factor(RMS.TRAIN$Survived)
    RMS.TRAIN$CHILD  <- as.numeric(RMS.TRAIN$CHILD)
    RMS.TRAIN$MOTHER <- as.numeric(RMS.TRAIN$MOTHER)
    RMS.TRAIN.RF     <- RMS.TRAIN
    RF_STACK        <- randomForest(Survived ~ Pclass+
                                    Sex+
                                    Age+
                                    SibSp+
                                    Parch+
                                    Fare+
                                    Embarked+
                                    Title+
                                    CHILD+
                                    MOTHER+
                                    F.SIZE+
                                    F.SIZE.B,
                                  data = data.frame(RMS.TRAIN),
                                  importance = T,
                                  ntree = 1000,
                                  nodesize = 5
                                  )
    PREDICTION.RF_STACK <- data.frame(Survived = predict(RF_STACK, RMS.TRAIN))
    confusionMatrix(PREDICTION.RF_STACK$Survived, RMS.TRAIN$Survived)
    
  }#Randomforest
  {
    {
      RMS.TRAIN <- as.data.frame(cbind(RMS.TOTAL[1:nrow(train),], train$Survived))
      RMS.TEST  <- as.data.frame(RMS.TOTAL[-(1:nrow(train)),])
      colnames(RMS.TRAIN)[colnames(RMS.TRAIN) == "V2"] <- 'Survived'
      RMS.TRAIN.7 <- RMS.TRAIN[1:as.integer(nrow(RMS.TRAIN)*0.7),]
      RMS.TRAIN.3 <- RMS.TRAIN[-(1:as.integer(nrow(RMS.TRAIN)*0.7)),]
    }#05. Split up train and test data
    RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                (sapply(RMS.TRAIN, class) == 'character' &
                   !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))] <-
      data.frame(
        sapply(RMS.TRAIN[, colnames(RMS.TRAIN) == 'Pclass' |
                           (sapply(RMS.TRAIN, class) == 'character' &
                              !(colnames(RMS.TRAIN) %in% c('Name','PassengerId','Ticket','Cabin')))],
               function(x) as.factor(x)
        ))
    RMS.TRAIN$Survived <- as.numeric(RMS.TRAIN$Survived)
    RMS.TRAIN$CHILD    <- as.numeric(RMS.TRAIN$CHILD)
    RMS.TRAIN$MOTHER   <- as.numeric(RMS.TRAIN$MOTHER)
    RMS.TRAIN.LOG      <- RMS.TRAIN
    LOG_STACK          <- glm(formula = Survived ~ .,
                              family = "binomial",
                              data = RMS.TRAIN[,!(colnames(RMS.TRAIN) %in% c("PassengerId", "Name", "Ticket", "Cabin"))])
    PREDICTION.LOG_STACK <- data.frame(Survived = predict(LOG_STACK, 
                                                          RMS.TRAIN[,!(colnames(RMS.TRAIN) %in% c("PassengerId", "Name", "Ticket", "Cabin","Survived"))],
                                                          type = 'response'))
    PREDICTION.LOG_STACK <- data.frame(Survived = as.numeric(PREDICTION.LOG_STACK > 0.5))
    confusionMatrix(PREDICTION.LOG_STACK$Survived, RMS.TRAIN$Survived)
  }#Logistic
  {
    
  }#Naive bayes
  
  {
    k = 10
    set.seed(1007)
    #Run the data preparation codes for each algorithm - mentioned at the beginning of module
    RMS.TRAIN$ID  <- sample(1:k, nrow(RMS.TRAIN), replace = T)
    
    {
      RMS.TRAIN.ENC.F$ID <- RMS.TRAIN$ID
      RMS.TRAIN.ENC$ID   <- RMS.TRAIN$ID
    }#XGBoost
    {
      RMS.TRAIN.RF$ID    <- RMS.TRAIN$ID
    }#Randomforest
    {
      RMS.TRAIN.LOG$ID   <- RMS.TRAIN$ID
    }#Logistic
    {}#Naive bayes
    
    {ERROR.XGB <- numeric()
    ERROR.RF  <- numeric()
    ERROR.LOG <- numeric()
    ERROR.META<- numeric()}#Error objects
    for (i in 1:k){
      
      {XGB.TRAIN.F <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID != i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
      XGB.TEST.F  <- RMS.TRAIN.ENC.F[RMS.TRAIN.ENC.F$ID == i,][,!(colnames(RMS.TRAIN.ENC.F) == "ID")]
      XGB.TRAIN.L <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID != i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
      XGB.TEST.L  <- RMS.TRAIN.ENC[RMS.TRAIN.ENC$ID == i,][,!(colnames(RMS.TRAIN.ENC) == "ID")]
      set.seed(1007)
      XGB_STACK <- xgboost(data = data.matrix(XGB.TRAIN.F),
                           label = XGB.TRAIN.L$Survived,
                           eta = 0.01,
                           max_depth = 3,
                           nround = 2000,
                           seed = 1007,
                           objective = "binary:logistic",
                           nthread = 3,
                           verbose = F
      )
      PREDICT <- predict(XGB_STACK, data.matrix(XGB.TEST.F))
      PREDICT.T <- predict(XGB_STACK, data.matrix(XGB.TRAIN.F))
      confusionMatrix(as.numeric(PREDICT > 0.5), XGB.TEST.L$Survived)
      PREDICTION.XGB_STACK <- data.frame(Survived = as.numeric(PREDICT > 0.5))
      PREDICTION.XGB_STACK.T <- data.frame(Survived = as.numeric(PREDICT.T > 0.5))
      TABLE.XGB = as.matrix(table(PREDICTION.XGB_STACK$Survived, XGB.TEST.L$Survived))
      #print((TABLE.XGB[1,1]+TABLE.XGB[2,2])/(TABLE.XGB[1,1]+TABLE.XGB[2,2]+TABLE.XGB[1,2]+TABLE.XGB[2,1]))
      ERROR.XGB[i] = 1 - (TABLE.XGB[1,1]+TABLE.XGB[2,2])/(TABLE.XGB[1,1]+TABLE.XGB[2,2]+TABLE.XGB[1,2]+TABLE.XGB[2,1])}#XGBoost predictions
      {RF.TRAIN <- RMS.TRAIN.RF[RMS.TRAIN.RF$ID != i,][,!(colnames(RMS.TRAIN.RF) == "ID")]
        RF.TEST  <- RMS.TRAIN.RF[RMS.TRAIN.RF$ID == i,][,!(colnames(RMS.TRAIN.RF) == "ID")]
        RF_STACK        <- randomForest(Survived ~ Pclass+
                                      Sex+
                                      Age+
                                      SibSp+
                                      Parch+
                                      Fare+
                                      Embarked+
                                      Title+
                                      CHILD+
                                      MOTHER+
                                      F.SIZE,
                                    data = data.frame(RF.TRAIN),
                                    importance = T,
                                    ntree = 1000,
                                    #Tuning
                                    #mtry = as.integer(ncol(TRAIN)/2),
                                    nodesize = 15
        )
        PREDICTION.RF_STACK.T <- data.frame(Survived = predict(RF_STACK, RF.TRAIN))
        PREDICTION.RF_STACK <- data.frame(Survived = predict(RF_STACK, RF.TEST))
        table_ = as.matrix(table(PREDICTION.RF_STACK$Survived, RF.TEST$Survived))
        #print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        ERROR.RF[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])}#Randomforest
      {
        LOG.TRAIN <- RMS.TRAIN.LOG[RMS.TRAIN.LOG$ID != i,][,!(colnames(RMS.TRAIN.LOG) == "ID")]
        LOG.TEST  <- RMS.TRAIN.LOG[RMS.TRAIN.LOG$ID == i,][,!(colnames(RMS.TRAIN.LOG) == "ID")]
        LOG_STACK<-  glm(formula = Survived ~ .,
                          family = "binomial",
                          data = LOG.TRAIN[,!(colnames(LOG.TRAIN) %in% c("PassengerId", "Name", "Ticket", "Cabin"))])
        PREDICTION.LOG_STACK.T <- data.frame(Survived = predict(LOG_STACK, 
                                                                LOG.TRAIN[,!(colnames(LOG.TRAIN) %in% c("PassengerId", "Name", "Ticket", "Cabin","Survived"))],
                                                                type = 'response'))
        PREDICTION.LOG_STACK.T <- data.frame(Survived = as.numeric(PREDICTION.LOG_STACK.T > 0.5))
        PREDICTION.LOG_STACK <- data.frame(Survived = predict(LOG_STACK, 
                                                              LOG.TEST[,!(colnames(LOG.TEST) %in% c("PassengerId", "Name", "Ticket", "Cabin","Survived"))],
                                                              type = 'response'))
        PREDICTION.LOG_STACK <- data.frame(Survived = as.numeric(PREDICTION.LOG_STACK > 0.5))
        table_ = as.matrix(table(PREDICTION.LOG_STACK$Survived, LOG.TEST$Survived))
        #print((table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1]))
        ERROR.LOG[i] = 1 - (table_[1,1]+table_[2,2])/(table_[1,1]+table_[2,2]+table_[1,2]+table_[2,1])
      }#Logistic
      {
      COLLATED_PREDICTIONS.TRAIN <- data.frame(PREDICTION.XGB_STACK = PREDICTION.XGB_STACK.T$Survived,
                                               PREDICTION.RF_STACK = PREDICTION.RF_STACK.T$Survived,
                                               PREDICTION.LOG_STACK = PREDICTION.LOG_STACK.T$Survived,
                                               ACTUALS = XGB.TRAIN.L$Survived)
      COLLATED_PREDICTIONS.TRAIN[] <- lapply(COLLATED_PREDICTIONS.TRAIN, as.numeric)
      COLLATED_PREDICTIONS.TRAIN$PREDICTION.RF_STACK <- ifelse(COLLATED_PREDICTIONS.TRAIN$PREDICTION.RF_STACK == 1, 0 , 1)
      COLLATED_PREDICTIONS.TEST <- data.frame(PREDICTION.XGB_STACK = PREDICTION.XGB_STACK$Survived,
                                         PREDICTION.RF_STACK  = PREDICTION.RF_STACK$Survived,
                                         PREDICTION.LOG_STACK = PREDICTION.LOG_STACK$Survived,
                                         ACTUALS              = XGB.TEST.L$Survived)
      COLLATED_PREDICTIONS.TEST[]  <- lapply(COLLATED_PREDICTIONS.TEST, as.numeric)
      COLLATED_PREDICTIONS.TEST$PREDICTION.RF_STACK <- ifelse(COLLATED_PREDICTIONS.TEST$PREDICTION.RF_STACK == 1, 0, 1)

      XGB_META <- xgboost(data = data.matrix(COLLATED_PREDICTIONS.TRAIN[,!(colnames(COLLATED_PREDICTIONS.TRAIN) == "ACTUALS")]),
                          label = COLLATED_PREDICTIONS.TRAIN$ACTUALS,
                          eta = 0.01,
                          max_depth = 3,
                          nrounds = 2000,
                          seed = 1007,
                          objective = 'binary:logistic',
                          nthread = 3,
                          verbose = F)
      PREDICT.META <- predict(XGB_META, data.matrix(COLLATED_PREDICTIONS.TEST[,!(colnames(COLLATED_PREDICTIONS.TEST) == "ACTUALS")]))
      confusionMatrix(as.numeric(PREDICT.META > 0.5), COLLATED_PREDICTIONS.TEST$ACTUALS)
      TABLE.META <- as.matrix(table(as.numeric(PREDICT.META > 0.5), COLLATED_PREDICTIONS.TEST$ACTUALS))
      ERROR.META[i] <- 1 - (TABLE.META[1,1]+TABLE.META[2,2])/(TABLE.META[1,1]+TABLE.META[2,2]+TABLE.META[1,2]+TABLE.META[2,1])
      }#Meta predictions
      
  }
  
    {
      BIAS.XGB <- mean(ERROR.XGB)
      VAR.XGB  <- sd(ERROR.XGB)
      print(paste("XGB | Bias = ", round(BIAS.XGB*100,2), "% & Variance = ", round(VAR.XGB*100,2), "%", sep = ""))
      }#XGBoost bias vs variance
    {
      BIAS.RF <- mean(ERROR.RF)
      VAR.RF  <- sd(ERROR.RF)
      print(paste("RF | Bias = ", round(BIAS.RF*100,2), "% & Variance = ", round(VAR.RF*100,2), "%", sep = ""))
      }#RF bias vs variance
    {
      BIAS.LOG <- mean(ERROR.LOG)
      VAR.LOG  <- sd(ERROR.LOG)
      print(paste("LOG | Bias = ", round(BIAS.LOG*100,2), "% & Variance = ", round(VAR.LOG*100,2), "%", sep = ""))
      }#Logistic bias vs variance
    {}#Naive bayes
    
    {
      BIAS.META <- mean(ERROR.META)
      VAR.META  <- sd(ERROR.META)
      print(paste("META | Bias = ", round(BIAS.META*100,2), "% & Variance = ", round(VAR.META*100,2), "%", sep = ""))
    }#Meta bias vs variance
  
  }#k-fold cross validation on base and stacked model
  
  {
    # There were 20 warnings (use warnings() to see them)
    # >   
    #   >     {
    #     +       BIAS.XGB <- mean(ERROR.XGB)
    #     +       VAR.XGB  <- sd(ERROR.XGB)
    #     +       print(paste("XGB | Bias = ", round(BIAS.XGB*100,2), "% & Variance = ", round(VAR.XGB*100,2), "%", sep = ""))
    #     +       }#XGBoost bias vs variance
    # [1] "XGB | Bias = 17.57% & Variance = 3.55%"
    # >     {
    #   +       BIAS.RF <- mean(ERROR.RF)
    #   +       VAR.RF  <- sd(ERROR.RF)
    #   +       print(paste("RF | Bias = ", round(BIAS.RF*100,2), "% & Variance = ", round(VAR.RF*100,2), "%", sep = ""))
    #   +       }#RF bias vs variance
    # [1] "RF | Bias = 16.96% & Variance = 4.54%"
    # >     {
    #   +       BIAS.LOG <- mean(ERROR.LOG)
    #   +       VAR.LOG  <- sd(ERROR.LOG)
    #   +       print(paste("LOG | Bias = ", round(BIAS.LOG*100,2), "% & Variance = ", round(VAR.LOG*100,2), "%", sep = ""))
    #   +       }#Logistic bias vs variance
    # [1] "LOG | Bias = 16.98% & Variance = 3.76%"
    # >     {}#Naive bayes
    # NULL
    # >     
    #   >     {
    #     +       BIAS.META <- mean(ERROR.META)
    #     +       VAR.META  <- sd(ERROR.META)
    #     +       print(paste("META | Bias = ", round(BIAS.META*100,2), "% & Variance = ", round(VAR.META*100,2), "%", sep = ""))
    #     +     }#Meta bias vs variance
    # [1] "META | Bias = 17.46% & Variance = 3.53%"
    
  }#output
  
}#15. Stacking
