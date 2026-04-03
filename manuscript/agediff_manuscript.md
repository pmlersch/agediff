---
title: "Variance in the Age Difference in Different-Sex Marriage across Time And Contexts"
author: "Philipp M. Lersch (plersch@diw.de)"
date: "March 2026"

bibliography: agediff_references.bib
link-citations: true
csl: american-sociological-review.csl   # swap for your preferred style

output:
  word_document:
    toc: true
    fig_caption: true
  pdf_document:
    latex_engine: xelatex
  html_document:
    toc: true
---

<!-- Compile with:  pandoc agediff_manuscript.md --citeproc -o agediff_manuscript.docx -->
<!-- or:           pandoc agediff_manuscript.md --citeproc -o agediff_manuscript.pdf  -->


## Open issues

- current marriage or first marriage
- marriage vs cohabitation: partner age gap vs marriage age gap

## Introduction

age homogamous or age-similar = roughly similar age

age heterogamous or age-dissimilar = substantially different age
age hypergamy = men older

Choosing a romantic partner is often considered to be a highly personal decision driven by love and maybe a bit of circumstance. However, across time and contexts, clear patterns emerge in partner selection. One such pattern is the age difference between spouses, where men are often older than women. This has been considered a universal law of human mating. Next to gender, age is one of the most critical characteristics determining partner choice. World-wide, the age gap in current unions is more than 4 years, substracing women's age from men's age. However systematic evidence on how normative this pattern is, how it varies across contexts and over time is limited.

The age difference in marriage is important for several reasons. First, it is related to power differences where the older partner is more powerful. Second, it affects shared lifespan of partners and planning for old age. Third, the age difference affects reproductive behavior. Importantly, men's reproductive capacity also decreases with age. Fourth, the age difference is a important window into social norms and cultural expectations regarding marriage and romantic partnerships. In this regard, information about norms are also instructive to understand partner markets and potential marriage squeezes.

- mortality
- risk of divorce

These reasons are also highly policy relevant. Marriage squeezes may radicalize young men. Age differences affect shared lifespan and has important implications for informal care giving. Power differences in couples may affect health and well-being. Fertility has important implications for economic development and the sustainability of welfare systems.

Finally, extreme case of child marriage.

Previous research on the age difference is limited, because, first, it is focused on the mean difference [@ausubelMeasuringAgeDifferences2022; @wilsonAgeDifferencesMarriage2008; @kleinAltersunterschiedZwischenEhepartnern1996] obscuring how tightly age differences cluster around this mean. Studying the variance of the age difference, and not only the mean, provides the opportunity to better understand how normative the age difference is.

Imagine a totalitarian society where women are by law forced to marry at age 18 and men at age 20. In contrast, imagine an alternative, liberal society where a similar two-year age difference at marriage is observed but with many couples having large deviations from this mean. In the first society, the age difference is highly normative, while in the second society, the age difference is not normative at all. Thus, studying only the mean obscures how normative the age difference is.

Studying the variance also allows to understand how the normativity of the age difference has changed over time. For example, in a society where the mean age difference is 2 years, but the variance has increased over time, it can be inferred that the normativity of the age difference has decreased over time, even though the mean has remained constant.

Studying the variance beyond mean also directs attention to women with older partners at the left of the age difference distribution.

Second, it is unclear how this normativity varies across societal contexts, limiting our understanding of cross-national variation. Third, it is unclear how the normativity has changed over time, indexed by marriage cohorts, limiting our understanding of long-term trends.

The current study aims to fill this gap by systematically studying the variance of the age difference in marriage across a large number of countries and over time. The study addresses the following question: How varied is the age difference in opposite-sex, married couples within countries and birth cohorts? Or in other words, how universal is a age difference in marriage?

I study age differences in all current marriages at the time of the survey, irrespective of the marriage order. I focus on marriage because it is a highly institutionalized form of partnership and thus more likely to be influenced by social norms than cohabitation. However, I also consider cohabitation in a robustness check. 

Age difference in current marriage is more relevant for people than age difference in first marriage alone.

Because I study current marriage and variation across birth cohorts, a number of processes contribute to differences in the age difference across marriage cohorts. First, selection into and out of (re-)marriage. Second, changes in the age difference at first marriage. Third, changes in the age difference in re-marriages. 

Following an individual over time, she will not be in my sample before she enters her first coresidential union. Once she separates before repartnering, she will not be included. Once her partner dies, she will also be omitted. 

Changes in the age difference in marriage can come about when typical behavior in both genders change. For example, women may partner later while men do not change, reducing the gap. Or men may partner earlier while women do not change, again reducing the gap. Or both may change but at different rates. 


