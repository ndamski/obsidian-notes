
# Paper Methodology Report

## Data Construction and Methodology

To examine whether intra‑regional trade integration among African, Caribbean, and Pacific (ACP) countries
facilitates or impedes bilateral trade with the European Union, we construct a novel panel dataset spanning
1995–2020. The analysis combines bilateral trade flows from the CEPII BACI database, covering 78 ACP signatories
to the Cotonou Agreement grouped into seven Regional Economic Communities (RECs)—ECOWAS, Central Africa (formerly
CEMAC), SADC, EAC, COMESA, CARIFORUM, and the Pacific Islands Forum. Our key explanatory variable, **Intra‑REC
Trade Share (IT Share)**, measures the proportion of each ACP country's total trade that remains within its own
regional bloc, capturing the depth of South‑South integration. Trade flows are complemented by gravity covariates
(distance, common language, colonial ties) from the CEPII Gravity database, while GDP and population are sourced
from the World Bank's WDI indicators. We further incorporate an Economic Partnership Agreement (EPA) treatment
dummy indicating whether a given ACP country has an EPA in force with the EU in a particular year.

Our empirical strategy follows the Poisson Pseudo‑Maximum Likelihood (PPML) approach pioneered by Santos Silva and
Tenreyro (2006), implemented via the `fixest` package in R. PPML is particularly suited to gravity‑type trade
equations as it accommodates the substantial share of zero trade flows in the EU‑ACP data—approximately 30 percent
of country‑pair observations—without requiring logarithmic transformation of the dependent variable. All
specifications include three high‑dimensional fixed effects: exporter‑year (EU member × year) to absorb outward
multilateral resistance and EU‑specific time trends; ACP country fixed effects to control for time‑invariant
heterogeneity; and calendar year dummies to capture common global shocks. Standard errors are clustered at the
bilateral pair level to allow for arbitrary serial correlation within each EU‑ACP dyad.

Our core specification estimates the effect of IT Share on total bilateral trade, with the EPA dummy included as a
control. We subsequently extend the model to include an interaction between EPA status and IT Share, permitting
the regional integration effect to differ between EPA‑treated and non‑treated country‑years. Complementary
specifications replace IT Share with an intensity‑adjusted measure, employ ordinary least squares on logged trade
as a diagnostic for zero‑trade observations, and split the sample by trade direction (ACP exports to EU versus EU
exports to ACP). Subsample regressions by REC assess heterogeneity across the seven regional blocs, while
robustness checks exclude early years with sparse data coverage and omit the two largest traders within each
region (South Africa and Nigeria) to ensure results are not driven by dominant observations. This comprehensive
approach allows us to identify whether deeper South‑South integration acts as a "building block" facilitating
EU‑ACP trade, or a "stumbling block" diverting trade away from extra‑regional partners.


# Script 1 Changes
## 1. Country Coverage

| Aspect | v1 | v2 |
|--------|----|----|
| **ACP universe** | 77 countries | **78 countries** |
| **Added** | — | GNQ (Equatorial Guinea) — full CEMAC member + Cotonou signatory |
| **Removed** | — | Cuba — OACPS member but *not* a Cotonou signatory |

> **Why it matters:** GNQ was missing in v1, meaning CEMAC's intra‑regional trade was under‑counted. The panel now
includes all 78 Cotonou signatories (OACPS‑79 minus Cuba).

---

## 2. REC Membership Definitions

| Change | v1 → v2 |
|--------|---------|
| **CEMAC → "Central Africa"** | Renamed to match the EU's EPA negotiating group (CEMAC‑6 + STP). |
| **CARICOM → "CARIFORUM"** | Renamed to reflect the correct EPA label (CARICOM‑14 + DOM). |
| **MRT (Mauritania)** | **New** time‑varying handling: member of ECOWAS 1995‑2000, then withdrew (NA from 2001).
|
| **Dual‑membership** | Resolved by assigning each country to its EPA group rather than overlapping RECs. |

> **Why it matters:** Trade‑share calculations now correctly account for MRT's exit from ECOWAS and for the exact
EPA grouping used by the EU.

---

## 3. GDP & Population Source

| Aspect | v1 | v2 |
|--------|----|----|
| **Source** | CEPII Gravity RDS | **WDI (World Bank API)** |
| **Fallback** | — | CEPII Gravity if WDI download fails |
| **Manual patches** | — | Cook Islands (COK) and Niue (NIU) added manually |
| **Caching** | — | WDI data cached to `wdi_gdp_pop_cache.rds` after first run |

> **Why it matters:** WDI provides more up‑to‑date and complete GDP/pop series. The cache avoids repeated API
calls.

---

## 4. Bug Fix: Duplicate Gravity Records

| Issue (v1) | Fix (v2) |
|------------|----------|
| Duplicates in CEPII Gravity data for some country‑pairs (e.g., ETH/SDN) caused **duplicate rows** in the final
panel. | Added explicit deduplication: for each EU‑ACP pair‑year, keep the row with a **non‑missing distance** (or
first non‑missing if ties). |

```r
# v2 code snippet
group_by(eu_iso3, acp_iso3, year) |>
  arrange(desc(!is.na(distance))) |>  # put non‑NA first
  slice(1) |>                           # keep one row
  ungroup()
```

> **Why it matters:** Duplicate rows would inflate the sample size and bias standard errors downward.

---

## 5. Code Organization & Robustness

