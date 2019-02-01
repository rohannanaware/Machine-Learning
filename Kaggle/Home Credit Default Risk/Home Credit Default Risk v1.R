#########################################################
# Import required libraries
#########################################################

library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(grid)

# library('ggplot2') # visualisation
library('scales') # visualisation
# library('grid') # visualisation
library('ggthemes') # visualisation
library('gridExtra') # visualisation
library('RColorBrewer') # visualisation
library('corrplot') # visualisation

#########################################################
# Reference links
#########################################################

# - Kaggle H | T kernel : https://www.kaggle.com/headsortails/steering-wheel-of-fortune-porto-seguro-eda

#########################################################
# Helper functions
#########################################################

# function to extract binomial confidence levels
get_binCI <- function(x,n) as.list(setNames(binom.test(x,n)$conf.int, c("lwr", "upr")))

# Define multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

#########################################################
# Load data
#########################################################

# get a list of files in input folder
# list.files('../input')
# application_train <- fread('../input/application_train.csv', header = T, stringsAsFactors = F)
application_train <- fread('application_train.csv', header = T, stringsAsFactors = F, na.strings = c("", " ", "NA"))

#########################################################
# eda
#########################################################

# group features by data type
table(sapply(application_train, function(x) class(x)))
# character   integer   numeric 
# 16        41        65 
# filter all character columns
application_train_character <- application_train %>%
  select_if(is.character)
