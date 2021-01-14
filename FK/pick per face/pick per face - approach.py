
# import required libraries
import pandas as pd
import os

# set working directory
os.chdir('C:/Users/rohan.nanaware/Documents/01 Flipkart/FC analytics/37 pick per face')

# load the required data

'''

Hypothesis : Reserving items from bins with maximum inventory would improve pick per face significantly

Data period: BBD (Oct 16 - 21, 12 hours early access for Plus) | binola, bhiwandi, wfld | malur_bts, ulub_bts
Methodology :
    Data prep. -
    1. Download inventory snapshot for a given day-FC at bin wid level
    2. Download the reservation and putaway details for the same day with bin details
        a. Reservation data : reservation id, created time, bin id, dbd, picklist id, picklist created time, wid, fsn
        b. Putaway data : putlist id, putlist created time, bin id, putaway time
        c. Inventory data : bin id, wid, quantity
        storage_location_type = 'store' and atp = 1
    # http://fdp.fkinternal.com/reports/view/scp/warehouse/FC_soft_reservations_sim_ip
    3. Aggregate the inventory data and reservation data at bin x wid level
        a. For all bins, set inv. = max(reservations, inventory in bin)
            i. This can be made more accurate by using live inventory data and keep refreshing it with the putaway and outbound data from all other flows
    
    Baseline metrics -
    1. Piclist size
        a. Overall
        b. By pickzone
        c. By vertical
            d. By design | pickzone wise, ulub_bts, frk_bts
    2. Pick per face
        a. ...
        http://fdp.fkinternal.com/reports/view/scp/warehouse/FC%20Pick%20phases
    3. Inter item travel distance
        a. For bins where step in seq. ids is consistent    
    
    Simulation -
    1. Order all bins at wid, inventory quantity level
    2. Sort all reservations by dbd x resevation created timestamp
    3. For all reservations, check -
        a. wid
        b. bins which contain that wid
        c. Take the first bin in the list of bins sorted by inventory
        d. Assign the bin to that reservation id
        e. Adjust the inventory in the bin by -1
        Repeat
    4. Rid, bin labels, created time, pickzone break, create picklist
    
'''
