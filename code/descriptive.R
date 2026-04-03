###############################################################################
## agediff_descriptive.R
## Descriptive analysis of within-couple age gaps across countries and birth
## cohorts using the harmonized multi-source dataset produced by merge_data.R.
##
## Structure:
##   1. Setup & data loading
##   2. Variable construction
##   3. Descriptive figures — ridgeline plots (Figures 3 and 3b)
##   4. Figure 4b: Variance decomposition over cohorts
##   5. Figure 5: Heatmap of SD by country × cohort
##
## Tables 1–5 and Figures 1, 2, 3c, 4, 6 are produced by the Stata
## script code/descriptive.do, which can do these equally well.
## Ridgeline figures (3, 3b) and Figures 4b and 5 are produced here.
##
## Input  : data/harmonized/harmonized.rds  (from merge_data.R)
##
## Packages used:
##   data.table — fast data manipulation
##   ggplot2    — all plotting (grammar of graphics)
##   ggridges   — ridgeline density plots
##   forcats    — reorder factor levels
###############################################################################


# =============================================================================
# 1. SETUP & DATA LOADING
# =============================================================================

# Load all required libraries --------------------------------------------------
# Each library() call makes one package's functions available in this session.

library(data.table)   # provides fast data manipulation and := syntax
library(ggplot2)      # provides ggplot(), geom_*, labs(), theme(), ggsave()
library(ggridges)     # provides geom_density_ridges_gradient()
library(forcats)      # provides fct_reorder() to sort factor levels by a value
library(patchwork)    # provides | and / operators to combine ggplot panels
library(devEMF)       # provides EMF (Enhanced Metafile) export device for Windows

# Set a consistent, clean visual theme for all plots --------------------------
# theme_set() applies this theme globally so every plot inherits it.
# Mirrors the Stata scheme-agediff.scheme: white background, horizontal-only
# grid lines in light grey, thin axis lines and ticks, no outer border.
theme_set(
  theme_minimal(base_size = 12) +             # minimal theme with 12-point base font
    theme(
      plot.title          = element_text(face = "bold"),  # make plot titles bold
      plot.subtitle       = element_text(color = "grey40"), # subtle subtitle color
      panel.grid.minor    = element_blank(),              # remove minor grid lines
      panel.grid.major.x  = element_blank(),              # remove vertical grid lines (Stata: draw_major_vgrid no)
      panel.grid.major.y  = element_line(color = "grey86", linewidth = 0.3), # light grey horizontal grid (Stata: "220 220 220", vthin)
      axis.line           = element_line(color = "grey30", linewidth = 0.3), # thin axis lines (Stata: linewidth axisline thin)
      axis.ticks          = element_line(color = "grey30", linewidth = 0.3), # thin tick marks (Stata: linewidth tick thin)
      axis.ticks.length   = unit(3, "pt")                 # short ticks
    )
)

# Read the harmonized dataset produced by merge_data.R -------------------------
path_harmonized <- file.path("data", "harmonized", "harmonized.rds")
df <- as.data.table(readRDS(path_harmonized))

# Create a 'country' column as a convenience alias for country_name so that
# all downstream analysis code can reference 'country' uniformly.
df[, country := country_name]

# Print the first six rows to verify the data loaded correctly
cat("Preview of the data:\n")
print(head(df))

# Print the dimensions
cat("\nDataset dimensions:", nrow(df), "rows ×", ncol(df), "columns\n")
cat("Sources:", paste(sort(unique(df$source)), collapse = ", "), "\n")


# =============================================================================
# 3. DESCRIPTIVE FIGURES — RIDGELINE PLOTS
#
# Ridgeline density plots (Figures 3 and 3b) are produced here because they
# rely on the ggridges package which has no equivalent in Stata.
# Tables 1–5 and Figures 1, 2, 3c, 4, 6 are produced by the Stata
# script code/descriptive.do.
# =============================================================================

# ---- Figure 3: Ridgeline density plot by country ----------------------------
# Ridgeline plots stack density curves vertically, one per country.
# They show the full shape of each country's age-gap distribution simultaneously,
# making it easy to compare across countries.

# For each country, compute the approximate mode (peak of the density) so we
# can sort countries by this value rather than the mean.
mode_by_country <- df[, .(
  mode_approx = density(age_diff)$x[which.max(density(age_diff)$y)]
), by = country]

# Sort country factor by mode for a more readable ridgeline layout
df <- df[mode_by_country, on = "country"]          # join mode into main data
df[, country_ord := fct_reorder(country, mode_approx)]  # create ordered factor