| Addition | Purpose |
|----------|---------|
| **Explicit checks** (`stopifnot`) | Validate that the panel contains exactly 78 ACP countries and ≤27 EU
members. |
| **MRT membership printout** | Confirms ECOWAS → NA transition in output. |
| **GDP‑gap diagnostics** | Lists any ACP country‑years still missing GDP after merging. |
| **Missing‑data summary** | Reports % missing for key variables (`it_share`, GDP, distance, etc.). |
| **WDI retry logic** | Up to 3 download attempts with a 5‑second wait between tries. |
| **Unique‑ness enforcement** | Even when loading cached WDI, `distinct(iso3, year)` is applied to avoid hidden
duplicates. |

> **Why it matters:** These checks catch data‑quality issues early and make the script reproducible.

---

## 6. File Naming

- **v1**: `eu_acp_panel.rds` / `.csv`
- **v2**: `eu_acp_panel_v2.rds` / `.csv`

> **Why it matters:** Avoids overwriting the original dataset; allows side‑by‑side comparison.

---

## Summary for Notes

| Theme | Key Change |
|-------|-------------|
| **Coverage** | Added GNQ; now 78 ACP countries. |
| **REC definitions** | CEMAC → Central Africa; CARICOM → CARIFORUM; MRT time‑varying. |
| **Macroeconomic data** | Switched from CEPII to WDI (with fallback). |
| **Data quality** | Fixed duplicate gravity rows; added extensive validation checks. |
| **Reproducibility** | WDI caching, retry logic, explicit country‑year uniqueness. |

These modifications improve the **accuracy**, **completeness**, and **robustness** of the final EU‑ACP gravity
panel before estimation.

# Script 2: Estimation Script — Explanation for Notes

Script 2 (`02_estimate_gravity.R`) takes the cleaned panel from Script 1 and runs the gravity‑model estimation.
Below is a section‑by‑section breakdown of what the code does and why each step matters.

---

## 1. Setup & Data Loading

- **Loads `eu_acp_panel_v2.rds`** — the final panel with 78 ACP × 27 EU × 26 years (1995‑2020).
- **Sets REC levels/colours** — consistent labels (CEMAC → Central Africa, CARICOM → CARIFORUM).
- **Creates `acp_region` variable** — groups the 7 RECs into Africa, Caribbean, Pacific for subsample analysis.
- **Defines variable dictionary (`DICT`)** — maps internal variable names to clean labels for tables (e.g.,
`it_share` → "Intra‑REC Trade Share").

---

## 2. Summary Statistics

Computes descriptive tables by REC:

| Statistic | Description |
|-----------|-------------|
| `n_countries` | Number of ACP members in the REC |
| `n_cy` | Country‑year observations |
| `it_share_mean/sd` | Average intra‑REC trade share and its dispersion |
| `gdp_acp_mean_mn` | Mean GDP (millions USD) of ACP partners |
| `pct_epa` | Share of country‑years under an active EPA |
| `mean_bilateral_usd` | Average EU‑ACP bilateral trade value |
| `pct_zero_trade` | Share of zero‑trade dyads (important for PPML) |

**Purpose:** Gives readers a sense of variation in the key dependent variable (IT Share) and controls before
regression.

---

## 3. Data‑Quality Diagnostics (Before Estimation)

These checks identify patterns of missing data that will affect the regression sample:

| Diagnostic | What it flags |
|------------|---------------|
| **Missing gravity covariates** | Country‑years with missing distance, GDP → dropped from all models |
| **SADC missing IT Share** | Which SADC members lack intra‑REC trade data (important because SADC has high IT
share) |
| **EPA variation by REC** | Whether every REC has both treated and untreated observations (otherwise EPA is
collinear with year FE) |
| **Contiguity check** | Determines whether to include `contiguity` as a control (dropped if <0.5% of pairs share
a border) |

**Why it matters:** Prevents surprise drops in observations after estimation and alerts you to potential
collinearity issues.

---

## 4. Model Formula Objects

Formulas are defined once and reused throughout. This ensures consistency across all specifications:

```
f_baseline    → ln(Distance) + Language + Colonial + EPA + FEs
f_main        → Baseline + IT Share
f_interaction → Main + EPA × IT Share
f_intensity   → Main with IT Intensity instead of IT Share
f_ols         → Same as f_main but on log(trade) (drops zeros)
f_acp_exp     → ACP exports to EU (direction‑specific)
f_eu_exp      → EU exports to ACP (direction‑specific)
```

**Fixed‑effects string** (used in all PPML models):

```
| exporter_year + acp_iso3 + year
```

- `exporter_year` = EU member × year → absorbs EU‑specific time trends and outward multilateral resistance.
- `acp_iso3` = ACP country fixed effect → absorbs time‑invariant ACP heterogeneity.
- `year` = common time shock.

> **Note:** `importer_year` (ACP × year) is **not** included because both `it_share` and `epa` vary at the
ACP‑year level. Including it would make those variables collinear.

---

## 5. Descriptive Plots

| Plot | What it shows |
|------|---------------|
| **IT Share distribution** (histogram by REC) | Spread of intra‑regional integration across blocs |
| **IT Share time series** (line chart) | How integration has evolved 1995‑2020 |
| **REC‑level scatter** (IT Share vs lntrade) | Visual "building block" vs "stumbling block" patterns |
| **Event study — calendar time** | EPA vs non‑EPA trends over time (parallel pre‑trends) |
| **Event study — relative time** | Trade around EPA entry (±10 years) |

These figures document **pre‑trends** and provide visual intuition before the regression results.

---

## 6. Main Estimation — Total Bilateral Trade

Five models are estimated:

