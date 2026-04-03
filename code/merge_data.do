
local dir "data/harmonized"
local first 1

foreach src in ess issp ipums dhs {
    capture confirm file "`dir'/`src'_harmonized.dta"
    if !_rc {
        if `first' {
            use "`dir'/`src'_harmonized.dta", clear
            local first 0
        }
        else append using "`dir'/`src'_harmonized.dta"
    }
    else di "[merge] `src' not found — skipping."
}

if `first' {
    di "[merge] No harmonized files found. Run the get_*.do scripts first."
    exit 1
}


* -----------------------------------------------------------------------------
* Variable construction
* -----------------------------------------------------------------------------

* numeric country var

encode country_name, gen(country_id)

* Top-code age and age_partner at 99 before creating the age difference variable
replace age         = 99 if age         > 99 & !missing(age)
replace age_partner = 99 if age_partner > 99 & !missing(age_partner)

* age_diff: man's age minus woman's age (sex 1=male, 2=female)
gen age_diff = .
replace age_diff = round(age - age_partner) if sex == 1 & sex_partner == 2
replace age_diff = round(age_partner - age) if sex == 2 & sex_partner == 1

* Create 10-year birth-cohort groups  [1930–1939], … [1990–1999].
* floor() maps each birth year to the start of its decade bin.
gen cohort_start = floor((birth_cohort - 1920) / 10) * 10 + 1920
gen cohort_group = string(cohort_start) + "-" + string(cohort_start + 9)

* Drop observations outside the defined range or with missing age_diff
replace cohort_group = "" if birth_cohort < 1920 | birth_cohort >= 2000 ///
    | missing(birth_cohort)
drop if cohort_group == ""

* Indicator: wife is older (age_diff < 0)
gen wife_older = (age_diff < 0)

* -----------------------------------------------------------------------------
* Survey weight normalization
* -----------------------------------------------------------------------------
* Raw design weights are not comparable across sources: IPUMS census weights
* run into the thousands while ESS/ISSP weights are near 1. Without rescaling,
* IPUMS would dominate any pooled statistic purely due to scale.
* Rescale within source × country × cohort so weights sum to N.
* This preserves relative within-cell weighting from each survey's design
* while removing cross-source scale differences. Where multiple sources cover
* the same cell, each contributes in proportion to its sample size.
* Step 1 — rescale within source × country × cohort so weights sum to N.
* This preserves the relative within-cell weighting from each survey's design
* while removing cross-source scale differences. A cell covered by both IPUMS
* (N=50,000) and ESS (N=500) will have each source contribute in proportion
* to its sample size, which is defensible since the larger source is also the
* more representative one.

bysort source country_iso cohort_group: egen _wsum = total(weight)
bysort source country_iso cohort_group: gen  no    = _N
replace weight = (weight / _wsum) * no
drop _wsum no

* summary
drop if missing(age_diff)
drop if age < 15
keep if birth_cohort > 1919 & birth_cohort < 1990

* -----------------------------------------------------------------------------
* Minimum cell size filter
* -----------------------------------------------------------------------------
* Drop country × cohort cells with fewer than 100 observations.
* Small cells yield unreliable statistics and can distort figures and models.

bysort country_name cohort_group: gen _n_cell = _N
di "[merge] Dropping " _N - (_N * (_n_cell >= 100)) " obs in country×cohort cells with < 100 cases."
count if _n_cell < 100
local n_dropped = r(N)
drop if _n_cell < 100
drop _n_cell
di "[merge] Dropped `n_dropped' observations from small cells."

di "=== Combined harmonized dataset ==="
di "Total records: " _N
tab source
su year age age_partner age_diff

compress

save "`dir'/harmonized.dta", replace
rcall: saveRDS(st.data(), "`dir'/harmonized.rds")

di "[merge] Done."