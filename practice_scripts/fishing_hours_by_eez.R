#############################################################
# Example Query : Find which EEZs vessels fish in 
# Description: 
# This query uses the vessel info table to identify all MMSI
# that fished in China each year and how much they fished
##############################################################

#############################################################
# Sub-query 1: Extract EEZ fishing summary from the 
# activity.eez array in vessel info table 
# Sub-query 2: get EEZ ID and information 
# Sub-query 3: Join country names to EEZ id 
# Sub-query 4: Filter to fishing in China (using ISO3 code)
############################################################

## Setup 
library(bigrquery)
billing_project <- "proj_code" # Update with project code 

## Define the query 
sql <-"

###standardSQL

WITH

  ##################################
  #Subquery1
  
  eez_fishing AS (
  SELECT
    ssvid,
    year,
    best.best_flag,
    best.best_vessel_class,
    value AS eez,
    fishing_hours
  FROM 
    `gfw_research.vi_ssvid_byyear_v20200115`
  CROSS JOIN 
    UNNEST (activity.eez)),
  
  ###################################  
  
  #Subquery2
  
  eez_names AS (
  SELECT
    CAST(eez_id AS STRING) AS eez, 
    reporting_name,
    sovereign1_iso3 AS iso3
  FROM 
    `gfw_research.eez.info`),
    
  ##################################
  
  #Subquery3
  
  eez_fishing_labeled AS (
  SELECT
    * 
  FROM 
    eez_fishing
  LEFT JOIN 
    eez_names
  USING 
    (eez))
  
  ###################################
  
  #Subquery4
  
  SELECT 
    * 
  FROM 
    eez_fishing_labeled
  WHERE
    iso3 = 'CHN'
  AND fishing_hours > 0 
  
"

## Run the query

#china_effort <- bq_project_query(billing_project, sql)