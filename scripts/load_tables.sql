BEGIN;

TRUNCATE TABLE bronze.crm_cust_info;\copy bronze.crm_cust_info 
FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
COMMIT;

SELECT COUNT(*) FROM bronze.crm_cust_inf
