### This report aims at covering the list of hypotheses that can be tested on the Titanic dataset which will be presented in the form of exploratory data analysis. The results from EDA will be used for enginnering further features which will get fed into modelling phase
### Please let me know comments/suggestions for further improvement

# load required libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(mice)
library(VIM)
library(ggplot2)
library(stats)
library(missForest)
library(caret)
library(tidyr)

# load data
train <- fread('../input/train.csv', header = T, stringsAsFactors = F, na.strings = c("", "NA"))
test  <- fread('../input/test.csv', header = T, stringsAsFactors = F, na.strings = c("", "NA"))

# data checks
print(paste('Total rows in train data ', nrow(train)))
print(paste('Rows in train data with NAs', sum(!complete.cases(train))))
print('# NAs by colum names #')
sapply(train, function(x) sum(is.na(x)))
# Age column has ~177 NAs, EMbarked has 2 and Cabin 687, will need to impute via mean/median or by prediction
# head(train[is.na(train$Age)])
print(paste('Total rows in test data ', nrow(test)))
print(paste('Rows in test data with NAs', sum(!complete.cases(test))))
print('# NAs by colum names #')
sapply(test, function(x) sum(is.na(x)))
# Age has 86 entries of NAs, Fare has 1 entry of NA and Cabin has 327

# NA imputation - ref. https://www.analyticsvidhya.com/blog/2016/03/tutorial-powerful-packages-imputing-missing-values/
## Visualizing the distribution of NAs in data
missing_values <- aggr(train, col = c('navyblue','yellow'),
                        labels = names(train), numbers = T,
                        ylab = c('Missing data', 'Pattern'))
## We will be using missForest technique to impute the NAs in Age
p1 <- train %>%
        ggplot(aes(Age, fill = Age)) + geom_histogram()
p1
quantile(train$Age, probs = seq(0, 1, 0.25), na.rm = T)
#   0%    25%    50%    75%   100% 
#  0.420 20.125 28.000 38.000 80.000
# convert character to factor
# train <- as.data.frame(unclass(train))
train <- as.data.frame(train)
train[sapply(train, is.character)] <- lapply(train[sapply(train, is.character)], as.factor)
train_sub <- train[!(colnames(train) %in% c("PassengerId", "Name", "Ticket", "Cabin"))]
train_sub <- train_sub %>%
            missForest(ntree = 500, mtry = 2)
train_sub$ximp
train_sub$OOBerror
# NRMSE       PFC 
# 0.1882002 0.1186727
# combining the imputed values with the filtered out fields
train <- cbind(train[colnames(train) %in% c("PassengerId", "Name", "Ticket", "Cabin")],
                train_sub$ximp)
quantile(train$Age, probs = seq(0, 1, 0.25), na.rm = T)# 
#   0%    25%    50%    75%   100% 
#  0.420 20.125 28.000 38.000 80.000
 # 0.420 21.000 29.000 36.715 80.000 : some change in the quantile distribution is observed post imputation

# Imputing the test data
test <- as.data.frame(test)
test[sapply(test, is.character)] <- lapply(test[sapply(test, is.character)], as.factor)
test_sub <- test[!(colnames(test) %in% c("PassengerId", "Name", "Ticket", "Cabin"))]
test_sub <- test_sub %>%
            missForest()
#test_sub$ximp
test_sub$OOBerror # very high error rate - could it be due to the lower observations available?
test <- cbind(test[colnames(test) %in% c("PassengerId", "Name", "Ticket", "Cabin")],
                test_sub$ximp)
# Train a random forest model
train$Survived <- as.factor(train$Survived)
rf <- randomForest(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked,
                    data = train,
                    ntree = 100,
                    mtry = 2)
print(rf)

# Exploratory Data Analysis followed by Feature Engineering

