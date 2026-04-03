# =============================================================================
# IPUMS International Data Pull
# Age, Partner's Age, Marital Status, Birth Cohort, Gender
# Countries: USA, Germany, Turkey
# =============================================================================

library(ipumsr)
library(dplyr)
library(tidyr)
library(readr)

# -----------------------------------------------------------------------------
# 1. API Key Setup
# -----------------------------------------------------------------------------
# You need an IPUMS account and API key from https://account.ipums.org/api_keys
# Run once to save your key:
#   set_ipums_api_key("YOUR_API_KEY_HERE", save = TRUE)
#
# This stores the key in your .Renviron as IPUMS_API_KEY so it persists
# across sessions.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 2. Discover Available Samples
# -----------------------------------------------------------------------------
# Query the IPUMS International catalog for all available samples, then
# filter to the three countries of interest.

cat("Fetching available IPUMS International samples...\n")
all_samples <- get_sample_info("ipumsi")

# Filter to USA, Germany, Turkey using the two-letter prefix in sample names
usa_samples <- all_samples %>% filter(grepl("^us", name))
deu_samples <- all_samples %>% filter(grepl("^de", name))
tur_samples <- all_samples %>% filter(grepl("^tr", name))

cat("\n--- Available USA samples ---\n")
print(usa_samples, n = Inf)
cat("\n--- Available Germany samples ---\n")
print(deu_samples, n = Inf)
cat("\n--- Available Turkey samples ---\n")
print(tur_samples, n = Inf)

# Combine all sample names into a single vector
selected_samples <- c(usa_samples$name, deu_samples$name, tur_samples$name)

cat("\nTotal samples selected:", length(selected_samples), "\n")
cat(selected_samples, sep = ", ")
cat("\n")

# -----------------------------------------------------------------------------
# 3. Define the Extract
# -----------------------------------------------------------------------------
# Variables requested:
#   AGE      - Respondent's age
#   SEX      - Sex / gender
#   MARST    - Marital status (harmonized)
#   BIRTHYR  - Year of birth (to construct birth cohort)
#   SPLOC    - Spouse's person number within household (for linking)
#   RELATE   - Relationship to household head (aids spouse linking)
#   PERNUM   - Person number within household (needed for SPLOC merge)
#   YEAR     - Census / survey year
#   COUNTRY  - Country code
#   SERIAL   - Household serial number (needed for within-household merge)
#   PERWT    - Person-level sampling weight

extract_def <- define_extract_micro(
  collection = "ipumsi",
  description = "Age differences project: USA, Germany, Turkey — all available periods",
  samples = selected_samples,
  variables = c(
    "YEAR",
    "COUNTRY",
    "SERIAL",
    "PERNUM",
    "PERWT",
    "AGE",
    "SEX",
    "MARST",
    "BIRTHYR",
    "SPLOC",
    "RELATE"
  ),
  data_format = "csv"
)

# -----------------------------------------------------------------------------
# 4. Submit, Wait, Download
# -----------------------------------------------------------------------------
cat("\nSubmitting extract request to IPUMS...\n")
submitted_extract <- submit_extract(extract_def)

cat("Extract submitted. Waiting for IPUMS to process...\n")
cat("(This can take minutes to hours depending on server load.)\n")
downloadable_extract <- wait_for_extract(submitted_extract)

cat("Extract ready. Downloading...\n")
data_files <- download_extract(downloadable_extract, download_dir = "data")

cat("Download complete. Reading data...\n")
raw_data <- read_ipums_micro(data_files)

# -----------------------------------------------------------------------------
# 5. Process Data: Link Spouse's Age and Construct Variables
# -----------------------------------------------------------------------------
cat("Processing data...\n")

# Create a lookup table of age by household + person number
spouse_ages <- raw_data %>%
  select(SERIAL, PERNUM, YEAR, COUNTRY, spouse_age = AGE)

# Merge spouse's age onto each respondent via SPLOC
data <- raw_data %>%
  left_join(
    spouse_ages,
    by = c("SERIAL" = "SERIAL",
           "SPLOC"  = "PERNUM",
           "YEAR"   = "YEAR",
           "COUNTRY" = "COUNTRY")
  )

# Construct birth cohort (10-year groups)
data <- data %>%
  mutate(
    birth_year = ifelse(BIRTHYR %in% c(0, 9999), YEAR - AGE, BIRTHYR),
    birth_cohort = cut(
      birth_year,
      breaks = seq(1850, 2020, by = 10),
      right = FALSE,
      labels = paste0(seq(1850, 2010, by = 10), "-",
                       seq(1859, 2019, by = 10))
    )
  )

# Recode country for readability
data <- data %>%
  mutate(
    country_name = case_when(
      COUNTRY == 840 ~ "USA",
      COUNTRY == 276 ~ "Germany",
      COUNTRY == 792 ~ "Turkey",
      TRUE           ~ as.character(COUNTRY)
    )
  )

# Recode sex for readability
data <- data %>%
  mutate(
    gender = case_when(
      SEX == 1 ~ "Male",
      SEX == 2 ~ "Female",
      TRUE     ~ NA_character_
    )
  )

# Recode marital status for readability
data <- data %>%
  mutate(
    marital_status = case_when(
      MARST == 1 ~ "Married, spouse present",
      MARST == 2 ~ "Married, spouse absent",
      MARST == 3 ~ "Separated/divorced",
      MARST == 4 ~ "Widowed",
      MARST == 0 ~ "Single/never married",
      TRUE       ~ "Unknown"
    )
  )

# Select and rename final analysis variables
data_clean <- data %>%
  select(
    year         = YEAR,
    country_code = COUNTRY,
    country_name,
    serial       = SERIAL,
    pernum       = PERNUM,
    perwt        = PERWT,
    age          = AGE,
    spouse_age,
    gender,
    marital_status,
    birth_year,
    birth_cohort,
    sploc        = SPLOC,
    relate       = RELATE
  )

# -----------------------------------------------------------------------------
# 6. Summary
# -----------------------------------------------------------------------------
cat("\n=== DATA SUMMARY ===\n")
cat("Total observations:", nrow(data_clean), "\n\n")

cat("Observations by country and year:\n")
data_clean %>%
  count(country_name, year) %>%
  print(n = Inf)

cat("\nObservations with linked spouse age:\n")
data_clean %>%
  filter(!is.na(spouse_age)) %>%
  count(country_name, year) %>%
  print(n = Inf)

cat("\nGender distribution:\n")
data_clean %>%
  count(country_name, gender) %>%
  print(n = Inf)

cat("\nMarital status distribution:\n")
data_clean %>%
  count(country_name, marital_status) %>%
  print(n = Inf)

# -----------------------------------------------------------------------------
# 7. Save Cleaned Data
# -----------------------------------------------------------------------------
output_path <- "data/ipums_agediff_data.csv"
write_csv(data_clean, output_path)
cat("\nCleaned data saved to:", output_path, "\n")

cat("\nDone.\n")

# Run data quality checks
source("code/data_quality_checks.R")
