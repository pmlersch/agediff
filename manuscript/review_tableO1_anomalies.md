# Review of Table O1: Anomalies in Country-Specific Descriptive Statistics

## Overview

Table O1 reports mean, SD, min, and max values for respondent age, partner age,
spousal age difference, survey year, and birth cohort by country. The following
anomalies were identified by cross-referencing with Table 2 (country-level
summaries) and the data-processing pipeline (`merge_data.do`, `get_dhs.do`,
`descriptive.do`).

---

## 1. DHS Age Cap Truncates Respondent Age at 49

**Affected countries (max\_age = 49):**
Afghanistan, Angola, Burundi, Central African Republic, Chad, Comoros, Congo,
Democratic Republic of Congo, Eritrea, Gabon, Gambia, Madagascar, Niger,
Nigeria, Swaziland.

**Problem:** DHS surveys interview women aged 15--49 only. Countries sourced
exclusively from DHS therefore have `max_age = 49`, producing a truncated age
distribution. This biases `mean_age` downward and `sd_age` narrower relative to
countries where census or ESS/ISSP data contribute older respondents. The
partner age (`age_partner`) is not symmetrically capped, creating an artificial
asymmetry between the two age distributions within the same country.

**Explanation:** This is a survey design feature, not a data error. DHS targets
women of reproductive age; husband/partner age is reported without the same cap.

**Suggested fix:**
- Flag these countries in the table or a footnote as "DHS-only, respondent age
  capped at 15--49."
- Consider whether analyses that compare age distributions across countries
  should be restricted to a common age window (e.g., 15--49 for both partners)
  or whether DHS-only countries should be marked separately in figures.

---

## 2. Single Survey Year Countries (sd\_year = 0.00)

**Affected countries:**
Afghanistan (2015), Angola (2015), Central African Republic (1995),
Iraq (1997), Japan (2012), Kosovo (2013), South Korea (2012), South Sudan
(2008), Sudan (2008), Suriname (2012), Swaziland (2006), Taiwan (2012).

**Problem:** These countries have data from only one survey round
(`sd_year = 0.00`, `min_year = max_year`). This means:
- No temporal variation can be estimated.
- Birth cohort coverage is narrow (constrained by a single cross-section).
- Statistics are not robust to survey-specific idiosyncrasies.

**Explanation:** Limited data availability -- either only one DHS round or one
ISSP round covers the country.

**Suggested fix:**
- Flag single-survey countries in the table with an indicator column or
  footnote.
- Consider excluding them from analyses that depend on temporal trends or
  cohort comparisons, or at minimum note the limitation.

---

## 3. Very Small Sample Sizes

**Affected countries (N from Table 2):**

| Country                  |     N |
|--------------------------|------:|
| Japan                    |   652 |
| Kosovo                   |   695 |
| South Korea              |   697 |
| Albania                  |   714 |
| Macedonia                |   714 |
| Central African Republic |   859 |
| Australia                |   922 |
| Taiwan                   | 1,078 |
| Angola                   | 1,214 |
| Swaziland                | 1,558 |
| Luxembourg               | 1,694 |
| Montenegro               | 2,001 |
| Yugoslavia               | 2,251 |

**Problem:** Countries with N < ~1,000 yield unreliable estimates of means and
especially SDs. Extreme min/max values in these small samples are likely driven
by individual outliers. The 100-observation minimum cell filter in
`merge_data.do` (line 86) operates at the country x cohort level, but does not
enforce a minimum total country N.

**Suggested fix:**
- Add a minimum total country N threshold (e.g., N >= 5,000) for inclusion in
  the main analysis. Relegate small-N countries to an appendix or exclude them.
- At minimum, add an N column to Table O1 so readers can assess reliability.

---

## 4. Implausible Extreme Age Differences

**Examples of extreme max\_age\_diff (husband older):**

| Country    | max\_age\_diff |
|------------|---------------:|
| Bangladesh |             84 |
| Guinea     |             83 |
| Brazil     |             83 |
| Indonesia  |             83 |

**Examples of extreme min\_age\_diff (wife older):**

| Country  | min\_age\_diff |
|----------|---------------:|
| Mozambique |          -80 |
| Cambodia   |          -75 |
| Guinea     |          -74 |
| South Africa |        -74 |

**Problem:** An age difference of 80+ years is biologically near-impossible and
almost certainly reflects data entry errors, miscoded ages, or age heaping (e.g.,
reporting ages as 99). The top-coding at 99 in `merge_data.do` (line 32--33)
prevents values above 99 but does not catch implausible combinations where both
ages are technically valid individually.

**Suggested fix:**
- Apply a plausible age-difference filter, e.g., drop observations where
  `|age_diff| > 40` or `|age_diff| > 3 * sd_age_diff` within each country.
