# Author : Rohan M. Nanaware
# Date C.: 15th Mar 2019
# Date M.: 15th Mar 2019
# Purpose: Driver analysis for Pick to Dispatch time
# Updates:
# 15th Mar 2019 : overall variability check
# 16th Mar 2019 : findings from overall check and fc deepdive
# 18th Apr 2019 : comparing the p995 of p2d by warehouse against the design numbers
# 16th May 2019 : variance analysis on latest data - need to test the inventory related hyp.

#################################################################
# import required libraries
#################################################################

library(data.table)
library(dplyr)
library(tidyr)
library(ggplot2)
# install.packages("readxl",dependencies = T)
library(readxl)

#################################################################
# import data
#################################################################

setwd("~/FC-analytics/09 P2D variance")
# input_data <- fread('input_data.csv',header = T,stringsAsFactors = F,na.strings = c("NULL","","NA"))
# added details on the time taken for packaging : qc completed to ibl generated
input_data <- fread('input_data_v2.csv',header = T,stringsAsFactors = F,na.strings = c("NULL","","NA"))
input_data <- fread('input_data_v3__201904181339.csv',header = T,stringsAsFactors = F,na.strings = c("NULL","","NA"))
input_data <- fread('input_data_v5.csv',header = T,
                    stringsAsFactors = F,
                    na.strings = c("NULL","","NA"))
inventory_data <- fread('inventory_data.csv',header = T,stringsAsFactors = F,na.strings = c("NULL","","NA"))
desgin_lead_time <- read_xlsx('p2d_fc_lvl_design_nos.xlsx',sheet = 'reference')
input_data_backup <- input_data

#################################################################
# data cleaning
#################################################################

nrow(input_data)
sapply(input_data, function(x) sum(is.na(x)))
# storage_location_capacity, storage_location_available_capacity have 100% NULL values
# picklist_completed_timestamp has 299 NULL values
# packing_box_used_length,b,h have 2% NULL values
# picklist_completed_by has 2k NULL values
# removing all columns with 100% NULLs
input_data$storage_location_capacity <- NULL
input_data$storage_location_available_capacity <- NULL
# treating unproductive time column
input_data$unproductive_time[is.na(input_data$unproductive_time)] <- 0
# converting unproductive time to minutes
input_data$unproductive_time <- input_data$unproductive_time/60
quantile(input_data$unproductive_time,probs = seq(0,1,0.1))
# removing outlier values of unproductive time
input_data <- input_data %>%
  filter(unproductive_time < quantile(input_data$unproductive_time, probs = 0.999))
# correlation of unproductive time with p2d
input_data %>%
  filter(unproductive_time != 0) %>%
  ggplot(aes(x=unproductive_time,y=p2d_minutes)) +
  geom_point()
# removing all rows with at least one null
input_data <- input_data[complete.cases(input_data)]
colnames(input_data)
# summary of all time difference columns
input_data %>% 
  select(colnames(input_data)[grep("minutes",colnames(input_data))]) %>%
  summary()
# summary of uproductive time
quantile(input_data$unproductive_time, probs = seq(0,1,0.01))
# needs outlier treatmet 
#   - very high unproductive hours value observed - need to verify sanity of mdm data
# removing cases where time differences are <= 0
input_data <- input_data[p2pc_minutes > 0 &
                           stg_minutes > 0 &
                           pkg_minutes >= 0 & # most values are 0 - proxy for pkg time not accurate
                           cny_minutes > 0 &
                           p2d_minutes > 0 &
                           p2dbd_minutes > 0]
input_data <- input_data %>%
  mutate(rfb_flag = ifelse(regexpr("refurbished",product_detail_cms_vertical) != -1,
                           1,
                           0)) %>%
  filter(rfb_flag == 0) %>%
  select(-c(rfb_flag))
# is unproductive time correlated with high p2d times?
input_data %>%
  filter(unproductive_time <= 2000) %>%
  sample_n(100000,replace=F) %>%
  ggplot(aes(x=unproductive_time,y=p2d_minutes)) +
  geom_point()+
  scale_y_continuous(breaks = seq(0,200,10)) + 
  stat_summary(fun.data = boxes, geom = 'boxplot')

boxes <- function(x) {
  r <- quantile(x, probs = c(0.01, 0.05, 0.5, 0.95, 0.99))
  names(r) <- c("ymin", "lower", "middle", "upper", "ymax")
  r
}

#################################################################
# eda
#################################################################

