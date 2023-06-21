## ------------------------------------------------------------------------------------------
##
## Script name: Corticosteroids Main Analysis
##
## Purpose of script: Show an example of code to run an analysis for a 
##     dynamic treatment regime for a time-varying exposure and time-dependent confounders
##     for a time-to-event outcome.
##
## Author: Katherine Hoffman
##
## Date Created: 2022-05-22
##
## Author: Katherine Hoffman, 2022
## Email: kathoffman.stats@gmail.com
##
## ------------------------------------------------------------------------------------------
##
## Notes: The data set of n=500 patients for time=(1,2,...,14) contains realistic values for patients but
## is a toy data set and cannot be used to obtain the result in the paper due to
## data-sharing restrictions. The interventions are 1: 6 days of corticosteroids at time of
## hypoxia vs. no corticosteroids
##
## ------------------------------------------------------------------------------------------

## system set up

options(java.parameters = '-Xmx2500m') # expand Java RAM for BART to run on a cluster computer
set.seed(7)
op <- options(nwarnings = 10000) ## <- get "full statistics" of warnings

## load necessary packages: 

# install.packages(c("tidyverse","earth","BART","glmnet"))
# devtools::install_github("nt-williams/lmtp@sl3") # sl3 compatible branch (faster)
# devtools::install_github("tlverse/sl3")

library(tidyverse)
library(lmtp) # note that this code uses sl3 version
library(future)
library(sl3)

plan(sequential) # change depending on parallelization preferences, see ?future for details

## -----------------------------------------------------------------------------------------

## load data

# wide-format, already pre-processed (see img/analytical_file.png and README.MD)
dat_lmtp <- read_rds(here::here("data/dat_demo.rds"))

## ----------------------------------------------------------------------------------------

## write intervention functions

# treatment intervention 1:
# when a patient becomes hypoxic, administer steroids for 6 days
# H is the day of severe hypoxia indicator variable created in data pre-processing
# this function takes in dataframe and treatment variable name (A_00, A_01, etc.)
# then if corresponding hypoxia indicator (H_00, H_01, etc.) is 1, set steroids to 1 for the next 6 days, otherwise, 0
int_steroids_after_hypoxia <- function(dat, trt) {
  trt_day <- parse_number(trt) # first, get the number of the treatment day of interest
  # we want to check the previous 6 days for hypoxia
  earliest_day_to_check <- max(0,trt_day-5)  # subtracting 5 will get us previous six days
  # this generates the relevant H_* column names for the hypoxia days we need to check
  hypoxia_days_to_check <- paste0("H_", 
                                  str_pad(earliest_day_to_check:trt_day, 
                                          width=2,
                                          side="left",
                                          pad="0")
  )
  # we'll set up a count variable to check when hypoxia was reached
  sum <- 0
  for(i in hypoxia_days_to_check){
    add <- ifelse(dat[[i]] == 1, 1, 0)
    sum <- sum + add
  }
  # if hypoxia was reached in one those (max) 6 days before treatment to check, return 1 for that treatment day
  return(ifelse(sum > 0, 1, 0)) # otherwise, return 0
}


# treatment intervention 2:
# never steroids - always return 0 for treatment
int_no_steroids <- function(data, trt) {
  data[[trt]] <- 0 # just change the entire treatment vector of interest to 0
  data[[trt]] # and return
}

## ------------------------------------------------------------------------------------------

## set up superlearner candidate learners (to run through {sl3} within lmtp)

mars_grid_params <- list( # manually create a grid of MARS learners
  degree = c(2,3),
  penalty = c(1,2,3)
)
mars_grid <- expand.grid(mars_grid_params, KEEP.OUT.ATTRS = FALSE)
mars_learners <- apply(mars_grid, MARGIN = 1, function(tuning_params) {
  do.call(Lrnr_earth$new, as.list(tuning_params))
})

# initiate other super learner candidates
lrn_lasso <- Lrnr_glmnet$new(alpha = 1)
lrn_ridge <- Lrnr_glmnet$new(alpha = 0)
lrn_enet <- Lrnr_glmnet$new(alpha = 0.5)
lrn_bart <- Lrnr_bartMachine$new()
lrn_mean <- Lrnr_mean$new()

learners <- unlist(list(
  #mars_learners, # don't include commented out libraries in demo code due to time
  lrn_lasso,
  #lrn_ridge,
  #lrn_enet,
  #lrn_bart,
  lrn_mean
),
recursive = TRUE
)

lrnrs <- make_learner(Stack, learners) # stack all learners together, see sl3 documentation

## -----------------------------------------------------------------------------------------

## set LMTP parameters of outcome, censoring treatment, and confounders

outcome_day <- 14 # half the outcome time frame (for computational time purposes)
padded_days <- str_pad(0:(outcome_day-1), 2, pad = "0")
padded_days_out <- str_pad(1:outcome_day, 2, pad = "0")

a <-  paste0("A_", padded_days) # names of treatment cols
bs <- dat_lmtp |> # names of baseline covariates cols
  select(red_cap_source, age, sex, bmi, cad, home_o2_yn, dm, htn, cva) |> # subset of baseline confounders from paper
  names()
y <- paste0("Y_",padded_days_out) # names of outcome cols
censoring <- paste0("C_",padded_days) # names of censoring cols (1 = observed at next time point)

used_letters <- dat_lmtp |> # names of time varying covariates
  select(starts_with("L_"),
         starts_with("H_"),
         -ends_with(paste0("_",outcome_day))) |>
  names() 

tv <- map(0:(outcome_day - 1), function(x) { # time varying covariates must be a list
  used_letters[str_detect(used_letters, str_pad(x, 2, pad="0"))]
})

## ----------------------------------------------------

## miscellaneous LMTP function parameters 

trim <- .995 # quantile range for trimming ranges, if necessary
folds <- 5 # cross-fitting folds (5 for time, 10 in paper)
SL_folds <- 5 # cross-validation folds for superlearning (5 for time, 10 in paper)
k <- 1 # we assume that data from k days previously is sufficient for the patient's covariate history
# this is 2 in the paper

## -----------------------------------------------------------------------------------------

## fit LMTP results objects -- note that estimate is for survival, not incidence rate

# intervention 1
res_steroid <-
  progressr::with_progress(
    lmtp_sdr(
      dat_lmtp,
      trt = a,
      outcome = y,
      baseline = bs,
      time_vary = tv,
      cens = censoring,
      shift = int_steroids_after_hypoxia,
      outcome_type = "survival",
      learners_outcome = lrnrs,
      learners_trt = lrnrs,
      folds = folds,
      .SL_folds = SL_folds,
      .trim = trim,
      k=k,
      intervention_type = "dynamic"
    )
  )

# intervention 2
res_no_steroid <-
  progressr::with_progress(
  lmtp_sdr(
    dat_lmtp,
    trt = a,
    outcome = y,
    baseline = bs,
    time_vary = tv,
    cens = censoring,
    shift = int_no_steroids,
    outcome_type = "survival",
    learners_outcome = lrnrs,
    learners_trt = lrnrs,
    folds = folds,
    .SL_folds = SL_folds,
    .trim = trim,
    k=k,
    intervention_type = "static"
  )
  )

## -----------------------------------------------------------------------------------------

## save results

saveRDS(res_steroid, file = here::here("output/res_steroid.rds"))
saveRDS(res_no_steroid, file = here::here("output/res_no_steroid.rds"))