# Features in data #
# PassengerID - Identifier. to be removed
# Name - Extract title(Mr, Mrs etc) to perform some EDA), combine people with similar surnames
# Ticket - Total 681 unique values - check if the letters in the ticket mean anything(CA, PC, A5)
# Cabin - Contains ~687 NAs - either remove or check if it has any relation with the ticket column
# Pclass - Class of the ticket : check if there are any deepdives on Fare within class and it's effect on Survival
# Sex - Female with higher likelihood to survive - check split by Age within Gender : Married vs. Unmarried and Family size
# Age - Young more likely to survive
# SibSp - Use to calcualte family size : check if surname can play a role here
# Parch - Use to calcualte family size : check if surname can play a role here
# Fare - Males opting for non-premium less likely to survive
# Embarked - Effect point of Embark

# Feature engineering ideas #
# Family size
# Title
# Surname : Important families

# Categorical features

# Title - correlated with Gender
train$Title <- gsub('(.*, )|(\\..*)', '', train$Name)
table(train$Title, train$Sex)# classify the titles into median titles
train$Title[train$Title %in% c('Capt', 'Col', 'Don','Dr','Jonkheer','Major','Rev','Sir')] <- 'Mr'
train$Title[train$Title %in% c('Mlle', 'Ms')] <- 'Miss'
train$Title[train$Title %in% c('Mme','the Countess','Lady')] <- 'Mrs'
train %>% ggplot(aes(x = Title, fill = Title)) + geom_bar()
train %>% group_by(Title, Survived) %>%
            count() %>%
            spread(Survived, n) %>%
            mutate(frac_survived = `1`/(`1`+`0`)*100) %>%
            ggplot(aes(Title, frac_survived, fill = Title)) + geom_col() + labs('Survival rate')
# Lower survival rate in males - male children had lower survival rate than women

# Passenger class - Pclass
train %>% ggplot(aes(x = Pclass, fill = Pclass)) + geom_bar()
train %>% group_by(Pclass, Survived) %>%
            count() %>%
            spread(Survived, n) %>%
            mutate(frac_survived = `1`/(`1`+`0`)) %>%
            ggplot(aes(x = Pclass, y = frac_survived, fill = Pclass)) + geom_col() + labs('Survival rate')
# passenger class has an effect on survival rate

# Sex
train %>% ggplot(aes(Sex, fill = Sex)) + geom_bar()
train %>% group_by(Sex, Survived) %>%
            count() %>%
            spread(Survived, n) %>%
            mutate(frac_survived = `1`/(`1`+`0`)) %>%
            ggplot(aes(x = Sex, y = frac_survived, fill = Sex)) + geom_col() + labs('Survival rate')
# Feamles more likely to survive

# Age
train %>% ggplot(aes(x = Age, fill = Survived)) + geom_histogram(bins = 10)
train %>% ggplot(aes(x = Age, fill = Survived)) + 
            geom_density(alpha = 0.5, bw = 0.01) + 
            theme(legend.position = "none")
quantile(train$Age, probs = c(0.05, seq(0, 1, 0.1), 0.95))# need not trim
# Sibsp
train %>% ggplot(aes(x = SibSp, fill = SibSp)) + geom_histogram(bins = 10) # trim outliers
quantile(train$
### Density plots not working out...





            
            


# Submissions
# 1. predicting that everyone dies
submission <- data.frame(`PassengerId` = test$PassengerId,
                        `Survived` = 0)
write.csv(submission, 'submission.csv', row.names = F) # Score - 0.62679
# 2. predicting that only male above age 5 die
submission <- data.frame(`PassengerId` = test$PassengerId,
                        `Survived` = ifelse(test$Sex == "male" & test$Age > 5 & !is.na(test$Age), 0, 1))
write.csv(submission, 'submission.csv', row.names = F) # Score - 0.65550
# 3. randomForest model no feature engineering
submission <- data.frame(`PassengerId` = test$PassengerId,
                        `Survived` = predict(rf, test))
write.csv(submission, 'submission.csv', row.names = F) # Score - 0.75119
