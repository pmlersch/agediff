"""
Generate a reference table of all IPUMS International country-year samples.

Produces a CSV with every known country-year combination available from
IPUMS International (ipumsi), including IPUMS numeric country codes,
ISO two-letter sample prefixes, and sample IDs.

Source: IPUMS International (https://international.ipums.org)
Coverage: 104 countries, 500+ census/survey samples
Last updated: 2026-02
"""

import csv

# Each entry: (ipums_country_code, country_name, sample_prefix, [years])
# ipums_country_code = IPUMS numeric COUNTRY code
# sample_prefix = two-letter code used in sample IDs (e.g., "ar" -> ar1970a)
# years = list of census/survey years with available microdata samples

IPUMS_SAMPLES = [
    (32,  "Argentina",            "ar", [1970, 1980, 1991, 2001, 2010]),
    (51,  "Armenia",              "am", [2001, 2011]),
    (40,  "Austria",              "at", [1971, 1981, 1991, 2001, 2011]),
    (50,  "Bangladesh",           "bd", [1991, 2001, 2011]),
    (112, "Belarus",              "by", [1999, 2009]),
    (204, "Benin",                "bj", [1979, 1992, 2002, 2013]),
    (68,  "Bolivia",              "bo", [1976, 1992, 2001, 2012]),
    (72,  "Botswana",             "bw", [1981, 1991, 2001, 2011]),
    (76,  "Brazil",               "br", [1960, 1970, 1980, 1991, 2000, 2010]),
    (854, "Burkina Faso",         "bf", [1985, 1996, 2006]),
    (116, "Cambodia",             "kh", [1998, 2004, 2008, 2013, 2019]),
    (120, "Cameroon",             "cm", [1976, 1987, 2005]),
    (124, "Canada",               "ca", [1971, 1981, 1991, 2001, 2011]),
    (152, "Chile",                "cl", [1960, 1970, 1982, 1992, 2002, 2017]),
    (156, "China",                "cn", [1982, 1990, 2000]),
    (170, "Colombia",             "co", [1964, 1973, 1985, 1993, 2005]),
    (188, "Costa Rica",           "cr", [1963, 1973, 1984, 2000, 2011]),
    (384, "Cote d'Ivoire",        "ci", [1988, 1998]),
    (192, "Cuba",                 "cu", [2002, 2012]),
    (208, "Denmark",              "dk", [1787, 1801, 1845, 1880, 1885]),
    (214, "Dominican Republic",   "do", [1960, 1970, 1981, 2002, 2010]),
    (218, "Ecuador",              "ec", [1962, 1974, 1982, 1990, 2001, 2010]),
    (818, "Egypt",                "eg", [1848, 1868, 1986, 1996, 2006]),
    (222, "El Salvador",          "sv", [1992, 2007]),
    (231, "Ethiopia",             "et", [1984, 1994, 2007]),
    (242, "Fiji",                 "fj", [1966, 1976, 1986, 1996, 2007, 2014]),
    (246, "Finland",              "fi", [2010]),
    (250, "France",               "fr", [1962, 1968, 1975, 1982, 1990, 1999, 2006, 2011]),
    (276, "Germany",              "de", [1970, 1971, 1981, 1987]),
    (288, "Ghana",                "gh", [1984, 2000, 2010]),
    (300, "Greece",               "gr", [1971, 1981, 1991, 2001, 2011]),
    (320, "Guatemala",            "gt", [1964, 1973, 1981, 1994, 2002]),
    (324, "Guinea",               "gn", [1983, 1996, 2014]),
    (332, "Haiti",                "ht", [1971, 1982, 2003]),
    (340, "Honduras",             "hn", [1961, 1974, 1988, 2001, 2013]),
    (348, "Hungary",              "hu", [1970, 1980, 1990, 2001, 2011]),
    (352, "Iceland",              "is", [1703, 1729, 1801, 1901]),
    (356, "India",                "in", [1983, 1987, 1993, 1999, 2004, 2009]),
    (360, "Indonesia",            "id", [1971, 1976, 1980, 1985, 1990, 1995, 2000, 2005, 2010]),
    (364, "Iran",                 "ir", [2006, 2011]),
    (368, "Iraq",                 "iq", [1997]),
    (372, "Ireland",              "ie", [1971, 1979, 1981, 1986, 1991, 1996, 2002, 2006, 2011, 2016]),
    (376, "Israel",               "il", [1972, 1983, 1995, 2008]),
    (380, "Italy",                "it", [2001, 2011]),
    (388, "Jamaica",              "jm", [1982, 1991, 2001]),
    (400, "Jordan",               "jo", [2004]),
    (404, "Kenya",                "ke", [1969, 1979, 1989, 1999, 2009, 2019]),
    (417, "Kyrgyz Republic",      "kg", [1999, 2009]),
    (418, "Laos",                 "la", [1995, 2005, 2015]),
    (426, "Lesotho",              "ls", [1996, 2006]),
    (430, "Liberia",              "lr", [1974, 2008]),
    (454, "Malawi",               "mw", [1987, 1998, 2008, 2018]),
    (458, "Malaysia",             "my", [1970, 1980, 1991, 2000]),
    (466, "Mali",                 "ml", [1987, 1998, 2009]),
    (480, "Mauritius",            "mu", [1990, 2000, 2011]),
    (484, "Mexico",               "mx", [1960, 1970, 1990, 1995, 2000, 2005, 2010, 2015, 2020]),
    (496, "Mongolia",             "mn", [1989, 2000, 2010, 2020]),
    (504, "Morocco",              "ma", [1982, 1994, 2004, 2014]),
    (508, "Mozambique",           "mz", [1997, 2007, 2017]),
    (104, "Myanmar",              "mm", [2014]),
    (524, "Nepal",                "np", [2001, 2011]),
    (528, "Netherlands",          "nl", [1960, 1971, 2001]),
    (558, "Nicaragua",            "ni", [1971, 1995, 2005]),
    (566, "Nigeria",              "ng", [2006, 2007, 2008, 2009, 2010]),
    (578, "Norway",               "no", [1801, 1865, 1876, 1900, 1910]),
    (586, "Pakistan",             "pk", [1973, 1981, 1998]),
    (591, "Panama",               "pa", [1960, 1970, 1980, 1990, 2000, 2010]),
    (600, "Paraguay",             "py", [1962, 1972, 1982, 1992, 2002]),
    (604, "Peru",                 "pe", [1993, 2007, 2017]),
    (608, "Philippines",          "ph", [1990, 2000, 2010]),
    (616, "Poland",               "pl", [2002, 2011]),
    (620, "Portugal",             "pt", [1981, 1991, 2001, 2011]),
    (630, "Puerto Rico",          "pr", [1970, 1980, 1990, 2000, 2005, 2010, 2015, 2020]),
    (642, "Romania",              "ro", [1977, 1992, 2002, 2011]),
    (643, "Russia",               "ru", [2002, 2010]),
    (646, "Rwanda",               "rw", [1991, 2002, 2012]),
    (686, "Senegal",              "sn", [1988, 2002, 2013]),
    (694, "Sierra Leone",         "sl", [2004, 2015]),
    (703, "Slovak Republic",      "sk", [1991, 2001, 2011]),
    (705, "Slovenia",             "si", [2002]),
    (710, "South Africa",         "za", [1996, 2001, 2007, 2011, 2016]),
    (728, "South Sudan",          "ss", [2008]),
    (724, "Spain",                "es", [1981, 1991, 2001, 2011]),
    (736, "Sudan",                "sd", [2008]),
    (740, "Suriname",             "sr", [2004, 2012]),
    (752, "Sweden",               "se", [1880, 1890, 1900, 1910]),
    (756, "Switzerland",          "ch", [1970, 1980, 1990, 2000, 2011]),
    (834, "Tanzania",             "tz", [1988, 2002, 2012]),
    (764, "Thailand",             "th", [1970, 1980, 1990, 2000]),
    (780, "Trinidad and Tobago",  "tt", [1970, 1980, 1990, 2000, 2011]),
    (792, "Turkey",               "tr", [1985, 1990, 2000]),
    (800, "Uganda",               "ug", [1991, 2002, 2014]),
    (804, "Ukraine",              "ua", [2001]),
    (826, "United Kingdom",       "gb", [1961, 1971, 1991, 2001]),
    (840, "United States",        "us", [1960, 1970, 1980, 1990, 2000, 2005, 2010, 2015, 2020]),
    (858, "Uruguay",              "uy", [1963, 1975, 1985, 1996, 2006, 2011]),
    (862, "Venezuela",            "ve", [1971, 1981, 1990, 2001]),
    (704, "Vietnam",              "vn", [1989, 1999, 2009, 2019]),
    (894, "Zambia",               "zm", [1990, 2000, 2010]),
    (716, "Zimbabwe",             "zw", [2012]),
]