- Alternatively, winsorize at the 0.1st and 99.9th percentiles.
- At minimum, report trimmed means alongside raw means.

---

## 5. Obsolete or Inconsistent Country Names

**Affected entries:**
- **Yugoslavia** (mean\_age = 55.69): Yugoslavia dissolved in the 1990s. This
  likely refers to Serbia from recent ESS rounds (min\_year = 2018,
  max\_year = 2024). The country name should be updated to "Serbia" or the
  relevant successor state.
- **Swaziland**: Officially renamed to "eSwatini" in 2018.
- **Macedonia**: Officially "North Macedonia" since 2019.

**Suggested fix:**
- Recode country names in the harmonization scripts to use current official
  names. This likely requires updating the `kountry` lookup or adding manual
  overrides in the source-specific `get_*.do` scripts.

---

## 6. Unusually High Mean Respondent Ages

**Affected countries:**

| Country    | mean\_age | min\_birth\_cohort | Data source (likely) |
|------------|----------:|-------------------:|----------------------|
| Yugoslavia |     55.69 |               1940 | ESS                  |
| Bulgaria   |     54.04 |               1930 | ESS                  |
| Australia  |     53.45 |               1940 | ISSP                 |
| Japan      |     52.84 |               1940 | ISSP                 |
| Montenegro |     53.24 |               1940 | ESS                  |
| Sweden     |     52.69 |               1920 | ESS                  |
| Croatia    |     52.97 |               1930 | ESS                  |

**Problem:** Mean respondent ages above 50 indicate that the sample is heavily
skewed toward older cohorts. This occurs when:
- Only recent survey rounds are available (surveyed in 2012--2024), so only
  older birth cohorts (pre-1990) remain in the sample.
- No census data (IPUMS) is available for the country, which would provide
  younger cohort observations from earlier decades.

This is not an error per se, but it means these countries' statistics are not
comparable to countries like Brazil or India where census data spans decades.

**Suggested fix:**
- Add a `data_sources` column to Table O1 indicating which sources contribute
  (DHS, ESS, ISSP, IPUMS).
- Discuss the non-comparability of age distributions across countries in the
  manuscript text.

---

## 7. Narrow Birth Cohort Ranges

Several countries have `min_birth_cohort` much later than the global minimum of
1920, meaning older cohorts are entirely unrepresented:

| Country                  | min\_cohort | max\_cohort | Range |
|--------------------------|------------:|------------:|------:|
| Central African Republic |        1944 |        1979 |    35 |
| Chad                     |        1947 |        1989 |    42 |
| Niger                    |        1948 |        1989 |    41 |
| Nigeria                  |        1950 |        1989 |    39 |
| Gambia                   |        1963 |        1989 |    26 |
| Afghanistan              |        1966 |        1989 |    23 |
| Angola                   |        1966 |        1989 |    23 |

This overlaps heavily with the DHS age-cap issue (anomaly 1) and single-survey
issue (anomaly 2). Countries with only one recent DHS round mechanically cover
only recent birth cohorts (survey year minus 49 to survey year minus 15).

**Suggested fix:**
- Same as anomaly 1 and 2: flag and discuss. No data-side fix is possible
  without additional data sources.

---

## 8. Partner Age Extremes vs. Respondent Age Constraints

In DHS-only countries, `max_age` is capped at 49 while `max_age_partner`
reaches 95--97 (e.g., Afghanistan: max\_age=49, max\_age\_partner=95; Chad:
max\_age=49, max\_age\_partner=95). This creates a structural asymmetry: the
husband's age is unbounded while the wife's age is truncated.

This inflates `mean_age_diff` and `sd_age_diff` in DHS-only countries because
very old husbands are retained while only younger wives are sampled.

**Suggested fix:**
- Consider capping partner age at a symmetric bound (e.g., also drop
  `age_partner > 49` in DHS-only countries) for sensitivity analyses.
- At minimum, note this asymmetry in the manuscript.

---

## Summary of Recommended Actions

| Priority | Action | Scope |
|----------|--------|-------|
| High | Add footnote/flag for DHS-only countries (age cap 49) | Table O1 + manuscript |
| High | Filter implausible age differences (\|age\_diff\| > 40) | `merge_data.do` |
| High | Update obsolete country names (Yugoslavia, Swaziland, Macedonia) | `get_*.do` scripts |
| Medium | Add N column and data-source column to Table O1 | `descriptive.do` |
| Medium | Flag single-survey-year countries | Table O1 |
| Medium | Consider minimum total country N threshold | `merge_data.do` |
| Low | Discuss non-comparability of mean ages across data sources | Manuscript text |
| Low | Symmetric age cap sensitivity analysis for DHS countries | Supplementary analysis |