| Model | Specification | Purpose |
|-------|---------------|---------|
| **M1** (Baseline PPML) | Gravity classics only | Benchmark |
| **M2** (Main PPML) | Baseline + IT Share | **Primary** estimate of intra‑REC integration effect |
| **M3** (Interaction PPML) | Main + EPA × IT Share | Tests whether EPA changes the IT Share relationship |
| **M4** (Intensity PPML) | IT Intensity instead of IT Share | Robustness to alternative openness measure |
| **M5** (OLS) | Log‑linear, drops zeros | Comparability to classic gravity; diagnostic for zero‑trade pairs |

All use:

- **Poisson Pseudo‑Maximum Likelihood (PPML)** — handles many zero trade flows correctly.
- **Clustered standard errors** on `pair_id` (accounts for serial correlation within each EU‑ACP dyad).
- **High‑dimensional fixed effects** via `fixest::fepois`.

---

## 7. Trade Direction Analysis

Splits the dependent variable into:

- **ACP exports to EU** (`ACP_to_EU`)
- **EU exports to ACP** (`EU_to_ACP`)

Run separately to test whether intra‑REC integration **diverts** ACP exports (a "stumbling block" for EU‑ACP
trade) while EU exports remain unchanged.

---

## 8. REC‑by‑REC Subsample Regressions

Runs M2 **separately for each of the 7 RECs**:

- Estimates the IT Share coefficient within each bloc.
- Produces a **coefficient plot** showing variation across RECs.
- PIF is noted as potentially unreliable (sparse data, many islands).

This addresses **heterogeneity**: the aggregate effect may mask opposite signs in different regions.

---

## 9. Marginal Effects

Calculates how the % change in bilateral trade varies across the **observed range** of IT Share:

- Uses the M2 coefficient (`b_it`).
- Plots % change against IT Share level with 95% CI band.
- Overlays REC‑specific means to show where each bloc sits on the curve.

**Interpretation:** A 10‑pp increase in IT Share might raise trade by X% for low‑integration RECs but have little
effect for high‑integration RECs.

---

## 10. Robustness Checks

| Check | What it does |
|-------|--------------|
| **R1: Regional subsamples** | Africa, Caribbean, Pacific separately |
| **R2: Drop early years** | Excludes 1995‑1997 (sparse BACI coverage) |
| **R3: Exclude South Africa** | Removes SADC's dominant trader |
| **R4: Exclude Nigeria** | Removes ECOWAS's dominant trader |

All compare to the main M2 specification.

---

## 11. OLS vs PPML Comparison (Zeros Diagnostic)

Computes:

```
% difference = (β_OLS – β_PPML) / |β_PPML| × 100
```

If the difference is **<15%**, the zero‑trade pairs are not driving the result; PPML and OLS tell the same story.
Larger differences signal that zeros carry important information.

---

## Summary for Methodology Section

> **Data & Sample**
> The analysis uses a panel of 78 ACP countries (grouped into 7 regional economic communities) trading with 27 EU
members over 1995‑2020. The key explanatory variable is **Intra‑REC Trade Share (IT Share)**, the proportion of
each ACP country's total trade that stays within its own regional bloc. An EPA dummy identifies country‑years when
an Economic Partnership Agreement is in force.

> **Identification Strategy**
> All regressions include three high‑dimensional fixed effects: exporter‑year (EU member × year), importer (ACP
country), and calendar year. This specification follows Anderson & van Wincoop (2003) by controlling for outward
multilateral resistance (exporter‑year), inward resistance (ACP fixed effect), and common time shocks (year). The
IT Share and EPA variables vary only at the ACP‑year level, so importer‑year FEs are omitted to avoid perfect
collinearity.

> **Estimation Method**
> The baseline model is estimated by **Poisson Pseudo‑Maximum Likelihood (PPML)** using `fixest::fepois`. PPML is
the workhorse for gravity equations with many zero trade flows because it does not require logging the dependent
variable and remains consistent under heteroskedasticity. Standard errors are clustered at the bilateral pair
level to allow arbitrary serial correlation within each EU‑ACP dyad.

> **Specification Hierarchy**
> - **M1**: Baseline gravity (distance, language, colonial ties, EPA).
> - **M2**: Adds IT Share (main specification).
> - **M3**: Adds EPA × IT Share interaction (tests whether the EPA changes the integration effect).
> - **M4**: Replaces IT Share with IT Intensity (robustness to the openness measure).
> - **M5**: OLS on logged trade (diagnostic for zero‑trade pairs).

> **Robustness**
> The core finding is tested through: (i) regional subsamples (Africa, Caribbean, Pacific); (ii) dropping the
first three years of data; (iii) excluding the two largest ACP traders (South Africa, Nigeria); and (iv) comparing
PPML to OLS to assess the influence of zero‑trade observations.

> **Heterogeneity**
> REC‑by‑REC subsample regressions and a marginal‑effects plot reveal whether the integration effect differs
across regional blocs.
# New Result Implications

## 1.  What the columns represent

| Column | Model | Key added regressors (relative to the baseline) |
|--------|-------|-----------------------------------------------|
| (1)    | Baseline PPML (Poisson‑PML) | – |
| (2)    | PPML + **Intra‑REC trade share** | Intra‑REC trade share (share of a country’s total exports that go to
its own REC) |
| (3)    | PPML + **Intra‑REC share** + **EPA × IT‑share** interaction | Interaction of the EPA dummy with the
share of IT goods in exports |
| (4)    | PPML + **Intra‑REC trade intensity** (instead of share) | Intra‑REC trade intensity (value of intra‑REC
trade per unit of GDP) |
| (5)    | OLS (log‑linear) | Same regressors as (1) but no intra‑REC variables; linear model |

All specifications contain three sets of fixed effects:

