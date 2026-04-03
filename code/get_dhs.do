* get_dhs.do
* Harmonize Demographic and Health Surveys (DHS) data.
* Input:  data/dhs_extract.csv
* Output: data/harmonized/dhs_harmonized.dta
*
* Women's recode (IR): V-prefix variables.
* Men's recode (MR):  MV-prefix variables.

do "code/check_harmonized.do"

local path_dhs "data/dhs/idhs2.dta"
local path_out "data/harmonized/dhs_harmonized.dta"

use "`path_dhs'", clear

* age
replace age = year - birthyear if missing(age)
replace age = . if age >= 99 | age < 15

* sex (constant by recode type)
gen sex = 2

* partner sex (opposite sex; set to missing for non-partnered below)
gen sex_partner = 1

* birth cohort
gen birth_cohort = birthyear
replace birth_cohort = year - age if missing(birth_cohort)

* marital status
destring marstat, replace
gen marital_status = ""
replace marital_status = "never_married" if marstat == 10 
replace marital_status = "married"       if marstat == 11 | marstat == 20 | marstat == 21
replace marital_status = "widowed"       if marstat == 31
replace marital_status = "divorced"      if marstat == 32
replace marital_status = "separated"     if marstat == 33

* not in union → partner sex not applicable
replace sex_partner = . if !inlist(marstat, 11, 20, 21)

* partner age
gen age_partner = husage
replace age_partner = . if age_partner >= 98 | age_partner < 15

* country: IPUMS DHS 'country' variable uses ISO 3166-1 numeric codes
gen country_iso = ""
capture {
    kountry country, from(iso3n) to(iso2c)
    replace country_iso = _ISO2C_
    drop _ISO2C_
}

capture {
    kountry country_iso, from(iso2c)
    rename NAMES_STD country_name
}
if _rc gen country_name = country_iso


* weight
gen weight = 1
local wt_col perweightmn
capture confirm variable `wt_col'
if !_rc {
    destring `wt_col', replace
    replace weight = `wt_col' / 1000000
}

* source tag
gen source = "dhs"

keep year sex sex_partner birth_cohort marital_status age age_partner ///
     country_iso country_name weight source
drop if missing(age_partner)

di "[DHS] Harmonized " _N " records."
run_dq_checks "dhs"
di "[DHS] Saving to `path_out'"
save "`path_out'", replace
di "[DHS] Done."
