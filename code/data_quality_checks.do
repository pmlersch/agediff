* data_quality_checks.do
* Sanity checks on simulated_demographic_data.csv.

local data_path "data/simulated_demographic_data.csv"
import delimited "`data_path'", clear varnames(1)

local issues 0

* 1. Dimensions
di "Rows: " _N "  Columns: " c(k)

* 2. Missing values
foreach v in country_code country year age age_sp sex gender marital_status birth_cohort {
    capture confirm variable `v'
    if !_rc {
        count if missing(`v')
        local n = r(N)
        if `n' > 0 {
            di "*** ISSUE: `v' has `n' missing values"
            local ++issues
        }
    }
    else di "*** ISSUE: missing column `v'"
}

* 3. Duplicate rows
duplicates report
* (duplicates report prints its own summary)

* 4. Age variables
foreach v in age age_sp {
    capture confirm variable `v'
    if !_rc {
        destring `v', replace
        su `v', meanonly
        di "`v' range: [" r(min) ", " r(max) "]"
        if r(min) < 15 {
            di "*** ISSUE: `v' below 15"
            local ++issues
        }
        if r(max) > 100 {
            di "*** ISSUE: `v' above 100"
            local ++issues
        }
        count if `v' == 999
        if r(N) > 0 {
            di "*** ISSUE: sentinel 999 in `v' (" r(N) " rows)"
            local ++issues
        }
        count if `v' < 0
        if r(N) > 0 {
            di "*** ISSUE: negative `v' (" r(N) " rows)"
            local ++issues
        }
    }
}

* extreme age differences (|age_diff| > 30)
capture confirm variable age age_sp sex
if !_rc {
    gen age_diff = cond(sex == 1, age - age_sp, age_sp - age)
    count if abs(age_diff) > 30
    di "Couples with |age_diff| > 30 years: " r(N)
}

* 5. Sex coding
capture confirm variable sex
if !_rc {
    count if !missing(sex) & !inlist(sex, 1, 2)
    if r(N) > 0 {
        di "*** ISSUE: unexpected sex values (" r(N) " rows)"
        local ++issues
    }
}

* 6. Birth cohort consistency
capture confirm variable birth_cohort year age
if !_rc {
    destring birth_cohort year age, replace
    count if birth_cohort != year - age & !missing(birth_cohort)
    if r(N) > 0 {
        di "*** ISSUE: birth_cohort != year - age for " r(N) " rows"
        local ++issues
    }
}

* 7. Survey year range
capture confirm variable year
if !_rc {
    count if (year < 1900 | year > 2030) & !missing(year)
    if r(N) > 0 {
        di "*** ISSUE: implausible year values"
        local ++issues
    }
    levelsof year, local(yr_vals)
    di "Unique years: `yr_vals'"
}

* 8. Country coverage
capture confirm variable country
if !_rc {
    levelsof country, local(n_ctry)
    di "Unique countries: `: word count `n_ctry''"
}

* 9. Marital status
capture confirm variable marital_status
if !_rc {
    levelsof marital_status, local(ms_levels) clean
    foreach lv of local ms_levels {
        if !inlist("`lv'", "married_spouse_present", "married_spouse_absent", ///
                   "separated", "divorced", "widowed", "") {
            di "*** ISSUE: unexpected marital_status: `lv'"
            local ++issues
        }
    }
    tab marital_status
}

* Summary
di "============================================================="
if `issues' == 0 di "RESULT: All checks passed."
else di "RESULT: `issues' issue(s) flagged."
di "============================================================="