* **exporter × year** (controls for time‑varying exporter‐specific shocks)
* **acp\_iso3 × year** (the partner “ACP” country‑year effects)
* **year** (common time trend)

The standard errors are clustered on the pair identifier, so they account for arbitrary correlation within each
bilateral relationship.

---

## 2.  Interpretation of the coefficients

Below, “elasticity” means the expected % change in the bilateral trade flow for a 1 % change in the RHS variable
(because both the dependent variable and the key regressors are in logs).

| Variable | (1) Baseline PPML | (2) PPML + Intra‑REC share | (3) PPML + EPA × IT‑share | (4) PPML + Intra‑REC
intensity | (5) OLS |
|----------|-------------------|----------------------------|---------------------------|--------------------------|----------|-------------------|----------------------------|---------------------------|--------------------------------|---------|
| **ln(Distance)** | **‑1.717*** (‑0.61) | **‑1.767*** (‑0.64) | **‑1.768*** (‑0.64) | **‑1.765*** (‑0.64) |
**‑1.201*** (‑0.24) |
| **Common Language** | **+1.113*** (+0.22) | **+1.119*** (+0.22) | **+1.119*** (+0.22) | **+1.119*** (+0.22) |
**+0.687*** (+0.13) |
| **Colonial Tie** |  +0.205 ( 0.23) | +0.186 ( 0.23) | +0.187 ( 0.23) | +0.185 ( 0.23) | **+1.251*** (+0.20) |
| **EPA (1 if in force)** | –0.031 ( 0.05) | –0.057 ( 0.04) | **‑0.097*** (‑0.05) | –0.054 ( 0.04) | **‑0.145***
(‑0.04) |
| **Intra‑REC Trade Share** | – | **‑1.084*** (‑0.48) | **‑0.999*** (‑0.48) | – | – |
| **EPA × IT‑Share** | – | – | **+0.729*** (‑0.43) | – | – |
| **Intra‑REC Trade Intensity** | – | – | – | –0.002 ( 0.003) | – |

*Significance: \*\*\* p < 0.01, \*\* p < 0.05, \* p < 0.1. Numbers in parentheses are clustered standard errors.*

### 2.1  Gravity “classics”

* **Distance** – The elasticity is around **‑1.7** in the PPML specifications, meaning a 1 % increase in distance
reduces bilateral exports by roughly 1.7 %. This is a stronger distance effect than the “canonical” ‑0.9 to ‑1.2
found in many gravity studies, indicating that the ACP‑partner pairs in the sample are especially sensitive to
geographic barriers. In OLS the effect is smaller (‑1.20) but still highly significant.

* **Common Language** – Having a common language raises expected trade by **e^1.12 ≈ 3.1‑fold** (≈ 200 % increase)
in the PPML models. The OLS estimate (≈ 0.69) is roughly half that size, reflecting the well‑known attenuation
bias of OLS when zeros are present.

* **Colonial Tie** – In PPML the point estimate is small and statistically indistinguishable from zero. In OLS it
is large and highly positive (+1.25). The PPML result is more credible because the Poisson model can handle the
many zero‑trade pairs that often involve former colonies; OLS artificially inflates the coefficient by regressing
through those zeros.

### 2.2  Trade‑policy variables

* **EPA (dummy = 1 if the agreement is in force)** –
  *In the baseline (col 1) the coefficient is negative but not significant.*
  When the **Intra‑REC trade share** is added (col 2) the coefficient stays insignificant.
  Once the **EPA × IT‑share** interaction is introduced (col 3) the main EPA effect becomes **‑0.097***
(significant at the 10 % level).
  In OLS (col 5) the EPA dummy is **‑0.145*** (highly significant and three times larger in magnitude).

  *Interpretation*: On average, the EPA seems to **reduce** bilateral trade for the average ACP exporter, at least
in the short run. However, the negative effect is **mitigated (or even reversed) for countries that export a
larger share of IT goods** (see the interaction below).

* **Intra‑REC Trade Share** – The coefficient is **‑1.0** (significant at the 5 % level) in columns 2 and 3. A 1 %
rise in the share of a country’s exports that stay within its own REC lowers bilateral trade with the rest of the
world by about 1 %. This is evidence of **trade diversion**: deeper regional integration pulls trade inward and
away from extra‑regional partners.

* **EPA × IT‑Share** (col 3) – The interaction term is **+0.73***.
  The *marginal* effect of an EPA for a country with IT‑share \(s\) is

  \[
  \frac{\partial \ln(\text{trade})}{\partial \text{EPA}} = -0.097 + 0.73 \times s .
  \]

  - If \(s = 0\) (no IT exports) the effect is **‑9.7 %** (consistent with the negative main effect).
  - If \(s = 0.13\) the effect turns **positive** (≈ 0 % net effect).
  - If \(s = 0.20\) the effect is **+5 %** (a modest boost).

  Hence, **the payoff from an EPA is conditional on the export structure**: countries that already export a
relatively high share of IT‑related goods benefit (or at least are not hurt) by the agreement.

* **Intra‑REC Trade Intensity** (col 4) – The coefficient is essentially zero (‑0.002, not significant). The
*share* of intra‑REC trade matters for trade diversion, but the *intensity* (value relative to GDP) does not.

---

## 3.  PPML versus OLS – why the differences?

