# -*- coding: utf-8 -*-
"""
Created on Wed Oct 31 18:57:12 2018

@author: adam.muhammad
"""
# Set working directory
os.chdir(r'C:\Analytics\FC\Dynamic Picklist')

# Data import and manipulations
data = pd.read_csv('dpl_fulldaydbd_zones_removed.csv')
df1=pd.DataFrame()


"""
sql code = select ob.reservation_id,
ob.picklist_display_id,
ob.reservation_created_timestamp,
ob.picklist_created_timestamp,
ob.picklist_picking_zone,
ob.fulfill_item_unit_dispatch_by_cutoff,
b.storage_location_id,
b.storage_location_label,
b.storage_location_location_sequence,
c.product_detail_height,
c.product_detail_length,
c.product_detail_breadth,
c.product_detail_weight,
c.product_detail_cms_vertical,
ob.fulfill_item_unit_lpht as lpht,
ob.fulfill_item_unit_ship_together_preference_id
from ekl.scp_warehouse__fc_outbound_breach_unit_l2_fact ob 
left join ekl.scp_warehouse__fc_reservation_l0_fact a 
on ob.fulfill_reference_id = a.reservation_fulfill_reference_id 
and reservation_inv_source_type != 'non_fki'
and reservation_outbound_type = 'customer_reservation'
left join ekl.scp_warehouse__fc_storage_location_dim b 
on a.picklist_item_suggested_location_key = b.fc_storage_location_dim_key
left join ekl.scp_warehouse__fc_product_detail_dim c 
on a.reservation_product_key = c.fc_product_detail_dim_key
where ob.reservation_status <> 'cancelled'
and ob.fiu_warehouse_id = 'blr_wfld'
and ob.fulfill_item_unit_dispatch_by_cutoff = '2018-09-08 16:30:00';

"""

max_distance = 1200#float(input('Enter the maximum inter item distance travel(feet?) : '))# 1200 "feet"?
min_quantity = 5#float(input('Enter the minimu quantity to be carried in a toat(# of items) : '))# 5
max_quantity = 25#float(input('Enter the maximum quantity to be carried in a toat(# of items) : '))# this needs to be looked up using product vertical : 25
max_weight = 12#float(input('Enter maximum permissible weight of items in toat(kgs) : '))# based on 25 item basket : 12kg
max_volume = 3500#float(input('Enter the toat volume(inch^3) : '))# based on 25 item basket : 3500 cubic inch
slot_size = 15#float(input('Enter the slot size for regular slots(in mins) : '))# 15mins
slot_size_rel = 5#float(input('Enter the slot size for relaxed slots(in mins) : '))# 5mins
setup_time=1200

percentile=95

output=run_simulation(data)

############Evaluation of simulation output##########

"""  Run this part to evaluate original parameters

df=pd.read_csv('dpl_fulldaydbd_zones_removed.csv')
df.sort_values('fulfill_item_unit_ship_together_preference_id', inplace = True)
df.drop_duplicates(subset ="fulfill_item_unit_ship_together_preference_id",keep =False,inplace = True)


df=df[~df['picklist_picking_zone'].isnull()]

try:
    del df['picklist_id']
except:
    True

names=list(df)
names[names.index('picklist_display_id')]='picklist_id'
df.columns=names


picklists_orig=df.loc[:,['storage_location_location_sequence','picklist_id']].sort_values('picklist_id').set_index('picklist_id')

picklists_orig['distance']=picklists_orig.groupby('picklist_id')['storage_location_location_sequence'].max()-picklists_orig.groupby('picklist_id')['storage_location_location_sequence'].min()

picklists_orig['picklist_size']=picklists_orig.groupby('picklist_id')['storage_location_location_sequence'].count()

picklists_orig=picklists_orig.reset_index()

picklists_orig=picklists_orig[~picklists_orig['picklist_id'].duplicated()]

picklists_orig.dropna(inplace=True)

#picklists_orig=picklists_orig[~(np.abs(picklists_orig.distance-picklists_orig.distance.mean()) > (3*picklists_orig.distance.std()))]

#picklists_orig=picklists_orig[picklists_orig['distance']>np.percentile(picklists_orig['distance'],85)]

gross_cost_orig=picklists_orig['distance'].sum()+setup_time*picklists_orig['picklist_id'].count()
number_of_picklists_orig=picklists_orig['picklist_id'].count()
picklist_size_distribution_orig=picklists_orig['picklist_size'].value_counts()

items_picked_orig=picklists_orig['picklist_size'].sum()
"""

df=output.copy()

picklists=df.loc[:,['storage_location_location_sequence','picklist_id','slot_id']].sort_values('picklist_id').set_index('picklist_id')

picklists['distance']=picklists.groupby('picklist_id')['storage_location_location_sequence'].max()-picklists.groupby('picklist_id')['storage_location_location_sequence'].min()

picklists['picklist_size']=picklists.groupby('picklist_id')['storage_location_location_sequence'].count()

picklists=picklists.reset_index()

picklists=picklists[~picklists['picklist_id'].duplicated()]

#picklists=picklists[picklists['distance']<np.percentile(picklists['distance'],90)]

gross_cost=picklists['distance'].sum()+setup_time*picklists['picklist_id'].count()
number_of_picklists=picklists['picklist_id'].count()
#picklist_size_distribution=picklists['picklist_size'].value_counts()
#items_picked=picklists['picklist_size'].sum()
number_of_picklists_reg=picklists[picklists['slot_id']<9000]['picklist_id'].count()
number_of_picklists_single_item=picklists[picklists['picklist_size']==1]['picklist_id'].count()
average_picklist_size=picklists[picklists['slot_id']<9000]['picklist_size'].mean()
average_picklist_volume=output[['product_volume','picklist_id']].groupby('picklist_id').agg('sum')['product_volume'].mean()
average_picklist_weight=output[['product_detail_weight','picklist_id']].groupby('picklist_id').agg('sum')['product_detail_weight'].mean()


number_of_picklists_single_item=picklists[picklists['picklist_size']<9000]['picklist_id'].count()


gross_cost_orig/gross_cost

a=pd.DataFrame([[gross_cost,number_of_picklists,number_of_picklists_reg,number_of_picklists_single_item,average_picklist_size,average_picklist_volume,average_picklist_weight,max_distance,min_quantity,max_quantity,max_weight,max_volume,slot_size,slot_size_rel,setup_time]])

a.columns=['gross_cost','no_picklists','no_picklists_reg','no_picklists_single_item','average_picklist_size','average_picklist_volume','average_picklist_weight','max_distance','min_quantity','max_quantity','max_weight','max_volume','slot_size','slot_size_rel','setup_time']


max_distance,min_quantity,max_quantity,max_weight,max_volume,slot_size,slot_size_rel,setup_time


df1=df1.append(a)

