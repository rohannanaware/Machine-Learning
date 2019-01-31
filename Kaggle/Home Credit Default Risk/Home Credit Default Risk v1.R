#########################################################
# Import required libraries
#########################################################

library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
library(grid)

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
application_train <- fread('application_train.csv', header = T, stringsAsFactors = F)

#########################################################
# eda
#########################################################

# group features by data type
table(sapply(application_train, function(x) class(x)))
# character   integer   numeric 
# 16        41        65 
# filter all character columns
# application_train <- data.frame(application_train)
# application_train_character = application_train[,c(as.integer(sapply(application_train, function(x) is.character(x))))]
application_train_character <- application_train %>%
  select_if(is.character)
summary(application_train_character)
# NA count
na_count = round(sapply(application_train_character, function(x) sum(is.na(x)))/nrow(application_train_character)*100, 0)
if (sum(na_count) > 0) {
  print("Columns with NAs")
  print(na_count[na_count > 0])
} else {
  print(paste("NAs absent in", "character type", "features"))
}

application_train_character <- cbind(application_train_character, "TARGET" = application_train$TARGET)

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
