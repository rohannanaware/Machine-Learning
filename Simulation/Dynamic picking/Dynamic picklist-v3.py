# Read in required packages
import os
import pandas as pd
import numpy as np
import math
from datetime import datetime


def run_simulation(data):
    global list_of_slots
    global picklist_id
    data['fulfill_item_unit_dispatch_by_cutoff']=pd.to_datetime(data['fulfill_item_unit_dispatch_by_cutoff'])
    #Identify lsit of dbds present in data
    dbd=list(data['fulfill_item_unit_dispatch_by_cutoff'].unique())
    dbd.sort()
    
    dbds=pd.DataFrame(dbd,columns=['dbd'])
    
    #create column with previous dbd
    dbds['prev_dbd']=dbds.shift(1)
    dbds['dbd']=pd.to_datetime(dbds['dbd'])
    dbds['prev_dbd']=pd.to_datetime(dbds['prev_dbd'])
    dbds.index.name='dbd_sequence'
    
    #remove dbd without any previous dbd
    dbds=dbds[~dbds['prev_dbd'].isnull()].reset_index()
    
    dbds['dbd_sequence']=dbds['dbd_sequence']*100000
    
    
    
    # Remove duplicates from data
    data.drop_duplicates(keep = 'first', inplace = True)
    
    # Remove all orders with more than one reservations
    data.sort_values('fulfill_item_unit_ship_together_preference_id', inplace = True)
    data.drop_duplicates(subset ="fulfill_item_unit_ship_together_preference_id",keep =False,inplace = True)
    
    # Split timestamp into Date and Time
    data['reservation_created_timestamp'] = pd.to_datetime(data['reservation_created_timestamp'])
    
    # Create a new column with volume of product
    data['fulfill_item_unit_dispatch_by_cutoff']=pd.to_datetime(data['fulfill_item_unit_dispatch_by_cutoff'])
    data['product_volume'] = data['product_detail_height']*data['product_detail_length']*data['product_detail_breadth']
    
    data_all=data.copy()
    # User inputs
    global max_distance
    global min_quantity
    global max_quantity
    global max_weight
    global max_volume
    global slot_size
    global slot_size_rel
    
    #cut_off_current  = "2018-09-08 13:00:00"#pd.to_datetime(input('Enter the current cut-off timestamp : '))
    #cut_off_previous = "2018-09-08 00:00:00"#pd.to_datetime(input('Enter the previous cut-off timestamp : '))
    
    final_output=pd.DataFrame()
    
    #iterating over different dbds in the data
    for index_dbd,row_dbd in dbds.iterrows():
        print('DBD started : {}'.format(row_dbd['dbd']))
        cut_off_current=row_dbd['dbd']
        cut_off_previous=row_dbd['prev_dbd']
        data=data_all[data_all['fulfill_item_unit_dispatch_by_cutoff']==cut_off_current]
        
        # Define slots : at a dbd level
        data['slot_id'] = data['reservation_created_timestamp'].apply(lambda x:0 if x < (pd.to_datetime(cut_off_previous) - pd.DateOffset(hours = 1.5)) else (math.ceil((x - (pd.to_datetime(cut_off_previous) - pd.DateOffset(hours = 1.5))).seconds/(60*slot_size)) if x < (pd.to_datetime(cut_off_current) - pd.DateOffset(hours = 1.5))
     else 9000 + math.ceil((x - (pd.to_datetime(cut_off_current) - pd.DateOffset(hours = 1.5))).seconds/(60*slot_size_rel))))
        
        # create a list of slots object - this removes the issue of a pickzone not having enough slot to run the whole loop 
        list_of_slots = data['slot_id'].unique().tolist()
        list_of_slots.append(1000000)
        list_of_slots.sort()
        # Initialise picklist_id variable
        
        picklist_id =1
        data['picklist_id'] = 0
        df_op = pd.DataFrame()
        df_out = pd.DataFrame()
        pickzones_completed = 0
        list_of_pickzones = data['picklist_picking_zone'].astype('str').unique().tolist()
        list_of_pickzones.sort()
        
        
        for pickzone in data['picklist_picking_zone'].unique():
            #print('Pickzone started : {}'.format(pickzone))
            df = picklist_df_creator(data[data['picklist_picking_zone'] == pickzone])
            df_out = df_out.append(df)
            pickzones_completed += 1
            #print('Pickzone completed : {} | pickzones completed : {}/{}'.format(pickzone, pickzones_completed, data['picklist_picking_zone'].nunique()))
    
        final_output=final_output.append(df_out)
        print('Simulation completed for DBD: {}'.format(row_dbd['dbd']))
    #Adding dbd to picklists to differentiate between picklist ids of different dbds
    final_output['dbd_proxy']=        final_output['fulfill_item_unit_dispatch_by_cutoff'].apply(lambda x:int(datetime.strftime(x,'%y%m%d%H%M%S0000')))
    final_output['picklist_id']=final_output['dbd_proxy']+final_output['picklist_id']
    del final_output['dbd_proxy'] 
    return final_output