# univariates
summary(application_train_character)
# NA count
na_count = round(sapply(application_train_character, function(x) sum(is.na(x)))/nrow(application_train_character)*100, 0)
if (sum(na_count) > 0) {
  print("Columns with NAs [%]")
  print(na_count[na_count > 0])
} else {
  print(paste("NAs absent in", "character type", "features"))
}
# [1] "Columns with NAs [%]"
#     OCCUPATION_TYPE  FONDKAPREMONT_MODE      HOUSETYPE_MODE  WALLSMATERIAL_MODE EMERGENCYSTATE_MODE 
#                  31                  68                  50                  51                  47 
application_train_character <- cbind(application_train_character, "TARGET" = application_train$TARGET)
{# > colnames(application_train_character)
  p1 <- application_train_character %>%
    group_by(NAME_CONTRACT_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_CONTRACT_TYPE,y = default_rate, fill = NAME_CONTRACT_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p2 <- application_train_character %>%
    group_by(CODE_GENDER,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = CODE_GENDER,y = default_rate, fill = CODE_GENDER)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p3 <- application_train_character %>%
    group_by(FLAG_OWN_CAR,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = FLAG_OWN_CAR,y = default_rate, fill = FLAG_OWN_CAR)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p4 <- application_train_character %>%
    group_by(FLAG_OWN_REALTY,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = FLAG_OWN_REALTY,y = default_rate, fill = FLAG_OWN_REALTY)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p5 <- application_train_character %>%
    group_by(NAME_TYPE_SUITE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_TYPE_SUITE,y = default_rate, fill = NAME_TYPE_SUITE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p6 <- application_train_character %>%
    group_by(NAME_INCOME_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_INCOME_TYPE,y = default_rate, fill = NAME_INCOME_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p7 <- application_train_character %>%
    group_by(NAME_EDUCATION_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_EDUCATION_TYPE,y = default_rate, fill = NAME_EDUCATION_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p8 <- application_train_character %>%
    group_by(NAME_FAMILY_STATUS,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_FAMILY_STATUS,y = default_rate, fill = NAME_FAMILY_STATUS)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p9 <- application_train_character %>%
    group_by(NAME_HOUSING_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = NAME_HOUSING_TYPE,y = default_rate, fill = NAME_HOUSING_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p10 <- application_train_character %>%
    group_by(OCCUPATION_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = OCCUPATION_TYPE,y = default_rate, fill = OCCUPATION_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p11 <- application_train_character %>%
    group_by(WEEKDAY_APPR_PROCESS_START,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = WEEKDAY_APPR_PROCESS_START,y = default_rate, fill = WEEKDAY_APPR_PROCESS_START)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p12 <- application_train_character %>%
    group_by(ORGANIZATION_TYPE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = ORGANIZATION_TYPE,y = default_rate, fill = ORGANIZATION_TYPE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p13 <- application_train_character %>%
    group_by(FONDKAPREMONT_MODE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = FONDKAPREMONT_MODE,y = default_rate, fill = FONDKAPREMONT_MODE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p14 <- application_train_character %>%
    group_by(HOUSETYPE_MODE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = HOUSETYPE_MODE,y = default_rate, fill = HOUSETYPE_MODE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p15 <- application_train_character %>%
    group_by(WALLSMATERIAL_MODE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = WALLSMATERIAL_MODE,y = default_rate, fill = WALLSMATERIAL_MODE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
  
  p16 <- application_train_character %>%
    group_by(EMERGENCYSTATE_MODE,TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})) %>%
    ggplot(aes(x = EMERGENCYSTATE_MODE,y = default_rate, fill = EMERGENCYSTATE_MODE)) +
    theme(legend.position = "none") +
    geom_col() +
    geom_errorbar(aes(ymin = lwr, ymax = upr)) + 
    labs(y = "Default rate [%]")
}# character type plots

call_multiplot <- function() {
  multiplot(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, cols = 4)
}

#########################################################
# findings
#########################################################

# char features
# Contract type revolving loans are less likely to default. 
# Women less likely to default. Interestingly women appear to be inclined marginally more towards Revolving loans.
# People owning a car are less likely to default.
# Owning a reality does not appear to have a significant impact on the default rate.
# 
# Education appears to have a significant impact with the default rate improving with increased education level.
# Civil married and unmarried people have higher likelihood of default.
# 
# Rented apartments appear to have highest default rates. What does housing type mean? - type of existing or of purchased house?
# Low-skill labourers have significantly high default rate. Low-skilled labourers contain 84% males against the sample average of 34%
# 
# Monolithic walled house buyers have lower default rate.

# filter for integer features
application_train_integer = application_train %>%
  select_if(is.integer)
# univariates
summary(application_train_integer)
# NA count
na_count = round(sapply(application_train_integer, function(x) sum(is.na(x)))/nrow(application_train_integer)*100, 0)
if (sum(na_count) > 0) {
  print("Columns with NAs [%]")
  print(na_count[na_count > 0])
} else {
  print(paste("NAs absent in", "numeric type", "features"))
}
sapply(application_train_integer, function(x) length(unique(x)))[sapply(application_train_integer, function(x) length(unique(x))) > 3]
# filtering for integer features with <= 5 levels
application_train_integer_flags <- application_train_integer %>%
      select_if(sapply(application_train_integer, function(x) length(unique(x))) <= 5)
colnames(application_train_integer_flags)
# > colnames(application_train_integer_flags)
{

  
  p1 <- application_train_integer_flags %>%
    group_by(FLAG_MOBIL, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_MOBIL, y = default_rate, fill = FLAG_MOBIL)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p2 <- application_train_integer_flags %>%
    group_by(FLAG_EMP_PHONE, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_EMP_PHONE, y = default_rate, fill = FLAG_EMP_PHONE)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
    
  p3 <- application_train_integer_flags %>%
    group_by(FLAG_WORK_PHONE, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_WORK_PHONE, y = default_rate, fill = FLAG_WORK_PHONE)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p4 <- application_train_integer_flags %>%
    group_by(FLAG_CONT_MOBILE, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_CONT_MOBILE, y = default_rate, fill = FLAG_CONT_MOBILE)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p5 <- application_train_integer_flags %>%
    group_by(FLAG_PHONE, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_PHONE, y = default_rate, fill = FLAG_PHONE)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p6 <- application_train_integer_flags %>%
    group_by(FLAG_EMAIL, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_EMAIL, y = default_rate, fill = FLAG_EMAIL)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p7 <- application_train_integer_flags %>%
    group_by(REGION_RATING_CLIENT, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REGION_RATING_CLIENT, y = default_rate, fill = REGION_RATING_CLIENT)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")

  p8 <- application_train_integer_flags %>%
    group_by(REGION_RATING_CLIENT_W_CITY, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REGION_RATING_CLIENT_W_CITY, y = default_rate, fill = REGION_RATING_CLIENT_W_CITY)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p9 <- application_train_integer_flags %>%
    group_by(REG_REGION_NOT_LIVE_REGION, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REG_REGION_NOT_LIVE_REGION, y = default_rate, fill = REG_REGION_NOT_LIVE_REGION)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p10 <- application_train_integer_flags %>%
    group_by(REG_REGION_NOT_WORK_REGION, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REG_REGION_NOT_WORK_REGION, y = default_rate, fill = REG_REGION_NOT_WORK_REGION)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
              
  p11 <- application_train_integer_flags %>%
    group_by(LIVE_REGION_NOT_WORK_REGION, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = LIVE_REGION_NOT_WORK_REGION, y = default_rate, fill = LIVE_REGION_NOT_WORK_REGION)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                
  p12 <- application_train_integer_flags %>%
    group_by(REG_CITY_NOT_LIVE_CITY, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REG_CITY_NOT_LIVE_CITY, y = default_rate, fill = REG_CITY_NOT_LIVE_CITY)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                  
  p13 <- application_train_integer_flags %>%
    group_by(REG_CITY_NOT_WORK_CITY, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = REG_CITY_NOT_WORK_CITY, y = default_rate, fill = REG_CITY_NOT_WORK_CITY)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                    
  p14 <- application_train_integer_flags %>%
    group_by(LIVE_CITY_NOT_WORK_CITY, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = LIVE_CITY_NOT_WORK_CITY, y = default_rate, fill = LIVE_CITY_NOT_WORK_CITY)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                      
  p15 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_2, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_2, y = default_rate, fill = FLAG_DOCUMENT_2)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                        
  p16 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_3, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_3, y = default_rate, fill = FLAG_DOCUMENT_3)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
}# integer dtype - levels less than 6 - 1 
{
    p1 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_4, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_4, y = default_rate, fill = FLAG_DOCUMENT_4)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p2 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_5, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_5, y = default_rate, fill = FLAG_DOCUMENT_5)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
    
  p3 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_6, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_6, y = default_rate, fill = FLAG_DOCUMENT_6)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p4 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_7, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_7, y = default_rate, fill = FLAG_DOCUMENT_7)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
     
  p5 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_8, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_8, y = default_rate, fill = FLAG_DOCUMENT_8)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p6 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_9, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_9, y = default_rate, fill = FLAG_DOCUMENT_9)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
      
  p7 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_10, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_10, y = default_rate, fill = FLAG_DOCUMENT_10)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")

  p8 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_11, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_11, y = default_rate, fill = FLAG_DOCUMENT_11)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p9 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_12, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_12, y = default_rate, fill = FLAG_DOCUMENT_12)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  p10 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_13, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_13, y = default_rate, fill = FLAG_DOCUMENT_13)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
             
  p11 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_14, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_14, y = default_rate, fill = FLAG_DOCUMENT_14)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                
  p12 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_15, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_15, y = default_rate, fill = FLAG_DOCUMENT_15)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                  
  p13 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_16, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_16, y = default_rate, fill = FLAG_DOCUMENT_16)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                    
  p14 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_17, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_17, y = default_rate, fill = FLAG_DOCUMENT_17)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                      
  p15 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_18, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_18, y = default_rate, fill = FLAG_DOCUMENT_18)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
                        
  p16 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_19, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_19, y = default_rate, fill = FLAG_DOCUMENT_19)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
    p17 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_20, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_20, y = default_rate, fill = FLAG_DOCUMENT_20)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
    
  p18 <- application_train_integer_flags %>%
    group_by(FLAG_DOCUMENT_21, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(default_rate = `1`/(`1` + `0`)*100,
           lwr = tryCatch(get_binCI(`1`,(`1`+`0`))[[1]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0}),
           upr = tryCatch(get_binCI(`1`,(`1`+`0`))[[2]]*100,
                          warning = function(w) {0},
                          error   = function(e) {0})
           ) %>%
    ggplot(aes(x = FLAG_DOCUMENT_21, y = default_rate, fill = FLAG_DOCUMENT_21)) +
    theme(legend.position = "none") +
    geom_point(color = "blue") +
    geom_errorbar(aes(ymin = lwr, ymax = upr), color = "blue") +
    labs(y = "Default rate [%]")
  
  multiplot(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, cols = 4)
}# integer dtype - levels less than 6 - 2
application_train_integer_flags <- application_train_integer %>%
      select_if(!(sapply(application_train_integer, function(x) length(unique(x))) <= 5))