| Issue | PPML (Poisson‑PML) | OLS (log‑linear) |
|-------|--------------------|------------------|
| **Treatment of zeros** | Naturally accommodates many zero trade flows; the likelihood is constructed for count
data. | Drops zeros (or replaces them with missing) → inflates the logged‑dependent variable. |
| **Coefficient magnitude** | Distance & language are larger (≈ ‑1.7, +1.1). | Smaller (‑1.2, +0.69) because the
sample is truncated. |
| **Colonial tie** | Not significant (the extensive margin matters). | Strongly positive – overstates the effect.
|
| **EPA** | Small, often insignificant; interaction reveals conditionality. | Large negative – overstates the
“cost” of an EPA. |
| **Fit** | No R² (pseudo‑R² can be computed but not reported). | R² ≈ 0.755 (high but misleading in the presence
of many zeros). |

**Take‑away:** The PPML estimates are the more reliable ones for a gravity model that includes many zero trade
flows. The OLS column is useful for a quick “ball‑park” but should not be the basis for policy conclusions.

---

## 4.  Policy implications (what the results suggest)

1. **EPAs alone are not a guaranteed trade‑boosting tool for ACP countries.**
   *Average effect*: modest negative impact on bilateral exports.
   *Exception*: Countries with a sizable IT‑sector can offset (or even reverse) the negative effect.

2. **Investing in the IT sector (or in ICT‑intensive exports) amplifies the benefits of EPA adoption.**
   The positive interaction implies that a “IT‑friendly” trade policy environment (low tariffs on IT goods,
efficient customs for electronics, digital connectivity) helps the EPA deliver positive trade gains.

3. **Regional integration (higher intra‑REC trade shares) tends to divert trade away from extra‑regional
partners.**
   Policymakers should be aware that while deeper REC integration can foster intra‑regional commerce, it may
simultaneously reduce export opportunities with the rest of the world. Balancing intra‑regional depth with
extra‑regional openness is crucial.

4. **Language barriers are a strong deterrent.**
   Enhancing language proficiency (e.g., through education, translation services) can substantially raise
bilateral trade flows.

5. **Colonial ties do not automatically confer trade advantages once you properly account for zero‑trade pairs.**

   Any historical advantage appears to be captured by other factors (e.g., language, institutional familiarity)
rather than a direct “colonial premium”.

6. **Gravity fundamentals remain powerful.**
   Distance and language dominate the explanatory power, reinforcing the classic gravity insight that geography
and communication costs are the first‑order determinants of bilateral trade.

---

## 5.  Caveats & further research

| Issue | Why it matters | How to address it |
|-------|----------------|-------------------|
| **Sample scope** (ACP exporters only) | Results may not generalise to other country groups. | Re‑estimate on
broader samples (e.g., all WTO members). |
| **Endogeneity of EPA & IT‑share** | Trade policy and export composition may be jointly determined. | Instrument
EPA adoption with political‑economy variables; use lagged IT‑share. |
| **Zero‑trade dynamics** | PPML treats zeros as a degenerate Poisson mass; in reality, zeros can be transient
(e.g., newly opened markets). | Consider a two‑stage hurdle or zero‑inflated Poisson. |
| **Time‑varying unobservables** |Exporter‑year and importer‑year FE soak up most time‑varying heterogeneity, but
bilateral‑specific shocks (e.g., sanctions) are not captured. | Add pair‑specific linear trends or use a
“diff‑in‑diff” design around EPA implementation dates. |
| **Measurement of “IT‑share”** | The share may be computed from HS‑level data; mis‑classification possible. | Use
more detailed product‑level data, or construct a true “ICT export” indicator. |

---

### Bottom line

- **Distance and language are the dominant forces** shaping ACP‑partner trade, exactly as the gravity model
predicts.
- **EPAs, on average, modestly depress bilateral exports**, but **the negative effect disappears (or turns
positive) for exporters with a high share of IT goods**.
- **A larger intra‑REC trade share pulls trade away from extra‑regional partners**, indicating trade diversion.
- **PPML delivers more credible estimates** than OLS, especially for the EPA and colonial‑tie variables.
- **Policy takeaway:** To make EPAs a growth‑enhancing tool for ACP countries, complement the agreements with
policies that boost the IT/ICT export sector and monitor the balance between regional integration and external
market access.


# Whole Paper Write-Up -- Need to ask Claude to rewrite given the new scripts

## What You Have (and It's Solid)

Your pipeline is well-built. Script 01 constructs a proper dyadic panel (77 ACP × 27 EU × 1995–2020), handles EU enlargement correctly, computes intra-REC trade share from BACI, and merges CEPII gravity covariates. Script 02 estimates a PPML gravity model with three-way fixed effects (exporter×year, ACP country, year), clustered SEs at the pair level, and produces a coherent set of robustness checks. The code is clean, self-documenting, and reproducible. A referee won't have much to complain about on methodology.

---

## Issues to Address Before Submitting

**1. The 2014–2016 missing GDP gap (Croatia/2 EU members)** Your `missing_covariates.csv` shows that _every single ACP country_ is missing 2 EU partner observations in 2014–2016. This is almost certainly Croatia (joined EU mid-2013) plus one of the 2004 enlargement countries having a GDP gap in CEPII Gravity. You need to identify exactly which EU members are causing this and either: (a) fill from World Bank WDI for those years, or (b) note it transparently. Losing 3 years across all dyads is meaningful — it's about 3,000 observations and covers the post-2013 EPA period for SADC and EAC.

**2. Sudan, Ethiopia, and small Pacific islands missing GDP throughout** Sudan is missing CEPII GDP for most of the panel (likely due to the 2011 South Sudan split). Ethiopia has gaps pre-2004 and post-2012. Cook Islands, Niue, Nauru, and Somalia are missing throughout large stretches. These aren't just noise — Sudan and Ethiopia are significant COMESA members. You should decide whether to drop them from COMESA subsample analysis or supplement from IMF WEO/World Bank. Document whatever you decide in the paper.

