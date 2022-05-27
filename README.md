<h1>Steroids Target Trial Emulation Tutorial</h1>

This repository was created to help other analysts run an analysis similar to Hoffman et. al's MedRxiv pre-print *Corticosteroids in COVID-19: Optimizing Observational Research Through Target Trial Emulations* (2022).

A [slide deck](presentations/hoffman_acic_slides.pdf) on this research was presented at the American Causal Inference Conference in Berkeley, CA on May 24, 2022.

<h2>Code Contents</h2>

-  [`analysis.R`](code/analysis.R): a script to run a similar analysis (pared to improve computational time) with demo data of n=2000 patients

- [`report_results.R`](code/report_results.R): a script to clean the output of `analysis.R`

<h2>Demo Data</h2>

The primary analysis is run using the open source `R` package [`lmtp`](https://github.com/nt-williams/lmtp) (*please note we use the `sl3`-compatible branch to improve computational speed*). A helpful vignette is available here. We provide demo data in the `data` folder in combination with this visual representation of the required data format:

![](/img/analytical_file.png)

The required data structure for a longitudinal time-to-event analysis is wide (one row per subject), with one column per time point per variable (treatment, censoring indicator, outcome indicator, time-varying covariate). The exception to this is baseline variables, which by definition do not have multiple time points.

A few notes to help with pre-processing:

- Subjects should by default have a "censoring" indicator of `1` to indicate they are *observed at the next time point*. If lost to follow up, this indicator becomes `0`. The censoring indicator should be `1` if the subject experiences the event at the next time point, and `NA` for the following time points.

- If a patient experiences the event, their outcome variables should be `1` for all time points until the end of the study.

- If a patient has a censoring indicator of `0` (meaning they are lost to follow-up starting at the next time point), all columns corresponding to those future time points should have values of `NA`.

<h2>Analysis Specifications</h2>

<h3>Super learner libraries</h3>

The code to make super learner libraries (via `sl3`) used in the paper's analysis is in `analysis.R`, however, all but LASSO and mean are commented out to improve computational time. Learners were the same for intervention and outcome mechanisms. We specified 10 folds for superlearner cross-validation. This is set to a value of `.SL_folds=5` in our demo analysis code for computational time purposes.

<h3>Time-dependent confounding assumption</h3>

We used a Markov assumption of 2, meaning a patient's time-dependent confounders for the previous two time periods (48 hour windows) were sufficient to capture confounding for the next time point's mechanism. This was a decision stemming from clinical knowledge (laboratory results are ordered in  24 or 48 hour intervals). This is set to a value of `k=1` in our demo analysis code for computational time purposes.

<h3>Cross-fitting</h3>

We employed 10-fold cross-fitting on our SDR estimator. This is set to a value of `folds=5` in our demo analysis code for computational time purposes.