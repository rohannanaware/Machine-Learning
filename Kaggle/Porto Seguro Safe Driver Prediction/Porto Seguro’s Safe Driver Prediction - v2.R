## load packages
library(data.table)
library(dplyr)
library(ggplot2)
library(tidyr)
library(corrplot)

## load data
train <- fread('../input/train.csv', header = T, stringsAsFactors = F, na.strings=c("-1","-1.0"))
test <- fread('../input/test.csv', header = T, stringsAsFactors = F, na.strings=c("-1","-1.0"))

train <- train %>% 
        mutate_at(vars(ends_with("cat")), funs(as.factor)) %>%
        mutate_at(vars(ends_with("bin")), funs(as.logical)) %>%
        mutate(target = as.factor(target))
test  <- test %>%
        mutate_at(vars(ends_with("cat")), funs(as.factor)) %>%
        mutate_at(vars(ends_with("bin")), funs(as.logical))
        
combined_data <- bind_rows(train %>% mutate(dset = "train"),
                            test %>% mutate(dset = "test",
                                            target = NA))

## plots : Individual features
p1 <- train %>% ggplot(aes(ps_ind_06_bin, fill = ps_ind_06_bin)) + geom_bar() ## binary feature
p2 <- train %>% ggplot(aes(ps_ind_02_cat, fill = ps_ind_02_cat)) + geom_bar() + scale_y_log10()## categorical feature
p3 <- train %>% mutate(ps_ind_01 = as.factor(ps_ind_01)) %>% ggplot(aes(ps_ind_01, fill = ps_ind_01)) + geom_bar() ## integer features
p4 <- train %>% ggplot(aes(ps_reg_01, fill = ps_reg_01)) + geom_histogram(fill = "dark green", binwidth = 0.1) ## float features
p5 <- train %>% ggplot(aes(target, fill = target)) + geom_bar()

## plots : Claim rates by features
p6 <- train %>% 
        group_by(ps_ind_06_bin, target) %>%
        count() %>%
        spread(target, n) %>%
        mutate(frac_claims = `1`/(`1`+`0`)*100) %>%
        ggplot(aes(ps_ind_06_bin, frac_claims, fill = ps_ind_06_bin)) + geom_col() + 
        labs(y = "Claim %")## binary features
p7 <- train %>%
        group_by(ps_ind_02_cat, target) %>%
        count() %>%
        spread(target, n) %>%
        mutate(frac_claims = `1`/(`1`+`0`)*100) %>%
        ggplot(aes(ps_ind_02_cat, frac_claims, fill = ps_ind_02_cat)) + geom_col() +
        labs(y = "Claim %")## categorical features
p8 <- train %>%
        group_by(ps_ind_01, target) %>%
        count() %>%
        spread(target, n) %>%
        mutate(frac_claims = `1`/(`1`+`0`)*100) %>%
        ggplot(aes(ps_ind_01, frac_claims, fill = ps_ind_01)) + geom_point()
        labs(y = "Claim %")## integer features
p9 <- train %>%
        ggplot(aes(ps_reg_01, fill = target)) + 
        #geom_density() +   
        geom_density(alpha = 0.5, bw = 0.05) +
        theme(legend.position = "none")## float features
        
# plot : Correlation matrix
p10 <- train %>%
        select(-starts_with("ps_calc"), -ps_ind_10_bin, -ps_ind_11_bin, -ps_car_10_cat, -id) %>%
        mutate_at(vars(ends_with("cat")), funs(as.integer)) %>%
        mutate_at(vars(ends_with("bin")), funs(as.integer)) %>%
        mutate(target = as.integer(target)) %>%
        cor(use="complete.obs", method="spearman") %>%
        corrplot(type = "lower", tl.col = "black", diag = False)

p10 <- train %>%
        select(-starts_with("ps_calc"), -ps_ind_10_bin, -ps_ind_11_bin, -ps_car_10_cat, -id) %>%
        mutate_at(vars(ends_with("cat")), funs(as.integer)) %>%
        mutate_at(vars(ends_with("bin")), funs(as.integer)) %>%
        mutate(target = as.integer(target)) %>%
        cor(use="complete.obs", method = "spearman") %>%
        corrplot(type="lower",tl.col="black",diag=F)