# Q. What is the general variability in p2d, do we observe the same amount of variability in it's constituents?
# overall p2d distribution
{input_data %>%
    ggplot(aes(x=p2d_minutes)) +
    geom_histogram(fill="blue",binwidth = 1) + 
    scale_x_continuous(limits = c(0,200))
  quantile(input_data$p2d_minutes, probs = seq(0,1,0.01))
  # p95 = 66m, p99 = 120m
  quantile(input_data$p2pc_minutes,probs=seq(0,1,0.01))
  quantile(input_data$p2pc_minutes[input_data$is_irt == 0],probs=seq(0,1,0.01))
  # p95 = 26m, p99 = 68m
  quantile(input_data$stg_minutes,probs=seq(0,1,0.01))
  # 90% cases spend less than 35 mins in staging area
  # 5% cases spend more than 45 mins
  quantile(input_data$pkg_minutes,probs=seq(0,1,0.1))
  # packaging time proxy not accurate?
  quantile(input_data$cny_minutes,probs=seq(0,1,0.01))
  # in ~5% of the cases we observe a shipment spending more than 7mins on the conveyer - manual weight capture?
  quantile(input_data$p2d_minutes,probs=seq(0,1,0.05))
  # 95% shipments are dispatched within 66 mins
  # 99% cases are dispatched within 119 mins
  quantile(input_data$p2dbd_minutes,probs=seq(0,1,0.01))
  # boxplot comparison of time intervals
  input_data %>%
    sample_n(size = 100000) %>%
    filter(is_irt==0) %>%
    select(p2pc_minutes,stg_minutes,p2d_minutes) %>%
    melt() %>%
    ggplot(aes(x=variable,y=value)) +
    geom_boxplot() +
    scale_y_continuous(limits = c(0,100))
  input_data %>%
    sample_n(size = 100000) %>%
    filter(is_irt==0) %>%
    select(p2pc_minutes,stg_minutes,p2d_minutes) %>%
    melt() %>%
    group_by(variable) %>%
    filter(value > 0) %>%
    summarise(cov = mean(value)/sd(value))
  # p2d has a cov of 12% while p2pc and stg are at ~3% each
  input_data %>%
    sample_n(size=100000) %>%
    filter(stg_minutes < 200 & p2pc_minutes < 200) %>%
    ggplot(aes(x=p2pc_minutes,y=stg_minutes)) +
    geom_point()
  temp <- input_data %>%
    sample_n(size=100000) %>%
    filter(stg_minutes < 200 & p2pc_minutes < 200 & stg_minutes > 0 & p2pc_minutes > 0)
  cor(temp$stg_minutes,temp$p2pc_minutes)
  # why is there such high negative correlation between packaging and staging time?
  # post removing cases with negative time differences
  # [1] 0.04627514
  
  # Findings #1: 
  # - overall p2d caps at ~65mins for 95th %le and 119mins for 99th %le - possible deepdives, fc et al
  # - 5% shipments have > 27mins of p2pc - possible deepdives on fc, pickzone, fe, LDAP, picklist features
  # - 5% shipments spend more than 35 mins in staging area - possible deepdives on fc, floor#, filling material - tolerance, fragility
  # - p2pc and stg time have much lower variability than p2d : how much variance is unexplained?
  # - design p2d by warehouse
}
{
  
  table(input_data$is_irt, input_data$rfb_flag)
  input_data %>%
    filter(is_irt == 0 & rfb_flag == 0) %>%
    group_by(dispatch_warehouse_id) %>%
    summarise(sq = sum(reservation_quantity),
              p005 = quantile(p2d_minutes, probs=0.005),
              p01 = quantile(p2d_minutes, probs=0.01),
              p05 = quantile(p2d_minutes, probs=0.05),
              p50 = quantile(p2d_minutes, probs=0.50),
              p95 = quantile(p2d_minutes, probs=0.95),
              p99 = quantile(p2d_minutes, probs=0.99),
              p995 = quantile(p2d_minutes, probs=0.995),
              p996 = quantile(p2d_minutes, probs=0.996),
              p997 = quantile(p2d_minutes, probs=0.997),
              p998 = quantile(p2d_minutes, probs=0.998),
              p999 = quantile(p2d_minutes, probs=0.999),
              mu = mean(p2d_minutes),
              sigma = sd(p2d_minutes),
              cov = sd(p2d_minutes)/mean(p2d_minutes)) %>%
    write.csv('warehouse_wise_p2d_excluding_rfb_irt.csv')
  input_data %>%
    filter(rfb_flag == 0) %>%
    group_by(dispatch_warehouse_id) %>%
    summarise(sq = sum(reservation_quantity),
              p005 = quantile(p2d_minutes, probs=0.005),
              p01 = quantile(p2d_minutes, probs=0.01),
              p05 = quantile(p2d_minutes, probs=0.05),
              p50 = quantile(p2d_minutes, probs=0.50),
              p95 = quantile(p2d_minutes, probs=0.95),
              p99 = quantile(p2d_minutes, probs=0.99),
              p995 = quantile(p2d_minutes, probs=0.995),
              p996 = quantile(p2d_minutes, probs=0.996),
              p997 = quantile(p2d_minutes, probs=0.997),
              p998 = quantile(p2d_minutes, probs=0.998),
              p999 = quantile(p2d_minutes, probs=0.999),
              mu = mean(p2d_minutes),
              sigma = sd(p2d_minutes),
              cov = sd(p2d_minutes)/mean(p2d_minutes)) %>%
    write.csv('warehouse_wise_p2d_excluding_rfb_including_irt.csv')
  
}# phase 1. - comparing the p2d numbers by warehouse with the design lead time

# FC level deepdive
{
  input_data %>%
    filter(p2d_minutes < 200) %>%
    ggplot(aes(x=dispatch_warehouse_id,y=p2d_minutes)) +
    # geom_boxplot(varwidth = T) +
    scale_y_continuous(breaks = seq(0,200,10)) +
    theme(axis.text.x = element_text(angle = 90)) +
    stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
  input_data %>% 
    group_by(dispatch_warehouse_id) %>% 
    summarise(sq = sum(reservation_quantity),
              p005 = quantile(p2d_minutes, probs=0.005),
              p01 = quantile(p2d_minutes, probs=0.01),
              p05 = quantile(p2d_minutes, probs=0.05),
              p50 = quantile(p2d_minutes, probs=0.50),
              p95 = quantile(p2d_minutes, probs=0.95),
              p99 = quantile(p2d_minutes, probs=0.99),
              p995 = quantile(p2d_minutes, probs=0.995),
              p996 = quantile(p2d_minutes, probs=0.996),
              p997 = quantile(p2d_minutes, probs=0.997),
              p998 = quantile(p2d_minutes, probs=0.998),
              p999 = quantile(p2d_minutes, probs=0.999),
              mu = mean(p2d_minutes),
              sigma = sd(p2d_minutes),
              cov = sd(p2d_minutes)/mean(p2d_minutes)) %>%
    View()
  # significant difference in p2d across warehouses : whitefield, kol dan and kol sank maintaining low p2d despite large volumes
  #   binola, bhiwandi and rasayani pulling down the p2d
  #   ! alite_fc_del01 showing very high p2d levels : median 200m
  input_data %>%
    filter(p2pc_minutes < 100) %>%
    ggplot(aes(x=dispatch_warehouse_id,y=p2pc_minutes)) +
    # geom_boxplot(varwidth = T) +
    scale_y_continuous(breaks = seq(0,200,10)) +
    theme(axis.text.x = element_text(angle = 90)) +
    stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
  input_data %>% 
    group_by(dispatch_warehouse_id) %>% 
    summarise(sq = sum(reservation_quantity),
              p05 = quantile(p2pc_minutes, probs=0.05),
              p25 = quantile(p2pc_minutes, probs=0.25),
              p50 = quantile(p2pc_minutes, probs=0.50),
              p75 = quantile(p2pc_minutes, probs=0.75),
              p95 = quantile(p2pc_minutes, probs=0.95),
              p99 = quantile(p2pc_minutes, probs=0.99)) %>%
    View()
  # significant difference in picklist completion time observed across warehouses
  #   binola, bilaspur the 90th%le touches 20mins
  #   whitefield remains in 5mins range
  #   for rasayani it touches 40min, 25min for bhiwandi
  input_data %>%
    filter(stg_minutes < 100) %>%
    ggplot(aes(x=dispatch_warehouse_id,y=stg_minutes)) +
    # geom_boxplot(varwidth = T) +
    scale_y_continuous(breaks = seq(0,100,10)) +
    theme(axis.text.x = element_text(angle = 90)) +
    stat_summary(fun.data = boxes, geom = 'boxplot')
  # relative less difference in stg minutes
  #   binola and bilaspur has ~50m and 60m stg times
  #   for wfld the stg time is ~40m
  #   for rasayani and bhiwandi the numbers are 40m and 55m resp.
  # rough work
  input_data %>%
    group_by(dispatch_warehouse_id) %>% 
    summarise(rq = sum(reservation_quantity)) %>%
    arrange(desc(rq))
  # # A tibble: 24 x 2
  # dispatch_warehouse_id     rq
  # <chr>                  <int>
  # 1 blr_wfld              337976
  # 2 binola                308972
  # 3 bil                   215900
  # 4 mum_bndi              209551
  # 5 hyderabad_medchal_01  202074
  # 6 kol_sank_01           171206
  # 7 kol_dan_01            157876
  # 8 blr_mal_01            133367
  # 9 del_ncr_flex_01       132686
  # 10 mah_rsyni             118476
  
}
# Findings #2: 
{
  # - significant variance in p2d,p2pc is observed across fcs
  # - interestingly the fcs that have higher p2d and p2pc have lower if not same staging time
  #   - this indicates an opportunity for transfer learning
  #   - comparing malur, whitefiled and rasayani : malur is lowest on p2d with it's p2pc at 
  #     par of whitefiled. The reason why whitefields p2d is almost twice as malur is the 
  #     larger time spent in staging and packaging area
  #   - Q. Why is whitefields staging time is so higher than malur when p2pc is almost same?
  #     - possible deepdives : requires warehouse visit as low visibility on the process from
  #       data standpoint. speak with people who have already worked on and are aware of the 
  #       problem, diff. coloured toats; item fragility; filling material - tolerance
  #   - rasayani has much worse p2d as compared with whitefield due to it's high p2pc while it's
  #     staging time is at par as whitefield
  #   - Q. Why is rasayani's p2pc so high as compared with whitefield when the staging time is almost same
  #     - possible deepdives : pickzone, picklist item quantity, ldap, irt,storage location
  #       data standpoint. speak with people who have already worked on and are aware of the problem, diff. coloured toats
}
{input_data %>% filter(stg_minutes <= 200) %>% mutate(is_irt = as.factor(is_irt)) %>% ggplot(aes(x=is_irt,y=stg_minutes))+geom_boxplot(varwidth = T)
}# - quick checks : validated staging time is not affected by irt 
# - no effect of floor# in wfld warehouse on staging minutes, p2d or p2pc

