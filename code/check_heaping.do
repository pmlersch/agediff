****************************************************************************************************************
** check_heaping.do
** Diagnostic checks for age-difference heaping at 0, 5, and 10 years
**
** Tests three hypotheses:
**   1. Heaping is concentrated in sources with proxy-reported partner age
**      (ISSP, DHS) rather than household-grid birth year (ESS) or census (IPUMS).
**   2. Heaping is driven by underlying age heaping in both partners' ages:
**      when both ages cluster at multiples of 5, so does the difference.
**   3. Heaping varies across countries within the same source, pointing to
**      country-level reporting practices rather than survey design alone.
**
** Input: data/harmonized/harmonized.dta
****************************************************************************************************************

use "data/harmonized/harmonized.dta", clear


* =============================================================================
* SETUP: heaping indicators
* =============================================================================

* Age difference divisible by 5
gen agediff_div5 = (mod(age_diff, 5) == 0) if !missing(age_diff)

* Age difference exactly 0, 5, or 10
gen agediff_at0  = (age_diff == 0)
gen agediff_at5  = (age_diff == 5)
gen agediff_at10 = (age_diff == 10)
gen agediff_heap = (agediff_at0 | agediff_at5 | agediff_at10)

* Individual age heaping (divisible by 5)
gen age_div5         = (mod(age, 5) == 0)         if !missing(age)
gen age_partner_div5 = (mod(age_partner, 5) == 0) if !missing(age_partner)
gen both_div5        = (age_div5 == 1 & age_partner_div5 == 1)


* =============================================================================
* CHECK 1: Heaping rates by source
*
* Under uniform (no-heaping) age differences, ~20% would be divisible by 5
* and each of 0/5/10 would appear at their expected frequency given the
* distribution shape. Excess above 20% signals heaping.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 1: Age-difference heaping by source"
di "============================================================"

preserve
    collapse (mean) pct_div5=agediff_div5                      ///
             (mean) pct_at0=agediff_at0                        ///
             (mean) pct_at5=agediff_at5                        ///
             (mean) pct_at10=agediff_at10                      ///
             (mean) pct_heap=agediff_heap                      ///
             (count) N=age_diff, by(source)
    foreach v of varlist pct_* {
        replace `v' = `v' * 100
    }
    format pct_* %6.2f
    format N %12.0fc
    list source N pct_div5 pct_at0 pct_at5 pct_at10 pct_heap, noobs sep(0)
    di _newline "Note: Under no heaping, pct_div5 ≈ 20%."
restore


* =============================================================================
* CHECK 2: Heaping rates by country (all sources pooled)
*
* Ranks countries by the share of age differences divisible by 5.
* Highlights the countries the user flagged: Ireland, Palestine, Israel, Slovenia.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 2: Age-difference heaping by country (all sources)"
di "============================================================"

preserve
    collapse (mean) pct_div5=agediff_div5                      ///
             (mean) pct_at0=agediff_at0                        ///
             (mean) pct_at5=agediff_at5                        ///
             (mean) pct_at10=agediff_at10                      ///
             (mean) pct_heap=agediff_heap                      ///
             (count) N=age_diff, by(country_name)
    foreach v of varlist pct_* {
        replace `v' = `v' * 100
    }
    format pct_* %6.2f
    format N %12.0fc
    gsort -pct_div5
    list country_name N pct_div5 pct_at0 pct_at5 pct_at10 pct_heap, noobs sep(0)
restore


* =============================================================================
* CHECK 3: Heaping by country × source
*
* For the flagged countries, breaks down heaping by source to identify
* which surveys drive the problem.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 3: Heaping by country × source (flagged countries)"
di "============================================================"

preserve
    keep if inlist(country_name, "Ireland", "Palestine", "Israel", "Slovenia")
    collapse (mean) pct_div5=agediff_div5                      ///
             (mean) pct_at0=agediff_at0                        ///
             (mean) pct_heap=agediff_heap                      ///
             (count) N=age_diff, by(country_name source)
    foreach v of varlist pct_* {
        replace `v' = `v' * 100
    }
    format pct_* %6.2f
    format N %12.0fc
    sort country_name source
    list country_name source N pct_div5 pct_at0 pct_heap, noobs sep(0)
