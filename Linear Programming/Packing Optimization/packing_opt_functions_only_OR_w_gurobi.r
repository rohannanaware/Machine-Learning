# =========================================================
#  load_packing_raw_data()

# R - actual product dimensions and tolerance alongwith boxes used and shipments
# R - q - should this not take only the mobiles/non-mobiles?
# =========================================================

load_packing_raw_data <- function(filename =filename)
{
  packing_raw <- read.csv(filename,stringsAsFactors=F)
  packing_raw <- na.omit(packing_raw)
  
  names(packing_raw) <- c('vertical_tolerance','wid_l','wid_b','wid_h','used_box','shipments')
  
  packing_raw$wid_l_with_tol <- as.numeric(packing_raw$wid_l)+as.numeric(packing_raw$vertical_tolerance)
  packing_raw$wid_b_with_tol <- as.numeric(packing_raw$wid_b)+as.numeric(packing_raw$vertical_tolerance)
  packing_raw$wid_h_with_tol <- as.numeric(packing_raw$wid_h)+as.numeric(packing_raw$vertical_tolerance)
  
  print(paste(nrow(packing_raw),'rows of packing raw data corresponding to ',sum(packing_raw$shipments),' shipments')) 
  return(packing_raw)
}

# =========================================================
#  load_packing_box_data()

# Box dimensions - brown vs. mobiles | box surface area formula?
# =========================================================

load_packing_box_data <- function(filename =filename)
{
  packing_boxes <- read.csv(filename,stringsAsFactors=F)
  packing_boxes <- na.omit(packing_boxes)
  names(packing_boxes) <- c('packing_box','packing_bucket','box_l','box_b','box_h','is_active')
  packing_boxes <- subset(packing_boxes,as.numeric(box_l)>0)
  
  packing_boxes <- transform(packing_boxes, box_l=as.numeric(box_l),
                             box_b=as.numeric(box_b), box_h=as.numeric(box_h))
  
  packing_boxes$box_vol <- with(packing_boxes, box_l*box_b*box_h)
  packing_boxes$box_surf_area <- with(packing_boxes, 2*(box_l+box_b)*(box_b+box_h))
  
  print(paste(nrow(packing_boxes),'rows of packing box data loaded')) 
  
  write.csv(packing_boxes[order(packing_boxes$box_vol),],'packing_boxes.csv',row.names=F)
  return(packing_boxes[order(packing_boxes$box_vol),])
}

# =========================================================
#  process_packing_raw_data()
# 1) Joins packing raw data with packing boxes data
# 2) Sort the three dimensions and reassign to new variables such that L>=B>=H
# 3) Update the dimensions to ensure that packing box dimensions are always <= WID dimensions
# 4) Rounding the dimensions up to a level of 0.5 inches
# =========================================================

