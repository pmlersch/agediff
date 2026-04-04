* get_ipums.do
* Harmonize IPUMS International census/register microdata.
* Input:  data/ipumsi_extract.csv
* Output: data/harmonized/ipums_harmonized.dta

do "code/check_harmonized.do"

local path_ipums "data/ipums/ipums.dta"
local path_out   "data/harmonized/ipums_harmonized.dta"

use "`path_ipums'", clear
rename *, lower

* age 
replace age = . if age > 120
replace age = year - birthyr if missing(age) & birthyr < 9999
replace age = . if age < 15 | age > 120

* partner age 
gen age_partner = age_sp if age_sp < 120
replace age_partner = year - birthyr_sp if missing(age_partner) & birthyr_sp < 9999
replace age_partner = . if age_partner < 15 | age_partner > 120

* sex
//nothing to do

* partner sex
gen sex_partner = sex_sp 

* birth cohort
gen birth_cohort = .
replace birthyr = . if birthyr >= 9999
replace birth_cohort = birthyr
replace birth_cohort = year - age if missing(birth_cohort)

* marital status
gen marital_status = ""

replace marital_status = "never_married" if marst == 1
replace marital_status = "married"       if marst == 2
replace marital_status = "separated"     if marst == 3
replace marital_status = "widowed"       if marst == 4

* country (ISO 3166-1 numeric → ISO2c)
* kountry requires a numeric variable; keep string copy only for manual overrides
tostring country, gen(_ctry_str) format(%03.0f) force
gen country_iso = ""

kountry country, from(iso3n) to(iso2c)
replace country_iso = _ISO2C_
drop _ISO2C_

* manual overrides for codes kountry does not resolve
replace country_iso = "PS" if _ctry_str == "275"
replace country_iso = "PR" if _ctry_str == "630"
replace country_iso = "SS" if _ctry_str == "728"
replace country_iso = "SD" if _ctry_str == "729"
replace country_iso = "LC" if _ctry_str == "662"
replace country_iso = "SL" if _ctry_str == "694"
replace country_iso = "SR" if _ctry_str == "740"
replace country_iso = "RU" if _ctry_str == "643"
drop _ctry_str

kountry country_iso, from(iso2c)
rename NAMES_STD country_name

* weight
gen weight = 1
replace weight = perwt

* source tag
gen source = "ipums"

* keep only harmonized columns and drop partner-less rows
keep year sex sex_partner birth_cohort marital_status age age_partner ///
     country_iso country_name weight source
drop if missing(age_partner)

di "[IPUMS] Harmonized " _N " records."
run_dq_checks "ipums"
di "[IPUMS] Saving to `path_out'"
save "`path_out'", replace
di "[IPUMS] Done."
