BEGIN;

TRUNCATE TABLE bronze.crm_cust_info;
TRUNCATE TABLE bronze.crm_prd_info;
TRUNCATE TABLE bronze.crm_sales_details;

-- Have to run the below copy commands line by line as \copy is terminal cmd and requires physical line breaks
\copy bronze.crm_cust_info FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.crm_prd_info FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/prd_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.crm_sales_details FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/sales_details.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')

COMMIT;

SELECT (
  SELECT COUNT(*) FROM bronze.crm_cust_info) AS cust_rows, 
  (SELECT COUNT(*) FROM bronze.crm_prd_info) AS prd_rows, 
  (SELECT COUNT(*) FROM bronze.crm_sales_details) AS sales_rows;