I consider birth cohorts informative because they are more likely to be influenced by similar social norms and historical events than marriage cohorts. For example, the same birth cohort may have been exposed to the same war, economic crisis, or social movement during their formative years, which may have shaped their attitudes and behaviors regarding partner selection and age differences in marriage. In contrast, marriage cohorts may be more heterogeneous in terms of their exposure to social norms and historical events, as they can include individuals from different birth cohorts who may have different experiences and attitudes towards age differences in marriage. Furthermore, focusing on birth cohorts allows to capture heterogenous effects of timing of first marriage and re-marriage across birth cohorts. Practically, focusing on birth cohorts also allows to include much more data because information on marriage entry is less prevalent.

The empirical investigation is guided by the expectation that there is variance and that this variance has changed. There are two main explanations for why the age difference emerges in the first place. Biological for mating. Age at puberty different for women and men. Also increasingly younger ages. However, humans seem to be the only specy for which such a systematic age difference exists (NOT TRUE!). Thus, social explanations seem more plausible. This is even more so because of the historical and contextual variation in age differences observed in prior scholarship.

Social explanations point to combination of individual behavior and social structures. Norms in patriarchic socities. Socialization. Gender equaly societies will not be characterized by all couples matching on age. Instead high variance in age difference which may be obscured in mean age difference. Exchange income vs attractiveness. Also availability in partner market relevant (e.g., war reduces available men at marriage age so that different age differences result). In the extreme, not a single marriage may show the mean age difference. Norms, of course, can vary by social groups.

We draw on the social-demographic theory of conjunctural action as a theoretical orientation for our study (Johnson-Hanks et al. 2011). The theory of conjunctural action suggests that vital events such as entry into cohabitation, marriage, and birth are the product of social action in conjunctures, i.e., bounded, temporary constellations of social structure with an inherent action potential. Social structures consist of two sets of interrelated elements, enabling and mutually reinforcing each other. First, schemas, such as ideas and values, are abstract (and often unconscious) ways of perception and action to make sense of the social world. Second, materials such as objects, behaviors, and legal institutions are sedimentations of schemas in the observable world. Notably, materials have two functions: they are action resources, and they convey schemas. A material’s value is relational to other schemas and materials. Individuals draw on schemas and materials to interpret and resolve conjunctures. Schemas and materials are unequally distributed between individuals and lumpy across social groups [@johnson-hanksTheoryConjuncturalAction2011].

Over time, the age difference may have decreased because of increasingly gender equal norms across many societies. Part of this is also increasing educational attainment for women, now often surpassing men, and women's older age at first marriage. However, given the stall of the gender revolution and a backclash against gender equality in more recent years, a leveling off of the trend may be expected.

I also expect that the normativity varies systematically across countries, with the weakest normativity in gender equal socities and the strongest normativity in highly gender-unequal socities.

To provide evidence on the normativity of the age difference in marriage, I analyze data from the IPUMS International database [@rugglesIntegratedPublicUse2025]. The data, which is the largest collection of demographic statistics on marriage in the world drawing on national censuses, administrative registers, and survey data, cover a large number of countries and time periods, allowing for a comprehensive analysis of cross-national and temporal variation in the age difference in marriage. In total, I observe XX,XXX,XXX marriages in my data from XX countries and territories covering the period from 19XX to 20XX. I match gender equality and economic development data at the country-cohort level to the marriages.

The results confirm some findings of recent scholarship, extend others, and make discoveries unanticipated by previous literature. First, the mean age difference observed in prior research masks considerable variation in the age difference within countries and marriage cohorts. While some countries exhibit a tight clustering around the mean age difference, others show a wide dispersion, indicating that the age difference is not a universal norm. On average, the middle 50% of couples in a country differ by about XX years from the mean age difference, with some countries exhibiting a much larger spread. Noteably, on average, about XX percent of couples have a negative age difference, indicating older women pairing with younger men.

Second, overall, the normativity of the age difference has decreased over time, with the variance increasing in more recent marriage cohorts. This is evidence for a loosening of norms regarding the age difference in marriage.

Third, however, this trend is not uniform across all countries. Some countries have seen a significant increase in variance, while others have experienced little change or even an decrease in variance, suggesting that the normativity of the age difference is influenced by country-specific factors.

Taken together, this study provides a comprehensive analysis of the variance in the age difference in marriage across countries and over time. The findings challenge the notion of a universal norm regarding the age difference in marriage and highlight the importance of considering variance, in addition to mean differences, when studying partner selection patterns.


## Results

In this study, I examine the age difference in current, different-sex marriage. The age difference is defined as husband's age minus wife's age. I consider all current marriages in the data irrespective of the marriage order including re-marriages. I differentiate marriages by birth cohort (10-year birth cohorts) and the country of residence (which must not be the country in which the marriage was concluded).

### Mean age difference by country and marriage cohort

