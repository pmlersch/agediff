# Results Guide: Interpreting the Analysis Outputs

**Project:** Variance in the Age Difference in Different-Sex Marriage across Time and Contexts  
**Author:** Philipp M. Lersch  
**Data sources:** DHS, ESS, ISSP, IPUMS International  

This document explains every table and figure produced by the analysis pipeline. For each output it describes what the output shows, how to read the numbers or visual elements, what patterns to look out for, and provides an example of how to frame an interpretation. Actual substantive conclusions are left to the researcher.

---

## How the Pipeline Produces Its Results

The analysis runs in the following order (see `code/main.do`):

1. **Data harmonisation** — `get_dhs.do`, `get_ess.do`, `get_ipums.do`, `get_issp.do`  
2. **Merging** — `merge_data.do` → `data/harmonized/harmonized.dta` and `.rds`  
3. **Descriptive statistics (Stata)** — `code/descriptive.do` → Tables 1–6, Figures 1, 2, 5, 9, 10  
4. **Descriptive statistics (R)** — `code/descriptive.R` → Figures 3, 4, 6, 7, 8  
5. **Basic multivariate models (R)** — `code/multivariate_basic.R` → Models M1–M5, Figures 11–13  
6. **Advanced country-level analysis (R)** — `code/multivariate_advanced.R` → Figures 14–19, Diagnostics D1–D9


The core outcome variable is `age_diff = husband's age − wife's age` (in whole years). Positive values mean the husband is older; negative values mean the wife is older; zero means they are the same age.

---

## Part 1: Tables

All tables are saved as Markdown files in `results/` and can be read directly in any text editor or rendered in a Markdown viewer.

---

### Table 1 — Overall Summary (`results/table1_overall.md`)

**What it contains:** A single-row summary of the entire pooled sample across all countries, cohorts, and survey sources.

**Columns:**

| Column | Meaning |
|--------|---------|
| `N` | Total weighted number of couples in the analysis sample |
| `Mean` | Weighted arithmetic mean of `age_diff` in years |
| `SD` | Weighted standard deviation of `age_diff` in years |
| `Median` | Weighted 50th percentile (middle value) of `age_diff` |
| `Q25` | Weighted 25th percentile (first quartile) |
| `Q75` | Weighted 75th percentile (third quartile) |
| `Pct_wife_older` | Percentage of couples where the wife is older than the husband (i.e., `age_diff < 0`) |
| `IQR` | Interquartile range = Q75 − Q25; the spread of the middle 50 % of couples |

**How to read the numbers:** The `Mean` tells you the typical age gap pooled across all contexts. The `SD` captures how much variation there is around that mean — a larger SD means more couples deviate substantially from the average. The `Median` is more robust to extreme values (e.g., very large gaps in some countries). `Pct_wife_older` signals the overall asymmetry: if husbands are almost always older, this percentage is low.

**What to look out for:** Check whether `Mean` and `Median` are close (they should be if the distribution is roughly symmetric). A large gap between them indicates a skewed distribution, likely because a small number of couples with very large age differences pull the mean upward. Check whether `Pct_wife_older` is consistent with the sign and magnitude of the mean.

**Example interpretation:** If the mean is 4.3 years and the median is 3.0 years, the distribution is right-skewed: most couples cluster around a 2–4 year husband-older gap, but a long upper tail of couples with very large gaps raises the mean above the median. An `IQR` of 6.0 means that the middle 50 % of couples have gaps ranging from 1 to 7 years.

---

### Table 2 — Summary by Country (`results/table2_by_country.md`)

**What it contains:** The same eight statistics as Table 1, computed separately for each country in the sample (~100+ countries), sorted from highest to lowest mean age gap.

**Columns:** Same as Table 1, plus `country_name`.

**How to read the numbers:** Each row represents one country's pooled statistics across all available cohorts and survey years. Countries at the top of the table have the largest average age gaps; countries at the bottom have the smallest. Within any country, `SD` tells you how homogeneous couples are — a large SD indicates that the country contains very diverse couples (some with no gap, some with very large gaps), not that couples are uniformly clustered around the mean.

**What to look out for:**
- Countries with very small `N` (few thousand) will have unstable estimates; their statistics should be treated with more caution than large-sample countries.
- Compare `Mean` and `Median` per country. If they differ greatly, the distribution for that country is strongly skewed — possibly due to polygamous or non-standard partnerships recorded in the data.
- Countries where `Pct_wife_older` is unusually high relative to their mean gap may have bimodal distributions or specific data anomalies.
- The `SD` column is substantively important: it measures normativity. A low SD means most couples conform closely to a similar age pattern; a high SD means age pairing norms are looser and more diverse.

**Example interpretation:** Suppose Country A has Mean = 12 years and SD = 10 years while Country B has Mean = 12 years and SD = 5 years. Both countries have the same average gap but very different dispersion. In Country A, couples vary enormously (some with no gap, some with 25+ years), suggesting weak norms around the age gap. In Country B, couples are clustered tightly around a 12-year gap, suggesting a strong and uniform norm.

---

### Table 3 — Summary by Birth Cohort (`results/table3_by_cohort.md`)

**What it contains:** The same eight statistics as Table 1, computed separately for each 10-year birth cohort group (1920–1929, 1930–1939, …, 1980–1989).

**Columns:** Same as Table 1, plus `cohort_group`.

**How to read the numbers:** Each row is one birth cohort, covering individuals born in that 10-year period. By comparing rows from oldest to youngest cohorts you see how age-gap patterns have changed across generations. The `Mean` row shows whether the typical gap has grown or shrunk over time. The `SD` row shows whether dispersion has converged or diverged across generations.

**What to look out for:**
- The 1920–1929 cohort has fewer observations than later cohorts because many of those individuals are no longer alive or not captured in surveys. Treat estimates for the oldest cohorts with caution.
- The 1980–1989 cohort contains only individuals born in those years who have already formed a stable partnership *and* were captured in the survey before the survey's data collection ended. This cohort may be younger on average than all other cohorts at the time of observation, which can bias estimates — see `code/check_cohort1990.do` for a detailed diagnostic.
- Check whether `SD` moves monotonically or non-monotonically across cohorts. A non-monotonic pattern (e.g., SD rising then falling) would require closer investigation.
- `Pct_wife_older` can increase over cohorts as gender norms equalise — watch for a trend.

**Example interpretation:** If Mean increases steadily from 3.0 years in the 1920s cohort to 5.0 years in the 1970s cohort while SD remains constant, this suggests a shift in the typical age gap without any change in how tightly couples cluster around it. If both Mean and SD increase together, later cohorts have both a larger average gap *and* more diverse couple compositions.

---

### Table 4 — Mean Age Gap by Country × Cohort (`results/table4_mean_by_country_cohort.md`)

**What it contains:** A matrix of weighted mean age gaps. Rows are countries; columns are birth cohorts (1920, 1930, …, 1980). Each cell contains the mean `age_diff` for that country-cohort combination. Cells with fewer than 100 observations are left blank.

