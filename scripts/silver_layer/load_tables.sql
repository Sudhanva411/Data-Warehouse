/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

===============================================================================
*/

DROP PROCEDURE IF EXISTS silver.load_all_staging_tables();

-- 2. Create the procedure with timing trackers
CREATE OR REPLACE PROCEDURE silver.load_all_staging_tables()
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
    TRUNCATE TABLE silver.crm_cust_info;
    TRUNCATE TABLE silver.crm_prd_info;
    TRUNCATE TABLE silver.crm_sales_details;
    TRUNCATE TABLE silver.erp_cust_az12;
    TRUNCATE TABLE silver.erp_loc_a101;
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    RAISE NOTICE '-> All staging tables truncated successfully.';

    -- Step 2: Bulk load data with logging for each step
    RAISE NOTICE 'Step 2: Starting bulk data import...';

INSERT INTO silver.crm_cust_info (
    cst_id, 
    cst_key, 
    cst_firstname, 
    cst_lastname, 
    cst_marital_status, 
    cst_gndr, 
    cst_create_date
)
SELECT cst_id, 
cst_key, 
TRIM(cst_firstname) AS cst_firstname, 
TRIM(cst_lastname) AS cst_lastname, 
CASE 
    WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
    WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
    ELSE 'N/A'
END cst_material_status, 
CASE 
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
    ELSE 'N/A'
END cst_gndr, 
cst_create_date FROM (
    SELECT *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
    ) WHERE flag_last = 1;
RAISE NOTICE '-> Loaded: silver.crm_cust_info';


INSERT INTO silver.crm_prd_info(
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT prd_id, 
REPLACE(SUBSTRING(prd_key, 1, 5),'-','_') as cat_id,
SUBSTRING(prd_key, 7, LENGTH(prd_key)) as prd_key,
prd_nm, 
COALESCE(prd_cost, 0) as prd_cost, 
CASE UPPER(TRIM(prd_line))
    WHEN 'M' THEN 'Mountain'
    WHEN 'R' THEN 'Road'
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'N/A'
END AS prd_line, 
prd_start_dt::DATE, 
(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day')::DATE AS prd_end_dt
FROM bronze.crm_prd_info;
RAISE NOTICE '-> Loaded: silver.crm_prd_info';

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        WHEN sls_order_dt <= 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
        ELSE (sls_order_dt::VARCHAR)::DATE
    END AS sls_order_dt,
    CASE 
        WHEN sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
        ELSE (sls_ship_dt::VARCHAR)::DATE
    END AS sls_ship_dt,
    CASE 
        WHEN sls_due_dt <= 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
        ELSE (sls_due_dt::VARCHAR)::DATE
    END AS sls_due_dt,
    CASE WHEN sls_sales IS NULL OR sls_sales<=0 OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales 
    END AS sls_sales,
    sls_quantity,
    CASE WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price 
    END AS sls_price
FROM bronze.crm_sales_details;
RAISE NOTICE '-> Loaded: silver.crm_sales_details';

INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT 
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) 
        ELSE cid 
    END AS cid,
    CASE 
        WHEN bdate > NOW() THEN NULL
        ELSE bdate
    END AS bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'N/A'
    END AS gen
FROM bronze.erp_cust_az12;
RAISE NOTICE '-> Loaded: silver.erp_cust_az12';

INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT 
    REPLACE(cid,'-','') cid, 
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry) 
    END AS cntry
FROM bronze.erp_loc_a101;
RAISE NOTICE '-> Loaded: silver.erp_loc_a101';

INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
SELECT 
    id, 
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;
RAISE NOTICE '-> Loaded: silver.erp_px_cat_g1v2';

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
CALL silver.load_all_staging_tables();
SELECT 
  (SELECT COUNT(*) FROM silver.crm_cust_info) AS cust_rows, 
  (SELECT COUNT(*) FROM silver.crm_prd_info) AS prd_rows, 
  (SELECT COUNT(*) FROM silver.crm_sales_details) AS sales_rows,
  (SELECT COUNT(*) FROM silver.erp_cust_az12) AS cust_rows_erp, 
  (SELECT COUNT(*) FROM silver.erp_loc_a101) AS loc_rows, 
  (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2) AS spx_cat_rows;