restore


* =============================================================================
* CHECK 4: Underlying age heaping in respondent and partner ages
*
* If both partners' ages are heaped at multiples of 5, the difference
* will mechanically land on a multiple of 5. Compare the rate of both
* ages being divisible by 5 across sources.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 4: Underlying age heaping (% divisible by 5) by source"
di "============================================================"

preserve
    collapse (mean) pct_age_div5=age_div5                      ///
             (mean) pct_partner_div5=age_partner_div5          ///
             (mean) pct_both_div5=both_div5                    ///
             (count) N=age_diff, by(source)
    foreach v of varlist pct_* {
        replace `v' = `v' * 100
    }
    format pct_* %6.2f
    format N %12.0fc
    list source N pct_age_div5 pct_partner_div5 pct_both_div5, noobs sep(0)
    di _newline "Note: Under no heaping, each ≈ 20%; both ≈ 4%."
restore


* =============================================================================
* CHECK 5: Age-difference heaping conditional on both ages being div-by-5
*
* Among couples where both ages are divisible by 5, the age difference
* is mechanically divisible by 5. Compare heaping rates for couples
* with vs. without both-ages-div5.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 5: Age-diff heaping conditional on both ages div-by-5"
di "============================================================"

preserve
    collapse (mean) pct_diff_div5=agediff_div5                 ///
             (count) N=age_diff, by(source both_div5)
    replace pct_diff_div5 = pct_diff_div5 * 100
    format pct_diff_div5 %6.2f
    format N %12.0fc
    sort source both_div5
    list source both_div5 N pct_diff_div5, noobs sep(2)
    di _newline "If heaping is mechanical, pct_diff_div5 = 100% when both_div5 = 1."
restore


* =============================================================================
* CHECK 6: Heaping over birth cohorts
*
* Age reporting quality has improved over time. Heaping should decline
* across cohorts, especially in developing countries.
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 6: Age-difference heaping by cohort and source"
di "============================================================"

preserve
    collapse (mean) pct_div5=agediff_div5                      ///
             (mean) pct_partner_div5=age_partner_div5          ///
             (count) N=age_diff, by(cohort_group cohort_start source)
    foreach v of varlist pct_* {
        replace `v' = `v' * 100
    }
    format pct_* %6.2f
    format N %12.0fc
    sort source cohort_start
    list source cohort_group N pct_div5 pct_partner_div5, noobs sep(8)
restore


* =============================================================================
* CHECK 7: Whipple-like index for partner age by source and country
*
* The Whipple index measures concentration of ages at digits 0 and 5.
* W = (sum of ages ending in 0 or 5) / (total / 5) × 100.
* W = 100 means no heaping; W > 100 means excess heaping.
* Computed here for partner age only (the proxy-reported variable).
* =============================================================================

di _newline(2) "============================================================"
di "CHECK 7: Whipple-like index for partner age, by source"
di "============================================================"

preserve
    * Restrict to standard Whipple range (ages 23–62)
    keep if age_partner >= 23 & age_partner <= 62

    gen partner_ends05 = (mod(age_partner, 5) == 0)
    collapse (mean) share_05=partner_ends05 (count) N=age_diff, by(source)
    * Whipple index: share at 0/5 digits relative to expected 2/10 = 0.20
    gen whipple = share_05 / 0.20 * 100
    format whipple %6.1f
    format N %12.0fc
    list source N whipple, noobs sep(0)
    di _newline "Whipple = 100: no heaping. >105: moderate. >125: significant."
restore

di _newline "--- By country (top 20 highest Whipple) ---"

preserve
    keep if age_partner >= 23 & age_partner <= 62
    gen partner_ends05 = (mod(age_partner, 5) == 0)
    collapse (mean) share_05=partner_ends05 (count) N=age_diff, by(country_name)
    gen whipple = share_05 / 0.20 * 100
    format whipple %6.1f
    format N %12.0fc
    gsort -whipple
    list country_name N whipple in 1/100, noobs sep(0)
restore

