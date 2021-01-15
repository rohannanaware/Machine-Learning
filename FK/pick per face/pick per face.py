
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
#input_data_sim.drop(['pickzone','pl_max','picking_zone_sim','storage_location_label_sim'],axis = 1,inplace = True)
#lookup the pickzones for the assigned bins
location_dim = input_data_sim.groupby(['picking_zone','storage_location_label'],as_index=False).agg({'fulfill_reference_id':'count'})
location_dim.sort_values(['storage_location_label','fulfill_reference_id'],ascending=[0,0],inplace = True)
location_dim.drop_duplicates(subset = 'storage_location_label',keep='first', inplace=True)
location_dim.drop('fulfill_reference_id',axis = 1,inplace = True)
location_dim.columns = ['picking_zone_sim','storage_location_label_sim']
input_data_sim = pd.merge(input_data_sim,
                           location_dim,
                           left_on='bin_assigned',
                           right_on='storage_location_label_sim',
                           how='left')
# input_data_sim.isna().sum()
input_data_sim['picking_zone_sim'] = input_data_sim['picking_zone_sim'].str.lower()
input_data_sim = pd.merge(input_data_sim,
                          ulub_bts_plsize,
                          how='left',
                          left_on='picking_zone_sim',
                          right_on='pickzone')
input_data_sim.loc[input_data_sim['pickzone'].isna(),'pl_max'] = 12

output_data_sim = pd.DataFrame()
for pz in input_data_sim.picking_zone_sim.unique():
    
    loop_data = input_data_sim[input_data_sim['picking_zone_sim'] == pz]
    loop_data.sort_values(by='reservation_created_timestamp',
                          ascending = True,inplace = True)
    loop_data.reset_index(inplace = True, drop = True)
    loop_data.reset_index(inplace = True, drop = False)
    pl_max = max(loop_data.pl_max)
    loop_data['picklist_id_sim'] = (loop_data['index'] // pl_max).astype(int).astype(str) + '_' + pz
    print('pickzone {} ran | cumulative reservations of {} %'.format(pz,round((output_data_sim.shape[0] + loop_data.shape[0])/input_data_sim.shape[0]*100,2)))
    output_data_sim = output_data_sim.append(loop_data)
        
# benchmark metrics : as is
input_data_sim_agg = input_data_sim.groupby(['picking_zone','picklist_display_id'],as_index=False).agg(
        {'fulfill_reference_id':'nunique',
         'storage_location_label':'nunique'})
input_data_sim_agg['pick_per_face'] = input_data_sim_agg['fulfill_reference_id']/input_data_sim_agg['storage_location_label']
input_data_sim_agg['pick_per_face'].agg({np.mean,np.median})
# mean      2.56 median    1.7
input_data_sim_agg['fulfill_reference_id'].agg({np.mean,np.median})
# mean      9.8 median    9

# benchmark metrics : simulation
output_data_sim_agg = output_data_sim.groupby(['picking_zone_sim','picklist_id_sim'],as_index=False).agg(
        {'fulfill_reference_id':'nunique',
         'bin_assigned':'nunique'})
output_data_sim_agg['pick_per_face'] = output_data_sim_agg['fulfill_reference_id']/input_data_sim_agg['storage_location_label']
output_data_sim_agg['pick_per_face'].agg({np.mean,np.median})
# mean      4.15 median    2.4
output_data_sim_agg['fulfill_reference_id'].agg({np.mean,np.median})
# mean      11.78 median    12

# export data
input_data_sim_agg.to_csv('input_data_sim_agg.csv')
output_data_sim_agg.to_csv('output_data_sim_agg.csv')
