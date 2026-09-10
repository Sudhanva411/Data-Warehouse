-- 1. Drop old version to prevent conflicts
DROP PROCEDURE IF EXISTS bronze.load_all_staging_tables();

-- 2. Create the procedure with timing trackers
CREATE OR REPLACE PROCEDURE bronze.load_all_staging_tables()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time   TIMESTAMP;
    duration   INTERVAL;
BEGIN
    -- Capture the exact live start time
    start_time := clock_timestamp();
    RAISE NOTICE '==================================================';
    RAISE NOTICE 'ETL PIPELINE STARTED AT: %', start_time;
    RAISE NOTICE '==================================================';

    -- Step 1: Clear old data from all tables
    RAISE NOTICE 'Step 1: Truncating old data from tables...';
    TRUNCATE TABLE bronze.crm_cust_info;
    TRUNCATE TABLE bronze.crm_prd_info;
    TRUNCATE TABLE bronze.crm_sales_details;
    TRUNCATE TABLE bronze.erp_cust_az12;
    TRUNCATE TABLE bronze.erp_loc_a101;
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    RAISE NOTICE '-> All staging tables truncated successfully.';

    -- Step 2: Bulk load data with logging for each step
    RAISE NOTICE 'Step 2: Starting bulk data import...';
    
    COPY bronze.crm_cust_info FROM 'C:/postgrestmp/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: crm_cust_info';

    COPY bronze.crm_prd_info FROM 'C:/postgrestmp/source_crm/prd_info.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: crm_prd_info';

    COPY bronze.crm_sales_details FROM 'C:/postgrestmp/source_crm/sales_details.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: crm_sales_details';

    COPY bronze.erp_cust_az12 FROM 'C:/postgrestmp/source_erp/CUST_AZ12.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: erp_cust_az12';

    COPY bronze.erp_loc_a101 FROM 'C:/postgrestmp/source_erp/LOC_A101.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: erp_loc_a101';

    COPY bronze.erp_px_cat_g1v2 FROM 'C:/postgrestmp/source_erp/PX_CAT_G1V2.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
    RAISE NOTICE '-> Loaded: erp_px_cat_g1v2';

    -- Capture live end time and calculate the total delta duration
    end_time := clock_timestamp();
    duration := end_time - start_time;

    RAISE NOTICE '==================================================';
    RAISE NOTICE 'Step 3: Database pipeline execution complete!';
    RAISE NOTICE 'ETL PIPELINE ENDED AT:   %', end_time;
    RAISE NOTICE 'TOTAL ETL DURATION:     %', duration;
    RAISE NOTICE '==================================================';
END;
$$;

-- Need to use CALL funtion to execute the above code.
CALL bronze.load_all_staging_tables();
SELECT 
  (SELECT COUNT(*) FROM bronze.crm_cust_info) AS cust_rows, 
  (SELECT COUNT(*) FROM bronze.crm_prd_info) AS prd_rows, 
  (SELECT COUNT(*) FROM bronze.crm_sales_details) AS sales_rows,
  (SELECT COUNT(*) FROM bronze.erp_cust_az12) AS cust_rows_erp, 
  (SELECT COUNT(*) FROM bronze.erp_loc_a101) AS loc_rows, 
  (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2) AS spx_cat_rows;
