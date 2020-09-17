#############################################################
# Example Query : Port visits by vessel id 
# Description: 
# This identifies all port visits in January 2018 and maps the
# the vessel_id to ssvid 
##############################################################

##############################################################
# Sub-query 1: Identify port visits 
# Sub-query 2: Map vessel_id to ssvid
##############################################################

## Setup 
library(bigrquery)
billing_project <- "proj_code" # Update with project code 

## Define the query 

sql <-"

###standardSQL

WITH 

  ######################################
  #Subquery1
  
  port_visits AS (
  SELECT
    vessel_id,
    start_timestamp,
    start_lat,
    start_lon,
    start_anchorage_id,
    end_timestamp,
    end_lat,
    end_lon,
    end_anchorage_id
  FROM 
    `world_fishing_827.pipe_production_v20190502.port_visits_*`
  WHERE
    _table_suffix BETWEEN '20180101' AND '20180201'),
    
  ########################################
  
  #Subquery2
  
  port_visits_with_ssvid AS (
  SELECT
    a.*,
    b.ssvid,
    TIMESTAMP_DIFF(end_timestamp, start_timestamp, SECOND)/3600 AS port_stay_duration_hr
  FROM port_visits a 
  LEFT JOIN (
  SELECT
    ssvid, 
    vessel_id
  FROM 
    `pipe_production_v20190502.vessel_info`) b
  ON a.vessel_id = b.vessel_id)
  
  ########################################
  
  SELECT
    * 
  FROM 
    port_visits_with_ssvid

"

## Run the query

#port_visits <- bq_project_query(billing_project, sql)