fig3 <- ggplot(df, aes(
  x    = age_diff,                                  # age gap on x-axis
  y    = country_ord,                               # one ridgeline per country
  fill = after_stat(x)                              # gradient fill along x
)) +
  geom_density_ridges_gradient(
    scale = 3,                                      # overlap between ridges
    rel_min_height = 0.01,                          # cut off very low tails
    gradient_lwd   = 0.3                            # thin border on ridges
  ) +
  scale_fill_viridis_c(                             # colorblind-friendly gradient
    option = "C",
    guide  = "none"                                 # suppress color bar legend
  ) +
  coord_cartesian(xlim = c(-10, 20)) +              # zoom to the informative range
  labs(
    x     = "Age difference (husband \u2212 wife, years)",
    y     = NULL,
    title = "Figure 3: Age-gap distributions by country"
  )

ggsave("results/fig3_ridgeline.pdf", fig3, width = 8, height = 12)
ggsave("results/fig3_ridgeline.emf", fig3, width = 8, height = 12, device = devEMF::emf)
cat("Saved: results/fig3_ridgeline\n")

# ---- Figure 3b: Ridgeline density by BIRTH COHORT ---------------------------
# This figure asks: how has the shape of the age-gap distribution changed
# across generations? Each ridge represents one 10-year cohort.

fig3b <- ggplot(df, aes(
  x    = age_diff,
  y    = cohort_group,                              # one ridge per birth cohort
  fill = after_stat(x)
)) +
  geom_density_ridges_gradient(
    scale = 2, rel_min_height = 0.01, gradient_lwd = 0.3
  ) +
  scale_fill_viridis_c(option = "C", guide = "none") +
  coord_cartesian(xlim = c(-10, 20)) +
  labs(
    x     = "Age difference (husband \u2212 wife, years)",
    y     = "Birth cohort",
    title = "Figure 3b: Age-gap distributions by birth cohort"
  )

ggsave("results/fig3b_ridgeline_cohort.pdf", fig3b, width = 8, height = 8)
ggsave("results/fig3b_ridgeline_cohort.emf", fig3b, width = 8, height = 8, device = devEMF::emf)
cat("Saved: results/fig3b_ridgeline_cohort\n")


# =============================================================================
# 4. FIGURE 4b: VARIANCE DECOMPOSITION OVER COHORTS
#
# Decomposes total variance of age_diff into:
#   Between-country variance = var(country means)        per cohort
#   Within-country variance  = wtd. mean of country var  per cohort
#   ICC = between / (between + within)
# =============================================================================

# Step 1: country × cohort means and SDs (min 30 obs per cell)
cc_stats <- df[, {
  n_cell <- .N
  if (n_cell >= 100) .(
    country_mean  = mean(age_diff),
    country_sd    = sd(age_diff),
    n_cell        = n_cell
  ) else NULL
}, by = .(country_id, cohort_start, cohort_group)]

# Contribution to within-country variance (weighted by df = n-1)
cc_stats[, within_contrib := country_sd^2 * (n_cell - 1L)]

# Step 2: cohort-level variance components
coh_var <- cc_stats[, .(
  between_var = var(country_mean),
  sum_within  = sum(within_contrib),
  sum_n       = sum(n_cell),
  n_ctries    = .N
), by = .(cohort_start, cohort_group)]

coh_var[, within_var   := sum_within / (sum_n - n_ctries)]
coh_var[, total_var    := between_var + within_var]
coh_var[, icc          := between_var / total_var]
coh_var[, between_sd_p := sqrt(between_var)]
coh_var[, within_sd_p  := sqrt(within_var)]

# Panel A: stacked bar — between and within variance
coh_long <- melt(
  coh_var,
  id.vars      = c("cohort_start", "cohort_group"),
  measure.vars = c("within_var", "between_var"),
  variable.name = "component", value.name = "variance"
)
coh_long[, component := factor(
  component,
  levels = c("within_var", "between_var"),
  labels = c("Within-country", "Between-country")
)]

p4b_a <- ggplot(coh_long, aes(x = cohort_group, y = variance, fill = component)) +
  geom_col() +
  scale_fill_manual(
    values = c("Within-country" = "#1f4e79", "Between-country" = "#8b0000"),
    name   = NULL
  ) +
  labs(x = NULL, y = "Variance (years\u00b2)", title = "A: Variance decomposition") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "top")

