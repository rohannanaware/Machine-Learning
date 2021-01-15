
################################################
# load required libraries
################################################

import pandas as pd
import os
from datetime import datetime as dt
import numpy as np

################################################
# set working directory
################################################

os.chdir('C:/Users/rohan.nanaware/Documents/37 pick per face')

################################################
# import data
################################################

# input_data = pd.read_csv('ulub_bts_bbd_reservations.csv')
input_data = pd.read_csv('ulub_bts_bbd_reservations_oct19-12pm-4pm.csv')

################################################
# data checks/cleaning
################################################

#NA count
#input_data.isna().sum()
input_data.dropna(inplace = True)
#input_data.columns

################################################
# data prep for simulation
################################################

# invetory data creation | rerun entire below block for reset
# filter data for a given reservation date
#input_data_inv = input_data[input_data['reservation_created_date_key'] == 20201016]
input_data_inv = input_data
input_data_inv.reset_index(inplace = True, drop = True)

# fill bins with a days reservations : aggregate at day bin x wid level
inventory_binwid_lvl = input_data_inv.groupby(
        ['storage_location_label','sequence_id', 'wid'], as_index = False
        ).agg({"fulfill_reference_id":"count"})
inventory_binwid_lvl.columns = ['storage_location_label', 'sequence_id', 'wid', 'qoh']
inventory_bin_lvl = input_data_inv.groupby(
        ['storage_location_label'], as_index = False
        ).agg({"fulfill_reference_id":"count",
                "wid":"nunique"})
del input_data_inv
inventory_bin_lvl.columns = ['storage_location_label','qoh_bin', 'wid_count'] 
inventory_binwid_lvl = pd.merge(inventory_binwid_lvl,
                                inventory_bin_lvl,
                                how='left',
                                on=['storage_location_label'])
inventory_binwid_lvl['atp'] = inventory_binwid_lvl['qoh']
inventory_binwid_lvl['bin_reservations'] = 0
#sort by wids to pick the bin with max wids
inventory_binwid_lvl.sort_values(by='wid_count',ascending=False,inplace = True)
# simulation input data | filter data for a given reservation date and a given cutoff | later these columns would be looped upon
#input_data_sim = input_data[(input_data['reservation_created_date_key'] == 20201016) &
#                             (input_data['dispatch_by_cutoff'] == '2020-10-16 18:30:00')]
input_data_sim = input_data
input_data_sim.sort_values(by='reservation_created_timestamp',ascending = True, inplace = True)
input_data_sim.reset_index(inplace = True, drop = True)
input_data_sim['bin_assigned'] = 0

# simulation loop
for index, row in input_data_sim.iterrows():
    
    if index % 10000 == 0:
        print(index)
        print(dt.now())
    # filter inventory data for the wid
    bin_label = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']) &
                                (inventory_binwid_lvl['atp'] > 0),
                                'storage_location_label'].head(1)
    # reduce atp by 1
    inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']) & (inventory_binwid_lvl['storage_location_label'].isin(bin_label)),'atp'] = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']) & (inventory_binwid_lvl['storage_location_label'].isin(bin_label)),'atp'] - 1
    # increase reservations on bin by 1
    inventory_binwid_lvl.loc[(inventory_binwid_lvl['storage_location_label'].isin(bin_label)),'bin_reservations'] = inventory_binwid_lvl.loc[(inventory_binwid_lvl['storage_location_label'].isin(bin_label)),'bin_reservations'] + 1
    # resort the dataframe by reservation and wid count
    inventory_binwid_lvl.sort_values(by=['bin_reservations','wid_count'],ascending=[0,0],inplace = True)
    inventory_binwid_lvl.reset_index(inplace = True,drop=True)
    # assign the bin to reservation
    bin_label.to_frame().reset_index(inplace = True,drop=True)
    input_data_sim.loc[index,'bin_assigned'] = bin_label.iloc[0]