process_packing_raw_data <- function(packing_raw_data=packing_raw_data,
                                     packing_box_data=packing_box_data) 
{
  library(sqldf)
  
  print('Starting process packing raw data')
  #Join box data with packing raw to get suggested and used box volumes and surface areas
  processed_packing_data <- sqldf('select pr.wid_l*pr.wid_b*pr.wid_h as wid_vol, pr.used_box as used_box,pr.shipments,pr.wid_l_with_tol,pr.wid_b_with_tol,pr.wid_h_with_tol, 
                                  pb.box_l as used_box_l, pb.box_b as used_box_b, pb.box_h as used_box_h,pb.box_vol as used_box_vol, pb.box_surf_area as used_box_surf_area
                                  from packing_raw_data pr left join packing_box_data pb on
                                  pr.used_box = pb.packing_box')
  
  processed_packing_data <- subset(processed_packing_data,wid_l_with_tol>0 & wid_b_with_tol>0 & wid_h_with_tol>0)
  
  processed_packing_data$sorted_l_with_tol <- processed_packing_data$wid_l_with_tol
  processed_packing_data$sorted_b_with_tol <- processed_packing_data$wid_b_with_tol
  processed_packing_data$sorted_h_with_tol <- processed_packing_data$wid_h_with_tol
  
  for(i in 1:nrow(processed_packing_data)) {
    processed_packing_data[i,'sorted_l_with_tol'] <- sort(as.numeric(processed_packing_data[i,c('wid_l_with_tol','wid_b_with_tol','wid_h_with_tol')]))[3]
    processed_packing_data[i,'sorted_b_with_tol'] <- sort(as.numeric(processed_packing_data[i,c('wid_l_with_tol','wid_b_with_tol','wid_h_with_tol')]))[2]
    processed_packing_data[i,'sorted_h_with_tol'] <- sort(as.numeric(processed_packing_data[i,c('wid_l_with_tol','wid_b_with_tol','wid_h_with_tol')]))[1]
  }
  
  processed_packing_data <- subset(processed_packing_data, select = -c(wid_l_with_tol,wid_b_with_tol,wid_h_with_tol))
  
  processed_packing_data$final_wid_vol <- with(processed_packing_data, sorted_l_with_tol*sorted_b_with_tol*sorted_h_with_tol)
  
  processed_packing_data <- transform(processed_packing_data, lupdated=ifelse(used_box_l<sorted_l_with_tol,used_box_l,sorted_l_with_tol),
                                      bupdated=ifelse(used_box_b<sorted_b_with_tol,used_box_b,sorted_b_with_tol), 
                                      hupdated=ifelse(used_box_h<sorted_h_with_tol,used_box_h,sorted_h_with_tol))
  
  processed_packing_data <- subset(processed_packing_data,used_box_vol>0)
  #  processed_packing_data <- subset(processed_packing_data,lupdated>=lmin & bupdated>=bmin & hupdated>=hmin)
  #  processed_packing_data <- subset(processed_packing_data,lupdated<=lmax & bupdated<=bmax & hupdated<=hmax)
  
  processed_packing_data$lupdated_rounded <- ceiling(processed_packing_data$lupdated*2)/2
  processed_packing_data$bupdated_rounded <- ceiling(processed_packing_data$bupdated*2)/2
  processed_packing_data$hupdated_rounded <- ceiling(processed_packing_data$hupdated*2)/2
  
  return(processed_packing_data)
}

# =========================================================
#  GENERATE_ROUNDED_PACKING_RAW_DATA()
# =========================================================
generate_rounded_packing_raw_data <- function(processed_packing_data = processed_packing_data,cms_vertical=cms_vertical){
  processed_packing_data$rounded_l <- ceiling(processed_packing_data$lupdated*2)/2
  processed_packing_data$rounded_b <- ceiling(processed_packing_data$bupdated*2)/2
  processed_packing_data$rounded_h <- ceiling(processed_packing_data$hupdated*2)/2
  
  rounded_packing_raw_data <- sqldf('select rounded_l as lupdated,rounded_b as bupdated,rounded_h as hupdated,
                                    sum(shipments) as shipments from processed_packing_data
                                    group by rounded_l,rounded_b,rounded_h')
  
  rounded_packing_data_filename = paste('rounded_packing_data_',cms_vertical,'.csv',sep='')
  
  write.csv(rounded_packing_raw_data,rounded_packing_data_filename,row.names=F)
  return(rounded_packing_raw_data)
}


# =========================================================
#  GENERATE_PACKING_BOXES()
# =========================================================

#Function to generate all possible packing boxes with LBH 
#being 0.5 in apart from 0 inches to 40 inches

generate_packing_boxes <- function(lmin=lmin,bmin=bmin,hmin=hmin,lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax,increment=0.5){
  
  l<-seq(lmin,lmax,increment)
  b<-seq(bmin,bmax,increment)
  h<-seq(hmin,hmax,increment)
  
  packing_box <- expand.grid(l=l,b=b,h=h)
  
  packing_box<- subset(packing_box,l>=b & b>=h)
  
  if(lmidmin > lmin | bmidmin > bmin | hmidmin > hmin){
    
    midl<-seq(lmin,lmidmin,increment)
    midb<-seq(bmin,bmidmin,increment)
    midh<-seq(hmin,hmidmin,increment)
    
    mid_packing_box <- expand.grid(l=midl,b=midb,h=midh)
    
    mid_packing_box<- subset(mid_packing_box,l>=b & b>=h)
    
    library(dplyr)
    
    packing_box <- setdiff(packing_box,mid_packing_box)
  }
  
  packing_box <- transform(packing_box, vol = l*b*h)
  
  packing_box <- transform(packing_box, surf_area = 2*(l+b)*(b+h))
  
  packing_box <- packing_box[order(packing_box$vol),]
  
  packing_box<-cbind(box=1:nrow(packing_box),packing_box)
  
  print(paste(round(nrow(packing_box)/100000,2),'lakhs new packing box dimensions generated with min lbh of',lmin,',',bmin,',',hmin,'and increment of',increment))  
  
  names(packing_box) = c('new_box','new_box_l','new_box_b','new_box_h','new_box_vol','new_box_surf_area')
  
  #Write to csv new packing boxes
  new_packing_boxes_data_file_name <- paste('new_packing_boxes_','min_',lmidmin,'_',bmidmin,'_',hmidmin,'_','max_',lmax,'_',bmax,'_',hmax,'.csv',sep='')
  
  write.csv(packing_box,new_packing_boxes_data_file_name,row.names=F)
  
  return(packing_box)
}

# =========================================================
#  GENERATE_PACKING_DIM_CONSTRAINTS()
# =========================================================

#Put together constraints to ensure sum of absolute difference of consecutive boxes is less than 2 inches

# generate_packing_dim_constraints <- function(new_packing_boxes=new_packing_boxes,lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax){
#   
#   packing_box <- new_packing_boxes
#   
#   packing_dim_constraints <- data.frame(box1=NULL, box2=NULL)
#   
#   for(i in 1:nrow(packing_box)){
#     
#     for (j in 1:nrow(packing_box)){
#       
#       if(abs(packing_box[i,'new_box_l']-packing_box[j,'new_box_l'])+ 
#          abs(packing_box[i,'new_box_b']-packing_box[j,'new_box_b'])+
#          abs(packing_box[i,'new_box_h']-packing_box[j,'new_box_h']) < 2.5 ){
#         
#         if(i!=j)
#           packing_dim_constraints = rbind(packing_dim_constraints,c(packing_box[i,'new_box'],packing_box[j,'new_box']))
#       }  
#     }
#   }
#   
#   packing_dim_constraints_data_file_name <- paste('packing_dim_constraints_','min_',lmidmin,'_',bmidmin,'_',hmidmin,'_','max_',lmax,'_',bmax,'_',hmax,'.csv',sep='')
#   
#   write.table(packing_dim_constraints,packing_dim_constraints_data_file_name,row.names=F,sep=",")
#   
#   packing_dim_constraints <- read.table(packing_dim_constraints_data_file_name,sep=',',skip=1)
#   write.table(packing_dim_constraints,'packing_dim_constraints.csv',row.names = F,col.names = F, sep=',')
#   
# }

generate_packing_dim_constraints <- function(new_packing_boxes=new_packing_boxes,lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax){
  
  library(data.table)
  new_packing_boxes <- data.table(new_packing_boxes)
  new_packing_boxes$rowname <- row.names(new_packing_boxes)
  df_merge <- CJ(left = new_packing_boxes$rowname, right = new_packing_boxes$rowname)
  setkey(df_merge, left)
  setkey(new_packing_boxes, rowname)
  df_merge <- new_packing_boxes[df_merge]
  colnames(df_merge)
  setkey(df_merge, right)
  setkey(new_packing_boxes, rowname)
  df_merge <- new_packing_boxes[df_merge]
  packing_dim_constraints <- data.frame(box1=NULL, box2=NULL)
  df_merge$flag_lbhdiff <- 
    ifelse(abs(df_merge$new_box_l - df_merge$i.new_box_l) +
             abs(df_merge$new_box_b - df_merge$i.new_box_b) +
             abs(df_merge$new_box_h - df_merge$i.new_box_h) < 2.5,
           ifelse(df_merge$new_box != df_merge$i.new_box, 1, 0),
           0)
  packing_dim_constraints <- df_merge[flag_lbhdiff == 1, .(new_box,i.new_box)]
  colnames(packing_dim_constraints) <- c("X1L",	"X2L")
  write.csv(packing_dim_constraints,"packing_dim_constraints_gurobi_dt.csv", row.names = F)
  packing_dim_constraints_data_file_name <- paste('packing_dim_constraints_','min_',lmidmin,'_',bmidmin,'_',hmidmin,'_','max_',lmax,'_',bmax,'_',hmax,'.csv',sep='')
  write.table(packing_dim_constraints,packing_dim_constraints_data_file_name,row.names=F,sep=",")
  packing_dim_constraints <- read.table(packing_dim_constraints_data_file_name,sep=',',skip=1)
  write.table(packing_dim_constraints,'packing_dim_constraints.csv',row.names = F,col.names = F, sep=',')
  packing_dim_constraints <- data.frame(packing_dim_constraints)
  
}


# =========================================================
#  SELECT_BOXES()
# =========================================================

# Function to apply feasibility constraints and select 
# appropriate box for each wid

select_boxes <- function(rounded_packing_raw_data=rounded_packing_raw_data,
                         new_packing_boxes=new_packing_boxes,
                         lmidmin=lmidmin,
                         bmidmin=bmidmin,
                         hmidmin =hmidmin,
                         lmax=lmax,
                         bmax=bmax,
                         hmax=hmax,
                         cum_perc=cum_perc,
                         min_shipments=min_shipments)
{
  library(sqldf)
  wids_updated <- sqldf('select lupdated as wid_lupdated,bupdated as wid_bupdated,hupdated as wid_hupdated,sum(shipments) as shipments
                        from rounded_packing_raw_data 
                        group by lupdated,bupdated,hupdated')
  
  wids_updated <- subset(wids_updated,wids_updated$wid_lupdated > lmidmin | 
                           wids_updated$wid_bupdated > bmidmin |
                           wids_updated$wid_hupdated > hmidmin)
  
  wids_updated <- subset(wids_updated,wids_updated$wid_lupdated <= lmax | 
                           wids_updated$wid_bupdated <= bmax |
                           wids_updated$wid_hupdated <= hmax)
  
  wids_updated <- wids_updated[order(-wids_updated$shipments),]
  
  wids_updated$cum_perc <- 
    cumsum(wids_updated$shipments)/sum(wids_updated$shipments)
  
  wids_updated$box_selected <- rep(NA,nrow(wids_updated))
  
  wids_filtered<- wids_updated[wids_updated$cum_perc<=cum_perc,]
  
  print(paste('Using cumulative sales of',cum_perc*100,'% (',sum(wids_filtered$shipments),') to select boxes'))
  
  for(i in 1:nrow(wids_filtered)) {
    
    wids_updated[i,'box_selected'] <- subset(new_packing_boxes, 
                                             new_box_l>=wids_updated[i,'wid_lupdated'] & 
                                               new_box_b>=wids_updated[i,'wid_bupdated'] & 
                                               new_box_h>=wids_updated[i,'wid_hupdated'])[1,'new_box']
    
  }
  
  boxes_selected <- sqldf('select wu.box_selected as selected_box,
                          pb.new_box_l as selected_box_l,
                          pb.new_box_b as selected_box_b,
                          pb.new_box_h as selected_box_h,
                          pb.new_box_vol as selected_box_vol,
                          pb.new_box_surf_area as selected_box_surf_area,
                          count(wu.box_selected) as selected_box_no_of_wids,
                          sum(wu.shipments) as selected_box_no_of_shipments
                          from wids_updated wu,
                          new_packing_boxes pb
                          where wu.box_selected = pb.new_box
                          group by wu.box_selected,
                          pb.new_box_l,pb.new_box_b,pb.new_box_h,
                          pb.new_box_vol,pb.new_box_surf_area')
  
  boxes_selected <- subset(boxes_selected,selected_box_no_of_shipments>=min_shipments)
  
  boxes_selected <- boxes_selected[order(-boxes_selected$selected_box_no_of_shipments),]
  
  boxes_selected$cum_perc <- 
    cumsum(boxes_selected$selected_box_no_of_shipments)/sum(boxes_selected$selected_box_no_of_shipments)
  
  print(paste(nrow(boxes_selected),'boxes remain after filtering out for minimum shipments per box of',min_shipments))
  return(boxes_selected)
}


# =========================================================
#  ASSIGN_SELECTED_BOXES()
# =========================================================

# Function to apply feasibility constraints and select 
# appropriate box for each wid

assign_selected_boxes <- function(processed_packing_data=processed_packing_data,
                                  rounded_packing_raw_data = rounded_packing_raw_data,
                                  packing_box_data=packing_box_data,
                                  lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax,
                                  roundto =0.5)
{
  #processed_packing_data$box_selected <- rep(NA,nrow(processed_packing_data))
  
  processed_copy <- subset(processed_packing_data,processed_packing_data$lupdated_rounded > lmidmin | 
                             processed_packing_data$bupdated_rounded > bmidmin |
                             processed_packing_data$hupdated_rounded > hmidmin)
  
  processed_copy <- subset(processed_copy,processed_copy$lupdated_rounded <= lmax & 
                             processed_copy$bupdated_rounded <= bmax &
                             processed_copy$hupdated_rounded <= hmax)
  
  rounded_packing_raw_data <- subset(rounded_packing_raw_data,rounded_packing_raw_data$lupdated > lmidmin |
                                       rounded_packing_raw_data$bupdated > bmidmin |
                                       rounded_packing_raw_data$hupdated > hmidmin)
  
  rounded_packing_raw_data <- subset(rounded_packing_raw_data,rounded_packing_raw_data$lupdated <= lmax &
                                       rounded_packing_raw_data$bupdated <= bmax &
                                       rounded_packing_raw_data$hupdated <= hmax)
  
  rounded_packing_raw_data$box_selected <- rep(NA,nrow(rounded_packing_raw_data))
  
  packing_box_data <- packing_box_data[order(packing_box_data$box_vol),]
  
  for(i in 1:nrow(rounded_packing_raw_data)) {
    
    rounded_packing_raw_data[i,'box_selected'] <- subset(packing_box_data, 
                                                         box_l>=rounded_packing_raw_data[i,'lupdated'] & 
                                                           box_b>=rounded_packing_raw_data[i,'bupdated'] & 
                                                           box_h>=rounded_packing_raw_data[i,'hupdated'])[1,'packing_box']
    
  }
  
  assigned_packing_data <- sqldf('select w.*,
                                 pb.packing_box as assigned_box,
                                 pb.box_l as assigned_box_l,
                                 pb.box_b as assigned_box_b,
                                 pb.box_h as assigned_box_h,
                                 pb.box_vol as assigned_box_vol,
                                 pb.box_surf_area as assigned_box_surf_area
                                 from processed_copy w 
                                 left join rounded_packing_raw_data r
                                 on w.lupdated_rounded= r.lupdated and w.bupdated_rounded = r.bupdated and w.hupdated_rounded = r.hupdated 
                                 left join packing_box_data pb
                                 on r.box_selected = pb.packing_box')
  
  #Difference in volume and surface area of the assigned box with respect to the used box
  assigned_packing_data <- transform(assigned_packing_data, vol_diff = shipments*(used_box_vol-assigned_box_vol))
  assigned_packing_data <- transform(assigned_packing_data, surf_area_diff = shipments*(used_box_surf_area-assigned_box_surf_area))
  
  return(assigned_packing_data)
}

# =========================================================
#  LOAD_AND_PROCESS_RAW_DATA()
# =========================================================
load_and_process_raw_data <- function(working_dir="C:/PackingOpt_1",
                                      cms_vertical = 'non_mobiles',
                                      cum_perc=cum_perc,
                                      min_shipments=min_shipments,
                                      lmin=lmin,
                                      bmin=bmin,
                                      hmin=hmin,
                                      lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax,
                                      increment = 0.5){
  
  setwd(working_dir)
  
  packing_raw_file_name <- paste('packing_raw_',cms_vertical,'.csv',sep='')
  
  packing_raw_data <- load_packing_raw_data(filename=packing_raw_file_name)
  
  packing_box_file_name <- paste('packing_boxes_',cms_vertical,'.csv',sep='')
  
  packing_box_data <- read.csv(packing_box_file_name,stringsAsFactors=F)
  
  processed_packing_data_filename = paste('processed_packing_data_',cms_vertical,'.csv',sep='')
  
  if(file.exists(processed_packing_data_filename))  {
    processed_packing_data <- read.csv(processed_packing_data_filename,stringsAsFactors=F)
  }
  else{
    processed_packing_data <- process_packing_raw_data(packing_raw_data=packing_raw_data, packing_box_data =packing_box_data)
    write.csv(processed_packing_data,processed_packing_data_filename,row.names=F)
  }
  
  rounded_packing_data_filename = paste('rounded_packing_data_',cms_vertical,'.csv',sep='')
  
  if(file.exists(rounded_packing_data_filename))  {
    rounded_packing_raw_data <- read.csv(rounded_packing_data_filename,stringsAsFactors=F)
  }
  else{
    rounded_packing_raw_data <- generate_rounded_packing_raw_data(processed_packing_data = processed_packing_data,cms_vertical = cms_vertical)
    write.csv(rounded_packing_raw_data,rounded_packing_data_filename,row.names=F)
  }
  
  new_packing_boxes_data_file_name <- paste('new_packing_boxes_','min_',lmidmin,'_',bmidmin,'_',hmidmin,'_','max_',lmax,'_',bmax,'_',hmax,'.csv',sep='')
  packing_dim_constraints_data_file_name <- paste('packing_dim_constraints_','min_',lmidmin,'_',bmidmin,'_',hmidmin,'_','max_',lmax,'_',bmax,'_',hmax,'.csv',sep='')
  
  if(file.exists(new_packing_boxes_data_file_name) & file.exists(packing_dim_constraints_data_file_name) ){
    new_packing_boxes<- read.csv(new_packing_boxes_data_file_name,stringsAsFactors=F)
    
    packing_dim_constraints <- read.table(packing_dim_constraints_data_file_name,sep=',',skip=1)
    write.table(packing_dim_constraints,'packing_dim_constraints.csv',row.names = F,col.names = F, sep=',')
  }
  else{
    new_packing_boxes <- generate_packing_boxes(increment=0.5,
                                                lmin=lmin,lmax=lmax,
                                                bmin=bmin,bmax=bmax,
                                                hmin=hmin,hmax=hmax,
                                                lmidmin = lmidmin, bmidmin=bmidmin,
                                                hmidmin = hmidmin)
  }
  initial_boxes_selected_filename <- paste('initial_boxes_selected_',cms_vertical,'_min_',lmidmin,'_',bmidmin,'_',hmidmin,'_max_',lmax,'_',bmax,'_',hmax,'_cumperc_',cum_perc,'_min_shipments_',min_shipments,'.csv',sep='')
  
  initial_boxes_selected <- select_boxes(rounded_packing_raw_data=rounded_packing_raw_data,new_packing_boxes=new_packing_boxes,min_shipments=min_shipments, cum_perc=cum_perc,lmidmin = lmidmin, bmidmin=bmidmin,
                                         hmidmin = hmidmin,lmax=lmax,bmax=bmax,hmax=hmax)
  write.csv(initial_boxes_selected,initial_boxes_selected_filename,row.names=F)
  
  
  assigned_packing_data_filename <- paste('assigned_packing_data_',cms_vertical,'_min_',lmidmin,'_',bmidmin,'_',hmidmin,'_max_',lmax,'_',bmax,'_',hmax,'_cumperc_',cum_perc,'_min_shipments_',min_shipments,'.csv',sep='')
  assigned_packing_data <- assign_selected_boxes(processed_packing_data=processed_packing_data,rounded_packing_raw_data = rounded_packing_raw_data,packing_box_data=packing_box_data,lmidmin = lmidmin,
                                                 bmidmin = bmidmin,
                                                 hmidmin = hmidmin,
                                                 lmax=lmax,bmax=bmax,hmax=hmax)
  write.csv(assigned_packing_data,assigned_packing_data_filename,row.names=F)
  
  
  assign('packing_box_data',packing_box_data, envir = .GlobalEnv)
  assign('processed_packing_data',processed_packing_data, envir = .GlobalEnv)
  assign('rounded_packing_raw_data',rounded_packing_raw_data, envir = .GlobalEnv)
  assign('new_packing_boxes',new_packing_boxes, envir = .GlobalEnv)
  assign('initial_boxes_selected',initial_boxes_selected, envir = .GlobalEnv)
  assign('assigned_packing_data',assigned_packing_data, envir = .GlobalEnv)
}

# =========================================================
#  calculate_packing_efficiency()
# =========================================================

calculate_packing_efficiency <- function(packing_final=assigned_packing_data,
                                         lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax,
                                         log_row_temp=log_row,
                                         is_initial=is_initial)
{
  packing_final <- subset(packing_final,packing_final$lupdated_rounded>lmidmin |
                            packing_final$bupdated_rounded > bmidmin |
                            packing_final$hupdated_rounded > hmidmin)
  
  packing_final <- subset(packing_final,packing_final$lupdated_rounded<=lmax &
                            packing_final$bupdated_rounded <= bmax &
                            packing_final$hupdated_rounded <= hmax)
  
  print(paste('Total shipments (in lakhs) :',round(sum(packing_final$shipments)/100000,2)))
  
  print('is_initial')
  print(is_initial)
  
  if(is_initial==1)
    log_row_temp <- c(log_row_temp,initial_shipments = round(sum(packing_final$shipments)/100000,2))
  else
    log_row_temp <- c(log_row_temp,final_shipments = round(sum(packing_final$shipments)/100000,2))
  
  packing_final_not_na <- subset(packing_final,!is.na(assigned_box_vol))
  #subset(packing_final,!is.na(box_l))
  
  print(paste('Coverage through selected boxes : ',round(sum(packing_final_not_na$shipments)/sum(packing_final$shipments),2)*100,'%',sep=''))
  
  if(is_initial==1) 
    log_row_temp <- c(log_row_temp, initial_coverage= round(sum(packing_final_not_na$shipments)/sum(packing_final$shipments),2)*100)  
  else
    log_row_temp <- c(log_row_temp, final_coverage= round(sum(packing_final_not_na$shipments)/sum(packing_final$shipments),2)*100)   
  
  print(paste('Vol. diff (in lakhs of cubic iches) between used and assigned boxes : ',
              with(packing_final_not_na,round(sum((used_box_vol-assigned_box_vol)*shipments)/100000,2))))
  
  if(is_initial==1)
    log_row_temp <- c(log_row_temp, initial_diff_in_vol= with(packing_final_not_na,round(sum((used_box_vol-assigned_box_vol)*shipments)/100000,2)))
  else
    log_row_temp <- c(log_row_temp, final_diff_in_vol= with(packing_final_not_na,round(sum((used_box_vol-assigned_box_vol)*shipments)/100000,2)))
  
  print(paste('Packing surf. area diff (in lakhs of square iches) between used and assigned boxes: ',
              with(packing_final_not_na,round(sum((used_box_surf_area-assigned_box_surf_area)*shipments)/100000,2))))
  
  if(is_initial==1)
    log_row_temp <- c(log_row_temp, initial_diff_in_surf_area= with(packing_final_not_na,round(sum((used_box_surf_area-assigned_box_surf_area)*shipments)/100000,2)))  
  else
    log_row_temp <- c(log_row_temp, final_diff_in_surf_area= with(packing_final_not_na,round(sum((used_box_surf_area-assigned_box_surf_area)*shipments)/100000,2)))  
  
  # print(paste('Minimum possible volumetric ratio if best fit packaging box is used for every WID based on its dimensions: ',
  #             with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(wid_vol*shipments),2))))
  
  print(paste('Total volumetric ratio - sum of assigned box volume divided by sum of WID shipped volumes: ',
              with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(wid_vol*shipments),2))))
  
  if(is_initial==1)
    log_row_temp <- c(log_row_temp, initial_vol_ratio= with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(wid_vol*shipments),2)))  
  else
    log_row_temp <- c(log_row_temp, final_vol_ratio= with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(wid_vol*shipments),2)))  
  
  print(paste('Total volumetric ratio (including tolerance) : ',
              with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(final_wid_vol*shipments),2))))
  
  if(is_initial==1)
    log_row_temp <- c(log_row_temp, initial_vol_ratio_with_tol= with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(final_wid_vol*shipments),2)))  
  else
    log_row_temp <- c(log_row_temp, final_vol_ratio_with_tol= with(packing_final_not_na,round(sum(assigned_box_vol*shipments)/sum(final_wid_vol*shipments),2)))  
  
  return(log_row_temp)
}

