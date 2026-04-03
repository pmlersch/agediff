"""
Generate a simulated demographic dataset for the agediff project.

Produces a CSV with 400,000 records (1,000 respondents × 10 waves × 40 countries)
containing: respondent age, partner age, gender, marital status, birth cohort,
country, and survey year.
"""

import csv
import random
import sys

random.seed(42)

# 40 countries with IPUMS numeric codes and parameters:
# (code, name, mean_age_diff, sd_age_diff, mean_marriage_age_women)
# mean_age_diff = husband_age - wife_age (positive = husband older)
# Values inspired by cross-national demographic research patterns
COUNTRIES = [
    (32,  "Argentina",       2.8, 4.0, 25),
    (40,  "Austria",         2.5, 3.5, 28),
    (50,  "Bangladesh",      5.5, 4.5, 18),
    (76,  "Brazil",          3.0, 4.2, 24),
    (120, "Cameroon",        6.0, 5.0, 19),
    (124, "Canada",          2.3, 3.4, 27),
    (152, "Chile",           2.7, 3.8, 25),
    (156, "China",           2.5, 3.0, 24),
    (170, "Colombia",        3.2, 4.5, 23),
    (208, "Denmark",         2.0, 3.2, 29),
    (818, "Egypt",           4.8, 4.0, 21),
    (231, "Ethiopia",        6.5, 5.5, 17),
    (246, "Finland",         2.1, 3.3, 29),
    (250, "France",          2.3, 3.5, 28),
    (276, "Germany",         2.5, 3.4, 28),
    (288, "Ghana",           5.5, 5.0, 20),
    (300, "Greece",          3.5, 3.8, 26),
    (356, "India",           4.5, 4.0, 20),
    (360, "Indonesia",       3.8, 3.5, 22),
    (364, "Iran",            4.0, 4.2, 22),
    (380, "Italy",           3.0, 3.6, 27),
    (392, "Japan",           2.2, 2.8, 28),
    (404, "Kenya",           5.0, 5.2, 20),
    (466, "Mali",            7.0, 6.0, 16),
    (484, "Mexico",          3.0, 4.0, 23),
    (504, "Morocco",         4.5, 4.5, 22),
    (528, "Netherlands",     2.2, 3.3, 29),
    (566, "Nigeria",         6.0, 5.5, 19),
    (578, "Norway",          2.1, 3.2, 29),
    (586, "Pakistan",        5.0, 4.5, 20),
    (604, "Peru",            3.0, 4.0, 23),
    (608, "Philippines",     3.5, 4.0, 24),
    (616, "Poland",          2.8, 3.5, 25),
    (643, "Russia",          2.5, 3.8, 24),
    (710, "South Africa",    3.5, 4.5, 25),
    (724, "Spain",           2.8, 3.5, 28),
    (752, "Sweden",          2.0, 3.2, 30),
    (792, "Turkey",          3.8, 3.8, 22),
    (826, "United Kingdom",  2.3, 3.4, 28),
    (840, "United States",   2.3, 3.5, 27),
]

# 10 survey waves
WAVE_YEARS = list(range(2005, 2015))

# Marital status categories
MARITAL_STATUSES = [
    "married_spouse_present",
    "married_spouse_absent",
    "separated",
    "divorced",
    "widowed",
]
# Weights: most respondents are married/spouse present since we model partnered individuals
MARITAL_WEIGHTS = [0.75, 0.08, 0.05, 0.08, 0.04]

GENDERS = ["male", "female"]

N_PER_WAVE_COUNTRY = 1000


def clamp(value, lo, hi):
    return max(lo, min(hi, value))


def gauss(mu, sigma):
    return random.gauss(mu, sigma)


def generate_records():
    """Yield one record dict at a time."""
    for country_code, country_name, base_age_diff, base_sd, base_marriage_age_w in COUNTRIES:
        for wave_year in WAVE_YEARS:
            # Cohort trend: age diff decreases ~0.08 yr per calendar year from 2005 baseline
            cohort_shift = (wave_year - 2005) * (-0.08)
            # Marriage age for women increases slightly over time
            marriage_age_shift = (wave_year - 2005) * 0.15

            mean_diff = base_age_diff + cohort_shift
            sd_diff = base_sd
            mean_marriage_age_w_adj = base_marriage_age_w + marriage_age_shift

            for _ in range(N_PER_WAVE_COUNTRY):
                gender = random.choice(GENDERS)
                marital_status = random.choices(MARITAL_STATUSES, weights=MARITAL_WEIGHTS, k=1)[0]

                # Generate wife's age at survey ~ marriage age + years since marriage
                years_married = max(0, gauss(10, 7))
                wife_age_at_marriage = max(15, gauss(mean_marriage_age_w_adj, 4))
                wife_age = clamp(round(wife_age_at_marriage + years_married), 15, 95)

                # Age difference (husband - wife)
                age_diff = gauss(mean_diff, sd_diff)
                husband_age = clamp(round(wife_age + age_diff), 15, 99)

                # Assign respondent vs partner based on gender
                if gender == "male":
                    age = husband_age
                    age_sp = wife_age
                else:
                    age = wife_age
                    age_sp = husband_age

                birth_cohort = wave_year - age

                yield {
                    "country_code": country_code,
                    "country": country_name,
                    "year": wave_year,
                    "age": age,
                    "age_sp": age_sp,
                    "sex": 1 if gender == "male" else 2,
                    "gender": gender,
                    "marital_status": marital_status,
                    "birth_cohort": birth_cohort,
                }


def main():
    outpath = "data/simulated_demographic_data.csv"
    fieldnames = [
        "country_code", "country", "year", "age", "age_sp",
        "sex", "gender", "marital_status", "birth_cohort",
    ]
    n = 0
    with open(outpath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for rec in generate_records():
            writer.writerow(rec)
            n += 1
    print(f"Wrote {n:,} records to {outpath}")


if __name__ == "__main__":
    main()
