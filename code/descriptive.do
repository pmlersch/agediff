****************************************************************************************************************
****************************************************************************************************************
***Author: Philipp M. Lersch
***Project: Variance in the Age Difference in Different-Sex Marriage across Time And Contexts
***Data sets: DHS, ESS, ISSP, IPUMS 
****************************************************************************************************************
****************************************************************************************************************

*****************************************************
**Descriptives I**
*****************************************************


* -----------------------------------------------------------------------------
* 1. Setup & data loading
* -----------------------------------------------------------------------------

use "data/harmonized/harmonized.dta", clear

* -----------------------------------------------------------------------------
* 3. Descriptive statistics — Tables
* -----------------------------------------------------------------------------

* ---- Table 1: Overall summary -----------------------------------------------
di _newline "===== Table 1: Overall age-gap summary ====="
preserve
    collapse (count) N=age_diff (mean) Mean=age_diff (sd) SD=age_diff    ///
             (p50) Median=age_diff (p25) Q25=age_diff (p75) Q75=age_diff ///
             (mean) Pct_wife_older=wife_older
    gen IQR = Q75 - Q25
    replace Pct_wife_older = round(Pct_wife_older * 100, 0.1)
    format N %12.0fc
    format Mean SD Median IQR Pct_wife_older %6.2f
    list N Mean SD Median IQR Pct_wife_older, noobs
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table1_overall.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table 2: Summary by country --------------------------------------------
di _newline "===== Table 2: Age-gap summary by country ====="
preserve
    collapse (count) N=age_diff (mean) Mean=age_diff (sd) SD=age_diff    ///
             (p50) Median=age_diff (p25) Q25=age_diff (p75) Q75=age_diff ///
             (mean) Pct_wife_older=wife_older (mean) Mean_age=age, by(country_name)
    replace Pct_wife_older = round(Pct_wife_older * 100, 0.1)
    format Mean SD Median Q25 Q75 Pct_wife_older Mean_age %6.2f
    gsort -Mean
    list country_name N Mean SD Median Q25 Q75 Pct_wife_older Mean_age, noobs sep(0)
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table2_by_country.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table 3: Summary by birth cohort ---------------------------------------
di _newline "===== Table 3: Age-gap summary by birth cohort ====="
preserve
    collapse (count) N=age_diff (mean) Mean=age_diff (sd) SD=age_diff    ///
             (p50) Median=age_diff (p25) Q25=age_diff (p75) Q75=age_diff ///
             (mean) Pct_wife_older=wife_older (mean) Mean_age=age, by(cohort_group)
    replace Pct_wife_older = round(Pct_wife_older * 100, 0.1)
    format Mean SD Median Q25 Q75 Pct_wife_older Mean_age %6.2f
    sort cohort_group
    list cohort_group N Mean SD Median Q25 Q75 Pct_wife_older Mean_age, noobs sep(0)
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table3_by_cohort.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table 4: Mean age gap by country × cohort (wide format) ----------------
di _newline "===== Table 4: Mean age gap by country x cohort ====="
preserve
    bysort country_name cohort_group: gen n_cell = _N
    drop if n_cell < 100
    collapse (mean) mean_gap=age_diff, by(country_name cohort_start)
    format mean_gap %6.2f
    reshape wide mean_gap, i(country_name) j(cohort_start)
    list, sep(0) noobs
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table4_mean_by_country_cohort.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table 5: SD of age gap by country × cohort (wide format) ---------------
di _newline "===== Table 5: SD of age gap by country x cohort ====="
preserve
    bysort country_name cohort_group: gen n_cell = _N
    drop if n_cell < 100
    collapse (sd) sd_gap=age_diff, by(country_name cohort_start)
    format sd_gap %6.2f
    reshape wide sd_gap, i(country_name) j(cohort_start)
    list, sep(0) noobs
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table5_sd_by_country_cohort.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table 6: Sample size by country × year (wide format) -------------------
di _newline "===== Table 6: Sample size by country x year ====="
preserve
    collapse (count) N=age_diff, by(country_name year)
    reshape wide N, i(country_name) j(year)
    gsort country_name
    list, sep(0) noobs
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/table6_n_by_country_year.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* ---- Table O1: Appendix — mean, SD, min, max by country --------------------
di _newline "===== Table O1: Descriptive statistics by country (appendix) ====="
preserve
    collapse (mean) mean_age=age (sd) sd_age=age (min) min_age=age (max) max_age=age                     ///
             (mean) mean_age_partner=age_partner (sd) sd_age_partner=age_partner                          ///
             (min)  min_age_partner=age_partner  (max) max_age_partner=age_partner                        ///
             (mean) mean_age_diff=age_diff       (sd)  sd_age_diff=age_diff                               ///
             (min)  min_age_diff=age_diff        (max) max_age_diff=age_diff                              ///
             (mean) mean_year=year               (sd)  sd_year=year                                       ///
             (min)  min_year=year                (max) max_year=year                                      ///
             (mean) mean_birth_cohort=birth_cohort (sd)  sd_birth_cohort=birth_cohort                     ///
             (min)  min_birth_cohort=birth_cohort  (max) max_birth_cohort=birth_cohort,                   ///
             by(country_name)
    format mean_age sd_age mean_age_partner sd_age_partner mean_age_diff sd_age_diff ///
           mean_year sd_year mean_birth_cohort sd_birth_cohort %6.2f
    format min_age max_age min_age_partner max_age_partner                           ///
           min_age_diff max_age_diff min_year max_year                               ///
           min_birth_cohort max_birth_cohort %6.0f
    gsort country_name
    list country_name                                                                 ///
         mean_age sd_age min_age max_age                                             ///
         mean_age_partner sd_age_partner min_age_partner max_age_partner             ///
         mean_age_diff sd_age_diff min_age_diff max_age_diff                         ///
         mean_year sd_year min_year max_year                                         ///
         mean_birth_cohort sd_birth_cohort min_birth_cohort max_birth_cohort,        ///
         noobs sep(0)
    quietly ds
    local _hdr "|"
    local _sep "|"
    foreach _v of varlist `r(varlist)' {
        local _hdr "`_hdr' `_v' |"
        local _sep "`_sep' --- |"
    }
    listtab using "results/tableO1_descriptives_by_country.md", replace rstyle(markdown) ///
        headlines("`_hdr'" "`_sep'")
