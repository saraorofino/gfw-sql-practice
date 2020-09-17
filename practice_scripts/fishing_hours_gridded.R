#############################################################
# Example Query : Gridded fishing effort 
# Description: 
# This query demonstrates how to extract valid positions and 
# calculate fishing hours. 
##############################################################

##############################################################
# Sub-query 1: Identify only good segments for vessel positions
# Sub-query 2: Identify "fishing" positions using neural net score
# Sub-query 3: Calculate fishing hours using neural net score/hours
# Aggregate hours and fishing hours to a 0.1 degree grid
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
  
  good_segments AS (
  SELECT
    seg_id
  FROM 
    `gfw_research.pipe_v20190502_segs`
  WHERE 
     good_seg
     AND positions > 10 
     AND NOT overlapping_and_short),
     
  ######################################
  
  #Subquery2
  
  fishing AS (
  SELECT
    ssvid, 
    FLOOR(lat * 10) as lat_bin,
    FLOOR(lon * 10) as lon_bin,
    EXTRACT(date FROM date) as date,
    hours,
    IF(nnet_score2 > 0.5, hours, 0) as fishing_hours
  FROM
    `gfw_resesarch.pipe_v20190502_fishing`
  WHERE date = '2018-11-20'
  AND seg_id IN (
    SELECT
       seg_id
    FROM
       good_segments)),
       
  ######################################
  
  #Subquery3
  
  fishing_binned AS (
  SELECT
     date, 
     lat_bin / 10 as lat_bin
     lon_bin / 10 as lon_bin,
     SUM(hours) as hours,
     SUM(fishing_hours) as fishing_hours
  FROM fishing
  GROUP BY date, lat_bin, lon_bin)
 
 ######################################
 
 SELECT 
   * 
 FROM 
   fishing_binned
"

## Run the query

#gridded_effort <- bq_project_query(billing_project, sql)