**How to read the numbers:** Reading across a row shows how the mean age gap has changed over generations within one country. Reading down a column shows cross-national variation within a single generation. The overall pattern (do most cells increase, decrease, or fluctuate over time?) indicates whether global convergence or divergence is occurring.

**What to look out for:**
- Many cells will be blank, especially for the oldest cohorts and for smaller countries. This missing data pattern should itself be noted — it tells you where the data coverage is thin.
- A negative cell value means the average wife was older than the average husband in that country-cohort — unusual but possible.
- Look for outlier cells: a single country-cohort cell that deviates dramatically from neighbouring cells may reflect a data anomaly rather than a real effect.
- Compare this table with Table 5 (SD). A country where Mean is stable but SD changes substantially is experiencing a shift in dispersion, not in the typical gap.

**Example interpretation:** If Sweden shows means of 3.5, 3.2, 2.8, 2.5, 2.3, 2.1, and 1.9 across cohorts 1920–1980, there is a clear and consistent decline in the average age gap over generations within that country.

---

### Table 5 — SD of Age Gap by Country × Cohort (`results/table5_sd_by_country_cohort.md`)

**What it contains:** Identical structure to Table 4, but cells contain the standard deviation of `age_diff` rather than the mean. This is the key normativity indicator: a low SD signals strong shared norms about appropriate age gaps; a high SD signals weak or absent norms.

**How to read the numbers:** Each cell answers the question: "How much do couples in this country and generation vary in their age gap?" A value of 4 means that roughly two-thirds of couples fall within ±4 years of the mean gap for that country-cohort. A value of 10 means the distribution is much wider and more diverse.

**What to look out for:**
- Do SDs tend to decrease over cohorts globally, or only in some regions? Global convergence would support modernisation arguments.
- Are high-SD countries the same as high-Mean countries? If so, mean and variance are correlated cross-nationally (see Figure 6 and Figure 13 for this relationship).
- For a given country, if SD increases in later cohorts, this may indicate increasing heterogeneity as norms weaken. If SD decreases, norms may be solidifying around a new (smaller) typical gap.
- Blank cells carry the same caveat as Table 4.

**Example interpretation:** If Nigeria shows SDs of 10.5, 9.8, 9.1, 8.7, 8.3, 7.5, 7.0 across cohorts 1920–1980, this indicates a gradual narrowing of the age-gap distribution over generations — fewer extremely large or extremely small gaps — even if the mean remains high.

---

### Table 6 — Sample Size by Country × Survey Year (`results/table6_n_by_country_year.md`)

**What it contains:** A matrix of unweighted observation counts. Rows are countries; columns are survey years. Each cell shows how many couple-records came from that country in that survey year. Cells with fewer than 100 observations are shown as blank.

**How to read the numbers:** This table tells you where the data come from and when. A country with entries in many survey years contributes data from multiple time points and will drive cohort-trend estimates more reliably. A country appearing in only one column provides a single cross-sectional snapshot.

**What to look out for:**
- Countries with very few total observations (sum across the row) produce unreliable statistics. The 100-observation floor per cell is a conservative filter; cells just above the threshold should still be treated cautiously.
- Survey years that are much older than the birth cohorts observed likely contain only the oldest birth cohorts for that country. Survey years that are very recent may observe younger birth cohorts only.
- Check whether countries you plan to highlight in the paper have adequate data coverage across the cohort range you are discussing.

**Example interpretation:** If Indonesia appears in columns 1990, 2000, 2005, and 2010 with counts of 200,000–300,000 in each, it has strong and repeated coverage and will contribute reliably to cohort trends. If a small country appears only in 2005 with 150 observations, any trend estimates for that country are not meaningful.

---

## Part 2: Figures — Descriptive

All figures are saved as both `.pdf` (for publication) and `.emf` (Enhanced Metafile, for editing in Word/PowerPoint) in `results/`. Produced by `code/descriptive.do` (Figures 1, 2, 5, 9, 10) and `code/descriptive.R` (Figures 3, 4, 6, 7, 8).

---

### Figure 1 — Histogram of Age Differences (`results/fig1_histogram.pdf`)

**What it shows:** A histogram of the pooled `age_diff` distribution across all countries, cohorts, and survey years. Each bar covers a one-year-wide bin. A dashed vertical line marks zero (same-age partners).

**Purpose:** To give an immediate impression of the overall shape of the distribution — its typical value, symmetry, and spread.

**How to interpret:**
- The peak of the histogram is the mode — the most common age gap in the data.
- The width of the histogram reflects dispersion: a narrow spike means nearly all couples have the same gap; a wide spread means age pairings are highly diverse.
- The mass to the left of the dashed line (negative values) represents couples where the wife is older.
- Long tails — especially the right tail — indicate that a minority of couples have very large age gaps (husband much older).

**What to look out for:** Age heaping — artificially high bars at multiples of 5 (e.g., 0, 5, 10, 15 years) may appear because survey respondents round ages. This is more pronounced in some data sources than others. See `code/check_heaping.do` for a formal assessment. If heaping is visible, the histogram is a useful diagnostic but the spikes at round numbers should not be over-interpreted as substantive peaks.

**Example interpretation:** If the histogram peaks at 3–4 years and falls off sharply on the left (few wife-older couples) but has a long right tail extending to 20+ years, the typical couple has a modest age gap with the husband slightly older, but a sizable minority have very large gaps.

---

### Figure 2 — Caterpillar Plot of Median and IQR by Country (`results/fig2_caterpillar.pdf`)

**What it shows:** One horizontal line segment per country. The dot on each line marks the median age gap for that country; the left end of the line marks Q25 and the right end marks Q75 (the IQR). Countries are sorted from bottom (smallest median) to top (largest median).

**Purpose:** To compare the location and spread of age gaps across all countries simultaneously, using robust statistics (median, IQR) that are not affected by extreme values.

**How to interpret:**
- The position of the dot shows the typical (median) gap for that country.
- The length of the line segment shows dispersion: a long line = a wide middle 50 % of couples = more diverse age pairings; a short line = more homogeneous.
- Countries at the top have the largest typical age gaps; countries at the bottom have the smallest.
- Countries where the Q25 endpoint is to the left of zero have many wife-older couples (the lower quartile includes negative values).

**What to look out for:** Look for countries where the IQR is long relative to others at the same median level — these countries have unusually high variance. Note whether the length of lines increases or decreases as you move up the y-axis (i.e., whether high-gap countries also tend to have more or less dispersion than low-gap countries). Compare the overall ordering with Table 2 to verify consistency.

**Example interpretation:** Two countries could sit at the same vertical position (same median) but one has a short line (IQR = 3 years) while the other has a long line (IQR = 10 years). Both have the same "typical" gap, but the second country's couples span a much wider range.

---

### Figure 3 — Ridgeline Density by Country (`results/fig3_ridgeline.pdf`)

**What it shows:** One density curve per country, stacked vertically and sorted by the mode (peak) of the distribution. The fill colour uses a gradient: warmer colours correspond to higher age-gap values.

