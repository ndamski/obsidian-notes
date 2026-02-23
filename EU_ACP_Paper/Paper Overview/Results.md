


**Abstract / Introduction — the one-line finding**

Higher intra-regional trade integration among ACP blocs is associated with significantly less bilateral trade with EU member states — a stumbling block effect. At the median level of regional integration, EU-ACP trade is approximately 11% lower; at the 90th percentile (characteristic of SADC), 36% lower. This holds across PPML and OLS, across both trade directions, and across five of seven regional blocs.

***

![[main_results.tex]]
---

**Data and sample — things to flag**

Sudan (SDN) and Ethiopia (ETH) are effectively dropped from estimation due to missing CEPII Gravity covariates throughout most of the panel. Both are COMESA members. Your COMESA results therefore reflect the remaining 10 members, not the full 12. State this explicitly.

SADC's missing IT Share is confined entirely to 1995–1999 for the five SACU members (Botswana, Lesotho, Namibia, Swaziland, South Africa). This is a BACI coverage gap in the early years, not a structural data problem. SADC identification runs on 2000–2020 for those countries.

GDP summary stats are now readable — SADC is the wealthiest bloc by a wide margin at $46.4bn mean GDP, followed by ECOWAS ($21.8bn). EAC ($17.6bn) and COMESA ($10.9bn) are mid-range. CARICOM ($6.9bn) and PIF ($1.4bn) are the smallest. This matters for contextualising the trade volume differences — SADC's mean bilateral trade of $292,345 dwarfs PIF's $8,138.

Zero-trade share varies substantially — PIF at 25.2% is a real data quality concern, versus 1.9–2.7% for most African blocs. This partly explains the implausible PIF coefficient.

---

**Results — main findings to write up**

**Finding 1 — The stumbling block result (Table 2, M2)**

IT Share coefficient: **−1.726 (p<0.01)**. The stumbling block effect is large, precisely estimated, and the central result of the paper. In PPML terms, moving from zero to the sample mean IT Share of around 0.12 is associated with roughly 19% less bilateral trade (`exp(-1.726 × 0.12) - 1`). The marginal effects table gives you the cleanest way to present this — use the percentile breakdown in the paper rather than trying to interpret the raw coefficient.

**Finding 2 — EPA partially attenuates the stumbling block (Table 2, M3)**

The interaction term EPA × IT Share is **+0.881 (p<0.05)**. The net IT Share effect for EPA countries is −1.721 + 0.881 = −0.840, still negative but meaningfully smaller than for non-EPA countries. This suggests EPAs partially counteract trade diversion from regional integration — ACP countries that have formalised their EU relationship retain more EU trade even as intra-REC integration deepens. However EPA alone is insignificant in M1 and M2, only becoming significant (and negative) once the interaction is included. Be careful how you frame this — EPA is not independently driving the results.

**Finding 3 — Trade direction asymmetry (direction table)**

This is potentially the most novel result. IT Share reduces both ACP exports to EU (−1.371, p<0.05) and EU exports to ACP (−1.997, p<0.01). The effect is actually larger for EU exports to ACP than for ACP exports to EU, which cuts against a simple trade diversion story. If regional integration were just diverting ACP exports to intra-REC partners you'd expect only the ACP→EU direction to be affected. The fact that EU→ACP is affected equally or more suggests something more structural — possibly that higher regional integration raises trade barriers or domestic preference for intra-REC goods in both directions, or that the CEPII bilateral trade costs that underlie the relationship are symmetric.

The EPA direction split is also striking: EPA has zero effect on ACP exports to EU (+0.007, insignificant) but is significantly negative for EU exports to ACP (−0.140, p<0.01). This requires an explanation in the paper. The most credible interpretations are: (a) selection — countries signing EPAs were already experiencing declining EU import penetration and signed partly in response; (b) the year FE is absorbing the post-2008 trade slowdown which coincides with the first major EPA wave; (c) EPA implementation involves transition periods where tariff reductions on EU goods are phased in slowly while ACP export preferences were already in place under the Cotonou framework.

**Finding 4 — REC heterogeneity (subsample table)**

Five of six identified RECs show stumbling block effects. Rank by magnitude: ECOWAS (−3.109), EAC (−2.660), COMESA (−2.619), SADC (−2.258), CARICOM (−1.940). All significant at 5% or better.

**CEMAC is the sole exception (+4.317, p<0.01).** This is worth developing. CEMAC has the lowest mean IT Share (0.048) and the deepest monetary integration of any ACP bloc through the CFA franc zone. The building block result there may reflect a qualitatively different type of integration — monetary union facilitating trade rather than preferential trade arrangements creating diversion. It also has the smallest sample (3,396 obs) so treat the magnitude cautiously, but the sign is reliable.

**SADC's EPA coefficient is positive and significant (+0.364, p<0.01)** — the only REC where EPA is clearly trade-creating in the subsample. SADC signed the most complex EPA given South Africa's dominant position, so this may reflect genuine preference gains, or it may reflect that SADC countries were already growing EU trade partners before 2016 entry.

**PIF: report the direction (stumbling block) but not the magnitude.** −29.61 is implausible. Note sparse data, 25% zero-trade pairs, and small island state volatility as reasons the point estimate is unreliable.

---

**Robustness — what to say**

The stumbling block result is robust across every specification. From 1998 onwards the coefficient actually strengthens to −2.064, suggesting the 1995–1997 years if anything dilute the finding slightly (plausibly because early BACI coverage is thinner). Excluding South Africa (−1.459) and Nigeria (−1.242) both reduce the magnitude moderately, confirming those dominant economies are not solely driving the result — the effect is present across the broader ACP membership. The OLS comparison gives −1.556 vs PPML −1.726, a 9.8% difference, confirming zero-trade pairs are not materially distorting the main finding.

---

**Limitations to acknowledge**

The FE structure (`exporter_year + acp_iso3 + year`) is a practical compromise — theoretically ideal multilateral resistance would require `importer_year` FEs, but those perfectly absorb IT Share and EPA given both vary only at the ACP country-year level. This is standard in the literature when the variable of interest is country-year specific, but worth stating explicitly.

IT Share is potentially endogenous — countries trading less with the EU may deepen intra-REC trade as a substitute, which would also produce a negative coefficient without any causal stumbling block mechanism. An instrumental variable strategy (e.g. using geographic distance between REC member capitals, or a Bartik-style shift-share based on pre-period trade patterns) would strengthen the causal interpretation. Flag this as a direction for future work.

Sudan and Ethiopia's exclusion means COMESA results are not fully representative of the bloc as formally constituted.







ValuePanel dimensions77 ACP × 27 EU × 1995–2020Estimation observations (M2)43,158Overall zero trade share7.7%PIF zero trade share25.3%Main IT share coefficient (PPML)−1.726*** (SE 0.391)Implied % effect at median IT share (0.070)−11.3%Implied % effect at p90 IT share (0.255)−35.6%OLS vs PPML divergence on IT share9.8%EPA × IT share interaction+0.881**Net IT share effect with EPA−0.840CEMAC IT share (anomaly)+4.317***SADC mean IT share (highest)0.298PIF/COMESA mean IT share (lowest)0.040EPA direction: EU exports−0.140***EPA direction: ACP exports+0.007 (n.s.)CARICOM EPA coverage50% country-yearsECOWAS EPA coverage2.4% country-years