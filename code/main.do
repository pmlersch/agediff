****************************************************************************************************************
****************************************************************************************************************
***Author: Philipp M. Lersch
***Project: Variance in the Age Difference in Different-Sex Marriage across Time And Contexts
***Data sets: DHS, ESS, ISSP, IPUMS 
****************************************************************************************************************
****************************************************************************************************************

*****************************************************
**MAIN**
*****************************************************

version 17
set more off

*ssc install kountry
*net install rcall, from("https://raw.githubusercontent.com/haghish/rcall/master/")
*ssc install cleanplots
*ssc install listtab

cd "D:/Papers/2025_agediff/"	//Work folder

***set graph options
set scheme cleanplots
graph set window fontface "Times New Roman"
graph set eps fontface Times

******************************************************************************
* 1. Harmonize individual data sources
******************************************************************************

do "code/get_dhs.do"
do "code/get_ess.do"
do "code/get_ipums.do"
do "code/get_issp.do"

******************************************************************************
* 2. Merge harmonized datasets
******************************************************************************

do "code/merge_data.do"

******************************************************************************
* 3. Statistical analysis
******************************************************************************


* 1a. Tables 1–5 and Figures 1, 2, 3c, 4, 4b, 5, 6 — produced in Stata
do "code/descriptive.do"

* 1b. Ridgeline figures 3 and 3b — produced in R (ggridges has no Stata
*     equivalent); also loads the harmonized data into the R session and
*     constructs cohort_group and age_diff for the multivariate models.
rcall: source("code/descriptive.R")

* -----------------------------------------------------------------------------
* 2. Basic multivariate analysis (Models M1–M4, Figures 7–9)
* -----------------------------------------------------------------------------
rcall: source("code/multivariate_basic.R")

* -----------------------------------------------------------------------------
* 3. Advanced multivariate analysis, country-level figures, and diagnostics
* -----------------------------------------------------------------------------
rcall: source("code/multivariate_advanced.R")