**Purpose:** To show the full shape of each country's age-gap distribution simultaneously — not just location or spread but skewness, bimodality, and the exact profile of the distribution.

**How to interpret:**
- Each curve is a kernel density estimate — a smoothed version of the country's histogram.
- The peak of the curve is the most common age gap (mode) for that country.
- The width of the curve indicates dispersion: narrow curves = concentrated distribution; wide, flat curves = dispersed distribution.
- A long right tail on a curve means that while the peak is at a modest gap, there are many couples with very large gaps in that country.
- Curves where significant mass lies to the left of zero have an appreciable share of wife-older couples.

**What to look out for:** Look for bimodal curves (two distinct humps) — these might indicate subpopulation heterogeneity within a country (e.g., different regional or religious groups). Check whether the mode and the mean (from Table 2) are consistent: if the mode is much lower than the mean, there is a strong right skew. Note that the x-axis is truncated at −10 and +20 years; extreme values beyond this range exist but are not shown to keep the figure readable.

**Example interpretation:** If a country's density curve has its peak at 0 and falls off symmetrically, couples are as likely to have the wife older as the husband older, with most couples same-age. If another country's curve peaks at 8 years with a long right tail and almost no mass below zero, husbands are almost always older and large age gaps are common.

---

### Figure 4 — Ridgeline Density by Birth Cohort (`results/fig4_ridgeline_cohort.pdf`)

**What it shows:** The same ridgeline format as Figure 3, but each ridge is one 10-year birth cohort (1920–1929 at the bottom, 1980–1989 at the top).

**Purpose:** To show how the shape of the overall age-gap distribution has changed across generations.

**How to interpret:**
- Reading from bottom to top is reading from oldest to youngest birth cohorts.
- A shift of the peak leftward across cohorts means the most common age gap is shrinking over generations.
- A narrowing of the curve (less width) means the distribution is becoming more concentrated, i.e., couples are converging toward more similar age gaps.
- Widening of the curve means greater diversity over time.

**What to look out for:** The oldest cohorts (1920s) may have fewer observations, producing rougher, less smooth density curves — this reflects sampling variability rather than a real distribution shape. The youngest cohort (1980s) may contain only recently formed partnerships among relatively young adults, which can create a different age profile from older cohorts observed at later life stages (see check_cohort1990.do).

**Example interpretation:** If curves progressively shift leftward and narrow from the 1930s to the 1970s, this would indicate that younger generations have both smaller typical age gaps and more homogeneous couple compositions than older generations.

---

### Figure 5 — Mean and SD of Age Gap over Birth Cohorts (`results/fig5_cohort_mean_sd.pdf`)

**What it shows:** A two-panel figure. Panel A (left) plots the mean age gap against birth cohort; Panel B (right) plots the standard deviation against birth cohort. Both panels show thin grey lines for individual countries and a bold coloured line for the overall pooled trend.

**Purpose:** To reveal whether mean age gaps and dispersion are converging or diverging across generations, and whether different countries follow the same trend.

**How to interpret:**
- **Panel A (Mean):** A downward trend means the typical age gap is declining over generations. An upward trend means it is growing. Individual grey country lines that run roughly parallel to the overall bold line suggest that all countries share the same trend direction, even if they start at different levels.
- **Panel B (SD):** A downward trend means the distribution of age gaps is becoming more concentrated — less variance, tighter norms. An upward trend means increasing diversity.
- When a country's grey line diverges from the overall trend (moves in a different direction), that country deviates from the global pattern and warrants closer investigation.
- Parallel country lines that move together suggest "parallel change" — countries converging or diverging as a group.

**What to look out for:** The overall bold line is the average across countries and cohorts, weighted by the data. It can be dominated by large-population countries. Compare whether Panel A and Panel B tell the same or different stories — divergence between mean and SD trends is theoretically interesting. Check whether the bold line changes steeply between any two adjacent cohorts; a sudden jump may reflect a data composition change rather than a true generational shift.

**Example interpretation:** If the bold line in Panel A declines steadily while in Panel B it also declines, then later-born generations tend to have smaller mean age gaps *and* are more homogeneous around that smaller gap. This would be consistent with a normative convergence story. If Panel A declines but Panel B increases, the mean gap is shrinking but couples are becoming more diverse — some going to equal-age partnerships, others keeping large gaps.

---

### Figure 6 — Variance Decomposition over Cohorts (`results/fig6_variance_decomposition.pdf`)

**What it shows:** A four-panel figure:
- **Panel A (Variance decomposition):** Stacked bar chart. Each bar represents one birth cohort. The dark blue segment shows within-country variance; the dark red segment shows between-country variance.
- **Panel B (ICC):** A line chart of the intraclass correlation coefficient (ICC) across birth cohorts.
- **Panel C (Between-country SD):** A line chart of the between-country standard deviation across cohorts.
- **Panel D (Within-country SD):** A line chart of the within-country (average) standard deviation across cohorts.

**Purpose:** To answer the question: how much of the total variation in age gaps is due to differences between countries versus differences among couples within countries? And how has this changed across generations?

**How to interpret:**
- **Panel A:** If the red (between-country) segment is tall relative to the blue (within-country) segment, then country context explains a large share of the total variance — where you live matters a great deal for your age gap. If the blue segment dominates, most variation is among individual couples within countries and country context matters less.
- **Panel B (ICC):** The ICC ranges from 0 to 1. An ICC of 0.20 means 20 % of the total variance is between countries. A rising ICC over cohorts means countries are diverging; a falling ICC means couples within countries are becoming more diverse relative to differences between countries.
- **Panel C:** The between-country SD tells you directly how much average age gaps vary across countries. If this declines, countries are converging toward each other in their typical age gaps.
- **Panel D:** The within-country SD shows how diverse couples are within the average country. If this declines, norms within countries are tightening.

**What to look out for:** Check whether Panel C (between-country convergence) and Panel D (within-country convergence) move in the same or opposite direction. They can move independently. A situation where Panel C declines but Panel D stays stable means countries converge toward each other but internal diversity within countries does not shrink. Also check whether the ICC in Panel B is low (suggesting within-country differences dominate) or high (suggesting between-country differences dominate) — this frames how important country context is in explaining age-gap variation.

**Example interpretation:** If Panel A shows that within-country variance (blue) accounts for roughly 80 % of total variance across all cohorts, and Panel B shows an ICC hovering around 0.20, then country context explains only a modest share of variation — most differences are between individual couples within the same country. If Panel C declines over cohorts while Panel D does not, countries are converging without couples becoming more alike within countries.

---

### Figure 7 — Heatmap of SD by Country × Cohort (`results/fig7_heatmap_sd.pdf`)

**What it shows:** A grid with countries on the y-axis (sorted by overall mean SD, highest at top) and birth cohorts on the x-axis. Each cell is filled with a colour representing the standard deviation of `age_diff` in that country-cohort cell. Missing cells (< 100 observations) are grey.