# Panel B: ICC
p4b_b <- ggplot(coh_var, aes(x = cohort_start, y = icc)) +
  geom_line(color = "orange") +
  geom_point(color = "orange", size = 2) +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(
    x = "Birth cohort", y = "ICC (between / total variance)",
    title = "B: Intraclass correlation"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Panel C: between-country SD
p4b_c <- ggplot(coh_var, aes(x = cohort_start, y = between_sd_p)) +
  geom_line(color = "firebrick") +
  geom_point(color = "firebrick", size = 2) +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  labs(
    x = "Birth cohort", y = "Between-country SD (years)",
    title = "C: Between-country SD"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Panel D: within-country SD
p4b_d <- ggplot(coh_var, aes(x = cohort_start, y = within_sd_p)) +
  geom_line(color = "navy") +
  geom_point(color = "navy", size = 2) +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  labs(
    x = "Birth cohort", y = "Within-country SD (years)",
    title = "D: Within-country SD"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

fig4b <- (p4b_a | p4b_b) / (p4b_c | p4b_d) +
  plot_annotation(
    title   = "Figure 4b: Variance decomposition of age gap across birth cohorts",
    caption = "Decomposing total variance into between- and within-country components"
  )

ggsave("results/fig4b_variance_decomposition.pdf", fig4b, width = 12, height = 8)
ggsave("results/fig4b_variance_decomposition.emf", fig4b, width = 12, height = 8, device = devEMF::emf)
cat("Saved: results/fig4b_variance_decomposition\n")


# =============================================================================
# 5. FIGURE 5: HEATMAP OF SD BY COUNTRY × COHORT
#
# Fill colour = SD of age difference; missing cells (< 100 obs) are left blank.
# Countries sorted by overall mean SD (largest at top).
# =============================================================================

# Compute SD per country × cohort cell (min 30 obs)
hm_data <- df[, .(sd_gap = sd(age_diff), n_cell = .N),
              by = .(country_name, cohort_start, cohort_group)]
hm_data <- hm_data[n_cell >= 100]

# Sort countries by overall mean SD (largest at top = highest factor level)
country_order <- hm_data[, .(overall_sd = mean(sd_gap)), by = country_name][order(-overall_sd)]
hm_data[, country_name := factor(country_name, levels = rev(country_order$country_name))]

fig5 <- ggplot(hm_data, aes(x = factor(cohort_start), y = country_name, fill = sd_gap)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "D", name = "SD (years)", na.value = "grey90") +
  labs(
    x       = "Birth cohort",
    y       = NULL,
    title   = "Figure 5: Dispersion of age gap by country and birth cohort",
    caption = "Fill = SD of age difference (years); missing = fewer than 100 obs"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 7)
  )

ggsave("results/fig5_heatmap_sd.pdf", fig5, width = 10, height = 12)
ggsave("results/fig5_heatmap_sd.emf", fig5, width = 10, height = 12, device = devEMF::emf)
cat("Saved: results/fig5_heatmap_sd\n")


# =============================================================================
# 6. FIGURE 5b: SHARE OF COUPLES WHERE WIFE IS OLDER BY COUNTRY × COHORT
#
# Two-panel figure:
#   Panel A — Heatmap of % wife older by country × cohort (like Figure 5)
#   Panel B — Cohort trend lines per country (grey) with overall trend (bold)
#
# Uses the binary variable wife_older = (age_diff < 0).
# =============================================================================

# ---- Compute % wife older per country × cohort (min 30 obs) ----------------
wo_cc <- df[, .(pct_wife_older = mean(wife_older) * 100, n_cell = .N),
            by = .(country_name, cohort_start, cohort_group)]
wo_cc <- wo_cc[n_cell >= 100]

# ---- Panel A: Heatmap -------------------------------------------------------
# Sort countries by overall mean % wife older (highest at top)
wo_country_order <- wo_cc[, .(overall_pct = mean(pct_wife_older)), by = country_name][order(-overall_pct)]
wo_cc[, country_name_ord := factor(country_name, levels = rev(wo_country_order$country_name))]

p5b_a <- ggplot(wo_cc, aes(x = factor(cohort_start), y = country_name_ord, fill = pct_wife_older)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "B", name = "% wife older", na.value = "grey90") +
  labs(
    x     = "Birth cohort",
    y     = NULL,
    title = "A: Share of couples where wife is older"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 7)
  )

# ---- Panel B: Cohort trend lines --------------------------------------------
# Overall trend
wo_overall <- df[, .(pct_wife_older = mean(wife_older) * 100), by = cohort_start]

p5b_b <- ggplot(wo_cc, aes(x = cohort_start, y = pct_wife_older, group = country_name)) +
  geom_line(color = "grey75", linewidth = 0.3) +
  geom_line(data = wo_overall, aes(group = 1), color = "firebrick", linewidth = 1) +
  geom_point(data = wo_overall, aes(group = 1), color = "firebrick", size = 2) +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(
    x     = "Birth cohort",
    y     = "% wife older",
    title = "B: Cohort trends by country"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ---- Combine panels ----------------------------------------------------------
fig5b <- (p5b_a | p5b_b) +
  plot_layout(widths = c(2, 1)) +
  plot_annotation(
    title   = "Figure 5b: Share of couples where wife is older across countries and birth cohorts",
    caption = "Left: heatmap (cells with < 100 obs excluded); Right: grey = individual countries, red = overall"
  )

ggsave("results/fig5b_wife_older.pdf", fig5b, width = 16, height = 12)
ggsave("results/fig5b_wife_older.emf", fig5b, width = 16, height = 12, device = devEMF::emf)
cat("Saved: results/fig5b_wife_older\n")