Figure 1 shows mean age difference by country and marriage cohort. Across all countries and marriage cohorts, the mean age difference is always positive, indicting the husband is on average older than the wife. However, there is considerable variation in the mean age difference across countries and marriage cohorts. The figure shows clear differences in mean age difference by country. In some countries, such as Country A, the mean age difference is about X years, while in other countries, such as Country B, the mean age difference is about Y years. There are also clear trends over time with more recent marriage cohorts showing lower age differences.

### Dispersion in the age difference in marriage

Figure 2 shows the standard deviation of the age difference by country and marriage cohort. The figure shows considerable variation in the standard deviation across countries and marriage cohorts. In some countries, such as Country C, the standard deviation is about X years, while in other countries, such as Country D, the standard deviation is about Y years. There are also clear trends over time with more recent marriage cohorts showing larger standard deviations. The standard deviation can be used to compute the spread of the age difference. For example, in Country C, about 68% of couples have an age difference within X ± SD years, while in Country D, about 68% of couples have an age difference within Y ± SD years.

Figure 3 focusses on the marriage cohort 2010--2020 and shows the association between the mean difference (x-axis) and the standard deviation (y-axis) across countries. The figure suggests that larger age differences are going hand in hand with more normativity (smaller variance). Countries with large mean age differences also tend to have smaller standard deviations and IQRs. This suggests that in countries where larger age differences are more common, there is also more normativity in the appropriate age difference.

We can zoom in on the 10 most diverse countries in terms of their age differences and the 10 least diverse age difference countries using ridgeplots. This is shown in Figure 4.

Figure 5 complements the descriptive evidence presented so far by presenting results from mixed-effects location scale models. These models allow me to estimate how the mean and variance of the age difference vary by country and marriage cohort simultaneously while accounting for the nested structure of the data (marriages nested within countries). The models show that both the mean and variance of the age difference vary significantly by country and marriage cohort on conventional statistical confidence levels. Specifically, relative to cohort 1950--59, the predicted partner age difference is X years smaller in 1970--79 (β = −0.45, 95% CI [−0.60, −0.31], p < 0.001). The between-country SD of intercepts is 0.85 years, residual SD is 3.1 years. The model also allows me to estimate the intraclass correlation coefficient (ICC), which indicates how much of the total variance in the age difference is due to differences between countries. The results show that the ICC is about X%, indicating that a significant portion of the variance in the age difference is due to differences between countries. Country accounts for 7--10% of total variance for early cohorts, falling to 4% for later cohorts.

Countries A and B show 1.5--1.8× higher residual SD relative to the reference. Residual SD declines from 3.4 to 2.9 years across cohorts, indicating dispersion narrowed.

### Older women

A specific aspect of the variance in age differences is the share of women older than their partners. One interesting finding is that in some countries, a significant proportion of couples have a negative age difference, indicating that the wife is older than the husband. This is shown in Figure 6, which shows the proportion of couples with a negative age difference by country and marriage cohort. The figure shows considerable variation across countries and marriage cohorts. In some countries, such as Country E, about X% of couples have a negative age difference, while in other countries, such as Country F, only about Y% of couples have a negative age difference. There are also clear trends over time with more recent marriage cohorts showing higher proportions of couples with a negative age difference.



### Macro-level explanations

Finally, the statistical model allows me to estimate the association between the age difference in marriage and economic development as well as gender equality. The model suggests that economic development is associated with a decrease in the age difference in marriage but is not related to the dispersion in age difference. At the same time, the gender equality index is associated with a larger dispersion in the age differences but is not associated with the mean age difference.

### Individual-level explanations

I consider two additional and closely related individual level explanations for the age difference: women's education and women's age at marriage. Because the data on women's education is only available for a subsample in my data, I continue with a smaller set of countries and marriage cohorts.

### Same-sex marriage


## Discussion

Summary

Findings

Theoretical implications

Policy implications

Study limitations

Because dissolved marriages are excluded, variance in older cohorts is likely understated, making our estimates of the secular increase in dispersion conservative.

Key questions for future research


## Methods

### Data

IPUMS international [@rugglesIntegratedPublicUse2025]

See [@ausubelMeasuringAgeDifferences2022] for key measurement decisions.

ESS

ISSP: sex of partner is not surveyed, so I cannot exclude same-sex partners

DHS: DHS only covers women 15–49 in developing countries — a fundamentally different target population than the other three sources

weighting?

### Sample

I restrict to birth cohorts before 1990 to have sufficiently old respondents at survey time to have entered marriage. I also restrict to birth cohorts after 1920 to avoid small sample sizes and selectivity in early cohorts. I also restrict to countries with at least 100 marriages per cohort to ensure reliable estimates of the variance.

### Measurement

in polygamy, age difference is computed as the age of the husband minus the age of the first wife.

potential alternative outcome: singulate mean age at marriage (SMAM): difference between average age at first marriage for women and men (computed separately)