**Purpose:** To give a visual overview of how dispersion varies simultaneously across countries and generations, and to identify which countries drive global trends.

**How to interpret:**
- Darker (or more saturated) cells indicate larger SDs — more dispersed age-gap distributions.
- Lighter (or less saturated) cells indicate smaller SDs — more concentrated distributions.
- A row that becomes lighter from left to right indicates that dispersion is declining over cohorts for that country.
- A row that stays consistently dark indicates that high dispersion persists across all generations in that country.
- A row with many grey (missing) cells indicates a country with limited data coverage.

**What to look out for:** Look for whether countries at the top of the y-axis (highest-SD countries) are consistently dark across all cohort columns or only in certain cohorts. Look for regional patterns if you can mentally group countries. Check whether the heatmap supports the global trend in Figure 6 Panel D — if Figure 6 Panel D shows a decline in within-country SD over cohorts, you would expect cells to become lighter from left to right in most rows.

**Example interpretation:** If a country row in Figure 5 shows cells going from dark blue (SD ≈ 9) in the 1930s to light yellow (SD ≈ 5) in the 1970s, that country has experienced a substantial reduction in age-gap dispersion over generations. If another country's row shows consistently medium-dark colour across all cohorts, its dispersion has remained stable.

---

### Figure 8 — Share of Couples Where Wife Is Older (`results/fig8_wife_older.pdf`)

**What it shows:** A two-panel figure.
- **Panel A (Heatmap):** Same grid structure as Figure 5 but the fill represents the percentage of couples where the wife is older (i.e., `age_diff < 0`).
- **Panel B (Line chart):** Grey lines = cohort trends for individual countries; red line = overall pooled trend.

**Purpose:** To examine whether husband-older asymmetry in couple formation is weakening over generations, and how this varies across countries.

**How to interpret:**
- In the heatmap (Panel A), darker/more saturated cells indicate a higher percentage of wife-older couples. A cell at 20 % means one in five couples in that country-cohort have the wife older.
- If cells become darker moving left to right across cohorts, the share of wife-older couples is rising over generations in that country.
- In Panel B, the overall red line shows the global cohort trend. Grey lines above the red line are countries where wife-older couples are more common than average; grey lines below are countries where they are less common.
- Convergence of grey lines toward the red line would indicate that countries are becoming more similar in how commonly wives are older.

**What to look out for:** Note that this is a binary indicator (wife older yes/no) derived from a continuous variable (`age_diff`). Because `age_diff` is measured in whole years, couples recorded at 0 are "same age" by this measure and are *not* counted as wife-older even if the wife is a few months older. This creates a floor effect in the data. Check whether the global trend in Panel B is driven by a few large-population countries or is representative of broad change.

**Example interpretation:** If the red line in Panel B rises from 10 % in the 1930s cohort to 20 % in the 1970s cohort, the share of wife-older couples has doubled across generations in the pooled sample. If several grey lines converge toward 15–20 % across cohorts, countries that previously had very few wife-older couples are catching up to those that already had many.

---

### Figure 9 — Mean vs. SD Scatter (`results/fig9_mean_vs_sd.pdf`)

**What it shows:** A scatter plot where each point is one country. The x-axis shows the mean age gap and the y-axis shows the SD of the age gap, both for the most recent birth cohort with sufficient data. Country names are printed next to their dots. A linear regression line (OLS) is shown in red.

**Purpose:** To examine the cross-national correlation between the average age gap and how dispersed couples are around that average. This addresses the question: do countries with large typical gaps also have more or less diverse couple formations?

**How to interpret:**
- A point in the upper right means a country has both a large mean gap and a large SD — the typical gap is large and couples vary considerably around it.
- A point in the lower left means a country has a small mean gap and a small SD — couples cluster tightly around a small gap.
- The slope of the red regression line tells you the direction of the correlation. A positive slope means higher-gap countries tend to also be more dispersed; a negative slope would mean higher-gap countries are more uniform.
- The spread of points around the regression line tells you how consistent this relationship is.

**What to look out for:** Points far from the regression line are interesting outliers — countries where mean and variance do not move together as expected. Check whether a specific region or data source systematically clusters in a particular area of the plot. Because this plot uses only the most recent cohort, the pattern may differ from earlier cohorts. The figure should be compared with Figure 16 (which uses a model-based approach on the same question).

**Example interpretation:** If the regression line has a positive slope and most African countries cluster in the upper-right while most European countries cluster in the lower-left, this would indicate that cross-national differences in mean age gap and in age-gap dispersion are positively correlated — countries with larger gaps also have more diverse couple formations.

---

### Figure 10 — Mean and SD by Country (Dot Plot) (`results/fig10_mean_sd_country.pdf`)

**What it shows:** For each country (sorted by mean), two dots are shown: one for the mean age gap (one colour) and one for the SD (another colour). Countries are listed on the y-axis.

**Purpose:** To simultaneously compare mean and dispersion across countries in a single figure, using moment-based statistics. This complements Figure 2 (which shows median and IQR).

**How to interpret:**
- The relative horizontal positions of the two dots for a given country tell you the ratio of dispersion to location. If the SD dot is far to the right of the mean dot, dispersion is large relative to the mean. If the SD dot is close to or below the mean dot, dispersion is modest.
- Countries are sorted by mean: moving from bottom to top, the mean increases. Check whether the SD dots also increase, decrease, or fluctuate as you move up the y-axis.
- Countries where the SD dot is far to the right of most others at the same mean level have unusually high dispersion.

**What to look out for:** Check whether mean and SD are correlated across countries (both increasing together or both staying stable). See Figure 9 for a formal scatter plot of this relationship. Note that this figure uses pooled data across all cohorts, so country-level estimates reflect the entire historical record, not just recent generations.

**Example interpretation:** If most countries cluster such that both mean and SD dots lie between 2 and 6 years, but a few countries have both dots beyond 10 years, this highlights a set of outlier countries with qualitatively different age-pairing patterns.

---

## Part 3: Multivariate Models

The multivariate analysis uses **location-scale mixed models** estimated with `nlme::lme()` in R. These models have two components:

- **Location (mean):** Estimated via fixed effects for cohort and random intercepts for country.
- **Scale (variance):** Estimated via `varIdent()`, which allows the residual standard deviation to differ by group (cohort or country).

The key innovation over a standard mixed model is that the variance itself is treated as a quantity to be estimated, not assumed constant. This directly tests whether age-gap dispersion differs across cohorts or countries.

All models use a 10 % random subsample (~40,000 observations) for computational feasibility. The subsample is drawn with `set.seed(123)` for reproducibility.

---

### Models M1–M4 (printed to R console / log file)

#### Model M1: Homoskedastic Baseline

**What it estimates:** The mean age gap is explained by birth cohort (fixed effects) and country (random intercept). The residual variance is assumed equal everywhere.

