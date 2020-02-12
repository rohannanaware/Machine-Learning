# -*- coding: utf-8 -*-
# Picklist generator function for regular period
def picklist_id_gen(data):
    # The input df1 has all observations pertaining to all slots <= active slot,
    #     the observations with putlist_id already created need to be excluded from the function
    
    # Loop variables
    global min_quantity
    global picklist_id
    loop_counter = 0
    quantity = 0
    volume = 0
    weight = 0
    min_quantity = min_quantity
    # Retain only those observations with picklist_id = 0 
    df1 = data[data['picklist_id'].isin([0])]
    
    # Order all reservations by location id - all reservations with no picklist id will be sorted together irrresp. of their slots
    df1 = df1.sort_values('storage_location_location_sequence', ascending = 1)
    df1 = df1.reset_index()# reset indices to be inline with the storage location

    # Get the next reservation's quantity, volume, weight
    df1['lead_product_volume'] = df1.product_volume.shift(-1) 
    df1['lead_product_detail_weight'] = df1.product_detail_weight.shift(-1) 
    df1['lead_storage_location_location_sequence'] = df1.storage_location_location_sequence.shift(-1)
    # df1['picklist_id'] = 0
    loop_counter = 0# loop counter will retain the number of items added into the picklist
    for index, row in df1.iterrows():
        if loop_counter == 0:
            # Re-initialize loop variables
            quantity = 1
            volume = row['product_volume']
            weight = row['product_detail_weight']
            distance_to_next = 0
        # Assign next item values to the loop  variables
        quantity = quantity + 1
        volume = volume + row['lead_product_volume']
        weight = weight + row['lead_product_detail_weight']
        if quantity > max_quantity:
            # the items in picklist have exceeded maximum allowable items for that vertical hence, create picklist
            df1.loc[index-loop_counter:index,['picklist_id']] = picklist_id
            loop_counter = 0
            picklist_id += 1
        elif (row['lead_storage_location_location_sequence'] - row['storage_location_location_sequence']) > max_distance or volume > max_volume or weight > max_weight:
            # permissible limits of distance, weight and volume are breached by picking next item
            if quantity - 1 < min_quantity:
                # picklist does not contain the minimum required quantity to be created hence, discard the picklist
                loop_counter = 0
                continue
            else:
                # create picklist
                df1.loc[index-loop_counter:index,['picklist_id']] = picklist_id
                loop_counter = 0
                picklist_id += 1
        else:
            # picklist has room for filling more items and addition of next item won't breach loop parameters
            loop_counter += 1
    return df1

# Picklist generator function for relaxed period
def picklist_id_gen_rel(data):
    # The input df1 has all observations pertaining to all slots <= active slot,
    #     the observations with putlist_id already created need to be excluded from the function
    
    # Loop variables
    global min_quantity
    global picklist_id
    loop_counter = 0
    quantity = 0
    volume = 0
    weight = 0
    min_quantity = min_quantity

    # Retain only those observations with picklist_id = 0 
    df1 = data[data['picklist_id'].isin([0])]
    
    # Order all reservations by location id - all reservations with no picklist id will be sorted together irrresp. of their slots
    df1 = df1.sort_values('storage_location_location_sequence', ascending = 1)
    df1 = df1.reset_index()# reset indices to be inline with the storage location

    # Get the next reservation's quantity, volume, weight
    df1['lead_product_volume'] = df1.product_volume.shift(-1) 
    df1['lead_product_detail_weight'] = df1.product_detail_weight.shift(-1) 
    df1['lead_storage_location_location_sequence'] = df1.storage_location_location_sequence.shift(-1)
    # df1['picklist_id'] = 0
    loop_counter = 0# loop counter will retain the number of items added into the picklist
    for index, row in df1.iterrows():
        if loop_counter == 0:
            # Re-initialize loop variables
            quantity = 1
            volume = row['product_volume']
            weight = row['product_detail_weight']
            distance_to_next = 0
        # Assign next item values to the loop  variables
        quantity = quantity + 1
        volume = volume + row['lead_product_volume']
        weight = weight + row['lead_product_detail_weight']
        if quantity > max_quantity:
            # the items in picklist have exceeded maximum allowable items for that vertical hence, create picklist
            df1.loc[index-loop_counter:index,['picklist_id']] = picklist_id
            loop_counter = 0
            picklist_id += 1
        elif (row['lead_storage_location_location_sequence'] - row['storage_location_location_sequence']) > max_distance or volume > max_volume or weight > max_weight:
            # permissible limits of distance, weight and volume are breached by picking next item, create picklist
            # here we are ignoring the fact that the items in the picklist could be lower than min. required items bcoz. it's relax time!
            df1.loc[index-loop_counter:index,['picklist_id']] = picklist_id
            loop_counter = 0
            picklist_id += 1
        else:
            # picklist has room for filling more items and addition of next item won't breach loop parameters
            loop_counter += 1
    return df1

# function to create picklists by vertical
def picklist_df_creator(data):
    global picklist_id
    global list_of_slots
    df_op = pd.DataFrame()
    #list_of_slots = data['slot_id'].unique().tolist()
    for i in list_of_slots:
        df1 = data[data['slot_id'].isin(list(range(0, i + 1)))]
        if i!=min(list_of_slots):df1 = df1[~df1['reservation_id'].isin(df_op['reservation_id'])]
        if i < 9000:

            #print("Running regular logic | slot id = ", i)
            df1 = picklist_id_gen(df1)
            if i == 0:
                df_op = df1[~df1['picklist_id'].isin([0])]
            else:
                df_op = df_op.append(df1[df1['picklist_id'].isin(range(1, 100000))])
        else:

            #print("Running relaxed logic | slot id = ", i)
            df1 = picklist_id_gen_rel(df1)
            df_op = df_op.append(df1[df1['picklist_id'].isin(range(1, 100000))])

            # Jugaad code begins here
            if i == max(list_of_slots):
                # for the last iteration of slot_id
                # apply a picklist_id = 0 filter on df1 and append the dataframe with the df_op
                df1 = df1[df1['picklist_id'].isin([0])]
                df1['picklist_id'] = picklist_id
                picklist_id += 1
                #or replace NaN with > 1200 distance
                df_op = df_op.append(df1)
            # Jugaad code ends here
    return df_op




"""
data=data_all[data_all['fulfill_item_unit_dispatch_by_cutoff']=='2018-09-08 00:00:00']

final_output['fulfill_item_unit_dispatch_by_cutoff'].value_counts()

data_all['fulfill_item_unit_dispatch_by_cutoff'].value_counts()

data_1=data_all[data_all['fulfill_item_unit_dispatch_by_cutoff']=='2018-09-08 13:00:00'].to_csv('1_raw.csv')


output_1=final_output[final_output['fulfill_item_unit_dispatch_by_cutoff']=='2018-09-08 13:00:00'].to_csv('1_output.csv')



df_out.slot_id.value_counts()
a=data.slot_id.value_counts().reset_index()


print(x for x in range(0, 10 + 1))

list(range(0,10+1))

"""