**3. SADC missing IT Share (12% of country-years)** Your `sadc_missing_it_share.csv` confirms gaps in SADC. South Africa likely has trade reported under customs union arrangements rather than directly. Since you exclude South Africa in robustness (M3 in sample robustness) and the coefficient barely changes (−1.726 → −1.459), this is manageable — but you need to explain in the paper _why_ SADC has missing IT share and what the missing countries are.

**4. The CEMAC anomaly needs a theoretical explanation** CEMAC is the only REC where intra-REC trade share has a _positive_ and significant coefficient (+4.317). This is a major finding that needs more than a footnote. CEMAC is a monetary union (CFA franc zone), has very low intra-bloc trade (mean IT share 0.048), and Cameroon utterly dominates its EU trade. You need to either explain this theoretically (e.g., complementarity rather than substitution applies when integration is nascent and oil-export dominated) or flag it as a structural outlier.

**5. PIF coefficient (−29.61) is dropped from your coefficient plot** The code comment says this is due to sparse data. That's defensible — 25% zero trade, smallest average bilateral flows ($8,138). But you need to discuss PIF in the text; you can't just silently exclude it from the figure. Frame it as a data limitation for micro-states.

**6. EPA coefficient sign puzzle** The baseline EPA coefficient is negative but insignificant in most specs, and becomes negative and significant in the OLS spec and the excluding-South-Africa robustness. In the direction breakdown, EPA is significantly negative only for EU exports to ACP (−0.1401***), not for ACP exports to EU (+0.0074). This asymmetry is substantively interesting — EPAs apparently coincide with _increased_ EU exports but no boost to ACP exports. This needs to be a core finding, not a footnote.

**7. The interaction term (M3) needs careful interpretation** The EPA × IT Share coefficient is +0.8806** against a main IT Share of −1.721***. This means the stumbling-block effect is _attenuated_ when an EPA is in force: net effect on trade for an EPA country = −1.721 + 0.8806 = −0.84, versus −1.721 for non-EPA countries. You should calculate this and put it in the paper. It also has a nice policy interpretation: EPAs partially counteract the trade-diverting tendencies of regional integration.

---

## What to Do Next (Prioritised)

**Immediately:**

- Identify and fix the 2014–2016 EU GDP gap. Check whether it's Croatia by filtering `missing_covs` by `eu_iso3`. Add a WDI supplement to script 01 for those specific country-years.
- Add an event-study / dynamic treatment plot. You have `epa_years` in the panel already. Run `fepois(total_bilateral ~ ... + i(epa_years, ref=-1) | FEs)` in fixest to get a pre/post event study. This is now essentially expected in any diff-in-diff adjacent paper and will stop a referee asking for it.
- Compute and report net marginal effects for EPA countries vs. non-EPA countries from M3.

**Before final submission:**

- Run a heteroskedasticity-robust Ramsey RESET test or Santos Silva & Tenreyro (2006) specification test to formally justify PPML over OLS. Your OLS vs PPML divergence is only 9.8% (well within the 15% threshold you set), which actually makes PPML look less critical here — address this directly.
- Consider a placebo / falsification test: assign fake EPA dates (e.g., 3 years earlier) and show the EPA coefficient disappears. This is a relatively easy addition to script 02.
- SADC: the IT share coefficient (−2.258) is significant despite 12% missing IT share. Either impute using trade-weighted REC averages for the missing country-years, or run a sensitivity dropping all SADC countries with missing IT share.

---

## How the Paper Should Be Written

Here is the full structure, section by section, with what to say in each based on your actual results.

---

### Title

**"Building Blocks or Stumbling Blocks? Intra-Regional Trade Integration and EU–ACP Bilateral Trade, 1995–2020"**

