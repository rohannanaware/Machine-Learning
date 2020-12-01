import pandas as pd
import numpy as np
import datetime as dt
import os
from random import seed, random
import matplotlib.pyplot as plt

os.chdir('C:/Users/rohan.nanaware/Documents/01 Flipkart/01 FC analytics/27 Pick by DH')

# read input data
picking_data = pd.read_csv('02 raw data/blr_wfld jan picking data 23 18-55.csv')
pincode_grouping = pd.read_csv('02 raw data/pincode_grouping.csv')

# logic
'''

--High level numbers :
1. Filter all orders for the pincode groups mentioned in data
2. Check the wave wise demand - will need more details to get capacity utlisation numbers
3. Check the amount of load for a given wave received before the end of previous wave

--Picklist creation logic
Scenario 1. : Running on FL
1. Create PLs at the start of cutoff, partitioned by each Pincode group and pickzone
    the UL for PL size is 12 which would reduce only if the Pincode - pickzone group does not have enough orders
    evaluate the trade off between cross zone vs. single pickzone
2. Assign PLs equal to the number of pickers : picklist creation time = DBD start time
3. Add the CT + Setup time for all PLs based on the PL quantity | picking CT per item = 25 sec, setup time per item = 8.75s
4. Next PL creation time would be as and when a picker becomes free
Scenario 2. : Running on PL
5. On top of this run a loop to check if there is any new order, if yes then which Pincoode group
6. Check if the orders are in relaxed time interval

--Results
1. Avg. picklist size, # of PL created, Quantity processed
2. Load received during and prior to relaxed period
3. Load processed during and prior to relaxed period
4. Capacity utlization, hourly
5. LDAP utlization

'''

picking_data.columns
picking_data[['reservation_created_timestamp','shipment_dispatched_timestamp','dbd']].head()
# filter for a given dispatch date
data = picking_data
data['reservation_created_timestamp'] = pd.to_datetime(data['reservation_created_timestamp'],format = '%d-%m-%Y %H:%M')
data['shipment_dispatched_timestamp'] = pd.to_datetime(data['shipment_dispatched_timestamp'],format = '%d-%m-%Y %H:%M')
data['dbd'] = pd.to_datetime(data['dbd'],format = '%d-%m-%Y %H:%M')
data['dbd'].value_counts()
# check the wave wise load distribution - select one wave for simulation
# data = data[data['dbd'].astype(str) == '2020-01-10 03:55:00']
data = data[data['dbd'].astype(str) == '2020-01-23 18:55:00']
# join data with pincode groups
pincode_grouping.columns
pincode_grouping.drop_duplicates(keep = 'first',inplace = True)
data.columns
data = pd.merge(data,pincode_grouping,
                how = 'left',
                left_on='fulfill_item_unit_destination_pincode',
                right_on='Pincode')
pincode_group = 0
pickzone = 0
no_of_orders = 0
max_picklist_size = 12
relax_time = 160
picklist_id_sim = 0
data['picklist_id_sim'] = 0
data['picklist_created_timestamp_sim'] = 0
i = 0
#  creating reservation created timestamp as a unique column
for index, row in data.iterrows():
    data.loc[index,'reservation_created_timestamp'] = data.loc[index,'reservation_created_timestamp'] + dt.timedelta(random()/1000)
# sort data in increasing order of reservation created timestamp
data.sort_values(['reservation_created_timestamp'],inplace = True)
for index, row in data[data['picklist_id_sim'] == 0].iterrows():
    if i % 100 == 0:
        print('Running loop number : {}, processed reservation count = {}'.format(i,data[data['picklist_id_sim'] != 0].shape[0]))
    i += 1
    Group = row['Group']
    picking_zone_name = row['picking_zone_name']
    reservation_created_timestamp = row['reservation_created_timestamp']
    # filter entire data for the pincode group and pickzone
    data_filt = data[(data['Group'] == Group) &
                     (data['picking_zone_name'] == picking_zone_name) &
                     (data['reservation_created_timestamp'] <= reservation_created_timestamp) &
                     (data['picklist_id_sim'] == 0)]
    no_of_orders = data_filt.shape[0]
    if (no_of_orders < max_picklist_size) and ((row['dbd'] - row['reservation_created_timestamp']).total_seconds()/60 > relax_time):
        continue
    else:
        picklist_id_sim += 1
        data.loc[data.index.isin(data_filt.index),'picklist_id_sim']= picklist_id_sim
        data.loc[data.index.isin(data_filt.index),'picklist_created_timestamp_sim'] = row['reservation_created_timestamp']
data_pre_relax_pending = data[data['picklist_id_sim'] == 0]
aggregations = {'reservation_id' : {'piq':'count'},
                'reservation_created_timestamp':{'picklist_created_timestamp_sim':'max'}}