application_train_integer_flags$SK_ID_CURR <- NULL
application_train_integer_flags <- cbind(application_train_integer_flags, "TARGET" = application_train$TARGET)
application_train_integer_flags$TARGET <- as.factor(application_train_integer_flags$TARGET)
colnames(application_train_integer_flags)
# [1] "CNT_CHILDREN"            "DAYS_BIRTH"              ""           ""        
# [5] "" "TARGET"   
{
  p1 <- application_train_integer_flags %>%
    ggplot(aes(CNT_CHILDREN, fill = TARGET)) +
    geom_density(alpha = 0.5, bw = 0.4) +
    xlim(0, 3)
  
  p2 <- application_train_integer_flags %>%
    ggplot(aes(DAYS_BIRTH, fill = TARGET)) +
    geom_density(alpha = 0.5, bw = 0.4)
  
  p3 <- application_train_integer_flags %>%
    ggplot(aes(DAYS_EMPLOYED, fill = TARGET)) +
    geom_density(alpha = 0.5, bw = 0.4) + 
    xlim(-17912, 0)

  p4 <- application_train_integer_flags %>%
    ggplot(aes(DAYS_ID_PUBLISH, fill = TARGET)) +
    geom_density(alpha = 0.5, bw = 1)

  p5 <- application_train_integer_flags %>%
    ggplot(aes(HOUR_APPR_PROCESS_START, fill = TARGET)) +
    geom_density(alpha = 0.5, bw = 0.4)
  
  multiplot(p1, p2, p3, p4, p5, cols = 3)
  
}# integer dtype - levels more than 5 : convert the TARGET variable into factor