**How to read the output:**
- **Fixed effects (`fixef()`):** The intercept is the estimated mean age gap for the reference birth cohort (the earliest cohort group in the data). Each cohort dummy coefficient gives the difference in mean gap compared to the reference cohort. A positive coefficient means that cohort has a larger mean than the reference; a negative coefficient means a smaller mean.
- **Random effects (`VarCorr()`):** `StdDev` for `(Intercept)` is the estimated standard deviation of country random intercepts — how much countries differ from each other in their mean age gap after controlling for cohort composition. A large value means substantial between-country heterogeneity in mean gaps.
- **Residual:** `sigma` is the estimated residual standard deviation (assumed constant across all groups in M1).

**What to look out for:** M1 is the baseline against which M2 and M3 are compared. By itself, M1 answers: "Controlling for country, how does the typical age gap change across cohorts?" The residual `sigma` gives a first estimate of within-group dispersion.

**Example interpretation:** If the cohort coefficient for `cohort_f1970-1979` is 2.5 and for `cohort_f1940-1949` is 1.0, couples born in the 1970s had an average gap that was 1.5 years larger than those born in the 1940s (conditional on country).

---

#### Model M2: Variance Differs by Cohort

**What it estimates:** Same fixed and random effects as M1, but the residual SD is allowed to be different in each birth cohort. This directly tests: does the *dispersion* of age gaps differ across generations?

**How to read the output:**
- **`VarIdent` coefficients:** These are multiplicative scaling factors for the residual SD relative to the reference cohort. A factor of 1.20 means the residual SD in that cohort is 1.20 × the reference cohort's SD — 20 % more dispersed.
- **`m2_var_cohort$sigma`:** The base residual SD, corresponding to the reference cohort.
- **To compute the actual SD per cohort:** multiply `sigma` by the `VarIdent` multiplier for each cohort. The resulting values are plotted in Figure 11 (`results/fig11_predicted_sd_cohort.pdf`).

**What to look out for:** Check whether the multipliers are close to 1.0 (meaning variance does not differ much across cohorts, and M2 adds little over M1) or whether they vary substantially. If the multiplier is consistently above or below 1.0 for earlier versus later cohorts, there is a systematic trend in dispersion.

**Example interpretation:** If the reference cohort is 1950–1959 with `sigma` = 6.0, and the 1970–1979 cohort has a `VarIdent` multiplier of 0.90, then the 1970s cohort has an estimated residual SD of 6.0 × 0.90 = 5.4 — the distribution became 10 % less dispersed.

---

#### Model M3: Variance Differs by Country

**What it estimates:** Same fixed and random effects as M1, but the residual SD is allowed to be different in each country. This tests: does *dispersion* vary across national contexts?

**How to read the output:**
- **`VarIdent` coefficients:** Multiplicative factors for the residual SD relative to the reference country.
- **`m3_var_country$sigma`:** The base residual SD for the reference country.
- **To compute SD per country:** multiply `sigma` by each country's factor. These are plotted in Figure 14 (`results/fig14_country_sigma_re.pdf`).

**What to look out for:** Countries whose factor is much greater than 1 have unusually wide distributions (high dispersion). Countries whose factor is much less than 1 have unusually narrow distributions. A very wide spread in the `VarIdent` factors means substantial cross-national differences in age-gap norms.

**Example interpretation:** If Germany's `VarIdent` factor is 0.70 and Niger's is 1.80, Germany's couples are 30 % less dispersed than the reference country while Niger's are 80 % more dispersed.

---

#### Model M4: Random Slope on Cohort Index

**What it estimates:** Extends M2 by also allowing the cohort trend in the *mean* age gap to differ across countries (random slope on `cohort_idx`, a numeric cohort index). This tests: do all countries follow the same generational trajectory in mean age gaps, or do some converge faster or slower?

**How to read the output:**
- **`VarCorr()`:** Now reports variance components for both the random intercept (country-level difference in mean gap) and the random slope on `cohort_idx` (country-level difference in cohort trends). A large variance on the slope means countries have very different generational trends.
- **Correlation between intercept and slope:** This is reported in `VarCorr()`. A negative correlation would mean that countries with larger baseline gaps tend to show steeper declines (catch-up convergence). A positive correlation would mean larger-gap countries also change more.

**What to look out for:** The random slope model is more complex and may have higher AIC than M2 if the additional random slope is not needed. Check the AIC comparison table to see whether M4 provides a meaningful improvement. If the variance on the cohort slope is very small, country-specific trajectories are similar and M2 is adequate.

**Example interpretation:** If the random slope variance is large, it means some countries show rapid generational declines in mean age gap while others show little or no change. Examining the country-specific BLUP (best linear unbiased prediction) slopes would reveal which countries are driving the trend and which are stable.

---

### Model Comparison Table (printed to R console)

**What it shows:** A table with four rows (M1–M4), columns `Model`, `AIC`, and `BIC`.

**AIC (Akaike Information Criterion):** A penalised goodness-of-fit measure. Lower AIC = better model, after penalising for the number of estimated parameters. Used for model selection.

**BIC (Bayesian Information Criterion):** Similar to AIC but with a heavier penalty for additional parameters. BIC tends to favour simpler models more than AIC.

**How to read the table:** Compare AIC and BIC across models. A difference of more than 2–4 AIC units is typically considered meaningful; differences of 10+ are strong. The model with the lowest AIC (or BIC) is preferred by that criterion. If M2 has substantially lower AIC than M1, variance does differ meaningfully by cohort. If M3 has lower AIC than M2, country-level variance heterogeneity matters more than cohort-level.

**What to look out for:** AIC and BIC may disagree — AIC may favour M4 while BIC favours M2. Report both and acknowledge the trade-off. Note that all models were fit with `method = "REML"`, which is appropriate for comparing random-effects structures but technically not recommended for comparing fixed-effects structures via LRT. The `anova()` call used for the LRT automatically refits with ML when needed.

**Example interpretation:** If M1: AIC = 250,000; M2: AIC = 249,200; M3: AIC = 248,800; M4: AIC = 248,850, then M3 has the best AIC. The large drop from M1 to M3 (−1,200 AIC units) indicates very strong evidence that variance differs across countries and models assuming constant variance are substantially misspecified.

---

### Likelihood Ratio Tests (printed to R console)

**What they show:** Formal statistical tests comparing M1 versus M2 (does cohort variance matter?) and M1 versus M3 (does country variance matter?).

**How to read the output:** The `anova()` output shows the degrees of freedom (df), log-likelihood (logLik), AIC, BIC, likelihood ratio statistic (L.Ratio), and p-value for the more complex model. A very small p-value (e.g., < 0.001) means the data strongly reject the homoskedastic baseline — the more complex variance structure is statistically required.

**What to look out for:** With very large sample sizes (40,000 observations), even trivially small differences in fit can yield extremely significant p-values. Do not rely solely on the p-value — check the size of the AIC improvement and the magnitude of the `VarIdent` coefficients to assess substantive importance.

---

## Part 4: Model-Based Figures