# picklist creation code
ulub_bts_plsize = pd.read_csv('ulub_bts_plsize.csv')
ulub_bts_plsize['pickzone'] = ulub_bts_plsize['pickzone'].str.lower()
ulub_bts_plsize.drop('fc',axis = 1,inplace = True)
input_data_sim['picking_zone'] = input_data_sim['picking_zone'].str.lower()
input_data_sim = pd.merge(input_data_sim,
                          ulub_bts_plsize,
                          how='left',
                          left_on='picking_zone',
                          right_on='pickzone')
input_data_sim.loc[input_data_sim['pickzone'].isna(),'pl_max'] = 12

output_data = pd.DataFrame()
#output_data.columns = input_data_sim.columns
loop_counter = 0
for pz in input_data_sim.picking_zone.unique():
    
    loop_data = input_data_sim[input_data_sim['picking_zone'] == pz]
    loop_data.sort_values(by='order_item_approved_timestamp',
                          ascending = True,inplace = True)
    loop_data.reset_index(inplace = True, drop = True)
    pl_id_counter = 1
    pl_size = 0
    for index, row in loop_data.iterrows():
        
        if loop_counter % 1000 == 0:
            print(loop_counter)
            
        if pl_size < row['pl_max']:
            # add more items to the pl
            loop_data[index,'pl_id_sim'] = str(pl_id_counter) + '_' + pz
            pl_size = pl_size + 1
        else:
            # create a new pl
            pl_id_counter = pl_id_counter + 1
            pl_size = 0
        output_data = output_data.append(loop_data)
        loop_counter = loop_counter + 1

output_data_sim = pd.DataFrame()
for pz in input_data_sim.picking_zone.unique():
    
    loop_data = input_data_sim[input_data_sim['picking_zone'] == pz]
    loop_data.sort_values(by='order_item_approved_timestamp',
                          ascending = True,inplace = True)
    loop_data.reset_index(inplace = True, drop = True)
    loop_data.reset_index(inplace = True, drop = False)
    pl_max = max(loop_data.pl_max)
    loop_data['picklist_id_sim'] = (loop_data['index'] // pl_max).astype(int).astype(str) + '_' + pz
    loop_data['picklist_id_sim'].value_counts()
    
    print('pickzone {} ran | cumulative reservations of {} %'.format(pz,round((output_data_sim.shape[0] + loop_data.shape[0])/input_data_sim.shape[0]*100,2)))
    output_data_sim = output_data_sim.append(loop_data)

# benchmarks
input_data_sim_agg = input_data_sim.groupby(['picklist_display_id'],as_index=False).agg(
        {'fulfill_reference_id':'count',
         'storage_location_label':'nunique'})
input_data_sim_agg['pick_per_face_asis'] = input_data_sim_agg['fulfill_reference_id']/input_data_sim_agg['storage_location_label']
input_data_sim_agg['pick_per_face_asis'].agg({np.mean,np.median})
# mean      1.265207 median    1.000000
input_data_sim_agg['fulfill_reference_id'].agg({np.mean,np.median})
# mean      2.432859 median    2.000000

# simulation results
output_data_sim_agg = output_data_sim.groupby(['picklist_id_sim'],as_index=False).agg(
        {'fulfill_reference_id':'count',
         'bin_assigned':'nunique'})
output_data_sim_agg['pick_per_face_asis'] = output_data_sim_agg['fulfill_reference_id']/input_data_sim_agg['storage_location_label']
output_data_sim_agg['pick_per_face_asis'].agg({np.mean,np.median})
# mean      7.713186 median    6.000000
output_data_sim_agg['fulfill_reference_id'].agg({np.mean,np.median})
# mean      10.920091 median    12.000000





# qc
temp1 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']) & (inventory_binwid_lvl['storage_location_label'].isin(bin_label)),:]
temp2 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']),:]
temp3 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['storage_location_label'].isin(bin_label)),:]

temp4 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']) & (inventory_binwid_lvl['storage_location_label'].isin(bin_label)),:]
temp5 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['wid'] == row['wid']),:]
temp6 = inventory_binwid_lvl.loc[(inventory_binwid_lvl['storage_location_label'].isin(bin_label)),:]
