## ------------------------------------------------------------------------------------------
##
## Script name: Corticosteroids Data Checks
##
## Purpose of script: Show how I fix the censoring indicators to match the LMTP data example `sim_timevary_surv`
##
## Author: Katherine Hoffman
##
## Date Created: 2023-02-18
##
## Author: Katherine Hoffman, 2023
## Email: kathoffman.stats@gmail.com
##
## ------------------------------------------------------------------------------------------
##
## Notes: This is not needed for the analysis, just contains a function to check data missingness that may be helpful for other analysts
##
## ------------------------------------------------------------------------------------------

library(tidyverse)
dat_lmtp <- read_rds(here::here("data/dat_demo.rds"))

# a function to check missingness up to time t
# when C_[t] == 1, while long as Y_[t] == 0, the observation should not have any missingness for 
# any of the treatment or time-varying covariates (ends_with _[t]) or baseline covariates (names in object `bs`)
check_missingness <- function(cens_name){
  y_num <- str_pad(parse_number(cens_name) + 1, side="left", width=2, "0")
  y_name <- paste0("Y_", y_num)
  tmp <- dat_lmtp |>
    filter(.data[[cens_name]] == 1, .data[[y_name]] == 0) |>
    select(id, one_of(bs), contains(y_num))
  n1 <- nrow(tmp)
  n2 <- nrow(drop_na(tmp))
  return(data.frame(cens_name, n1, n2, ok = n1==n2))
}

map_dfr(censoring, check_missingness) # all time points are OK now! 

# this cleaning fixed the C_ indicators to match the new lmtp example, data object `sim_timevary_surv`
# the censoring value of 0 vs NA after the event occurs or C_[t]=0 does not matter because the unit is no longer at risk, however, I've fixed this to match the example data for clarity
dat_lmtp_fix_censoring <-
  dat_lmtp |>
  mutate(C_01 = case_when(Y_01 == 1 ~ NA_real_, C_00 == 0 ~ NA_real_, TRUE ~ C_01),
         C_02 = case_when(Y_02 == 1 ~ NA_real_, C_01 == 0 ~ NA_real_, is.na(C_01) ~ NA_real_, TRUE ~ C_02),
         C_03 = case_when(Y_03 == 1 ~ NA_real_, C_02 == 0 ~ NA_real_, is.na(C_02) ~ NA_real_, TRUE ~ C_03),
         C_04 = case_when(Y_04 == 1 ~ NA_real_, C_03 == 0 ~ NA_real_, is.na(C_03) ~ NA_real_, TRUE ~ C_04),
         C_05 = case_when(Y_05 == 1 ~ NA_real_, C_04 == 0 ~ NA_real_, is.na(C_04) ~ NA_real_, TRUE ~ C_05),
         C_06 = case_when(Y_06 == 1 ~ NA_real_, C_05 == 0 ~ NA_real_, is.na(C_05) ~ NA_real_, TRUE ~ C_06),
         C_07 = case_when(Y_07 == 1 ~ NA_real_, C_06 == 0 ~ NA_real_, is.na(C_06) ~ NA_real_, TRUE ~ C_07),
         C_08 = case_when(Y_08 == 1 ~ NA_real_, C_07 == 0 ~ NA_real_, is.na(C_07) ~ NA_real_, TRUE ~ C_08),
         C_09 = case_when(Y_09 == 1 ~ NA_real_, C_08 == 0 ~ NA_real_, is.na(C_08) ~ NA_real_, TRUE ~ C_09),
         C_10 = case_when(Y_10 == 1 ~ NA_real_, C_09 == 0 ~ NA_real_, is.na(C_09) ~ NA_real_, TRUE ~ C_10),
         C_11 = case_when(Y_11 == 1 ~ NA_real_, C_10 == 0 ~ NA_real_, is.na(C_10) ~ NA_real_, TRUE ~ C_11),
         C_12 = case_when(Y_12 == 1 ~ NA_real_, C_11 == 0 ~ NA_real_, is.na(C_11) ~ NA_real_, TRUE ~ C_12),
         C_13 = case_when(Y_13 == 1 ~ NA_real_, C_12 == 0 ~ NA_real_, is.na(C_12) ~ NA_real_, TRUE ~ C_13)
                          )

saveRDS(dat_lmtp_fix_censoring, "data/dat_demo.rds") # overwrite previous demo data