These figures visualise quantities extracted from the fitted models. They translate model coefficients into readily interpretable graphics. Produced by `code/multivariate_basic.R` (Figures 11–13) and `code/multivariate_advanced.R` (Figures 14–19).

---

### Figure 11 — Model-Estimated Age-Gap Dispersion by Cohort (`results/fig11_predicted_sd_cohort.pdf`)

**What it shows:** A line chart. The x-axis is birth cohort; the y-axis is the model-estimated residual SD from M2. Each point represents the estimated within-cohort standard deviation after controlling for country.

**Purpose:** To directly visualise the model-based estimate of how much dispersion in age gaps each cohort has, net of between-country differences.

**How to interpret:** The y-value for a given cohort is the model's estimate of the typical within-country SD for that cohort. A declining line means later-born cohorts have less dispersed age-gap distributions (tighter norms); a rising line means increasing diversity; a U-shape would indicate a non-monotonic generational trend.

**What to look out for:** Compare this figure with the raw SD trends in Figure 6 Panel D. Discrepancies between the two indicate that some of the raw trend in Figure 5 was attributable to changing country composition across cohorts (e.g., more high-SD developing countries in older cohorts), while Figure 11 controls for country.

**Example interpretation:** If the line in Figure 11 shows a modest U-shape — declining from the 1920s to the 1950s and then rising again for the 1970s–1980s — this would suggest that after controlling for country, dispersion was lower in mid-century cohorts, potentially reflecting a period of stronger normative consensus, before loosening in more recent generations.

---

### Figure 12 — Model-Predicted Mean Age Gap by Cohort (`results/fig12_predicted_mean_cohort.pdf`)

**What it shows:** A line chart. The x-axis is birth cohort; the y-axis is the population-average predicted mean age gap from M2 (fixed effects only, country random effects set to zero).

**Purpose:** To visualise the cohort trend in the mean age gap as estimated by the mixed model, representing the "average country."

**How to interpret:** This is the model-based equivalent of the bold line in Figure 5 Panel A, but derived from the regression coefficients rather than simple averages. A positive slope means the mean gap is increasing over cohorts (averaged across countries); a negative slope means it is declining. Because random effects are zeroed out, this line represents a hypothetical average country, not any specific country.

**What to look out for:** Compare this line with the simple means in Table 3. If both tell the same story, the model fit is consistent with the raw data. Differences indicate that country composition or weighting affects the raw cohort trend. The reference level on the y-axis is the predicted mean for the reference birth cohort.

---

### Figure 13 — Location-Scale Model-Implied Distributions by Cohort (`results/fig13_model_implied_densities.pdf`)

**What it shows:** A two-panel figure combining the mean (from Figure 12) and the SD (from Figure 11):
- **Panel A (Density curves):** For each cohort, a normal distribution curve is drawn using the model-predicted mean (Figure 12) and the model-predicted SD (Figure 11). Curves are colour-coded by cohort and overlaid on the same axis.
- **Panel B (Mean ± SD ribbon):** A line plot of the predicted mean with shaded bands at ±1 and ±2 SD around it, across cohorts.

**Purpose:** This is the key results figure for the modelling section. It makes the full distributional shift across cohorts vivid and tangible — the reader can see simultaneously how the peak (location) and width (scale) of the distribution change across generations.

**How to interpret:**
- In Panel A, if curves from older cohorts are wider (more spread out) and centred at a different value than younger cohorts, both the mean and variance have changed across generations. The overlap between curves indicates how similar adjacent cohorts are.
- A rightward shift of curve peaks over cohorts (earlier cohorts further right) with narrowing widths (later cohorts narrower) would mean both mean and SD are declining over generations.
- In Panel B, if the ribbon (±1 and ±2 SD) narrows over cohorts while the line shifts, dispersion is decreasing; if the ribbon widens, dispersion is increasing.

**What to look out for:** These are **model-implied** normal distributions — they assume the within-cohort distribution is approximately normal, which the diagnostics (D1–D4) assess. If the normality assumption is severely violated, the implied curves will be misleading. Always read this figure in conjunction with the diagnostic figures.

**Example interpretation:** If the 1940s cohort curve in Panel A is wide and centred at 5 years while the 1970s cohort curve is narrow and centred at 4 years, the model estimates both a smaller typical gap and more concentrated couple formations in later generations, even after accounting for between-country differences.

---

### Figure 14 — Country-Level Residual SD from M3 (`results/fig14_country_sigma_re.pdf`)

**What it shows:** A dot plot (caterpillar layout) with one dot per country. Countries are sorted on the y-axis from lowest (bottom) to highest (top) estimated residual SD. The x-axis shows the estimated residual SD from M3 (the model that allows variance to differ by country).

**Purpose:** To rank countries by their within-country age-gap dispersion, as estimated by the model, net of cohort composition.

**How to interpret:** Countries at the top have the most dispersed age-gap distributions (weak norms; couples vary widely). Countries at the bottom have the most concentrated distributions (strong norms; couples cluster tightly). The value on the x-axis is the estimated standard deviation of `age_diff` for that country after controlling for cohort.

**What to look out for:** Compare with the raw SD in Table 2 and Figure 7. The model-based estimates in Figure 14 control for cohort composition; raw estimates in Table 2 do not. Large discrepancies between a country's rank in Figure 14 and its rank in Table 2 indicate that cohort composition is confounding the raw estimate. Note that model estimates are derived from a 40,000-observation subsample; for countries with very few observations in the subsample, estimates may be imprecise.

---

### Figure 15 — Country Random Intercepts (`results/fig15_country_mu_re.pdf`)

**What it shows:** A dot plot with one dot per country, sorted by the size of the random intercept. The x-axis shows the estimated country-level deviation from the overall mean age gap (i.e., the BLUP — Best Linear Unbiased Prediction). A dashed vertical line marks zero.

**Purpose:** To show how much each country's mean age gap differs from the overall average *after controlling for birth cohort*.

**How to interpret:**
- A dot to the right of zero means that country has a mean age gap larger than the average after accounting for cohort composition.
- A dot to the left of zero means the country's mean gap is below average.
- Countries with dots far from zero are outliers in mean gap level.

**What to look out for:** The random intercepts sum to approximately zero across all countries (by the random effects constraint). Countries with very large positive or negative random intercepts are the main drivers of cross-national variation in the mean. Check whether countries with large positive intercepts (high mean) also have large residual SDs (Figure 14) or vice versa — this is directly examined in Figure 16.

---

### Figure 16 — Relationship between Mean and Variance across Countries (`results/fig16_mean_vs_variance_re.pdf`)

**What it shows:** A scatter plot. The x-axis is the country random intercept (mean deviation, from Figure 15); the y-axis is the country-specific residual SD (from Figure 14). Each dot is a country, labelled. A linear regression line with 95 % confidence interval is shown.

**Purpose:** To directly examine whether countries with larger-than-average mean age gaps also tend to be more or less dispersed. This is the model-based version of Figure 9.