Heaping because of proxy responses at 0, 5, 10.  Heaping is concentrated in sources with proxy-reported partner age (ISSP, DHS) rather than household-grid birth year (ESS) or census (IPUMS).


#### Macro data

These indicators are highly correlated:

- Gender equality from United Nations Development Programme
- GDP: World Economic Outlook database from the International Monetary Fund

squeeze indicator

### Empirical Strategy

Mixed effects location scale models


## Acknowledgements

I thank Reinhard Schunck without whom this study would not have taken off.

The author wishes to acknowledge the statistical offices that provided the underlying data making this research possible: National Institute of Statistics and Censuses, Argentina; National Bureau of Statistics, Austria; Institute of Geography and Statistics, Brazil; Ministry of Statistics and Analysis, Belarus; Statistics Canada, Canada; National Institute of Statistics, Chile; National Bureau of Statistics, China; National Administrative Department of Statistics, Colombia; National Institute of Statistics and Censuses, Costa Rica; National Institute of Statistics and Censuses, Ecuador; Central Agency for Public Mobilization and Statistics, Egypt; National Institute of Statistics, Spain; National Institute of Statistics and Economic Studies, France; Ghana Statistical Services, Ghana; National Statistical Office, Greece; Central Statistical Office, Hungary; Central Bureau of Statistics, Israel; Central Organization for Statistics and Information Technology, Iraq; National Bureau of Statistics, Kenya; National Institute of Statistics, Cambodia; National Institute of Statistics, Geography, and Informatics, Mexico; Department of Statistics, Malaysia; Statistics Netherlands, Netherlands; Census and Statistics Directorate, Panama; National Statistics Office, Philippines; Central Bureau of Statistics, Palestine; National Institute of Statistics, Portugal; National Institute of Statistics, Romania; National Institute of Statistics, Rwanda; Bureau of Statistics, Uganda; Office of National Statistics, United Kingdom; Bureau of the Census, United States; National Institute of Statistics, Venezuela; General Statistics Office, Vietnam; Statistics South Africa, South Africa; National Statistical Service, Armenia; National Institute of Statistics, Bolivia; National Statistics Directorate, Guinea; National Institute of Statistics, Italy; Department of Statistics, Jordan; National Statistical Committee, Kyrgyzstan; National Statistical Office, Mongolia; Statistical Office of the Republic of Slovenia, Slovenia; Federal Statistical Office, Switzerland; Office of National Statistics, Cuba; Government Statistics Department, Saint Lucia; National Directorate of Statistics and Informatics, Mali; Central Bureau of Statistics, Nepal; National Institute of Statistics and Informatics, Peru; Statistics Division, Pakistan; U.S. Bureau of the Census, Puerto Rico; National Agency of Statistics and Demography, Senegal; National Statistical Office, Thailand; Bureau of Statistics, Tanzania; Statistical Centre, Iran; Central Statistics Office, Ireland; Statistical Institute, Jamaica; National Statistical Office, Malawi; Statistics Sierra Leone, Sierra Leone; Central Bureau of Statistics, Sudan; Department of Statistics and Censuses, El Salvador; BPS Statistics Indonesia, Indonesia; Department of Statistics, Morocco; National Institute of Information Development, Nicaragua; Turkish Statistical Institute, Turkey; National Institute of Statistics, Uruguay; Bangladesh Bureau of Statistics, Bangladesh; National Institute of Statistics and Demography, Burkina Faso; Central Bureau of Census and Population Studies, Cameroon; Bureau of Statistics, Fiji; Institute of Statistics and Informatics, Haiti; National Bureau of Statistics, South Sudan; National Statistics Office, Dominican Republic; Institute of Statistics and Geo-Information Systems, Liberia; State Committee of Statistics, Ukraine; Central Statistics Office, Zambia; Central Statistical Agency, Ethiopia; National Institute of Statistics, Mozambique; General Directorate of Statistics, Surveys, and Censuses, Paraguay; Central Statistics Office, Botswana; Central Statistics Office, Poland; Central Statistical Office, Trinidad and Tobago; Bureau of Statistics, Lesotho; National Institute for Statistics and Economic Analysis, Benin; National Institute of Statistics, Honduras; National Statistical Office, Papua New Guinea; National Statistics Agency, Zimbabwe; National Institute of Statistics, Guatemala; Statistics Bureau, Laos; National Institute of Statistics, Togo; Federal State Statistics Service, Russia; Statistics Finland, Finland; Ministry of Labour, Immigration and Population, Myanmar; Statistics Mauritius, Mauritius; General Bureau of Statistics, Suriname; Statistical Office of the Slovak Republic, Slovakia; National Institute of Statistics, Côte d'Ivoire; and Federal Statistical Office, Germany.


## References
