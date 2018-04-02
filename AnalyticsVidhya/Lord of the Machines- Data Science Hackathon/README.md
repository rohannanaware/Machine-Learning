[Contest home](https://datahack.analyticsvidhya.com/contest/lord-of-the-machines/)

* Achieved ~56% accuracy on test dataset(AUC ROC)
* Rank in top 40%
* Approach - 
  * Hypothesis driven
    1. Run a quick and dirty iteration using gradient boost. Achieve as good accuracy as possible
    2. Perform basic EDA - 
            a. Drivers of click through - Email attributes, Customer attributes, external factors
            b. Email attributes - Structure and content, header, subject, does the address contain the name of user?,
                                  Time of day and day of week, etc.
            c. Cust. attributes - No. of emails sent/opened/clicked by the customer, frequency of engagement,
                                  Affinity to a given type of email, etc.
            d. Ext. factors     - Time of year, holiday season, prize associated, etc.
    3. Feature engineering based on the findings from EDA
    4. Rerun model iteration
    5. Model hypertuning
    
  * Stats driven
    1. Create a new prediction model with email open as dependent.
    2. Use the email open propensity as an input to predict click propensity
    3. Check variable importance plots - remove or merge features
