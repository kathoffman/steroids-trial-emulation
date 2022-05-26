<h1>Steroids Target Trial Emulation Tutorial</h1>

This repository was created to help other analysts run an analysis similar to Hoffman et. al's *Corticosteroids in COVID-19: Optimizing Observational Research Through Target Trial Emulations* (2022).

A [slideshow](presentations/hoffman_acic_slides.pdf) summary of the paper is available in the [presentations](/presentations) folder. These slides were presented by Katherine Hoffman at the American Causal Inference Conference in Berkeley, CA on May 24, 2022.

<h2>Code Tutorial Contents</h2>

- A script run a similar analysis (pared to improve computational time) with demo data of n=2000 patients: [`analysis.R`](code/analysis.R).

- A script run a similar analysis to clean the output of `analysis.R`: [`report_results.R`](code/report_results.R)

<h2>Demo Data</h2>

The analysis is primarily run using the open source `R` package `lmtp` (*please note we use the `sl3`-compatible version*). We provide demo data in the `data` folder in combination with this visual representation of the required data format:

![](/img/analytical_file.png)

The required data structure for a longitudinal time-to-event analysis is wide (one row per subject), with one column per time point per variable (treatment, censoring indicator, outcome indicator, time-varying covariate). The exception to this is baseline variables, which by definition do not have multiple time points.

A few notes to help with pre-processing:

- Subjects should by default have a "censoring" indicator of `1` to indicate they are *observed at the next time point*. If lost to follow up, this indicator becomes `0`. The censoring indicator should be `1` if the subject experiences the event at the next time point, and `NA` for the following time points.

- If a patient experiences the event, their outcome variables should be `1` for all time points until the end of the study.

- If a patient has a censoring indicator of `0` (meaning they are lost to follow-up starting at the next time point), all columns corresponding to those future time points should have values of `NA`.