restore

* -----------------------------------------------------------------------------
* 4. Descriptive figures
* -----------------------------------------------------------------------------

* ---- Figure 1: Histogram of age differences (all data) ----------------------
twoway histogram age_diff,  width(1)               ///
    xline(0, lpattern(dash))                                  ///
    ytitle("Density")                                            ///
    xtitle("Age difference (husband - wife)")                ///
    title("Figure 1: Distribution of within-couple age gaps")             ///
    name(fig1_histogram, replace)
graph export "results/fig1_histogram.emf",  replace
graph export "results/fig1_histogram.pdf",  replace


* ---- Figure 2: Caterpillar plot — median and IQR by country -----------------
preserve
    collapse (p50) med=age_diff (p25) q25=age_diff (p75) q75=age_diff,  ///
        by(country_name)
    sort med
    gen country_n = _n

    * Build value label mapping country_n → country name
    capture label drop cntry_lbl
    forvalues i = 1/`=_N' {
        local clab = country_name[`i']
        label define cntry_lbl `i' "`clab'", modify
    }
    label values country_n cntry_lbl

    local ncnt = _N
    twoway                                                                 ///
        (pcspike country_n q25 country_n q75, lwidth(thin))           ///
        (scatter country_n med, msymbol(O) msize(vsmall)),                        ///
        ylabel(1(1)`ncnt', valuelabel labsize(half_tiny) angle(0))                    ///
        ytitle("") xtitle("Age difference (husband - wife): Median and IQR")         ///
        legend(off)                                                        ///
        title("Figure 2: Median age gap and interquartile range by country") ///
        name(fig2_caterpillar, replace)
    graph export "results/fig2_caterpillar.emf",  replace
    graph export "results/fig2_caterpillar.pdf",  replace    
restore


* ---- Figure 5: Mean and SD of age gap over birth cohorts --------------------
* Two-panel figure: left = mean, right = SD. Individual country lines in grey;
* overall trend in bold colour.

* Country-cohort statistics (min 30 observations per cell)
preserve
    bysort country_name cohort_group: gen n_cell = _N
    drop if n_cell < 100
    collapse (mean) mean_gap=age_diff (sd) sd_gap=age_diff, ///
        by(country_name cohort_start)
    sort country_name cohort_start
    tempfile cc_stats
    save `cc_stats'
restore

* Overall cohort statistics
preserve
    collapse (mean) mean_overall=age_diff (sd) sd_overall=age_diff, ///
        by(cohort_start)
    sort cohort_start
    tempfile ov_stats
    save `ov_stats'
restore

* Build Panel A (mean) and Panel B (SD), then combine
preserve
    use `cc_stats', clear
    merge m:1 cohort_start using `ov_stats', nogen keep(1 3)

    levelsof country_name, local(countries)
    local cmd_mean ""
    local cmd_sd   ""
    foreach c of local countries {
        local cmd_mean `cmd_mean' ///
            (line mean_gap cohort_start if country_name == "`c'", ///
                lcolor(gs12) lwidth(vthin))
        local cmd_sd `cmd_sd'   ///
            (line sd_gap cohort_start if country_name == "`c'",   ///
                lcolor(gs12) lwidth(vthin))
    }

    * Panel A: mean
    twoway `cmd_mean'                                                      ///
        connected mean_overall cohort_start,                   ///
        xtitle("Birth cohort") ytitle("Mean age gap (husband - wife)")             ///
        xlabel(1920(10)1980, angle(45) labsize(small))                   ///
        title("A: Mean") legend(off)                                      ///
        name(fig5a_mean, replace)
    graph save "fig5a_mean_tmp.gph", replace

    * Panel B: SD
    twoway `cmd_sd'                                                        ///
        connected sd_overall cohort_start,                       ///
        xtitle("Birth cohort") ytitle("SD of age gap (husband - wife)")            ///
        xlabel(1920(10)1980, angle(45) labsize(small))                   ///
        title("B: Standard deviation") legend(off)                        ///
        name(fig5b_sd, replace)
    graph save "fig5b_sd_tmp.gph", replace

    graph combine "fig5a_mean_tmp.gph" "fig5b_sd_tmp.gph", cols(2)        ///
        title("Figure 5: Mean and dispersion of age gap across birth cohorts") ///
        note("Grey lines = individual countries; coloured line = overall trend") ///
        name(fig5_combined, replace)
    graph export "results/fig5_cohort_mean_sd.emf",      replace
    graph export "results/fig5_cohort_mean_sd.pdf",      replace

    erase "fig5a_mean_tmp.gph"
    erase "fig5b_sd_tmp.gph"