#########################################################
# findings
#########################################################

# sig factors : FLAG_EMP_PHONE, FLAG_WORK_PHONE, FLAG_PHONE, REGION_RATING_CLIENT_W_CITY, REGION_RATING_CLIENT_W_CITY,
#               REG_CITY_NOT_LIVE_CITY, REG_CITY_NOT_WORK_CITY, LIVE_CITY_NOT_WORK_CITY, FLAG_DOCUMENT_3,
#               FLAG_DOCUMENT_6, FLAG_DOCUMENT_13, FLAG_DOCUMENT_14, FLAG_DOCUMENT_15, FLAG_DOCUMENT_16,
#               FLAG_DOCUMENT_18, DAYS_BIRTH, DAYS_EMPLOYED, DAYS_ID_PUBLISH
# outlier treatment required for CNT_CHILDREN, DAYS_EMPLOYED

# filter for numeric features
application_train_numeric <- application_train %>%
  select_if(sapply(application_train, function(x) class(x)) == "numeric")
na_count = round(sapply(application_train_numeric, function(x) sum(is.na(x)))/nrow(application_train_numeric)*100, 0)
if (sum(na_count) > 0) {
  print("Columns with NAs [%]")
  print(na_count[na_count > 0])
} else {
  print(paste("NAs absent in", "numeric type", "features"))
}
application_train_numeric_na <- application_train_numeric %>%
  select_if(sapply(application_train_numeric, function(x) sum(is.na(x))/nrow(application_train) <= 0.2))
summary(application_train_numeric_na)
# > colnames(application_train_numeric_na)
# [1] ""           ""                 ""                ""           
# [5] "" "DAYS_REGISTRATION"          "CNT_FAM_MEMBERS"            "EXT_SOURCE_2"              
# [9] "EXT_SOURCE_3"               "OBS_30_CNT_SOCIAL_CIRCLE"   "DEF_30_CNT_SOCIAL_CIRCLE"   "OBS_60_CNT_SOCIAL_CIRCLE"  
# [13] "DEF_60_CNT_SOCIAL_CIRCLE"   "DAYS_LAST_PHONE_CHANGE"     "AMT_REQ_CREDIT_BUREAU_HOUR" "AMT_REQ_CREDIT_BUREAU_DAY" 
# [17] "AMT_REQ_CREDIT_BUREAU_WEEK" "AMT_REQ_CREDIT_BUREAU_MON"  "AMT_REQ_CREDIT_BUREAU_QRT"  "AMT_REQ_CREDIT_BUREAU_YEAR"