data_agg = data_pre_relax_pending.groupby(['Group','picking_zone_name'], as_index=False).agg(aggregations)
data_agg.columns = ['Group','picking_zone_name','picklist_id_sim','picklist_created_timestamp_sim']
for index, row in data_agg.iterrows():
    if index % 100 == 0:
        print('Finished running : {}'.format(index))
    picklist_id_sim += 1
    picklist_created_timestamp_sim = max(row['picklist_created_timestamp_sim'],(data['dbd'][0] - dt.timedelta(minutes = relax_time)))
    data.loc[(data['Group'] == row['Group']) & 
             (data['picking_zone_name'] == row['picking_zone_name']) &
             (data['picklist_id_sim'] == 0),'picklist_id_sim'] = picklist_id_sim
    data.loc[(data['Group'] == row['Group']) & 
             (data['picking_zone_name'] == row['picking_zone_name']) &
             (data['picklist_created_timestamp_sim'] == 0),'picklist_created_timestamp_sim'] = picklist_created_timestamp_sim
# simulation code ends here
# summarise results
data['picklist_created_timestamp_sim'] = pd.to_datetime(data['picklist_created_timestamp_sim'])
for index, row in data.iterrows():
    tm = row['picklist_created_timestamp_sim']
    data.loc[index,'picklist_created_timestamp_sim_round'] = tm - dt.timedelta(minutes=tm.minute % 15,
            seconds=tm.second,
            microseconds=tm.microsecond)
data['reservation_quantity'] = 1
# data.picklist_created_timestamp_sim_round.value_counts()
data_pl_lvl = data.groupby(['picklist_id_sim']).agg({
        'reservation_quantity':'sum',
        'picklist_created_timestamp_sim':'max',
        'picklist_created_timestamp_sim_round':'max',
        'reservation_created_timestamp':'max'})    
data_pl_lvl.is_relax_slot = 0
for index, row in data_pl_lvl.iterrows():
    if (((data['dbd'][0] - row['picklist_created_timestamp_sim']).total_seconds()/60) <= relax_time):
        data_pl_lvl.loc[index,'is_relax_slot'] = 1
    else:
        data_pl_lvl.loc[index,'is_relax_slot'] = 0
    if (((data['dbd'][0] - row['reservation_created_timestamp']).total_seconds()/60) > relax_time):
        data_pl_lvl.loc[index,'is_reserved_prior_to_relax'] = 1
    else:
        data_pl_lvl.loc[index,'is_reserved_prior_to_relax'] = 0
data_pl_lvl.to_csv('04 code output/data_pl_lvl_v4.csv')

# Module 2 code starts here
'''
Inputs req. - 
    # no. of pickers
    # end of previous cutoff
    # no. of picklists
    # CT for picklist processing : setup, inter item picked time
        - picking_time = Setup time + Inter item picking time * No. of items
    # picklist level details on quantity, picklist created time

Output -
    # picklist assigned timestamp
    # picklist completed timestamp
    
Desired state - 
    # manpower in constrained time slot is enough to finish picking in relaxed slot
    # picklist completed timestamp of last PL should be less than the DBD
'''

# no. of pickers
no_of_pickers = data.picklist_assigned_to.nunique()
prev_dbd = '2020-01-23 13:30:00'

# sort the PLs by picklist_created timestamp
data_pl_lvl.sort_values(['picklist_created_timestamp_sim'],inplace = True)
data_pl_lvl.reset_index(drop = True,inplace = True)
picklists = data_pl_lvl.loc[:,['picklist_created_timestamp_sim','reservation_quantity','is_relax_slot']]

# loop variables
pickers = pd.DataFrame(data.picklist_assigned_to.unique())
pickers.columns = ['LDAP_id']
pickers['count_of_pls_processed'] = 0
pickers['busy_till'] = pd.to_datetime(prev_dbd)
picklists['picklist_assigned_timestamp_sim'] = 0
picklists['picklist_assigned_to_sim'] = 0
picklists['picklist_completed_timestamp_sim'] = 0
setup_time = 300
inter_item_picking_time = 30

for index, row in picklists.iterrows():
#    if index == 2:
#        break
    # sort the pickers by the order in which they will become free
    pickers.sort_values('busy_till',inplace = True)
    pickers.reset_index(drop = True,inplace = True)
    # calculate the total picking time
    p2pc = setup_time + inter_item_picking_time * row['reservation_quantity']
    # check how far we have to wait until we can assign a picklist to the picker
    busy_till = max(pickers.loc[0,'busy_till'],row['picklist_created_timestamp_sim'])
    picklists.loc[index,'picklist_assigned_timestamp_sim'] = pd.to_datetime(busy_till)
    # update the busy till for picker
    pickers.loc[0,'busy_till'] = busy_till + dt.timedelta(seconds = p2pc)
    pickers.loc[0,'count_of_pls_processed'] = pickers.loc[0,'count_of_pls_processed'] + 1
    # update picklist attributes
    picklists.loc[index,'picklist_assigned_to_sim'] = pickers.loc[0,'LDAP_id']
    picklists.loc[index,'picklist_completed_timestamp_sim'] = pickers.loc[0,'busy_till']
    print(index)
    