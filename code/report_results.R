## ------------------------------------------------------------------------------------------
##
## Script name: Corticosteroids Reporting
##
## Purpose of script: Show an example of code to run an report results for a
## longitudinal analysis with LMTP.
##
## Author: Katherine Hoffman
##
## Date Created: 2022-05-23
##
## Author: Katherine Hoffman, 2022
## Email: kah2797@med.cornell.edu
##
## ------------------------------------------------------------------------------------------
##
## Notes: The data set of n=2000 patients contains realistic values for patients but
## is a toy data set and cannot be used to obtain the result in the paper due to
## data-sharing restrictions. 
##
## ------------------------------------------------------------------------------------------

## load necessary libraries

library(tidyverse)
library(gt)
library(lmtp)

## ------------------------------------------------------------------------------------------

## read in results

res_steroid <- read_rds(here::here("code/github_tutorial/res_steroid.rds"))
res_no_steroid <- read_rds(here::here("code/github_tutorial/res_no_steroid.rds"))

## ------------------------------------------------------------------------------------------

## make results table for mortality incidence rate (instead of survival)

res_steroid %>% tidy()

imap_dfr(list("Steroids" = res_steroid, "No Steroids" = res_no_steroid),
        function(x,y){
  x %>%
    tidy() %>%
    mutate(intervention = y,
           estimate=1-estimate,
           conf_low = 1-conf.high,
           conf_high=1-conf.low) %>%
   select(estimate, conf_low, conf_high)
           
})

%>% tidy() %>% mutate(estimate=1-estimate, conf_low = 1-conf.high, conf_high=1-conf.low) %>% select(estimate, conf_low, conf_high)