# =========================================================
#  optimize_packing_boxes
# =========================================================

run_or_model <- function(initial_boxes_selected=initial_boxes_selected,
                         no_of_boxes=no_of_boxes,
                         no_of_existing_boxes=no_of_existing_boxes,
                         old_packing_boxes = packing_box_data,
                         new_packing_boxes = new_packing_boxes,
                         use_initial_boxes = use_initial_boxes,
                         minimize_value=minimize_value,
                         lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax
){
  
  print(1)
  print(Sys.time())
  if(use_initial_boxes == 1){
    packing_boxes <- initial_boxes_selected
    names(packing_boxes) <- c('new_box','new_box_l','new_box_b','new_box_h','new_box_vol','new_box_surf_area','new_box_no_of_wids','new_box_no_of_shipments','new_box_cum_perc')
  }
  else
    packing_boxes = new_packing_boxes
  
  print(2)
  print(Sys.time())
  packing_boxes = sqldf('select nb.*, case when length(ob.packing_box) >1 then 1 else 0 end as existing_box
                        from packing_boxes nb left join old_packing_boxes ob
                        on nb.new_box_l = box_l and nb.new_box_b = box_b
                        and nb.new_box_h = box_h')
  
  existing_box_constraint <- packing_boxes[packing_boxes$existing_box==1,'new_box']
  
  write.table(matrix(existing_box_constraint,nrow=1),'existing_box_constraint.csv',row.names = F,col.names = F, sep=',')
  
  print(3)
  print(Sys.time())
  generate_packing_dim_constraints(new_packing_boxes=packing_boxes,lmidmin=lmidmin,bmidmin=bmidmin,hmidmin=hmidmin,lmax=lmax,bmax=bmax,hmax=hmax)
  
  print(4)
  print(Sys.time())
  or_cost_data <- sqldf('select orig.selected_box as base_box,
                        orig.selected_box_l as base_box_l,
                        orig.selected_box_b as base_box_b,
                        orig.selected_box_h as base_box_h,
                        orig.selected_box_vol as base_box_vol,
                        orig.selected_box_surf_area as base_box_surf_area,
                        orig.selected_box_no_of_shipments as box_box_no_of_shipments,
                        selected.new_box as box_selected,
                        selected.new_box_l as box_selected_l,
                        selected.new_box_b as box_selected_b,
                        selected.new_box_h as box_selected_h,
                        selected.new_box_vol as box_selected_vol,
                        selected.new_box_surf_area box_selected_surf_area
                        from initial_boxes_selected orig join packing_boxes selected')
  
  # for(i in 1:nrow(or_cost_data)){
  #   if(minimize_value == "volume"){
  #     or_cost_data[i,'cost'] <- ifelse(or_cost_data[i,'box_selected_l']>=or_cost_data[i,'base_box_l'] &
  #                                        or_cost_data[i,'box_selected_b']>=or_cost_data[i,'base_box_b'] &
  #                                        or_cost_data[i,'box_selected_h']>=or_cost_data[i,'base_box_h'],
  #                                      or_cost_data[i,'box_box_no_of_shipments']*(or_cost_data[i,'box_selected_vol']-or_cost_data[i,'base_box_vol']),
  #                                      99999999999999999999)
  #   }
  #   if(minimize_value == "surface_area"){
  #     or_cost_data[i,'cost'] <- ifelse(or_cost_data[i,'box_selected_l']>=or_cost_data[i,'base_box_l'] &
  #                                        or_cost_data[i,'box_selected_b']>=or_cost_data[i,'base_box_b'] &
  #                                        or_cost_data[i,'box_selected_h']>=or_cost_data[i,'base_box_h'],
  #                                      or_cost_data[i,'box_box_no_of_shipments']*(or_cost_data[i,'box_selected_surf_area']-or_cost_data[i,'base_box_surf_area']),
  #                                      99999999999999999999)
  #   }
  # }
  
  write.csv(or_cost_data, 'sample_cost_loop.csv', row.names = F)
  print(5)
  print(Sys.time())
  if(minimize_value == "volume"){
    or_cost_data$cost <- ifelse(or_cost_data$box_selected_l>=or_cost_data$base_box_l &
                                  or_cost_data$box_selected_b>=or_cost_data$base_box_b &
                                  or_cost_data$box_selected_h>=or_cost_data$base_box_h,
                                or_cost_data$box_box_no_of_shipments*(or_cost_data$box_selected_vol-or_cost_data$base_box_vol),
                                99999999999999999999)
  }
  if(minimize_value == "surface_area"){
    or_cost_data$cost <- ifelse(or_cost_data$box_selected_l>=or_cost_data$base_box_l &
                                  or_cost_data$box_selected_b>=or_cost_data$base_box_b &
                                  or_cost_data$box_selected_h>=or_cost_data$base_box_h,
                                or_cost_data$box_box_no_of_shipments*(or_cost_data$box_selected_surf_area-or_cost_data$base_box_surf_area),
                                99999999999999999999)
  }
  write.csv(or_cost_data, 'sample_cost.csv', row.names = F)
  
  or_cost_data <- or_cost_data[,c('base_box','box_selected','cost')]
  
  library(reshape2)
  
  print(6)
  print(Sys.time())
  or_cost_data <- dcast(or_cost_data,base_box~box_selected,value.var = 'cost')
  
  write.csv(or_cost_data,'cost_data.csv',row.names=F)
  
  print('before running python command')
  
  print(7)
  print(Sys.time())
  python_run_status <- system2('C:/ProgramData/Anaconda3/python',as.character(c('pack_gurobi.py',no_of_boxes,no_of_existing_boxes)),stdout = T,stderr = T)
  
  or_output <- read.csv('packing_or_output.csv',stringsAsFactors = F,row.names=1,header=T,check.names=F)
  
  or_box_summary <- data.frame(box=colnames(or_output),is_selected=sapply(or_output,max))
  
  print(8)
  print(Sys.time())
  or_box_summary <- sqldf('select obs.box as packing_box,
                          pb.new_box_l as box_l,
                          pb.new_box_b as box_b,
                          pb.new_box_h as box_h,
                          pb.new_box_l*pb.new_box_b*pb.new_box_h as box_vol,
                          2*(pb.new_box_l+pb.new_box_b)*(pb.new_box_b+pb.new_box_h) as box_surf_area
                          from or_box_summary obs left join
                          new_packing_boxes pb on obs.box = pb.new_box
                          where is_selected=1')
  
  return(or_box_summary)
}


# =========================================================
#  optimize_packing_boxes
# =========================================================

optimize_packing_boxes <- function(working_dir="C:/PackingOpt_1",
                                   training_file ="packing_raw_mobiles.csv",
                                   test_file="packing_raw.csv",
                                   packing_box_file='packing_boxes_all.csv',
                                   cms_vertical='non_mobiles',
                                   lmin=6.0,
                                   bmin=4.5,
                                   hmin=1.0,
                                   lmidmin = 0,
                                   bmidmin = 0,
                                   hmidmin = 0,
                                   lmax=9,
                                   bmax=7.5,
                                   hmax=4,
                                   select_box_incr=0.5,
                                   cum_perc=0.8,
                                   min_shipments=1000,
                                   boxes_selected_file=NA,
                                   no_of_boxes = 30,
                                   no_of_existing_boxes=0,
                                   use_initial_boxes=1,
                                   minimize_value='surface_area'){
  
  log_row <- c(cms_vertical=cms_vertical,
               lmidmin = lmidmin,
               bmidmin = bmidmin,
               hmidmin = hmidmin,
               lmax=lmax,
               bmax=bmax,
               hmax=hmax,
               cum_perc=cum_perc,
               min_shipments=min_shipments,
               no_of_boxes = no_of_boxes,
               no_of_existing_boxes=no_of_existing_boxes,
               use_initial_boxes=use_initial_boxes,
               minimize_value=minimize_value)
  
  print('calling load and process raw data')
  
  load_and_process_raw_data(working_dir=working_dir,
                            cms_vertical = cms_vertical,
                            cum_perc=cum_perc,
                            min_shipments=min_shipments,
                            lmin=lmin,
                            bmin=bmin,
                            hmin=hmin,
                            lmidmin = lmidmin,
                            bmidmin = bmidmin,
                            hmidmin = hmidmin,
                            lmax=lmax,
                            bmax=bmax,
                            hmax=hmax,
                            increment = 0.5) 
  
  if(!is.na(boxes_selected_file)){
    test_boxes_selected <- read.csv(boxes_selected_file,stringsAsFactors = F)
    assign(paste(warehouse,'_test_boxes',sep=''),test_boxes_selected, envir = .GlobalEnv)
  }
  
  if(exists('test_boxes_selected')){
    final_boxes_selected <- test_boxes_selected
  }
  else{
    
    print('calling calculate packing efficiency')
    
    log_row <- calculate_packing_efficiency(packing_final=assigned_packing_data,
                                            lmidmin=lmidmin,
                                            bmidmin=bmidmin,
                                            hmidmin=hmidmin,
                                            lmax=lmax,
                                            bmax=bmax,
                                            hmax=hmax,
                                            log_row_temp =log_row,
                                            is_initial = 1)
    ########
    
    print('calling run or model')  
    
    final_boxes_selected <- run_or_model(initial_boxes_selected=initial_boxes_selected,
                                         new_packing_boxes=new_packing_boxes,
                                         no_of_boxes=no_of_boxes,
                                         no_of_existing_boxes=no_of_existing_boxes,
                                         use_initial_boxes = use_initial_boxes,
                                         minimize_value=minimize_value,
                                         lmidmin=lmidmin,
                                         bmidmin=bmidmin,
                                         hmidmin=hmidmin,
                                         lmax=lmax,
                                         bmax=bmax,
                                         hmax=hmax)
    
  }
  
  cat('\n')
  print('Packing utilization with 100% adherence')
  cat('\n')
  
  optimized_packing_data <- assign_selected_boxes(processed_packing_data=processed_packing_data,rounded_packing_raw_data = rounded_packing_raw_data,packing_box_data=final_boxes_selected,lmidmin = lmidmin,
                                                  bmidmin = bmidmin,
                                                  hmidmin = hmidmin,
                                                  lmax=lmax,bmax=bmax,hmax=hmax)
  
  optimized_packing_data_file_name <- paste('optimized_packing_data_',cms_vertical,'_min_',lmidmin,'_',bmidmin,'_',hmidmin,'_max_',lmax,'_',bmax,'_',hmax,'_cumperc_',cum_perc,'_min_shipments_',min_shipments,'_no_of_boxes_',no_of_boxes,'_existing_boxes_',no_of_existing_boxes,'.csv',sep='')
  write.csv(optimized_packing_data,optimized_packing_data_file_name,row.names=F)
  
  
  print('Packing utilization after optimized box selection and fitting:')
  cat('\n')
  
  log_row <- calculate_packing_efficiency(packing_final=optimized_packing_data,
                                          lmidmin=lmidmin,
                                          bmidmin=bmidmin,
                                          hmidmin=hmidmin,
                                          lmax=lmax,
                                          bmax=bmax,
                                          hmax=hmax,
                                          log_row_temp = log_row,
                                          is_initial = 0)
  
  optimal_boxes_summary <- sqldf("select wf.assigned_box, wf.assigned_box_l, wf.assigned_box_b, wf.assigned_box_h, 
                                 wf.assigned_box_vol as vol, wf.assigned_box_surf_area as surf_area, 
                                 sum(shipments) as shipments, round(sum(assigned_box_vol*shipments)/sum(wid_vol*shipments),2) as pf from optimized_packing_data wf 
                                 group by wf.assigned_box, wf.assigned_box_l, wf.assigned_box_b, wf.assigned_box_h")
  
  optimal_boxes_file_name <- paste('optimal_boxes_',cms_vertical,'_min_',lmidmin,'_',bmidmin,'_',hmidmin,'_max_',lmax,'_',bmax,'_',hmax,'_cumperc_',cum_perc,'_min_shipments_',min_shipments,'_no_of_boxes_',no_of_boxes,'_existing_boxes_',no_of_existing_boxes,'.csv',sep='')
  write.csv(optimal_boxes_summary,optimal_boxes_file_name,row.names=F)
  
  write.table(matrix(log_row,nrow=1), "pack_opt_log.csv", sep = ",",append=T,row.names=F,col.names = F)
}
