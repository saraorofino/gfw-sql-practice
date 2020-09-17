#############################################################
# Example Query : Vessel information examples 
# Description: 
# A few different example queries for how to use vessel 
# information and filter by flags, geartypes, etc. 
##############################################################

## Setup 
library(bigrquery)
billing_project <- "proj_code" # Update with project code 

## Define the queries

###############################################################
# Find all fishing vessels using the best list that aren't 
# Chinese flagged

sql <-"

 SELECT
   ssvid
 FROM 
   `world-fishing-827.gfw_research.vi_ssvid_v20200115`
 WHERE on_fishing_list_best AND
 best.best_flag != 'CHN'
 
"

###############################################################
# Find all fishing vessel using the best list that are not Chinese
# flagged and are likely drifting longlines

sql <- "

  SELECT
    ssvid
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE on_fishing_list_best AND
  best.best_flag != 'CHN' AND
  best.best_vessel_class = 'drifting_longlines'
  
"

###############################################################
# Find all fishing vessel ssvid using the best list that are not 
# Chinese flagged and are likely used by multiple vessels

sql <- "

  SELECT
    ssvid
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE on_fishing_list_best AND
  best.best_flag != 'CHN' AND
  activity.overlap_hours_multinames > 0 
  
"

###############################################################
# Find all ssvid using the best list that self report as fishing
# vessels but are likely gear 

sql <- "

  SELECT
    ssvid
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE on_fishing_list_sr AND
  best.best_flag != 'CHN' AND
  best.best_vessel_class = 'gear'
  
"

###############################################################
# Find all ssvid using best list that self report as fishing 
# vessels are not likely gear, but are not on our best fishing list

sql <- "

  SELECT
    ssvid
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE on_fishing_list_sr AND
  best.best_vessel_class != 'gear' AND
  NOT on_fishing_list_best
  
"

###############################################################
# What is the most common vessel type for vessels that self report
# to be fishing vessels but which are not on the best list 

sql <- "

  SELECT
    best.best_vessel_class,
    COUNT(*) AS counts
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE on_fishing_list_sr AND NOT on_fishing_list_best
  GROUP BY best.best_vessel_class
  ORDER BY counts DESC
  
"

###############################################################
# In 2018 how many vessels were likely fishing vessels (on best list)
# but that fished for fewer than 24 hours?

sql <- "

  SELECT
    COUNT(*)
  FROM
    `world-fishing-827.gfw_research.vi_ssvid_v20200115`
  WHERE year = 2018
  AND on_fishing_list_best
  AND activity.fishing_hours < 24
  
"

###############################################################
# How many hours did Chinese fishing vessels fish in each EEZ in
# 2018? Ignore any ssvid that have a chance of being used by 
# multiple vessels. (Note that null means it is in the high seas)

sql <- "

WITH 

  summary_by_eez AS(
  SELECT
    CAST(value AS int64) AS eez_id,
    SUM(e.fishing_hours) fishing_hours
  FROM
    `gfw_research.vi_ssvid_v20200115`
  LEFT JOIN 
     UNNEST(activity.eez) AS e
  WHERE 
    best.best_flag = 'CHN'
    AND on_fishing_list_best
    AND NOT activity.offsetting
    AND activity.overlap_hours_multinames = 0
    AND year = 2018
  GROUP BY eez_id)
  
  
  SELECT
    reporting_name,
    CAST(fishing_hours AS int64) fishing_hours
  FROM 
    summary_by_eez
  LEFT JOIN
    `gfw_research.eez_info`
  USING
    (eez_id)
  ORDER BY
    fishing_hours DESC
  
"

###############################################################
# In 2018, how many vessels fished for more than 24 hours
# in the high seas? (Note that null means it is in the high seas)

sql <- "

WITH 

  sssvid_by_eez AS (
  SELECT
    ssvid,
    CAST(value AS int64) AS eez_id,
    SUM(e.fishing_hours) fishing_hours
  FROM
    `gfw_research.vi_ssvid_v20200115`
  LEFT JOIN
    UNNEST(activity.eez) AS e
  WHERE 
    on_fishing_list_best
    AND activity.overlap_hours_multinames = 0
    AND NOT activity.offsetting
    AND year = 2018
  GROUP BY 
    eez_id,
    ssvid)
    
  SELECT
    COUNT(*) FROM ssvid_by_eez
    WHERE fishing_hours > 24 AND eez_id is NULL
  
"

###############################################################
# In 2018, how many vessels, by flag state fished for more than 
# 24 hours in the high seas? 

sql <- "

WITH 

  sssvid_by_eez AS (
  SELECT
    ssvid,
    best.best_flag flag,
    CAST(value AS int64) AS eez_id,
    SUM(e.fishing_hours) fishing_hours
  FROM
    `gfw_research.vi_ssvid_v20200115`
  LEFT JOIN
    UNNEST(activity.eez) AS e
  WHERE 
    on_fishing_list_best
    AND activity.overlap_hours_multinames = 0
    AND NOT activity.offsetting
    AND year = 2018
  GROUP BY 
    eez_id,
    flag,
    ssvid)
    
  SELECT
    flag,
    COUNT(*) vessels FROM ssvid_by_eez
    WHERE fishing_hours > 24 AND eez_id is NULL
    GROUP BY flag
    ORDER BY vessels DESC
  
"