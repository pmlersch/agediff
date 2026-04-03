* get_issp.do
* harmonize international social survey programme (issp) data.



do "code/check_harmonized.do"

local path_issp "data/issp/za5900_v4-0-0.dta"
local path_out  "data/harmonized/issp_harmonized.dta"

use "`path_issp'", clear
rename *, lower

* identify country variable
local country_var ""
foreach v in v4 {
    capture confirm variable `v'
    if !_rc & "`country_var'" == "" local country_var `v'
}
if "`country_var'" == "" {
    di "[issp] cannot find country variable."
    exit 1
}

* age
destring age, replace
replace age = . if inlist(age, 0, 998, 999) | age < 15

* sex
destring sex, replace

replace sex = . if inlist(sex, 0, 9)

* year
destring dateyr, replace
gen year = dateyr

replace year = . if year == 9999

* birth cohort
gen birth_cohort = year - age

* partner age
gen age_partner = .
local partner_age_var ""
foreach v in v66 {
    capture confirm variable `v'
    if !_rc & "`partner_age_var'" == "" local partner_age_var `v'
}
if "`partner_age_var'" != "" {
    destring `partner_age_var', replace
    replace age_partner = `partner_age_var'
    replace age_partner = . if inlist(age_partner, 0, 998 , 999) | age_partner < 15
    di "[issp] partner age variable: `partner_age_var'"
}

replace age_partner = . if age_partner > 120

else di "[issp] no partner age variable found — set to missing."

* partner sex
gen sex_partner = sex * -1 + 3 //sex of partner not surveyed, I assume opposite-sex partnerships

* marital status
destring marital, replace
gen marital_status = ""
replace marital_status = "married"          if marital == 1
replace marital_status = "never_married" if marital == 2 //civil partnership as never married
replace marital_status = "separated"        if marital == 3
replace marital_status = "divorced"         if marital == 4
replace marital_status = "widowed"          if marital == 5
replace marital_status = "never_married"    if marital == 6

* country: ISSP v4 uses ISO 3166-1 numeric codes (same as UN numeric)
gen country_iso = ""
capture {
    kountry `country_var', from(iso3n) to(iso2c)
    replace country_iso = _ISO2C_
    drop _ISO2C_
}

capture {
    kountry country_iso, from(iso2c)
    rename NAMES_STD country_name
}
if _rc gen country_name = country_iso

* weight
destring weight, replace

* source tag
gen source = "issp"

* keep only harmonized columns and drop partner-less rows
keep year sex sex_partner birth_cohort marital_status age age_partner ///
     country_iso country_name weight source
drop if missing(age_partner)

di "[issp] harmonized " _n " records."
run_dq_checks "issp"
di "[issp] saving to `path_out'"
save "`path_out'", replace
di "[issp] done."