{

  application_train_numeric_na <- cbind(application_train_numeric_na, "TARGET" = application_train$TARGET)  

  p1 <- application_train_numeric_na %>%
    ggplot(aes(x = AMT_INCOME_TOTAL, fill = TARGET)) +
    # geom_density(alpha = 0.5, bw = 0.4) + 
    geom_histogram(bins = 30) +
    xlim(quantile(application_train_numeric_na$AMT_INCOME_TOTAL, probs = 0.05, na.rm = T), 
         quantile(application_train_numeric_na$AMT_INCOME_TOTAL, probs = 0.95, na.rm = T))
  
  p2 <- application_train_numeric_na %>%
    ggplot(aes(x = AMT_CREDIT, fill = TARGET)) +
    # geom_density(alpha = 0.5, bw = 0.4) + 
    geom_histogram(bins = 30) +
    xlim(quantile(application_train_numeric_na$AMT_CREDIT, probs = 0.05, na.rm = T), 
         quantile(application_train_numeric_na$AMT_CREDIT, probs = 0.95, na.rm = T))
  
  p3 <- application_train_numeric_na %>%
    ggplot(aes(x = AMT_ANNUITY, fill = TARGET)) +
    # geom_density(alpha = 0.5, bw = 0.4) + 
    geom_histogram(bins = 30) +
    xlim(quantile(application_train_numeric_na$AMT_ANNUITY, probs = 0.05, na.rm = T), 
         quantile(application_train_numeric_na$AMT_ANNUITY, probs = 0.95, na.rm = T))
  
  p4 <- application_train_numeric_na %>%
    ggplot(aes(x = AMT_GOODS_PRICE, fill = TARGET)) +
    # geom_density(alpha = 0.5, bw = 0.4) + 
    geom_histogram(bins = 30) +
    xlim(quantile(application_train_numeric_na$AMT_GOODS_PRICE, probs = 0.05, na.rm = T), 
         quantile(application_train_numeric_na$AMT_GOODS_PRICE, probs = 0.95, na.rm = T))
  
  p5 <- application_train_numeric_na %>%
    ggplot(aes(x = REGION_POPULATION_RELATIVE, fill = TARGET)) +
    # geom_density(alpha = 0.5, bw = 0.4) + 
    geom_histogram(bins = 30) +
    xlim(quantile(application_train_numeric_na$REGION_POPULATION_RELATIVE, probs = 0.05, na.rm = T), 
         quantile(application_train_numeric_na$REGION_POPULATION_RELATIVE, probs = 0.95, na.rm = T))
  
  multiplot(p1, p2, p3, p4, p5, cols = 3)
  
  application_train_numeric_na %>%
    ggplot(aes(x = TARGET, y = AMT_GOODS_PRICE)) +
    geom_boxplot()
}# float features : NA% <= 20 - wip

#########################################################
# wip - eda automation
#########################################################

{
  for (column in colnames(application_train_character)[1:ncol(application_train_character) - 1]) {
    
    assign(paste0("plot_", "char_", column), eval(parse(text = paste("application_train_character %>%
                                                                     group_by(" , column , ",TARGET) %>%
                                                                     count() %>%
                                                                     spread(TARGET, n) %>%
                                                                     mutate(default_rate = `1`/(`1` + `0`)*100,
                                                                     lwr = tryCatch(get_binCI(`1`, (`1` + `0`))[[1]]*100,
                                                                     warning = function(w) {0},
                                                                     error   = function(e) {0}),
                                                                     upr = tryCatch(get_binCI(`1`, (`1` + `0`))[[2]]*100,
                                                                     warning = function(w) {0},
                                                                     error   = function(e) {0})) %>%
                                                                     ggplot(aes(x =",column , ", y = default_rate, fill =" , column , paste0(")) +
                                                                                                                                             # theme(legend.position = ", "none", ") +
                                                                                                                                             geom_col()
                                                                                                                                             # + geom_errorbar(aes(ymin = lwr, ymax = upr))"
                                                                                                                                             # + labs(y = ","Default rate [%]",")"
    )))))
  }
  
  multiplt_text = "multiplot("
  for (plot in unlist(ls()[as.numeric(lapply(ls(), function(x) grep("plot_", x))) == 1])) {
    if(!is.na(plot)){
      # print(plot)
      multiplt_text = paste0(multiplt_text, plot, ",")
    }
  }
  multiplt_text <- paste0(substr(multiplt_text, 1, nchar(multiplt_text) - 1), ", cols = 4)")
  eval(parse(text = multiplt_text))
} # facing error while multiplotting