**How to interpret:**
- A positive slope means high-mean-gap countries also have high within-country dispersion.
- A negative slope would mean high-mean-gap countries are actually more uniform (narrower distribution) than low-mean-gap countries — less intuitive but theoretically possible if cultural norms strongly dictate a specific large gap.
- A slope near zero means mean and variance are essentially uncorrelated across countries.

**What to look out for:** The confidence interval shading shows uncertainty around the linear fit. If the interval is wide, the relationship is not well-determined from the data. Check whether any single country is heavily influencing the slope — countries at the extreme right with very high SDs. The labelled country names help identify which specific countries are outliers.

---

### Figure 17 — Full Distribution Evolution for Selected Countries (`results/fig17_country_density_evolution.pdf`)

**What it shows:** A faceted figure with eight panels, one per selected country (Sweden, Germany, United States, Brazil, India, Egypt, Nigeria, Mali). Within each panel, one density curve per birth cohort is overlaid. Curves are colour-coded by cohort.

**Purpose:** To show the full distributional change — not just a summary statistic — within specific countries across generations. This is the country-level analogue of Figure 13.

**How to interpret:**
- Within each panel, if successive cohort curves shift leftward and narrow, that country's couples are forming partnerships with smaller, more homogeneous age gaps in younger generations.
- If curves move right or widen, the opposite is true.
- Panels are arranged from low-mean to high-mean countries (Sweden at top-left, Mali at bottom-right), so differences in scale and shape across the eight panels reflect the global range of age-gap patterns.

**What to look out for:** The eight countries were chosen to span different world regions and mean-gap levels. Results from these eight should not be generalised to all countries without checking other countries in the data. Some cohorts within countries may have few observations, producing rough or irregular density curves. Focus on cohorts with smooth curves.

**Example interpretation:** If Sweden's panel shows all cohort curves overlapping closely between −5 and +8 years with the peak consistently at 2 years, Sweden's distribution has been stable across generations. If Nigeria's panel shows the oldest cohort's curve centred at 12 years and the youngest cohort's curve centred at 8 years with some narrowing, there is a generational shift toward smaller and more uniform gaps.

---

### Figure 18 — SD Trends for Selected Countries (`results/fig18_country_sd_trends.pdf`)

**What it shows:** A line chart. The x-axis is birth cohort; the y-axis is the observed standard deviation of `age_diff`. Each country is shown as a separate coloured line.

**Purpose:** A compact summary of the dispersion trends shown in detail in Figure 14. Allows direct comparison of SD trends across the eight spotlight countries in one view.

**How to interpret:**
- Lines declining from left to right indicate decreasing within-country dispersion over generations.
- Lines remaining flat indicate stable dispersion.
- Lines crossing each other indicate that countries are changing at different rates.
- A country whose line starts high (large SD in old cohorts) but falls sharply is converging rapidly toward lower dispersion.

**What to look out for:** Compare the ordering of countries by SD level in Figure 18 with their ordering by mean in Figure 17. Check whether the country with the most rapid decline in SD is among those with the largest initial gap.

---

## Part 5: Model Diagnostics (Figures D1–D9)

Diagnostic figures are produced by `code/multivariate_advanced.R` and saved in `results/` with the prefix `figD`. They assess whether the model assumptions are satisfied. Poor diagnostics do not necessarily invalidate results, but they should be reported and discussed.

---

### Figure D1 — Residuals vs. Fitted (M2) (`results/figD1_resid_vs_fitted_m2.pdf`)

**What it checks:** Whether the model residuals are randomly scattered around zero across the full range of fitted values, or whether there is a systematic pattern.

**How to read it:** The x-axis is the fitted (predicted) value; the y-axis is the Pearson (standardised) residual. The dashed horizontal line marks zero. A loess smoother (red curve) shows the average residual at each fitted value.

**What a good diagnostic looks like:** Points scatter randomly around zero; the red smoother is flat and near zero across the entire range of fitted values.

**What to look out for:** A curved smoother (e.g., U-shape or inverted-U) suggests model misspecification — a non-linear cohort effect may be needed. A fan-shaped pattern (widening spread at higher or lower fitted values) suggests remaining heteroskedasticity that the `varIdent` structure has not fully captured. Systematic negative residuals at one end of the x-axis indicate the model underestimates the mean for those cases.

---

### Figure D2 — Q-Q Plot of Residuals (M2) (`results/figD2_qq_m2.pdf`)

**What it checks:** Whether the standardised residuals follow an approximate normal distribution.

**How to read it:** Each point represents one observation. The x-axis is the quantile expected from a standard normal; the y-axis is the actual quantile from the data. Points that fall on the diagonal red line indicate that the residuals are normally distributed.

**What a good diagnostic looks like:** Points follow the diagonal line closely, especially in the middle range.

**What to look out for:** Heavy tails (points curving away from the line at both ends) indicate that the residuals have more extreme values than a normal distribution — more kurtosis. This is very common with age-gap data because a minority of couples have very large gaps. Right-skew (points above the line at the right end) indicates positive skewness in residuals. Some departure from normality is acceptable, especially at the tails, but the degree of departure should be noted.

---

### Figure D3 — Residual Spread by Cohort (M2) (`results/figD3_resid_by_cohort_m2.pdf`)

**What it checks:** Whether the `varIdent` correction successfully equalised residual variance across cohort groups.

**How to read it:** Box plots of standardised residuals, one box per birth cohort. If `varIdent` worked well, all boxes should have approximately the same width (spread).

**What a good diagnostic looks like:** All boxes have similar interquartile range and similar whisker length.

**What to look out for:** If one cohort's box is noticeably wider than others, the `varIdent` did not fully capture that cohort's extra variance — perhaps the distribution is non-normal in that cohort, or there are additional sources of heteroskedasticity. Differences in box medians across cohorts indicate remaining mean effects not captured by the fixed effects.

---

### Figure D4 — Residual Distribution (M2) (`results/figD4_resid_hist_m2.pdf`)

**What it checks:** Overall shape of the standardised residuals, compared to a standard normal curve.

**How to read it:** A histogram of standardised residuals with a standard normal density curve overlaid in red.

**What a good diagnostic looks like:** The histogram bars roughly track the red normal curve, with the peak near zero and symmetric tails.

**What to look out for:** A peak that is much taller and narrower than the normal curve indicates leptokurtosis (heavier-than-normal tails). A flatter histogram indicates platykurtosis. A shift of the peak away from zero indicates a systematic bias. Multiple humps (bimodality) would suggest distinct subgroups in the residuals.

---

### Figures D5–D7 — Diagnostics for M3 (Variance by Country)

These three figures mirror D1, D2, and D3 but for M3.

- **D5** (`results/figD5_resid_vs_fitted_m3.pdf`): Residuals vs. fitted for M3. Same interpretation as D1.
- **D6** (`results/figD6_qq_m3.pdf`): Q-Q plot for M3. Same interpretation as D2.
- **D7** (`results/figD7_resid_by_country_m3.pdf`): Residual spread by country for M3. Same interpretation as D3 but for countries instead of cohorts. One box per country, sorted by residual SD. After the `varIdent` correction, all boxes should have similar spread.

