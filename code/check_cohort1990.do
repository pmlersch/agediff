****************************************************************************************************************
** check_cohort1990.do
** Diagnostic checks for the negative mean age gap in the 1990–1999 birth cohort
**
** Tests three hypotheses:
**   1. Selection on age at observation: the 1990s cohort is observed much
**      younger than earlier cohorts, so only early marriages are captured.
**   2. Early marriages have smaller (or negative) age gaps: men who marry
**      very young tend to partner with same-age or older women.
**   3. DHS truncation: DHS interviews women 15–49 only, which may
**      over-represent very young couples in recent cohorts.
**
** Input: data/harmonized/harmonized.dta
****************************************************************************************************************

use "data/harmonized/harmonized.dta", clear


* =============================================================================
* CHECK 1: Age at survey and sample size by cohort
*
* If the 1990s cohort is observed at much younger ages, that confirms
* right-censoring: most people from that cohort haven't married yet.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 1: Age at survey and sample size by cohort"
di "============================================================"

* Age at time of survey
gen age_at_survey = year - birth_cohort

preserve
    collapse (mean) mean_age_survey=age_at_survey              ///
             (p50) median_age_survey=age_at_survey             ///
             (min) min_age_survey=age_at_survey                ///
             (max) max_age_survey=age_at_survey                ///
             (count) N=age_diff, by(cohort_group cohort_start)
    sort cohort_start
    format mean_age_survey median_age_survey %6.1f
    format N %12.0fc
    list cohort_group N mean_age_survey median_age_survey      ///
         min_age_survey max_age_survey, noobs sep(0)
restore


* =============================================================================
* CHECK 2: Mean age gap by age at survey within the 1990s cohort
*
* If selection drives the negative mean, then restricting to older
* respondents (observed at 30+) should shift the mean toward positive values.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 2: Mean age gap by age at survey, 1990–1999 cohort"
di "============================================================"

preserve
    keep if cohort_start == 1990

    * Create age-at-survey bins
    gen age_survey_bin = .
    replace age_survey_bin = 15 if age_at_survey >= 15 & age_at_survey < 20
    replace age_survey_bin = 20 if age_at_survey >= 20 & age_at_survey < 25
    replace age_survey_bin = 25 if age_at_survey >= 25 & age_at_survey < 30
    replace age_survey_bin = 30 if age_at_survey >= 30 & age_at_survey < 35
    replace age_survey_bin = 35 if age_at_survey >= 35

    collapse (mean) mean_gap=age_diff (mean) pct_wife_older=wife_older ///
             (sd) sd_gap=age_diff (count) N=age_diff,                  ///
             by(age_survey_bin)
    replace pct_wife_older = pct_wife_older * 100
    format mean_gap sd_gap pct_wife_older %6.2f
    format N %12.0fc
    list age_survey_bin N mean_gap sd_gap pct_wife_older, noobs sep(0)
restore


* =============================================================================
* CHECK 3: Mean age gap by cohort, restricted to age at survey >= 30
*
* Applying a uniform minimum-age filter across cohorts should eliminate
* or strongly attenuate the 1990s anomaly. If the negative gap persists
* even among 30+ respondents, the pattern would be substantive.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 3: Mean age gap by cohort — all vs. age at survey >= 30"
di "============================================================"

preserve
    * Full sample means
    collapse (mean) mean_gap_all=age_diff                     ///
             (mean) pct_wo_all=wife_older                     ///
             (count) N_all=age_diff, by(cohort_group cohort_start)
    tempfile full
    save `full'
restore

preserve
    keep if age_at_survey >= 30

    collapse (mean) mean_gap_30plus=age_diff                  ///
             (mean) pct_wo_30plus=wife_older                  ///
             (count) N_30plus=age_diff, by(cohort_group cohort_start)

    merge 1:1 cohort_start using `full', nogen
    sort cohort_start
    replace pct_wo_all    = pct_wo_all * 100
    replace pct_wo_30plus = pct_wo_30plus * 100
    gen diff_mean = mean_gap_30plus - mean_gap_all
    format mean_gap_all mean_gap_30plus diff_mean              ///
           pct_wo_all pct_wo_30plus %6.2f
    format N_all N_30plus %12.0fc
    list cohort_group N_all mean_gap_all pct_wo_all            ///
         N_30plus mean_gap_30plus pct_wo_30plus diff_mean,     ///
         noobs sep(0)
restore


* =============================================================================
* CHECK 4: Country-level comparison — all ages vs. age >= 30, 1990s cohort
*
* For countries with the most extreme negative values, does the gap
* flip to positive when restricted to older respondents?
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 4: Country-level mean age gap, 1990s cohort — all vs. 30+"
di "============================================================"

preserve
    keep if cohort_start == 1990
    bysort country_name: gen n_all = _N

    * Full sample
    collapse (mean) mean_all=age_diff (count) N_all=age_diff, ///
             by(country_name)
    tempfile c_full
    save `c_full'
restore

preserve
    keep if cohort_start == 1990 & age_at_survey >= 30

    collapse (mean) mean_30plus=age_diff (count) N_30plus=age_diff, ///
             by(country_name)

    merge 1:1 country_name using `c_full', nogen
    gen diff = mean_30plus - mean_all
    gsort mean_all
    format mean_all mean_30plus diff %6.2f
    format N_all N_30plus %12.0fc
    list country_name N_all mean_all N_30plus mean_30plus diff ///
         if N_all >= 30, noobs sep(0)
restore


* =============================================================================
* CHECK 5: Role of DHS truncation
*
* DHS only surveys women 15–49. If DHS dominates the 1990s cohort,
* this sample restriction could drive the negative gap. Compare
* mean age gap by source within the 1990s cohort.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 5: Mean age gap by source, 1990s cohort"
di "============================================================"

preserve
    keep if cohort_start == 1990
    collapse (mean) mean_gap=age_diff (mean) pct_wife_older=wife_older ///
             (sd) sd_gap=age_diff (count) N=age_diff                   ///
             (mean) mean_age=age_at_survey,                            ///
             by(source)
    replace pct_wife_older = pct_wife_older * 100
    format mean_gap sd_gap pct_wife_older mean_age %6.2f
    format N %12.0fc
    list source N mean_gap sd_gap pct_wife_older mean_age, noobs sep(0)
restore


* =============================================================================
* CHECK 6: Share of 1990s cohort sample by source
*
* Shows whether DHS or IPUMS dominates the 1990s cohort observations.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 6: Source composition by cohort"
di "============================================================"

preserve
    gen one = 1
    collapse (count) N=one, by(cohort_group cohort_start source)
    bysort cohort_start: egen cohort_total = total(N)
    gen pct = N / cohort_total * 100
    format N cohort_total %12.0fc
    format pct %6.1f
    sort cohort_start source
    list cohort_group source N pct, noobs sep(4)
restore


di _newline(2) "============================================================"
di "SUMMARY"
di "============================================================"
di "If Check 1 shows the 1990s cohort is observed at much younger ages,"
di "Check 2 shows the gap increases with age at survey,"
di "and Check 3 shows the negative gap disappears for 30+ respondents,"
di "then the negative mean is a selection/censoring artifact."
di "Check 5–6 reveal whether DHS truncation compounds the issue."
