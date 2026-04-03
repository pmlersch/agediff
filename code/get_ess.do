* get_ess.do
* Harmonize European Social Survey (ESS) data.
* Input:  data/ess/ess.dta
* Output: data/harmonized/ess_harmonized.dta

do "code/check_harmonized.do"

local path_ess "data/ess/ess.dta"
local path_out "data/harmonized/ess_harmonized.dta"

use "`path_ess'", clear
rename *, lower

* age
replace agea = . if agea >= 999 | agea < 15
replace age = agea if missing(age)
replace age = round(age)

* sex
gen sex = .
replace sex = 1 if gndr == 1
replace sex = 2 if gndr == 2

* year (inwds/questcmp/scwsds datetime fields → inwyys/inwyr integer fields → essround)
gen year = .
foreach v in inwds questcmp scwsds {
    capture confirm variable `v'
    if !_rc {
        replace year = year(dofc(`v')) if year == .
    }
}

foreach v in inwyys inwyr {
    capture confirm variable `v'
    if !_rc {
        replace `v' = . if `v' >= 7777
        replace year = `v' if year == .
    }
}

capture confirm variable essround
if !_rc {
    gen _rnd_yr = .
    replace _rnd_yr = 2002 if essround == 1
    replace _rnd_yr = 2004 if essround == 2
    replace _rnd_yr = 2006 if essround == 3
    replace _rnd_yr = 2008 if essround == 4
    replace _rnd_yr = 2010 if essround == 5
    replace _rnd_yr = 2012 if essround == 6
    replace _rnd_yr = 2014 if essround == 7
    replace _rnd_yr = 2016 if essround == 8
    replace _rnd_yr = 2018 if essround == 9
    replace _rnd_yr = 2020 if essround == 10
    replace _rnd_yr = 2022 if essround == 11
    replace year = _rnd_yr if missing(year) & !missing(essround)
    drop _rnd_yr
}

* birth cohort
replace yrbrn = . if yrbrn >= 7777
gen birth_cohort = yrbrn
replace birth_cohort = year - age if missing(birth_cohort) & !missing(age) & !missing(year)

* marital status

gen marital_status = ""

replace marital_status = "married"          if marital == 1
replace marital_status = "separated"        if marital == 2
replace marital_status = "divorced"         if marital == 3
replace marital_status = "widowed"          if marital == 4
replace marital_status = "never_married"    if marital == 5

replace marital_status = "married"          if (marital_status == "" | missing(marital_status)) & maritalb == 1
replace marital_status = "civil_partnership" if (marital_status == "" | missing(marital_status)) & maritalb == 2
replace marital_status = "separated"        if (marital_status == "" | missing(marital_status)) & maritalb == 3
replace marital_status = "divorced"         if (marital_status == "" | missing(marital_status)) & maritalb == 4
replace marital_status = "widowed"          if (marital_status == "" | missing(marital_status)) & maritalb == 5
replace marital_status = "never_married"    if (marital_status == "" | missing(marital_status)) & maritalb == 6

replace marital_status = "married"       if (marital_status == "" | missing(marital_status)) & maritala == 1
replace marital_status = "separated"     if (marital_status == "" | missing(marital_status)) & maritala == 3
replace marital_status = "divorced"      if (marital_status == "" | missing(marital_status)) & maritala == 5
replace marital_status = "widowed"       if (marital_status == "" | missing(marital_status)) & maritala == 6
replace marital_status = "never_married" if (marital_status == "" | missing(marital_status)) & maritala == 9

* partner age and sex from household grid
gen age_partner = .
gen sex_partner = .
gen _partner_yob = .

foreach rshp_prefix in rship rshipa {
    forvalues i = 2/6 {
        local rv `rshp_prefix'`i'
        local yv yrbrn`i'
        local gv gndr`i'
        replace _partner_yob = `yv' if missing(_partner_yob) & ///
            !missing(`rv') & `rv' == 1 & !missing(`yv') & `yv' < 7777
         replace sex_partner = `gv' if missing(sex_partner) & ///
                !missing(`rv') & `rv' == 1 & inlist(`gv', 1, 2)
        }
    }

replace age_partner = year - _partner_yob
replace age_partner = . if age_partner < 15 | age_partner > 110

drop _partner_yob

* country
gen country_iso = upper(trim(cntry))
capture {
    kountry country_iso, from(iso2c)
    rename NAMES_STD country_name
}
if _rc gen country_name = country_iso

replace country_name = "Kosovo" if country_iso == "XK"

* weight
gen weight = .
capture confirm variable dweight
capture confirm variable pspwght
if !_rc replace weight = dweight * pspwght
else {
    capture confirm variable dweight
    if !_rc replace weight = dweight
    else replace weight = 1
}

* source tag
gen source = "ess"

* keep only harmonized columns and drop partner-less rows
keep year sex sex_partner birth_cohort marital_status age age_partner ///
     country_iso country_name weight source
drop if missing(age_partner)

di "[ESS] Harmonized " _N " records."
run_dq_checks "ess"
di "[ESS] Saving to `path_out'"
save "`path_out'", replace
di "[ESS] Done."
