#############################################################
# Example Query : Fishing effort 
# Description: 
# This query demonstrates how to extract valid positions and 
# calculate fishing hours. 
##############################################################

##############################################################
# Sub-query 1: Identify only good segments for vessel positions
# Sub-query 2: Identify "fishing" positions using neural net score
# Sub-query 3: Calculate fishing hours using neural net score/hours
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
    lat,
    lon,
    nnet_score2,
    timestamp,
    EXTRACT(year FROM date) AS year,
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
 
 SELECT 
   * 
 FROM 
   fishing
"

## Run the query

#fishing_effort <- bq_project_query(billing_project, sql)