def generate_table():
    """Generate a flat country-year table with sample metadata."""
    rows = []
    for country_code, country_name, prefix, years in IPUMS_SAMPLES:
        for year in sorted(years):
            # Construct IPUMS sample ID: two-letter prefix + 4-digit year + "a"
            sample_id = f"{prefix}{year}a"
            rows.append({
                "country_code": country_code,
                "country_name": country_name,
                "sample_prefix": prefix,
                "year": year,
                "sample_id": sample_id,
            })
    return rows


def main():
    rows = generate_table()

    outpath = "data/ipums_country_year_table.csv"
    fieldnames = [
        "country_code",
        "country_name",
        "sample_prefix",
        "year",
        "sample_id",
    ]

    with open(outpath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    # Print summary
    countries = sorted(set(r["country_name"] for r in rows))
    print(f"Wrote {len(rows)} country-year records to {outpath}")
    print(f"Countries: {len(countries)}")
    print(f"Year range: {min(r['year'] for r in rows)}-{max(r['year'] for r in rows)}")
    print()
    print("Samples per country:")
    for c in countries:
        n = sum(1 for r in rows if r["country_name"] == c)
        yrs = sorted(r["year"] for r in rows if r["country_name"] == c)
        print(f"  {c}: {n} samples ({', '.join(str(y) for y in yrs)})")


if __name__ == "__main__":
    main()
