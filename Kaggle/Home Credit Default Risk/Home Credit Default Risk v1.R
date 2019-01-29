#########################################################
# Import required libraries
#########################################################
library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)

#########################################################
# Reference links
#########################################################

# - Kaggle HorT kernel : https://www.kaggle.com/headsortails/steering-wheel-of-fortune-porto-seguro-eda

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

list.files('../input/')

# [1] "application_test.csv" "application_train.csv" [3] "bureau_balance.csv" "bureau.csv" [5] "credit_card_balance.csv" "installments_payments.csv" [7] "POS_CASH_balance.csv" "previous_application.csv" [9] "sample_submission.csv"

application_train <- fread('../input/application_train.csv', header = T, stringsAsFactors = F)

# Univariates
table(application_train$TARGET)
# Overall default rate ~8%

# Bivariates

## Categorical features

# NAME_CONTRACT_TYPE
p1 = application_train %>%
    group_by(NAME_CONTRACT_TYPE, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(frac_def = `1`/(`1`+`0`)*100,
            lwr = get_binCI(`1`,(`1`+`0`))[[1]]*100,
            upr = get_binCI(`1`,(`1`+`0`))[[2]]*100
            ) %>%
    ggplot(aes(NAME_CONTRACT_TYPE, frac_def, fill = NAME_CONTRACT_TYPE)) + 
    geom_col() + 
    geom_errorbar(aes(ymin = lwr, ymax = upr), width = 0.5, size = 0.7, color = 'gray30') + 
    theme(legend.position = "none") + labs(y = 'Default rate [%]')
# Cash loans have higher chance of default

# CODE_GENDER
p2 = application_train %>%
    group_by(CODE_GENDER, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(frac_def = `1`/(`1`+`0`)*100
            # lwr = get_binCI(`1`,(`1`+`0`))[[1]]*100
            # upr = get_binCI(`1`,(`1`+`0`))[[2]]*100
            ) %>%
    ggplot(aes(CODE_GENDER, frac_def, fill = CODE_GENDER)) + 
    geom_col()
    #geom_errorbar(aes(ymin = lwr, ymax = upr), width = 0.5, size = 0.7, color = 'gray30') + 
    theme(legend.position = "none") + labs(y = 'Default rate [%]')
# Males have a higher propensity to default

# FLAG_OWN_CAR
p3 = application_train %>%
    group_by(FLAG_OWN_CAR, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(frac_def = `1`/(`1`+`0`)*100,
            lwr = get_binCI(`1`,(`1`+`0`))[[1]]*100,
            upr = get_binCI(`1`,(`1`+`0`))[[2]]*100
            ) %>%
    ggplot(aes(FLAG_OWN_CAR, frac_def, fill = FLAG_OWN_CAR)) + 
    geom_col() + 
    geom_errorbar(aes(ymin = lwr, ymax = upr), width = 0.5, size = 0.7, color = 'gray30') + 
    theme(legend.position = "none") + labs(y = 'Default rate [%]')
# People owning a car have a lower rate of default

# FLAG_OWN_REALTY
p4 = application_train %>%
    group_by(FLAG_OWN_REALTY, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(frac_def = `1`/(`1`+`0`)*100,
            lwr = get_binCI(`1`,(`1`+`0`))[[1]]*100,
            upr = get_binCI(`1`,(`1`+`0`))[[2]]*100
            ) %>%
    ggplot(aes(FLAG_OWN_REALTY, frac_def, fill = FLAG_OWN_REALTY)) + 
    geom_col() + 
    geom_errorbar(aes(ymin = lwr, ymax = upr), width = 0.5, size = 0.7, color = 'gray30') + 
    theme(legend.position = "none") + labs(y = 'Default rate [%]')
# People owning realty have slightly lower default rate

# Integer features

# CNT_CHILDREN
p5 = application_train %>%
    mutate(CNT_CHILDREN = ifelse(CNT_CHILDREN < 5, CNT_CHILDREN, 5)) %>%
    group_by(CNT_CHILDREN, TARGET) %>%
    count() %>%
    spread(TARGET, n) %>%
    mutate(frac_def = `1`/(`1`+`0`)*100
            #lwr = get_binCI(`1`,(`1`+`0`))[[1]]*100,
            #upr = get_binCI(`1`,(`1`+`0`))[[2]]*100
            ) %>%
    ggplot(aes(CNT_CHILDREN, frac_def)) + 
    geom_point() + 
    #geom_errorbar(aes(ymin = lwr, ymax = upr), width = 0.5, size = 0.7, color = 'gray30') + 
    theme(legend.position = "none") + labs(y = 'Default rate [%]')
table(application_train$CNT_CHILDREN)
# Default rte is observed to increase with increasing children

# Float features

# AMT_INCOME_TOTAL

application_train$AMT_INCOME_TOTAL = ifelse(application_train$AMT_INCOME_TOTAL < quantile(application_train$AMT_INCOME_TOTAL, 0.01),
                                            quantile(application_train$AMT_INCOME_TOTAL, 0.01),
                                            ifelse(application_train$AMT_INCOME_TOTAL > quantile(application_train$AMT_INCOME_TOTAL, 0.99),
                                                   quantile(application_train$AMT_INCOME_TOTAL, 0.99),
                                                   application_train$AMT_INCOME_TOTAL))

p6 = application_train %>%
    ggplot(aes(AMT_INCOME_TOTAL, fill = TARGET)) +
    geom_density(alpha = 1, bw = 0.01) + 
    theme(legend.position = "none")
    
    AMT_CREDIT
application_train %>%
    ggplot(aes(AMT_CREDIT, fill = TARGET)) +
    geom_density(alpha = 1, bw = 0.1) + 
    theme(legend.position = "none")
    
application_train %>%

  ggplot(aes(AMT_CREDIT, fill = TARGET)) +

  geom_density(alpha = 0.5, bw = 0.05) +

  theme(legend.position = "none")