**Additional note for D7:** Because there are many countries (~40), this is a horizontal box plot to keep it readable. Countries sorted toward the right (larger residual SD) may indicate that the `varIdent` correction underfits those countries' variance.

---

### Figure D8 — Q-Q Plot of Country Random Effects (M3) (`results/figD8_qq_random_effects.pdf`)

**What it checks:** Whether the country-level random intercepts (BLUPs) are approximately normally distributed. The mixed-effects model assumes that random effects are drawn from a normal distribution.

**How to read it:** Same Q-Q plot format as D2, but with only ~40 points (one per country). Each point is the estimated BLUP for one country.

**What a good diagnostic looks like:** With only ~40 points, the line will never fit perfectly. Look for gross departures — very heavy tails (extreme outliers), strong skew, or clustering that suggests discrete groups rather than a continuous normal distribution.

**What to look out for:** With few countries (compared to thousands of individuals) the Q-Q plot has limited resolution. A few points off the line at the tails are expected and do not necessarily invalidate the analysis. If the random effects span a very wide range and show clear skew, the normality assumption for random effects may be questionable and sensitivity analyses using different model specifications would be advisable.

---

### Figure D9 — Observed vs. Model-Implied Distributions (`results/figD9_observed_vs_predicted.pdf`)

**What it checks:** For six selected countries (Sweden, United States, Brazil, India, Nigeria, Mali), whether the observed age-gap distribution (grey area) is well approximated by the model-implied normal distribution (red curve).

**How to read it:** Each panel is one country. The grey shaded area is the observed kernel density estimate. The red line is the normal distribution with the mean and SD estimated by M3 for that country.

**What a good diagnostic looks like:** The red line tracks the grey area closely — peaks at the same location, similar width, and neither too narrow nor too wide.

**What to look out for:**
- If the red curve is narrower than the grey area, the model underestimates variance for that country.
- If the grey area has a prominent right tail that the red curve misses, there are more very-large-gap couples than the normal model predicts (right-skewed residuals).
- If the grey area is bimodal (two humps) while the red curve has one peak, the normal assumption fails for that country — possibly due to distinct subgroups (e.g., different ethnic or religious communities with different norms).
- Age heaping (spikes at multiples of 5 in the grey area) does not affect the red curve, so a spiky grey area with a smooth red curve is not a model failure — it reflects data limitations.

---

## Part 6: Numeric Diagnostic Summaries (printed to R console)

Beyond the figures, three numeric tables are printed to the console during execution of `code/multivariate_advanced.R`.

### Standardised Residual Summary Table

**What it shows:** For each model (M1, M2, M3), the mean, standard deviation, skewness, and kurtosis of the Pearson-standardised residuals.

**Target values for a well-fitting model:**
- `Mean` ≈ 0 (no systematic bias)
- `SD` ≈ 1 (standardisation is working; each residual is divided by its estimated stratum SD)
- `Skewness` ≈ 0 (symmetric)
- `Kurtosis` ≈ 3 (normal distribution has kurtosis 3; values above 3 mean heavier tails than normal)

**What to look out for:** A large improvement in SD from M1 to M2 or M3 indicates the heteroskedastic model better captures the scale of residuals. A kurtosis substantially above 3 (common for age-gap data with a heavy right tail) signals that the normal assumption is imperfect. This should be acknowledged in any write-up.

### SD of Standardised Residuals by Cohort (M2) and by Country (M3)

**What they show:** For M2, the SD of standardised residuals within each cohort group. For M3, the SD within each country. Target value is 1 for each group.

**What to look out for:** Groups where the SD deviates substantially from 1 (e.g., SD > 1.5 or SD < 0.5) are groups where the `varIdent` correction did not adequately capture the variance. This could indicate a non-normal residual distribution within that group, a group with very few observations, or a genuine model misspecification.

---

## Quick Reference: Which File Produces Which Output

| Output | Produced by | File prefix |
|--------|------------|-------------|
| Table 1 (overall) | `code/descriptive.do` | `table1_overall` |
| Table 2 (by country) | `code/descriptive.do` | `table2_by_country` |
| Table 3 (by cohort) | `code/descriptive.do` | `table3_by_cohort` |
| Table 4 (mean, country × cohort) | `code/descriptive.do` | `table4_mean_by_country_cohort` |
| Table 5 (SD, country × cohort) | `code/descriptive.do` | `table5_sd_by_country_cohort` |
| Table 6 (N, country × year) | `code/descriptive.do` | `table6_n_by_country_year` |
| Figure 1 (histogram) | `code/descriptive.do` | `fig1_histogram` |
| Figure 2 (caterpillar, median/IQR) | `code/descriptive.do` | `fig2_caterpillar` |
| Figure 3 (ridgeline, by country) | `code/descriptive.R` | `fig3_ridgeline` |
| Figure 4 (ridgeline, by cohort) | `code/descriptive.R` | `fig4_ridgeline_cohort` |
| Figure 5 (mean and SD, cohort trends) | `code/descriptive.do` | `fig5_cohort_mean_sd` |
| Figure 6 (variance decomposition) | `code/descriptive.R` | `fig6_variance_decomposition` |
| Figure 7 (heatmap, SD) | `code/descriptive.R` | `fig7_heatmap_sd` |
| Figure 8 (wife older, heatmap + trends) | `code/descriptive.R` | `fig8_wife_older` |
| Figure 9 (mean vs. SD scatter) | `code/descriptive.do` | `fig9_mean_vs_sd` |
| Figure 10 (mean and SD, by country) | `code/descriptive.do` | `fig10_mean_sd_country` |
| Figure 11 (model SD by cohort) | `code/multivariate_basic.R` | `fig11_predicted_sd_cohort` |
| Figure 12 (model mean by cohort) | `code/multivariate_basic.R` | `fig12_predicted_mean_cohort` |
| Figure 13 (model-implied densities) | `code/multivariate_basic.R` | `fig13_model_implied_densities` |
| Figure 14 (country-level sigma) | `code/multivariate_advanced.R` | `fig14_country_sigma_re` |
| Figure 15 (country random intercepts) | `code/multivariate_advanced.R` | `fig15_country_mu_re` |
| Figure 16 (mean vs. variance, RE) | `code/multivariate_advanced.R` | `fig16_mean_vs_variance_re` |
| Figure 17 (country density evolution) | `code/multivariate_advanced.R` | `fig17_country_density_evolution` |
| Figure 18 (country SD trends) | `code/multivariate_advanced.R` | `fig18_country_sd_trends` |
| Figure 19 (country × cohort variance) | `code/multivariate_advanced.R` | `fig19_country_cohort_variance` |
| Diagnostics D1–D9 | `code/multivariate_advanced.R` | `figD1`–`figD9` |
| Models M1–M5, AIC table, LRT | `code/multivariate_basic.R` | — |

---

*Last updated: see git history for revision dates.*
