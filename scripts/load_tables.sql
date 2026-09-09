BEGIN;

TRUNCATE TABLE bronze.crm_cust_info;
TRUNCATE TABLE bronze.crm_prd_info;
TRUNCATE TABLE bronze.crm_sales_details;
TRUNCATE TABLE bronze.erp_cust_az12;
TRUNCATE TABLE bronze.erp_loc_a101;
TRUNCATE TABLE bronze.erp_px_cat_g1v2;

-- Have to run the below copy commands line by line as \copy is terminal cmd and requires physical line breaks
\copy bronze.crm_cust_info FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.crm_prd_info FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/prd_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.crm_sales_details FROM 'C:/Users/sasudhan/Downloads/datasets/source_crm/sales_details.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.erp_cust_az12 FROM 'C:/Users/sasudhan/Downloads/datasets/source_erp/CUST_AZ12.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.erp_loc_a101 FROM 'C:/Users/sasudhan/Downloads/datasets/source_erp/LOC_A101.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')
\copy bronze.erp_px_cat_g1v2 FROM 'C:/Users/sasudhan/Downloads/datasets/source_erp/PX_CAT_G1V2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',')

COMMIT;

SELECT (
  SELECT COUNT(*) FROM bronze.crm_cust_info) AS cust_rows, 
  (SELECT COUNT(*) FROM bronze.crm_prd_info) AS prd_rows, 
  (SELECT COUNT(*) FROM bronze.crm_sales_details) AS sales_rows,
  (SELECT COUNT(*) FROM bronze.erp_cust_az12) AS cust_rows_erp, 
  (SELECT COUNT(*) FROM bronze.erp_loc_a101) AS loc_rows, 
  (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2) AS spx_cat_rows;

