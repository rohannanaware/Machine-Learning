# Author : Rohan M. Nanaware
# Date C.: 25th Oct 2020
# Date M.: 30th Nov 2020
# Purpose: Measure the existing underutilisation in FC under LPHT based dispatch construct

#####################################################################
###################### load required libraries ######################
#####################################################################
 
import pandas as pd
import numpy as np
import os
from datetime import datetime

#####################################################################
######################### set working directry ######################
#####################################################################

os.chdir(r'C:\Users\rohan.nanaware\Documents\33 D0 connect')

#####################################################################
######################### read input data ###########################
#####################################################################

input_data = pd.read_csv('input_data_nov20.csv')
source_capacity = pd.read_csv('source_capacity.csv')

#####################################################################
######################### clean the data ############################
#####################################################################

input_data.fc_name.value_counts()
fc_name = 'frk_bts'
# filtering for warehouse
input_data = input_data[input_data['fc_name'] == fc_name]
source_capacity = source_capacity.reset_index(drop = False)
source_capacity.columns = ['Source', 'Date', 'Cutoff time', 'Capacity', 'Running Counter',
       'MH pincode', 'buffer_percentage','buffer_percentage_2']
source_capacity = source_capacity.loc[source_capacity['Source'] == fc_name,['Source','Date','Cutoff time','Capacity','Running Counter']]
source_capacity['Date'] = pd.to_datetime(source_capacity['Date']).dt.date
source_capacity['Cutoff time'] = pd.to_datetime(source_capacity['Cutoff time']).dt.time
#input_data_backup = input_data
input_data = input_data.loc[:,['fulfill_reference_id', 'fc_name', 
       'approve_datetime', 'approve_dt', 'approve_tm',
       'dbd_datetime', 'dbd_dt', 'dbd_tm', 'lpht_datetime', 'lpht_dt',
       'lpht_tm', 'dispatch_date', 'dispatch_dt', 'dispatch_tm']]
input_data['dbd_datetime'] = pd.to_datetime(input_data['dbd_datetime'])
input_data['dbd_dt'] = pd.to_datetime(input_data['dbd_datetime']).dt.date
input_data['dbd_tm'] = pd.to_datetime(input_data['dbd_datetime']).dt.time

# assign the dbd that's the closest to the lpht
#   - Filter out dbds after approve date time
#   - Maintain a dbd date time, dbd date and dbd time, total capacity, active capacity column
#   - Loop 1 : If lpht_tm > approve_tm then lpht_dt = approve_dt else lpht_dt = approve_dt + 1
#           : do while dbd is null (Filter all dbds with date time between approve and lpht date time and non zero capacity
#           : list(dbd) >= 1 then (Sort in descending order of time and assign the top dbd to the order)
#               else lpht_dt = lpht_dt + 1, continue

dbds = input_data.groupby(['dbd_datetime','dbd_dt','dbd_tm'],as_index = False).agg({'fulfill_reference_id':'count'})
dbds.columns
dbds = pd.merge(dbds,
              source_capacity,
              left_on = ['dbd_dt','dbd_tm'],
              right_on = ['Date','Cutoff time'],
              how = 'left')
dbds_backup = dbds
dbds = dbds[~dbds.Capacity.isna()]
dbds.drop('fulfill_reference_id',axis = 1,inplace = True)
input_data['dbd_sim'] = 0
input_data['lpht_sim'] = 0
dbds['wave_cap'] = dbds['Capacity']
dbds['active_cap'] = dbds['Capacity']
input_data.reset_index(inplace = True, drop = True)
pd.set_option('mode.chained_assignment', None)

print(datetime.now())
for index, row in input_data.iterrows():
    
    if index % 10000 == 0:
        print(index)
        print(datetime.now())
    
    #find the lpht date time    
    if row['lpht_tm'] > row['approve_tm']:
        lpht_dt = row['approve_dt']
    else:
        lpht_dt = (pd.to_datetime(row['approve_datetime']) + pd.DateOffset(hours=24)).strftime(format = '%Y-%m-%d')
    lpht_dt_tm = pd.to_datetime(lpht_dt+' '+row['lpht_tm'])
    # find the list of eligible dbds    
    dbds_filt = dbds.loc[(dbds['dbd_datetime'] >= row['approve_datetime']) &\
                         (pd.to_datetime(dbds['dbd_datetime']) <= lpht_dt_tm) &\
                         (dbds['active_cap'] >= 1),'dbd_datetime']
    while dbds_filt.shape[0] == 0:
        lpht_dt = (pd.to_datetime(lpht_dt) + pd.DateOffset(hours=24)).strftime(format = '%Y-%m-%d')
        lpht_dt_tm = pd.to_datetime(lpht_dt+' '+row['lpht_tm'])
        dbds_filt = dbds.loc[(dbds['dbd_datetime'] >= row['approve_datetime']) &\
                         (pd.to_datetime(dbds['dbd_datetime']) <= lpht_dt_tm) &\
                         (dbds['active_cap'] >= 1),'dbd_datetime']
        
    dbds.loc[dbds['dbd_datetime'].isin(dbds_filt.to_frame().sort_values(by = 'dbd_datetime',ascending = False).head(1).dbd_datetime),'active_cap'] = dbds.loc[dbds['dbd_datetime'].isin(dbds_filt.to_frame().sort_values(by = 'dbd_datetime',ascending = False).head(1).dbd_datetime),'active_cap'] - 1
        
    input_data.loc[index,'dbd_sim'] = dbds_filt.to_frame().sort_values(by = 'dbd_datetime',ascending = False).head(1)['dbd_datetime'].reset_index(drop = True)[0]
    # code updates
    input_data.loc[index,'lpht_sim'] = lpht_dt_tm
        
print(datetime.now())

# Simulation code ends here

# Result QC
temp = dbds.loc[dbds['active_cap'] < dbds['wave_cap'],:]
temp['cap_used'] = temp['wave_cap']-temp['active_cap']
temp['cap_used'].sum()

# Metrics
# D0 connect impact
input_data['lpht_datetime'] = pd.to_datetime(input_data['lpht_datetime'])
input_data['approve_datetime'] = pd.to_datetime(input_data['approve_datetime'])

input_data['lpht_24hr_connect'] = ((input_data['lpht_datetime'] - input_data['approve_datetime']).astype('timedelta64[h]') <= 24).astype('int')

# Capacity utilization, pre and post
dbds.to_csv('simulation_underutilization_frk_bts_20201029-20201114.csv')
input_data.to_csv('simulation_raw_underutilization_frk_bts_20201029-20201114.csv')
