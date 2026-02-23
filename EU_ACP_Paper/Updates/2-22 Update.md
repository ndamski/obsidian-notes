# Analysis of Your EU-ACP Gravity Analysis and Paper Writing Guide

## Executive Summary of Your Results

Your analysis examines whether intra-regional trade integration among ACP (African, Caribbean, Pacific) countries
helps or hinders bilateral trade with EU member states, and whether in-force Economic Partnership Agreements
(EPAs) change this relationship.

### Key Findings:

1. **Main Result**: Intra-REC Trade Share has a **negative and significant** effect on EU-ACP bilateral trade
(coefficient = -1.76, p<0.01). This supports the "stumbling block" hypothesis—stronger regional integration among
ACP countries actually reduces their bilateral trade with the EU.

2. **EPA Interaction**: The positive and significant interaction term (0.90, p<0.05) suggests that EPAs partially
mitigate the negative effect of regional integration on trade.

3. **Trade Direction**: The effect is slightly stronger for EU exports to ACP (-1.86) than ACP exports to EU
(-1.60).

4. **Heterogeneity**: All RECs show negative effects, but with substantial variation—PIF (Pacific Islands) shows
the largest negative coefficient (-29.6), while Central Africa shows the smallest effect (-0.81, not significant).

---

## Paper Structure Following Feenstra, Yotov & Baier Style

### Tier 1: Core Results Tables

| Table | Description | File |
|-------|-------------|------|
| **Table 1** | Summary Statistics by REC | `summary_statistics.csv` |
| **Table 2** | Main Regression Results | `main_results.tex` |
| **Table 3** | Trade Direction Analysis | `direction_results.tex` |

### Tier 2: Heterogeneity Analysis

| Table | Description | File |
|-------|-------------|------|
| **Table 4** | REC-by-REC Subsamples | `rec_subsample_results.tex` |
| **Table 5** | Regional Subsamples (Africa/Caribbean/Pacific) | `regional_robustness.tex` |

### Tier 3: Robustness

| Table | Description | File |
|-------|-------------|------|
| **Table 6** | Sample Robustness | `sample_robustness.tex` |
| **Table 7** | Extended Robustness | `robustness_extended.tex` |
| **Table 8** | OLS vs PPML Comparison | `ols_vs_ppml_comparison.csv` |

---

## 4. Figures to Emphasize (Priority Order)

### Must-Include Figures:

1. **Figure 1**: Mean IT Share Over Time by REC
   - File: `it_share_time_series.png`
   - Shows evolution of intra-regional integration across 7 RECs

2. **Figure 2**: IT Share vs EU-ACP Trade (REC-level scatter)
   - File: `stumbling_block_scatter.png`
   - Visual demonstration of the negative relationship

3. **Figure 3**: REC Coefficient Plot
   - File: `rec_coef_plot.png`
   - Shows heterogeneity across regional blocs (exclude PIF from main text, mention in appendix)

4. **Figure 4**: Marginal Effects of IT Share
   - File: `marginal_effects_it_share.png`
   - Translates coefficients into interpretable percentage changes

### Supporting Figures (Appendix):

5. **Figure A1**: IT Share Distribution by REC
6. **Figure A2**: Event Study (EPA vs Non-EPA trends)
7. **Figure A3**: Relative Time Event Study

---

## 5. Combining Figures for Publication

### Option A: Combined Regional Analysis Figure

Create a single multi-panel figure combining:

- Panel A: Time series of IT Share by REC
- Panel B: Scatter plot with regression lines
- Panel C: REC coefficient forest plot

```latex
\begin{figure}[htbp]
  \centering
  \begin{subfloat}[Regional Trends]{%
    \includegraphics[width=0.45\textwidth]{it_share_time_series.png}%
    \label{fig:rec_trends}
  }
  \subfloat[IT Share vs Trade]{%
    \includegraphics[width=0.45\textwidth]{stumbling_block_scatter.png}%
    \label{fig:scatter}
  }
  \caption{Regional Integration and EU-ACP Trade: Descriptive Evidence}
  \label{fig:descriptive}
\end{figure}
```

### Option B: Results Summary Figure

Combine coefficient plot + marginal effects:

```latex
\begin{figure}[htbp]
  \centering
  \begin{subfloat}[REC Heterogeneity]{%
    \includegraphics[width=0.48\textwidth]{rec_coef_plot.png}%
  }
  \subfloat[Marginal Effects]{%
    \includegraphics[width=0.48\textwidth]{marginal_effects_it_share.png}%
  }
  \caption{Effect of Intra-REC Trade Share on EU-ACP Bilateral Trade}
  \label{fig:main_results}
\end{figure}
```

### Recommended Combined CSV for Replication:

Create a `results_summary.csv` that consolidates key results:

```csv
model,specification,it_share_coef,it_share_se,n_obs,notes
M1,Baseline PPML,,,44054,No IT Share variable
M2,Main PPML,-1.755,0.384,43238,Core specification
M3,PPML + EPA interaction,-1.758,0.378,43238,
M4,IT Intensity,-0.006,0.002,43238,Alternative measure
M5,OLS,-1.526,0.245,40334,Log-linear
```

---


## Suggestions for Write-Up

### Strengths to Highlight:

1. **Novel data construction**: 78 ACP countries across 7 RECs, 1995-2020
2. **Clean identification**: Time-varying EPA treatment + country-pair fixed effects
3. **Comprehensive robustness**: Multiple specifications, subsamples, and alternative measures
4. **Policy relevance**: Direct implications for EU-ACP trade policy and regional integration

### Points to Clarify:

1. **Why negative effect?** Discuss possible mechanisms:
   - Trade diversion: Regional integration may shift trade toward regional partners
   - Supply constraints: Regional integration doesn't necessarily increase productive capacity
   - Regulatory divergence: Different standards may complicate EU trade

2. **EPA interaction interpretation**: The positive interaction (0.90) suggests EPAs partially offset the negative
regional effect—explain why this might occur

3. **Coefficient magnitude**: At the mean IT Share (~10%), the effect is approximately -16% reduction in bilateral
trade; at 90th percentile (~26%), it's -36%

### Caveats to Mention:

1. **PEARSON dispersion statistic**: It's around 2.0 (mentioned in code), suggesting mild overdispersion—consider
negative binomial robustness
2. **Missing data**: Eritrea and Somalia have missing gravity covariates in some years
3. **PIF coefficient**: Very large negative coefficient (-29.6) likely due to small sample and sparse trade patterns

---

## Immediate Action Items

1. **Create combined figures** for the main text (Figures 1-4 above)
2. **Revise Table 2** (main_results.tex) to include percentage change interpretation in the notes
3. **Add appendix table** showing country coverage and any data quality issues
4. **Consider negative binomial** specification given mild overdispersion
5. **Write abstract** (150-200 words) summarizing the key findings