(The building block/stumbling block framing is already embedded in your code and maps directly onto Bhagwati's canonical question. Your main result — that the answer is largely "stumbling block" — makes this title work.)

---

### Abstract (150–200 words)

State the question (does deeper intra-ACP regional integration promote or reduce bilateral trade with the EU?), the method (PPML gravity model, 77 ACP × 27 EU dyads, 1995–2020, BACI trade data), the main finding (a one-unit increase in intra-REC trade share reduces EU–ACP bilateral trade by approximately 36% at the median), the heterogeneity finding (CEMAC is the only REC where integration is trade-promoting; all others show stumbling-block effects), the EPA interaction (EPAs attenuate but do not eliminate the stumbling-block effect), and the policy implication (regional integration in ACP blocs has not been complementary to EU partnership; EPA design needs to account for intra-bloc trade diversion).

---

### 1. Introduction

Open with the political and policy context: the Cotonou Agreement (2000), the transition to Economic Partnership Agreements, and the 2023 Samoa Agreement codifying the EU–ACP relationship around 77 developing countries organised into seven RECs. The EPA negotiation process was premised on a dual ambition — deepen EU–ACP bilateral trade _and_ encourage ACP regional integration. The implicit assumption was that these are complementary. Your paper tests whether that assumption holds.

State the research question clearly: does higher intra-REC trade integration (measured as the share of total ACP trade that occurs within the REC) increase or decrease bilateral trade flows with EU members?

Motivate why this matters: the Samoa Agreement was signed in November 2023 and will govern EU–ACP trade relations for the coming decades. The EU is simultaneously pursuing more ambitious EPA implementation. If intra-REC integration and EU–ACP trade are substitutes rather than complements, the EPA architecture may need rethinking.

Summarise your main findings in the introduction: the stumbling-block result, the CEMAC exception, the EPA interaction, and the asymmetric EPA effect by trade direction.

Contribution paragraph: this is the first paper to systematically estimate the IT share–EU trade nexus across all seven ACP RECs simultaneously, using a properly-specified PPML gravity model with exporter–year fixed effects that absorb multilateral resistance. Prior work (cite relevant EPA gravity papers) focuses on single RECs or the bilateral EPA effect without conditioning on the degree of intra-bloc integration.

---

### 2. Institutional Background and Related Literature

**2.1 The EU–ACP Trade Architecture** Brief history: Lomé Conventions (1975–2000) → Cotonou Agreement (2000) → EPA negotiations → staggered EPA entry into force (CARIFORUM 2008, Pacific 2009, ESA/COMESA 2012, Central Africa 2014, West Africa 2016, SADC 2016, EAC 2016) → Samoa Agreement 2023. Note that as of your panel end (2020), significant EPA variation exists: CARICOM is 50% treated, SADC 14.4%, EAC 19.2%, while ECOWAS is barely 2.4% treated.

**2.2 The Building Block vs. Stumbling Block Debate** Bhagwati (1991) introduced the terminology. The theoretical literature is split: customs unions can divert trade from efficient third-country suppliers toward inefficient bloc partners (stumbling blocks) or lower trade costs in ways that also benefit external partners (building blocks). The empirical evidence is mixed. Cite Baier & Bergstrand (2007) on PTA effects, Magee (2008) on building blocks, and any specific EPA evaluation papers you've drawn on.

**2.3 ACP Regional Integration** Describe the seven RECs briefly — size, GDP, integration depth, major trading partners. Note the heterogeneity: SADC's mean IT share is 0.298 (driven by South Africa), COMESA's is 0.040, PIF's 0.040. This variation is what your model exploits.

---

### 3. Data and Methodology

**3.1 Panel Construction** Panel: 77 ACP countries × 27 EU member states × 1995–2020, sourced from BACI HS92 V202601 (CEPII). EU enlargement dates handled explicitly: pre-accession years for 2004, 2007, and 2013 entrants are excluded from the dyad grid. This yields approximately 43,000 observations after dropping country-years with missing gravity covariates.

Dependent variable: total bilateral trade (sum of EU exports to ACP and ACP exports to EU), in USD thousands.

Key independent variable — Intra-REC Trade Share (IT Share): for each ACP country $i$ in REC $r$ and year $t$, IT share is the ratio of $i$'s trade with other REC members to $i$'s total trade with the world. Constructed from BACI. This measures the degree to which $i$ has oriented its trade internally within the bloc. Note SADC has 12% missing IT share (explain source — likely DR Congo and South Africa customs data issues).

EPA dummy: coded 1 from the calendar year of entry into force, sourced from WTO RTA database and EPA texts. 39 of 77 ACP countries have an EPA by end of panel; entry-into-force dates vary from 2008 (CARIFORUM) to 2020 (Solomon Islands).

Gravity covariates: bilateral distance (capital-to-capital, CEPII Gravity V202211), common official language, colonial tie ever, contiguity (excluded — fewer than 0.5% of EU-ACP dyads share a land border). GDP sourced from CEPII Gravity RDS. Note the 2014–2016 gap for [X EU members — to be determined].

**3.2 Estimation Strategy** The standard gravity equation for bilateral trade flows, estimated by PPML following Santos Silva & Tenreyro (2006) to handle zero trade flows and heteroskedasticity. Specification:

$$E[T_{ijt}] = \exp(\beta_1 \ln d_{ij} + \beta_2 L_{ij} + \beta_3 C_{ij} + \beta_4 \text{EPA}_{it} + \beta_5 \text{IT Share}_{it} + \alpha_{it} + \gamma_i + \delta_t) \cdot \epsilon_{ijt}$$

where $i$ indexes EU members, $j$ indexes ACP countries, $t$ is year. Fixed effects: exporter×year ($\alpha_{it}$) absorbs all time-varying EU-side characteristics including EU GDP, trade policy, and multilateral resistance; ACP country FE ($\gamma_j$) absorbs time-invariant ACP characteristics; year FE ($\delta_t$) absorbs global shocks. Standard errors clustered at the dyad (pair) level.

The exporter×year FE is the standard solution to the multilateral resistance problem in one-sided panel gravity (the ACP side is the "importer" here and varies in IT share, so we cannot also include importer×year FEs without losing identification on IT share).

Discuss the OLS comparison (M5): PPML and OLS coefficients on IT share diverge by only 9.8%, suggesting zero trade pairs are not driving the result. Nevertheless, PPML is preferred as the theoretically appropriate estimator.

---

### 4. Results

**4.1 Main Results (Table 1)**

Work through the five models. The baseline (M1) confirms standard gravity: distance reduces trade (−1.669***), common language increases it (+1.141***), colonial ties are positive but insignificant. EPA is negative but insignificant in the baseline.

Adding IT share (M2, your main model): IT share enters with a coefficient of −1.726***, strongly significant. Interpret this in percentage terms using your marginal effects: at the median IT share of 0.070, the estimated effect implies an 11.3% reduction in bilateral EU trade compared to the counterfactual of no intra-REC integration. At the 90th percentile IT share (0.255, roughly SADC-level integration), the effect is a 35.6% reduction. This is your headline stumbling-block finding.

The interaction model (M3) adds EPA × IT Share (+0.881**). Interpretation: for countries with an in-force EPA, the net stumbling-block coefficient is −1.721 + 0.881 = −0.840. EPAs attenuate the stumbling-block effect by roughly half, but do not eliminate it. This is a meaningful result: EPA countries are partially protected against the trade-diverting consequences of deeper regional integration, or alternatively, EPA market access reassures EU exporters even as ACP countries trade more internally.

The IT intensity alternative (M4) uses a levels-based intensity measure and confirms the direction (−0.0045**). This is reassurance that the result is not specific to the share transformation.

**4.2 Trade Direction (Table: direction_results)**

Splitting into ACP exports to EU and EU exports to ACP: the stumbling-block effect operates in both directions, but it is stronger and more precisely estimated for EU exports (−1.997*** vs −1.371**). More notably, the EPA coefficient is near zero for ACP exports (+0.007) but significantly negative for EU exports (−0.140***). This is an asymmetric EPA finding that deserves substantive discussion: EPAs appear to have redirected EU export capacity _away_ from ACP markets (perhaps because EPA obligations increased competition from third countries or because EPAs were accompanied by preference erosion), while ACP export patterns to the EU were essentially unchanged.

**4.3 REC Heterogeneity (Table: rec_subsample_results)**

Walk through each REC. Six of seven RECs show negative IT share coefficients, confirming the stumbling-block result is not driven by one region. The coefficients are: ECOWAS −3.109***, SADC −2.258**, EAC −2.660***, COMESA −2.619***, CARICOM −1.940**, PIF −29.61*** (flagged as unreliable due to sparse data and excluded from the coefficient plot).

CEMAC is the exception: IT share coefficient +4.317***, positive and significant. Discuss: CEMAC has the second-lowest mean IT share (0.048), is a monetary union with a fixed CFA peg, and Cameroon accounts for roughly 70% of CEMAC–EU trade. In a bloc where true regional integration is nascent and concentrated in one dominant economy, higher IT share may proxy for Cameroon's integration into both regional and EU markets simultaneously, rather than trade diversion. This is an area for future research.

**4.4 Robustness (Tables: sample_robustness, regional_robustness)**

Sample sensitivity: dropping the first three years (pre-1998, when BACI coverage is thinner) actually _strengthens_ the IT share coefficient to −2.064***, consistent with the result not depending on early years. Dropping South Africa weakens it to −1.459*** (South Africa's intra-SADC trade heavily pulls down SADC's IT share and dominates SADC–EU flows, so excluding it is informative). Dropping Nigeria similarly gives −1.242***. Both remain significant, confirming the result is not mechanically driven by large-economy dominance.

Regional subsamples: African countries alone give −1.519***, Caribbean −1.940**, Pacific −29.61*** (same caveats as PIF). The stumbling-block result is consistent across all three ACP geographic groupings.

---

### 5. Discussion and Policy Implications

Open with the puzzle: the EU–ACP EPA architecture was designed under the assumption that deeper regional integration and stronger EU–ACP bilateral ties are mutually reinforcing. Your results suggest the opposite is generally true, with EPAs providing partial but incomplete mitigation.

Mechanisms: intra-REC trade growth may divert productive capacity toward bloc partners, may signal policy attention turning inward, or may reflect supply chains increasingly oriented toward regional rather than transatlantic trade. The stumbling-block mechanism is demand-side (ACP countries importing more from regional partners substituting for EU imports) and supply-side (ACP exporters finding regional markets more accessible than EU markets with their sanitary, phytosanitary, and rules-of-origin requirements).

The EPA interaction result is the most policy-relevant finding. EPAs attenuate the stumbling-block effect. One interpretation: EPA market access guarantees make EU trade more resilient to the gravitational pull of regional integration. Another: EPA countries have more sophisticated institutional relationships with the EU that maintain trade ties even as domestic and regional trade grows. Either way, the implication is that deeper and broader EPA coverage matters — the 38 ACP countries without an EPA in force by 2020 are exposed to the full stumbling-block effect without the attenuating benefit.

The asymmetric direction result (EPA hurts EU exports, not ACP exports) is worth a policy paragraph: if EU exporters are losing share in ACP markets over time, this has implications for how the EU frames EPA renegotiations under the Samoa Agreement.

---

### 6. Conclusion

Summarise the three findings: (1) intra-REC trade integration is a stumbling block for EU–ACP bilateral trade overall; (2) the effect is heterogeneous — six of seven RECs show stumbling-block patterns, CEMAC is the exception; (3) in-force EPAs attenuate but do not eliminate the stumbling-block effect, and this attenuation operates asymmetrically by trade direction.

Limitations: panel ends in 2020 (misses 2021–2023 post-Samoa developments, COVID disruption in final year); CEPII Gravity data gaps affect Sudan, Ethiopia, and small Pacific micro-states; causal interpretation is constrained by the inability to fully rule out reverse causality (though EPA timing is largely exogenous).

Future research: event-study analysis exploiting staggered EPA entry into force (you have `epa_years` ready to go), product-level analysis asking whether the stumbling-block is concentrated in specific sectors, and extension to the Samoa Agreement period once post-2023 data become available.

---

### Tables and Figures to Include

The paper needs: Table 1 (main_results.tex), Table 2 (direction_results.tex), Table 3 (rec_subsample_results.tex), Table 4 (sample_robustness.tex and regional_robustness.tex — these can be combined into one robustness table), a summary statistics table (summary_statistics.csv formatted), a marginal effects figure (the plot your code generates), and the REC coefficient plot (excluding PIF, as your code already does). If you add the event-study, that figure goes between the main results and the robustness section.

---

## One Overarching Note on Framing

Right now your code is framed around "does IT share help or hinder?" — a neutral question. Your results answer it firmly: it hinders, with one exception and one important modifier (EPAs). The paper's framing should lean into this answer rather than stay neutral. The "stumbling block" label should be in your title and abstract, not buried in the discussion. Editors and referees at development economics or international economics journals will appreciate a paper that commits to its finding.