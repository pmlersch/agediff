* check_harmonized.do
* Defines run_dq_checks: validates a harmonized dataset in memory.
* Usage: run_dq_checks "ess"   (call after loading the harmonized dataset)

capture program drop run_dq_checks
program define run_dq_checks
    args src
    local pfx "[`=upper("`src'")'] DQ"
    local issues 0

    * 1. Required columns
    foreach v in year sex sex_partner birth_cohort marital_status age ///
                 age_partner country_iso country_name weight source {
        capture confirm variable `v'
        if _rc {
            di "`pfx' *** ISSUE: missing column: `v'"
            local ++issues
        }
    }

    * 2. Missing values in key columns
    foreach v in year sex age country_iso birth_cohort marital_status {
        capture confirm variable `v'
        if !_rc {
            count if missing(`v')
            local n = r(N)
            if `n' > 0 {
                di "`pfx' *** ISSUE: `v' has `n' NAs"
                local ++issues
            }
        }
    }

    * 3. Age range
    foreach v in age age_partner {
        capture confirm variable `v'
        if !_rc {
            su `v', meanonly
            if r(min) < 15 {
                di "`pfx' *** ISSUE: `v' below 15 (min = `=r(min)')"
                local ++issues
            }
            if r(max) > 100 {
                di "`pfx' *** ISSUE: `v' above 100 (max = `=r(max)')"
                local ++issues
            }
        }
    }

    * 4. Sentinel value 999
    foreach v in age age_partner {
        capture confirm variable `v'
        if !_rc {
            count if `v' == 999
            local n = r(N)
            if `n' > 0 {
                di "`pfx' *** ISSUE: sentinel 999 in `v' (`n' rows)"
                local ++issues
            }
        }
    }

    * 5. Negative ages
    foreach v in age age_partner {
        capture confirm variable `v'
        if !_rc {
            count if `v' < 0 & !missing(`v')
            local n = r(N)
            if `n' > 0 {
                di "`pfx' *** ISSUE: negative `v' (`n' rows)"
                local ++issues
            }
        }
    }

    * 6. Sex coding
    capture confirm variable sex
    if !_rc {
        count if !missing(sex) & sex != 1 & sex != 2
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: unexpected sex values (`n' rows)"
            local ++issues
        }
    }

    * 7. Birth-cohort consistency
    capture confirm variable birth_cohort
    if !_rc {
        count if abs(birth_cohort - (year - age)) > 1 & ///
                 !missing(birth_cohort) & !missing(year) & !missing(age)
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: birth_cohort != year - age for `n' rows"
            local ++issues
        }
    }

    * 8. Plausible survey year
    capture confirm variable year
    if !_rc {
        count if (year < 1900 | year > 2030) & !missing(year)
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: implausible year values"
            local ++issues
        }
    }

    * 9. Missing country ISO
    capture confirm variable country_iso
    if !_rc {
        count if missing(country_iso)
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: `n' rows have missing country_iso"
            local ++issues
        }
    }

    * 10. Unexpected marital status
    capture confirm variable marital_status
    if !_rc {
        levelsof marital_status, local(ms_levels) clean
        foreach lv of local ms_levels {
            if !inlist("`lv'", "married", "civil_partnership", "separated", ///
                       "divorced", "widowed", "never_married", "") {
                di "`pfx' *** ISSUE: unexpected marital_status: `lv'"
                local ++issues
            }
        }
    }

    * 11. Weight validity
    capture confirm variable weight
    if !_rc {
        count if weight < 0 & !missing(weight)
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: `n' rows with negative weight"
            local ++issues
        }
        count if missing(weight)
        local n = r(N)
        if `n' > 0 {
            di "`pfx' *** ISSUE: `n' rows with missing weight"
            local ++issues
        }
    }

    if `issues' == 0 di "`pfx' All checks passed."
    else di "`pfx' `issues' issue(s) flagged."
end