restore


* ---- Figure 9: Scatter — mean vs. SD for the most recent cohort -------------
* Each point is one country; line = OLS trend.
preserve
    * Identify the latest cohort group with at least 500 observations
    bysort cohort_group: gen n_cohort = _N
    * Keep only cohort groups large enough
    keep if n_cohort >= 500
    * Select the most recent such cohort
    egen latest_start = max(cohort_start)
    keep if cohort_start == latest_start
    local latest_lbl = cohort_group[1]

    * Country-level summary (min 30 obs per country)
    bysort country_name: gen n_ctry = _N
    drop if n_ctry < 100
    collapse (mean) mean_gap=age_diff (sd) sd_gap=age_diff, by(country_name)

    twoway                                                                  ///
        (scatter sd_gap mean_gap,                                          ///
            mcolor(navy%80) msymbol(O) msize(small)                       ///
            mlabel(country_name) mlabsize(tiny) mlabpos(3))               ///
        (lfit sd_gap mean_gap,                                             ///
            lcolor(firebrick) lwidth(thin)),                               ///
        xtitle("Mean age gap (years)")                                     ///
        ytitle("SD of age gap (years)")                                    ///
        title("Figure 9: Mean vs. dispersion of age gaps (`latest_lbl' cohort)") ///
        legend(off)                                                        ///
        name(fig9_mean_vs_sd, replace)
    graph export "results/fig9_mean_vs_sd.emf",  replace
    graph export "results/fig9_mean_vs_sd.pdf",  replace
restore

* ---- Figure 10: Mean & SD of age gap by country ----------------------------
* Each country: dot at mean and SD
* Complements Figure 2 (median [IQR]) using moment-based statistics.
preserve
    collapse (mean) mean_gap=age_diff (sd) sd_gap=age_diff              ///
             (count) N=age_diff, by(country_name)
    drop if N < 100
    sort mean_gap
    gen country_n = _n

    capture label drop cntry10_lbl
    forvalues i = 1/`=_N' {
        local clab = country_name[`i']
        label define cntry10_lbl `i' "`clab'", modify
    }
    label values country_n cntry10_lbl

    local ncnt = _N
    twoway                                                                  ///
        (scatter country_n sd_gap , msize(vsmall))                                      ///
        (scatter country_n mean_gap, msize(vsmall)),                    ///
        ylabel(1(1)`ncnt', valuelabel labsize(half_tiny) angle(0))                        ///
        ytitle("") xtitle("Age difference (husband-wife)")  ///
        legend(order(1 "Mean" 2 "SD"))                                                        ///
        title("Figure 10: Mean and dispersion of age gap by country")       ///
        name(fig10_mean_sd_country, replace)
    graph export "results/fig10_mean_sd_country.pdf", replace
    graph export "results/fig10_mean_sd_country.emf", replace
restore

*last line