# Exploring the cuts for Fingings #1
# - 5% shipments have > 27mins of p2pc - possible deepdives on fc, pickzone, fe, irt, picklist features
# 1. Pickzone
{
  input_data %>% 
    group_by(dispatch_warehouse_id) %>% 
    summarise(pc = length(unique(picklist_picking_zone)),
              p2d.m = median(p2d_minutes),
              p2pc.m = median(p2pc_minutes),
              # trying random stuff - does sq per pickzone affect p2pc?
              sq = sum(reservation_quantity),
              sq.p = sq/pc) %>%
    arrange(desc(pc)) %>%
    View()
  {# # A tibble: 24 x 2
    # dispatch_warehouse_id    pc
    # <chr>                 <int>
    #   1 blr_wfld                 90
    # 2 binola                   84
    # 3 mum_bndi                 83
    # 4 bil                      63
    # 5 kol_sank_01              57
    # 6 hyderabad_medchal_01     56
    # 7 mah_rsyni                56
    # 8 blr_mal_01               41
    # 9 del_ncr_flex_01          29
    # 10 kol_dan_01               28
    # # ... with 14 more rows
    }# large variance in piczone counts across warehouses
  # deepdive for warehouse that a. can be visited or b. has a large variance in p2pc
  # let's do both!
  # whitefield
  input_data = data.table(input_data)
  input_data_wfld <- input_data[dispatch_warehouse_id=='blr_wfld']
  length(unique(input_data_wfld$picklist_picking_zone))#90
  input_data_wfld %>%
    filter(p2pc_minutes < 30) %>%
    ggplot(aes(x=picklist_picking_zone,y=p2pc_minutes)) +
    # geom_boxplot(varwidth = T) +
    scale_y_continuous(breaks = seq(0,30,1)) +
    theme(axis.text.x = element_text(angle = 90)) +
    stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
  # identify the highest and lowest p2pc pickzones and compare and contrast the inventory placement
  input_data_wfld %>%
    group_by(picklist_picking_zone) %>%
    summarise(pcle05 = quantile(p2pc_minutes,probs=0.05),
              pcle25 = quantile(p2pc_minutes,probs=0.25),
              pcle50 = quantile(p2pc_minutes,probs=0.50),
              pcle75 = quantile(p2pc_minutes,probs=0.75),
              pcle95 = quantile(p2pc_minutes,probs=0.95),
              sq = sum(reservation_quantity)) %>%
    View()
  {
    # Pickzone - 4002
    # Pickzone - 4001
    View(table(input_data_wfld$product_detail_cms_vertical[input_data_wfld$picklist_picking_zone == 'Pickzone - 4002']))
    # mobile_refurbished - and other refurbished items
    View(table(input_data_wfld$product_detail_cms_vertical[input_data_wfld$picklist_picking_zone == 'Pickzone - 4001']))
    # mobile, headphone and watch refurbished
    input_data %>%
      mutate(rfb_flag = ifelse(regexpr("refurbished",product_detail_cms_vertical) != -1,
                               1,
                               0),
             rfb_flag = as.factor(rfb_flag)) %>%
      filter(p2pc_minutes <= 100) %>%
      ggplot(aes(x=rfb_flag,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,100,10))
    # at overall level the median time is 10m vs 5m although the p95 is 55m vs. 10m
    # for whitefield the same numbers are 25m vs. 2m and 90m vs. 5m
    # something's cooking : refurbished have a different flow, need to exclude from p2d calculations
    
    }# rough work : do refurbished items always have higher p2d? - yeah, but something's cooking in wfld
  # define a refurbished flag in data
  input_data <- input_data %>%
    mutate(rfb_flag = ifelse(regexpr("refurbished",product_detail_cms_vertical) != -1,
                             1,
                             0),
           rfb_flag = as.factor(rfb_flag))
  # Findings #3
  # - For whitefield the pickzones do not have significant impact on p2pc except the 
  #   refurbished products where the p2pc95 is 18x vs. the overall 5.5x for rfb vs. non_rfb
  # rasayani
  input_data_rasy <- input_data[dispatch_warehouse_id=='mah_rsyni']
  quantile(input_data_rasy$p2d_minutes, probs=seq(0,1,0.01))
  # significant variance in p2pc pickzone wise : Pickzone #16,17 show p2pc95 of 172m vs. pickzone 8,10 with ~40m
  input_data_rasy %>%
    filter(p2pc_minutes <= 200) %>%
    ggplot(aes(x=picklist_picking_zone,y=p2pc_minutes)) +
    geom_boxplot(varwidth = T) +
    scale_y_continuous(breaks = seq(0,200,10)) +
    theme(axis.text.x = element_text(angle = 90))
  #  quantiles
  input_data_rasy %>%
    group_by(picklist_picking_zone) %>%
    summarise(pcle05 = quantile(p2pc_minutes,probs=0.05),
              pcle25 = quantile(p2pc_minutes,probs=0.25),
              pcle50 = quantile(p2pc_minutes,probs=0.50),
              pcle75 = quantile(p2pc_minutes,probs=0.75),
              pcle95 = quantile(p2pc_minutes,probs=0.95),
              sq = sum(reservation_quantity)) %>%
    arrange(desc(pcle95)) %>%
    View()
  input_data_rasy %>%
    filter(picklist_picking_zone == 'Pickzone-8') %>%
    group_by(product_detail_cms_vertical) %>%
    summarise(rq = sum(reservation_quantity)) %>%
    arrange(desc(rq)) %>%
    View()
  # Findings #4: 
  # significant variance in p2pc pickzone wise : Pickzone #16,17 show p2pc95 of 172m vs. pickzone 8,10 with ~40m
  # Pickzone 16,17 vs. 8,10 - Lifestyle(kurta, jean, tshirt) vs. Electroics(Smartwatch, powerbank, trimmer)
  #   For whitefield the p2pc for lifestyle does not appear as high as rasayani - added in findings 1 - p95 = 10m
  #   All lifestyle zones placed on the same floor
  #   Possible deepdives : Inventory placement - check the KPI tree  for features relating to inventory placement, 
  #                         picklist item quantity, LDAP
  input_data_wfld %>%
    filter(product_detail_cms_vertical == 'kurta') %>%
    group_by(product_detail_cms_vertical) %>%
    summarise(rq = sum(reservation_quantity),
              p95 = quantile(p2pc_minutes,probs=0.95)) %>%
    arrange(desc(rq)) %>%
    View()
  # for whitefield the p2pc for lifestyle does not appear as high as rasayani - added in findings 1
  
}# 1. Pickzone
{
  {
    # We know that there is a variance in p2pc across warehouses, and within pickzones of warehosues
    #   Could piq be causing this - deepdive would be to compare  the piq across pickzones wihtin warehouses
    #   Also, another line of check is whether there is any differrence in piq across warehouses - this   
    # Here as well we will contrast the features of whitefield and rasayani
    # whitefield
    picklist_item_qty <- input_data_wfld %>%
      group_by(picklist_display_id) %>%
      summarise(piq = sum(reservation_quantity)) %>%
      as.data.table()
    input_data_wfld <- data.table(input_data_wfld)
    setkey(picklist_item_qty,picklist_display_id)
    setkey(input_data_wfld,picklist_display_id)
    input_data_wfld <- picklist_item_qty[input_data_wfld]
    input_data_wfld %>%
      ggplot(aes(x=picklist_picking_zone,y=piq)) +
      geom_boxplot(varwidth = T) +
      theme(axis.text.x = element_text(angle = 90))
    # no variance in piq by pickzone
    input_data_wfld %>%
      filter(p2pc_minutes <= 10) %>%
      mutate(piq = as.factor(piq)) %>%
      ggplot(aes(x=piq,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T)
    # marginal rise in p2pc with piq but no sig. difference
    # rasayani
    picklist_item_qty <- input_data_rasy %>%
      group_by(picklist_display_id) %>%
      summarise(piq = sum(reservation_quantity)) %>%
      as.data.table()
    input_data_rasy <- data.table(input_data_rasy)
    setkey(picklist_item_qty,picklist_display_id)
    setkey(input_data_rasy,picklist_display_id)
    input_data_rasy <- picklist_item_qty[input_data_rasy]
    input_data_rasy %>%
      ggplot(aes(x=picklist_picking_zone,y=piq)) +
      geom_boxplot(varwidth = T) +
      theme(axis.text.x = element_text(angle = 90))
    # no variance in piq by pickzone
    input_data_rasy %>%
      filter(p2pc_minutes <= 200) %>%
      mutate(piq = as.factor(piq)) %>%
      ggplot(aes(x=piq,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T)
    # piq = 11 has relatively higher p2pc than other piqs
    input_data_rasy %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(rq = sum(reservation_quantity)) %>% 
      arrange(desc(rq)) %>%
      mutate(rq_cump = cumsum(rq)/sum(rq)) %>%
      View()
    input_data_rasy %>%
      filter(piq == 11) %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(rq = sum(reservation_quantity)) %>% 
      arrange(desc(rq)) %>%
      mutate(rq_cump = cumsum(rq)/sum(rq)) %>%
      View()
    # larger presence of lifestyle vertical : for piq = 11, of the top verticals contributing to ~50% rq
    #   ~41% is coming from lifestyle - the share of these verticals at overall case drops to 16%
    #     -- hinting to inventory placement
    
    {picklist_item_qty <- input_data[,
                                     list(piq=sum(reservation_quantity)),
                                     by='picklist_display_id']
      input_data = picklist_item_qty[input_data, on='picklist_display_id']
      input_data %>%
        group_by(piq) %>%
        summarise(p01 = quantile(p2pc_minutes,probs=0.01),
                  p05 = quantile(p2pc_minutes,probs=0.05),
                  p50 = quantile(p2pc_minutes,probs=0.50),
                  p95 = quantile(p2pc_minutes,probs=0.95),
                  p99 = quantile(p2pc_minutes,probs=0.99),
                  rq  = sum(reservation_quantity)) %>%
        arrange(piq) %>%
        mutate(rq_cump = cumsum(rq)/sum(rq)) %>%
        View()
      input_data %>%
        filter(p2pc_minutes <= 100) %>%
        mutate(piq = as.factor(piq)) %>%
        ggplot(aes(x=piq,y=p2pc_minutes)) +
        geom_boxplot(varwidth = T) + 
        scale_y_continuous(breaks = seq(0,100,10))
      quantile(input_data$piq, probs = seq(0,1,0.01))
      # piq <= 12 for 95% picklists and <= 20 for 99.5% of picklists, piq does not appear to have
      #   for piq = 25,28,30 the p2pc appears to be very high
      input_data %>%
        filter(piq == 30) %>%
        group_by(product_detail_cms_vertical) %>%
        summarise(n())
      input_data %>%
        # filter(product_detail_cms_vertical == 'sticker') %>%
        group_by(piq) %>%
        summarise(n())%>%
        View()
      sum(input_data[product_detail_cms_vertical == 'sticker']$reservation_quantity)/sum(input_data$reservation_quantity)
      sum(input_data[product_detail_cms_vertical == 'sticker' & piq > 20]$reservation_quantity)/sum(input_data[piq > 20]$reservation_quantity)
      # ~3% of overall shipments are from sticker vertical, although for picklists with item quantity > 20, this number jumps to ~88%
      View(table(input_data[product_detail_cms_vertical == 'sticker' & piq > 20]$dispatch_warehouse_id))
      # majority of warehouses where stickers with piq > 20 are being dispatched are kol_sank_01,blr_wfld,binola
      quantile(input_data$p2pc_minutes, probs = c(0.01,seq(0.05,0.95,0.1),0.99))
      quantile(input_data[product_detail_cms_vertical == 'sticker']$p2pc_minutes, probs = c(0.01,seq(0.05,0.95,0.1),0.99))
      quantile(input_data[product_detail_cms_vertical == 'sticker' & piq > 25]$p2pc_minutes, probs = c(0.01,seq(0.05,0.95,0.1),0.99))
      # for all picklists with item
      # Q. is there a difference in picklist item quantity by warehouse?
      input_data %>%
        group_by(dispatch_warehouse_id) %>%
        summarise(p05 = quantile(piq, probs = 0.05),
                  p50 = quantile(piq, probs = 0.50),
                  p95 = quantile(piq,probs = 0.95),
                  rq = sum(reservation_quantity)) %>%
        View()
      colnames(input_data_wfld)
      input_data_wfld %>%
        group_by(piq) %>%
        summarise(pcle05 = quantile(p2pc_minutes,probs=0.05),
                  pcle25 = quantile(p2pc_minutes,probs=0.25),
                  pcle50 = quantile(p2pc_minutes,probs=0.50),
                  pcle75 = quantile(p2pc_minutes,probs=0.75),
                  pcle95 = quantile(p2pc_minutes,probs=0.95),
                  sq = sum(reservation_quantity),
                  sq_cumsum = cumsum(sq)) %>%
        arrange(piq) %>%
        mutate(sq_cumsum = cumsum(sq)/sum(sq)) %>%
        View()
      input_data_wfld %>%
        filter(p2pc_minutes <= 300) %>%
        mutate(piq = as.factor(piq)) %>%
        ggplot(aes(x=piq,y=p2pc_minutes)) +
        geom_boxplot(varwidth = T) +
        scale_y_continuous(breaks = seq(0,300,10))}# previous analysis = overall level + warehouse deepdives
    
  }# picklist item quantity
  {
    input_data %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(p05 = quantile(p2pc_minutes, probs = 0.05),
                p50 = quantile(p2pc_minutes, probs = 0.05),
                p95 = quantile(p2pc_minutes, probs = 0.05),
                sq = sum(reservation_quantity)) %>%
      arrange(desc(sq)) %>%
      View()
    # overall the 
    quantile(input_data$p2pc_minutes, probs = seq(0.05,0.95,0.1))
    input_data %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(p05 = quantile(p2d_minutes, probs = 0.05),
                p50 = quantile(p2d_minutes, probs = 0.05),
                p95 = quantile(p2d_minutes, probs = 0.05),
                sq = sum(reservation_quantity)) %>%
      arrange(desc(sq)) %>%
      filter(p95 >= 45.35) %>%
      View()
    input_data %>%
      filter(p2pc_minutes <= 200) %>%
      ggplot(aes(x=product_detail_cms_vertical,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T) +
      scale_x_continuous(breaks = seq(0,100,10)) +
      theme(axis.title.x = element_text(angle = 90))
    
  }# picklist vertical
  {
    # Q. could floor number be pulling down the staging area numbers?
    input_data %>%
      filter(dispatch_warehouse_id=='blr_wfld') %>%
      group_by(picking_zone_floor_no) %>%
      summarise(sum(reservation_quantity),
                median(stg_minutes))
    # convert floor number to factor before using in ggplot
    input_data$picking_zone_floor_no <- as.factor(input_data$picking_zone_floor_no)
    input_data %>%
      filter(dispatch_warehouse_id=='blr_wfld' & p2pc_minutes < 30) %>%
      mutate(picking_zone_floor_no = as.factor(picking_zone_floor_no)) %>%
      ggplot(aes(x=picking_zone_floor_no,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,100,1)) +
      theme(axis.text.x = element_text(angle = 90))
    # no effect of floor# in wfld warehouse on staging minutes, p2d or p2pc
    input_data %>%
      filter(dispatch_warehouse_id=='mah_rsyni' & p2pc_minutes < 100) %>%
      mutate(picking_zone_floor_no = as.factor(picking_zone_floor_no)) %>%
      ggplot(aes(x=picking_zone_floor_no,y=p2pc_minutes)) +
      geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,100,10)) +
      theme(axis.text.x = element_text(angle = 90))
    # floor # does not appear to have large effect on the staging time but is affecting p2pc
    input_data_rasy %>%
      filter(picking_zone_floor_no == 1) %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(rq = sum(reservation_quantity)) %>%
      arrange(desc(rq)) %>%
      View()
    
  }# floor #
  {
    
    input_data_wfld %>%
      # filter(p2pc_minutes <= 50) %>%
      ggplot(aes(x=as.factor(is_irt),y=p2pc_minutes)) +
      geom_boxplot(varwidth = T)
    # scale_y_continuous(breaks = seq(0,50,1))
    input_data_wfld %>%
      group_by(is_irt) %>%
      summarise(sq = sum(reservation_quantity),
                p01 = quantile(p2d_minutes, probs=0.01),
                p25 = quantile(p2d_minutes, probs=0.25),
                p50 = quantile(p2d_minutes, probs=0.50),
                p95 = quantile(p2d_minutes, probs=0.95),
                p99 = quantile(p2d_minutes, probs=0.99))
    # irt cases take longer wiht 20m diff in p95
    input_data_rasy %>%
      group_by(is_irt) %>%
      summarise(sq = sum(reservation_quantity),
                p01 = quantile(p2d_minutes, probs=0.01),
                p25 = quantile(p2d_minutes, probs=0.25),
                p50 = quantile(p2d_minutes, probs=0.50),
                p95 = quantile(p2d_minutes, probs=0.95),
                p99 = quantile(p2d_minutes, probs=0.99))
    # irt delta more promninent - p95 80m vs. 240m
    # share of irt  ~25% vs. 6% for whitefield
    # which verticals are contrbuting to irt
    input_data_wfld %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(rq = sum(reservation_quantity),
                rq_irt = sum(reservation_quantity[is_irt == 1]),
                irt_pct = rq_irt/rq) %>%
      arrange(desc(rq)) %>%
      View()
    input_data_rasy %>%
      group_by(product_detail_cms_vertical) %>%
      summarise(rq = sum(reservation_quantity),
                rq_irt = sum(reservation_quantity[is_irt == 1]),
                irt_pct = rq_irt/rq) %>%
      arrange(desc(rq)) %>%
      View()
    
  }# irt
  
}# 2. picklist features

{
  input_data_mal <- input_data %>%
    filter(dispatch_warehouse_id == 'blr_mal_01')
  input_data_mal %>%
    group_by(product_vertical_attribute_tolerance) %>%
    summarise(pcle05 = quantile(stg_minutes,probs=0.05),
              pcle25 = quantile(stg_minutes,probs=0.25),
              pcle50 = quantile(stg_minutes,probs=0.50),
              pcle75 = quantile(stg_minutes,probs=0.75),
              pcle95 = quantile(stg_minutes,probs=0.95),
              sq = sum(reservation_quantity))
  input_data_wfld %>%
    group_by(product_vertical_attribute_tolerance) %>%
    summarise(pcle05 = quantile(stg_minutes,probs=0.05),
              pcle25 = quantile(stg_minutes,probs=0.25),
              pcle50 = quantile(stg_minutes,probs=0.50),
              pcle75 = quantile(stg_minutes,probs=0.75),
              pcle95 = quantile(stg_minutes,probs=0.95),
              sq = sum(reservation_quantity))
  input_data_mal %>%
    group_by(shipment_is_fragile) %>%
    summarise(pcle05 = quantile(stg_minutes,probs=0.05),
              pcle25 = quantile(stg_minutes,probs=0.25),
              pcle50 = quantile(stg_minutes,probs=0.50),
              pcle75 = quantile(stg_minutes,probs=0.75),
              pcle95 = quantile(stg_minutes,probs=0.95),
              sq = sum(reservation_quantity))
  input_data_wfld %>%
    group_by(shipment_is_fragile) %>%
    summarise(pcle05 = quantile(stg_minutes,probs=0.05),
              pcle25 = quantile(stg_minutes,probs=0.25),
              pcle50 = quantile(stg_minutes,probs=0.50),
              pcle75 = quantile(stg_minutes,probs=0.75),
              pcle95 = quantile(stg_minutes,probs=0.95),
              sq = sum(reservation_quantity))
  
  
}

# malur vs. whitefield
# Step 1/2 : comparing the p995 of p2d by warehouse against the design numbers
{
  # read in the design numbers
  
}# comparing the p995 of p2d by warehouse against the design numbers

# Work done post  16th May

{
  #################################################################
  # import data
  #################################################################
  
  input_data <- fread('input_data_v10.csv',header = T,
                      stringsAsFactors = F,
                      na.strings = c("NULL","","NA"))
  inventory_data <- fread('inventory_data.csv',header = T,stringsAsFactors = F,na.strings = c("NULL","","NA"))
  input_data_backup <- input_data
  # input_data <- input_data_backup
  
  #################################################################
  # data cleaning
  #################################################################
  
  input_data$storage_location_capacity <- NULL
  input_data$storage_location_available_capacity <- NULL
  # treating columns with false NAs
  sapply(input_data, function(x) sum(is.na(x)))
  input_data$unproductive_time[is.na(input_data$unproductive_time)] <- 0
  input_data$shipment_item_on_hold_reason[is.na(input_data$shipment_item_on_hold_reason)] <- 'Not on hold'
  input_data$inter_item_pick_interval[is.na(input_data$inter_item_pick_interval)] <- 0
  input_data$inter_item_sbs_pack_interval[is.na(input_data$inter_item_sbs_pack_interval)] <- 0
  # converting unproductive time to minutes
  input_data$unproductive_time <- input_data$unproductive_time/60
  quantile(input_data$unproductive_time,probs = seq(0,1,0.1))
  # removing outlier values of unproductive time
  input_data <- input_data %>%
    filter(unproductive_time < quantile(input_data$unproductive_time, probs = 0.999))
  input_data <- data.table(input_data)
  # removing all rows with at least one null
  input_data <- input_data[complete.cases(input_data)]
  colnames(input_data)
  # summary of all time difference columns
  input_data %>% 
    select(colnames(input_data)[grep("minutes",colnames(input_data))]) %>%
    summary()
  # removing cases where time differences are <= 0
  input_data <- input_data[p2pc_minutes > 0 &
                             c2i_minutes > 0 &
                             i2d_minutes > 0 &
                             p2d_minutes > 0 &
                             p2dbd_minutes > 0 &
                             pp_pu_minutes > 0 &
                             ps2pp_minutes > 0]
  # removing refurb cases
  input_data <- input_data %>%
    mutate(rfb_flag = ifelse(regexpr("refurbished",product_detail_cms_vertical) != -1,
                             1,
                             0)) %>%
    filter(rfb_flag == 0) %>%
    select(-c(rfb_flag))
  # remove duplicate entries
  input_data <- data.table(input_data)
  input_data <- input_data[order(input_data$fulfill_item_unit_id,-input_data$shipment_dispatched_timestamp),]
  input_data <- input_data[!duplicated(input_data$fulfill_item_unit_id)]
  # View(input_data[input_data$fulfill_item_unit_id == 'jvbzco1i:1:0814:akjaf7oiff9ke9lsm7vtunla4'])
  
  #################################################################
  # eda
  #################################################################
  
  # warehouse level p2d child element variance
  {
    input_data %>%
      filter(p2d_minutes < 200) %>%
      ggplot(aes(x=dispatch_warehouse_id,y=p2d_minutes)) +
      # geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,200,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    input_data %>%
      filter(p2pc_minutes < 100) %>%
      ggplot(aes(x=dispatch_warehouse_id,y=p2pc_minutes)) +
      # geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,100,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    input_data %>%
      filter(pp_pu_minutes < 70) %>%
      ggplot(aes(x=dispatch_warehouse_id,y=pp_pu_minutes)) +
      # geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,70,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    input_data %>%
      filter(c2i_minutes < 100) %>%
      ggplot(aes(x=dispatch_warehouse_id,y=c2i_minutes)) +
      # geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,100,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    input_data %>%
      filter(i2d_minutes < 40) %>%
      ggplot(aes(x=dispatch_warehouse_id,y=i2d_minutes)) +
      # geom_boxplot(varwidth = T) +
      scale_y_continuous(breaks = seq(0,40,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    
    # checking the pp_pu quantiles by warheouse
    input_data %>%
      group_by(dispatch_warehouse_id) %>%
      summarise(sq = sum(reservation_quantity),
                p005 = quantile(pp_pu_minutes, probs=0.005),
                p01 = quantile(pp_pu_minutes, probs=0.01),
                p05 = quantile(pp_pu_minutes, probs=0.05),
                p25 = quantile(pp_pu_minutes, probs=0.25),
                p50 = quantile(pp_pu_minutes, probs=0.50),
                p75 = quantile(pp_pu_minutes, probs=0.75),
                p95 = quantile(pp_pu_minutes, probs=0.95),
                p99 = quantile(pp_pu_minutes, probs=0.99),
                p995 = quantile(pp_pu_minutes, probs=0.995),
                mu = mean(pp_pu_minutes),
                sigma = sd(pp_pu_minutes),
                cov = sd(pp_pu_minutes)/mean(pp_pu_minutes)) %>%
      View()
    # median ~60s, 93%le = 5m
    
  }# boxplots on warehouse level variance of p2d and it's children - overall
  
  {# p2pc - 
  #   1. irt
  #   2. inventory placement : bin density(# of wids), bin depth(qty per wid), pick phase, rank in picklist, inter item distance
  #   3. vertical : effect of vertical on picklist item picked inter time
  #   4. distance from DZ
  #   5. distance from chute - if no transporter : malur
  
  # c2i - 
  #   1. Drop zone to chute area distance
  #   2. Less visits by transported in drop zone
  #   3. Time spent by toat in DZ
  #   4. Vertical travel time(floor #, bin height)
  #   5. FIFO in staging
  #   6. Staging to packaging time
  #   7. Waiting time at packaging station
  #   8. Packaging time for lower rank picklist items
  
  # i2d -
  #   1. tolerance and fragility
  #   2. presence of profiler
  #   3. manual vs. profielr weighing
  
  # p2d -
  #   1. unproductive time
  #   2. order of picking and packaging
  }# hypotheses discussed with Shrey-Abhishek
  {
    
    # p2d ladder : 
    # 
    # irt split :
    # picking irt
    # packing irt
    # 
    # intra pl : 
    # excess picking time: evaluate if excess picking time is correlated with experience
    #   - check the design picking time - 20s? Compare with median value
    # excess packing time: evaluate if excess packing time is correlated with fragility
    #   - check the design packing time - 40s? Compare with median value
    # 
    # extra pl :
    # effect of floor# and other c2i hyp
    # 
    # else buckets :
    # FIFO extra pl
    # WIP extra pl
    # 
    # need to check scope :
    # profiler vs. manual weighing?
    # adjust for unproductive time
    
  }# p2d ladder
  
  # checking for whitefield warehouse only
  input_data <- data.table(input_data)
  input_data_wfld <- input_data[input_data$dispatch_warehouse_id == 'blr_wfld']
  
  # p2d
  {
    input_data_wfld_pl <- input_data_wfld[,
                                          list(p2d_min  = min(p2d_minutes),
                                               p2d_max  = max(p2d_minutes),
                                               p2d      = mean(p2d_minutes),
                                               p2d_diff = max(p2d_minutes)-min(p2d_minutes),
                                               p2pc_min = min(p2pc_minutes),
                                               p2pc_max = max(p2pc_minutes),
                                               p2pc     = mean(p2pc_minutes),
                                               p2pc_diff= max(p2pc_minutes)-min(p2pc_minutes),
                                               qty      = sum(reservation_quantity),
                                               c2i_min  = min(c2i_minutes),
                                               c2i_max  = max(c2i_minutes),
                                               c2i      = mean(c2i_minutes),
                                               c2i_diff = max(c2i_minutes)-min(c2i_minutes)),
                                          by=picklist_display_id]
    quantile(input_data_wfld_pl$c2i_diff, probs = seq(0,1,0.05))
    table(input_data_wfld_pl$qty)
    input_data_wfld_pl %>%
      filter(p2d_diff <= 100) %>%
      ggplot(aes(x=as.factor(qty),y=p2d_diff))+
      scale_y_continuous(breaks=seq(0,100,10)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)  
    input_data_wfld_pl %>%
      filter(p2d_diff <= 100 & qty == 12) %>%
      ggplot(aes(x=p2d_max,y=p2d_diff)) + 
      geom_point()
    # higher p2d levels has generally higher p2d diff
    input_data_wfld_pl %>%
      # filter(p2pc_diff <= 100) %>%
      ggplot(aes(x=as.factor(qty),y=p2pc_diff))+
      scale_y_continuous(breaks=seq(0,10,1)) +
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)    
    input_data_wfld_pl %>%
      filter(c2i_diff <= 50) %>%
      ggplot(aes(x=as.factor(qty),y=c2i_diff))+
      scale_y_continuous(breaks=seq(0,50,5)) +
      # geom_boxplot(varwidth = T) + 
      theme(axis.text.x = element_text(angle = 90)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    # organic growth in median value of c2i with piq, but need to investigate the reason for 10-15 min jump in c2i within pl
    cor(input_data_pl$p2d_max, input_data_pl$p2d_diff)
    input_data_wfld_pl %>%
      filter(p2d_diff > 100) %>%
      # count()
      View()
    # investigate why - 
    input_data_wfld %>%
      filter(picklist_display_id == 'F49496219') %>%
      select(picklist_item_id,picklist_item_picked_timestamp,shipment_dispatched_timestamp,p2d_minutes,c2i_minutes) %>%
      View()
    # why was the c2i diff beyond 10 mins?
    input_data_wfld_pl %>%
      filter(qty == 12 & c2i_diff > 10) %>%
      select(picklist_display_id) %>%
      head()
    # picklist_display_id
    # 1           F49588830
    # 2           F49624201
    # 3           F49613197
    # 4           F49589188
    # 5           F49738669
    # 6           F49620015
    input_data_wfld %>%
      filter(picklist_display_id == 'F49588830') %>%
      View()
    # need a seperate classification for these cases where the c2i is being extended
    #   - Unattributed packing station hold time
    # this will be different from the FIFO and WIP, since the toat is already in packing process
    #   - a high value of c2i diff indicates either higher pkging time of previous shipment or
    #     high sbs of current shipment or unproductive time
    
  }# ~50% correlation between the maximum p2p value and the p2d difference indicating that higher p2d may be indicative of higher differences

  {
    
    input_data_wfld$unproductive_time <- input_data_wfld$unproductive_time/60
    quantile(input_data_wfld$unproductive_time, probs = seq(0,1,0.01))
    # ~80% cases the unproductive time is 0. For ~11% cases the unproductive time is > 11m
    input_data_wfld %>%
      ggplot(aes(x=unproductive_time,y=p2d_minutes)) +
      geom_point()
    # need the timestamps to adjust unproductive time accurately
    
  }# unproductive time variance
  
  {
    # picking irt
    table(input_data_wfld$is_irt)
    input_data_wfld %>%
      ggplot(aes(x=factor(is_irt),y=p2pc_minutes)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    # quantum = ~4%
    # packing irt
    table(input_data_wfld$shipment_item_on_hold_reason)
    input_data_wfld %>%
      ggplot(aes(x=factor(shipment_item_on_hold_reason),y=p2d_minutes)) +
      stat_summary(fun.data = boxes,geom = "boxplot",varwidth=T)
    # quantum = negligible
    
    input_data_wfld$is_irt_pick <- input_data_wfld$is_irt
    input_data_wfld$is_irt_pack <- ifelse(input_data_wfld$shipment_item_on_hold_reason != 'Not on hold',1,0)
    
  }# irt - picking and packing - is_irt_pick,is_irt_pack
  {
    
    # input_data_wfld$pcr_ts <- strptime(input_data_wfld$picklist_created_timestamp,format = '%Y-%m-%d %H:%M:%OS')
    # input_data_wfld$pip_ts <- strptime(input_data_wfld$picklist_item_picked_timestamp,format = '%Y-%m-%d %H:%M:%OS')
    # input_data_wfld$ps2pp_minutes <- difftime(input_data_wfld$pip_ts,input_data_wfld$pcr_ts,units = "mins")
    # input_data_wfld$ps2pp_minutes <- as.numeric(input_data_wfld$ps2pp_minutes)
    input_data_wfld_pl <- input_data_wfld %>%
      # select(-c(pcr_ts,pip_ts)) %>%
      group_by(picklist_display_id) %>%
      summarise(ps2pp_minutes = min(ps2pp_minutes))
    # picklist creation to start time - includes setup time + delay in start
    quantile(input_data_wfld_pl$ps2pp_minutes, probs = seq(0,1,0.01))
    # 50th%le ~2m10s, 95th%le - 10m anything in excess is either delay in setup, tech issues, bulk picklist creation, etc. - need to verify with ground ops
    # setup time is ~X% of p2pc
    quantile(input_data_wfld$p2pc_minutes, probs = seq(0,1,0.05))
    # p50 = 6m36s, p95 = 18m33s
    input_data_wfld_pl$is_excess_setup_time <- ifelse(input_data_wfld_pl$ps2pp_minutes > 5 & input_data_wfld_pl$ps2pp_minutes <= 10,
                                                      1,0)
    input_data_wfld_pl$is_excess_setup_time_tech_issue <- ifelse(input_data_wfld_pl$ps2pp_minutes > 10,
                                                                 1,0)
    input_data_wfld <- data.table(input_data_wfld)
    input_data_wfld_pl <- data.table(input_data_wfld_pl)
    input_data_wfld <- input_data_wfld_pl[input_data_wfld, on = 'picklist_display_id']
    
  }# setup time profile - is_excess_setup_time, is_excess_setup_time_tech_issue
  {
    input_data_wfld_pl <- input_data_wfld %>%
      group_by(picklist_display_id) %>%
      summarise(pp_pu_minutes = min(pp_pu_minutes))
    quantile(input_data_wfld_pl$pp_pu_minutes, probs = seq(0,1,0.01))
    # median = 1m 5s
    # 95th %le at 5m
    quantile(input_data_wfld$pp_pu_minutes, probs = seq(0.99,1,0.001))
    # ~0.5% cases have more than 45m closure time - tech issues
    input_data_wfld_pl$is_excess_tote_drop_time <- ifelse(input_data_wfld_pl$pp_pu_minutes > 5 & input_data_wfld_pl$pp_pu_minutes <= 10,
                                                      1,0)
    input_data_wfld_pl$is_excess_tote_drop_time_tech_issue <- ifelse(input_data_wfld_pl$pp_pu_minutes > 10,
                                                                 1,0)
    input_data_wfld <- data.table(input_data_wfld)
    input_data_wfld_pl <- data.table(input_data_wfld_pl)
    input_data_wfld <- input_data_wfld_pl[input_data_wfld,on = 'picklist_display_id']
    
  }# tech issues/last item picked to picklist closure - is_excess_tote_drop_time,is_excess_tote_drop_time_tech_issue
  {
    
    # for picking time per item we can use picklist item picked timestamp
    quantile(input_data_wfld$inter_item_pick_interval, probs = seq(0,1,0.01))
    # ~12% cases have more than 30s picking time - median = 10s
    # for inter item packaging time - we will take a difference of successive c2i min - successive ibl generation timestamp
    quantile(input_data_wfld$inter_item_sbs_pack_interval, probs = seq(0,1,0.01))
    # ~14% cases have packing + sbs time higher than 60s - median = 33s
    
    input_data_wfld$is_excess_picking_time <- ifelse(input_data_wfld$inter_item_pick_interval > 0.5,
                                                     1,0)
    input_data_wfld$is_excess_packing_time <- ifelse(input_data_wfld$inter_item_sbs_pack_interval > 1,
                                                     1,0)
    
  }# excess picking/packing time - is_excess_picking_time, is_excess_packing_time
  {
    # effect of order of picking on p2pc
    input_data_wfld <- input_data_wfld %>%
      arrange(picklist_item_id) %>%
      group_by(picklist_display_id) %>%
      mutate(order_of_pick = cumsum(reservation_quantity))
    # input_data_wfld <- data.table(input_data_wfld)
    # View(head(input_data_wfld[picklist_display_id == 'F49583643']))
    input_data_wfld %>%
      ggplot(aes(x=factor(order_of_pick),y=p2pc_minutes)) +
      geom_boxplot(varwidth = T)
    # few deepdives
    # need ps2pp time to evaluate effect of rank on pick
    View(head(input_data_wfld_pl[input_data_wfld_pl$piq == 12]))
    View(input_data_wfld[input_data_wfld$picklist_display_id == 'F49491686'])
    # when vertical changed from face wash to perfume the inter item picking time exceeded the design number

    # effect of order of packing
    input_data_wfld <- input_data_wfld %>%
      arrange(ibl_creation_timestamp) %>%
      group_by(picklist_display_id) %>%
      mutate(order_of_pack = cumsum(reservation_quantity))
    input_data_wfld %>%
      ggplot(aes(x=factor(order_of_pack),y=p2d_minutes)) +
      stat_summary(fun.data = boxes,geom = 'boxplot') +
      scale_y_continuous(breaks = seq(0,40,1))
    # overall 10 min increase in median of c2i
    
    # for picking, piq is more important than order of pick when looking from an 
    #   overall p2d standpoint, since each item moves together in a tote
    # for packing order of pack is more important than piq as each item moves loose
    
  }# order of pick/pack - TBD - driver analysis
  {
    input_data_wfld <- data.frame(input_data_wfld)
    # picklist created earlier reaches the packing station later
    input_data_wfld$pc_ts <- strptime(input_data_wfld$picklist_created_timestamp,format = '%Y-%m-%d %H:%M:%OS')
    input_data_wfld$iblc_ts <- strptime(input_data_wfld$ibl_creation_timestamp,format = '%Y-%m-%d %H:%M:%OS') 
    input_data_wfld_pl <- input_data %>%
      group_by(picklist_display_id) %>%
      summarise(picklist_created_timestamp_min = min(pc_ts),
                ibl_creation_timestamp_min = min(iblc_ts),
                p2d_minutes_avg = mean(p2d_minutes)) %>%
      arrange(ibl_creation_timestamp_min)
    # lag of ibl and pl created timestamp
    input_data_wfld_pl <- data.table(input_data_wfld_pl)    
    input_data_wfld_pl[,
                       c('picklist_created_timestamp_min_lag_1','ibl_creation_timestamp_min_lag_1') :=
                         .(shift(picklist_created_timestamp_min,1,fill = 0,type="lag"),
                           shift(ibl_creation_timestamp_min,1,fill = 0,type="lag"))]
    input_data_wfld_pl$is_fifo <- ifelse(input_data_wfld_pl$ibl_creation_timestamp_min > input_data_wfld_pl$ibl_creation_timestamp_min_lag_1 &
                                        input_data_wfld_pl$picklist_created_timestamp_min < input_data_wfld_pl$picklist_created_timestamp_min_lag_1,
                                      1,0)
    input_data_wfld_pl %>%
      filter(p2d_minutes_avg < 95) %>%
      ggplot(aes(x=factor(fifo),y=p2d_minutes_avg)) +
      stat_summary(fun.data = boxes, geom = 'boxplot') +
      scale_y_continuous(breaks = seq(0,95,5))
    # ~10m difference in p2d median times for FIFO issue. ~25m diff. in p2d p95
    input_data_wfld_pl <- input_data_wfld_pl %>%
      select(-c('picklist_created_timestamp_min','ibl_creation_timestamp_min','p2d_minutes_avg','picklist_created_timestamp_min_lag_1','ibl_creation_timestamp_min_lag_1'))
    input_data_wfld_pl <- data.table(input_data_wfld_pl)
    input_data_wfld <- input_data_wfld %>%
      select(-c(pc_ts,iblc_ts)) %>%
      as.date.table()
    input_data_wfld <- input_data_wfld_pl[input_data_wfld, on = 'picklist_display_id']
      
  }# FIFO - is_fifo
  {
    # waiting time in DZ, DZ to chute travel, chute to staging, staging area wait, staging to packing station, packing station wait, etc.
  }# waiting time
  
  {
    
    p2d_stack <- input_data_wfld %>%
      select(setdiff(c("picklist_display_id","reservation_quantity","p2d_minutes",colnames(input_data_wfld)[grep("is_",colnames(input_data_wfld))]),
                       c("is_irt","shipment_is_fragile"))) %>%
      as.data.table()
    p2d_stack <- within(p2d_stack,
                        quantiles <- as.integer(cut(p2d_minutes,
                                                    quantile(p2d_minutes, probs = seq(0,1,0.05)),
                                                    include.lowest = T)))
    p2d_stack$p2d_minutes_rounded <- floor(p2d_stack$p2d_minutes/5)*5
    p2d_stack <- data.frame(p2d_stack)
    p2d_stack$rowSum <- rowSums(p2d_stack[colnames(p2d_stack)[grep("is_",colnames(p2d_stack))]])
    p2d_stack$is_driver_identified <- ifelse(p2d_stack$rowSum != 0, 1, 0)
    table(p2d_stack$is_driver_identified)
    table(p2d_stack$rowSum)# interesting plot
    p2d_stack_agg <- p2d_stack %>%
      group_by(p2d_minutes_rounded,
               is_irt_pick,is_irt_pack,
               is_excess_setup_time, is_excess_setup_time_tech_issue,
               is_excess_tote_drop_time,is_excess_tote_drop_time_tech_issue,
               is_excess_picking_time, is_excess_packing_time,
               is_fifo) %>%
      summarise(reservation_quantity = sum(reservation_quantity))
    write.csv(p2d_stack_agg, 'p2d_stack_agg_v2.csv', row.names = F)
                  
  }# p2d ladder code
  
}