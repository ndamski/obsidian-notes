
# 1. What We Did Today

## 1.1  Rethought the REC Depth Variable

Originally planned to code ACP countries on an ordinal 0–4 integration scale following the Baier et al. (2014) typology. Decided against this as the primary variable because it relies on de jure treaty text, which Standaert (2015) shows diverges badly from de facto integration in Africa. Built a full REC Depth coding spreadsheet anyway — now saved as REC_Depth_Index_Coding.xlsx — to use as a robustness check or appendix rather than the main variable. Following the UNU-CRIS (2009) formulas already in the Comparative Regionalization notes, settled on IT Share — `(intra-REC exports + imports) / total trade` — as the primary measure of regional openness. IT Share is data-driven, continuous, varies by country and year, and requires no researcher judgment about integration depth. IT Intensity was also computed as a secondary measure.

**EPA Entry-into-Force Dates**

EPA stands for Economic Partnership Agreement — these are the trade deals the EU has negotiated with ACP countries since the mid-2000s. Each one has a specific date when it legally came into force and preferential tariff access began. We manually coded these dates for every ACP country that has one — for example CARIFORUM signed in November 2008, Cameroon in August 2014, the EAC group in September 2016, and so on. In the dataset this becomes a simple binary variable: for each ACP country in each year, EPA = 1 if the agreement is already in force, 0 if not. Countries with no EPA stay at 0 throughout the whole panel. This is what allows us to measure whether having an EPA changes trade flows.

**IT Share and IT Intensity**

IT Share stands for Intra-Regional Trade Share. For each ACP country in each year, it answers the question: out of all the trade this country does with the whole world, what fraction of it is with other members of its own regional bloc? So if Nigeria exports $100bn total and $15bn goes to other ECOWAS countries, its IT Share is 0.15. A higher number means the country is more economically embedded in its region.

IT Intensity is a refinement of that. The problem with the raw share is that a large REC will mechanically show higher intra-regional trade just because its members are big — not because they're especially integrated. IT Intensity corrects for this by dividing the IT Share by the REC's share of world trade. So it measures whether a country trades with its neighbours _more than you'd expect_ given how big those neighbours are. It's a more sophisticated measure of genuine regional bias in trade patterns.

## 1.2  Built the Data Pipeline (01_build_panel.R)

Constructed the full panel dataset from raw sources:

•        Downloaded and loaded BACI HS92 V202601 (1995–2024) — bilateral trade flows for all country pairs

•        Loaded CEPII Gravity RDS V202211 for distance, language, colonial ties, GDP, and population

•        Computed IT Share and IT Intensity for every ACP country from BACI flows

•        Built the EU–ACP bilateral trade panel including zero-trade pairs (essential for PPML)

•        Merged EPA entry-into-force dates for all ACP countries as a binary treatment variable

•        Saved the final merged panel as eu_acp_panel.rds

- Downloaded and loaded BACI HS92 V202601 (1995–2024)
- Loaded CEPII Gravity RDS V202211 for distance, language, colonial ties, GDP, population
- Constructed IT Share and IT Intensity for all ACP countries from BACI
- Built EU-ACP bilateral trade panel including zero-trade pairs
- Merged EPA entry-into-force dates for all ACP countries
- Saved final panel as RDS

**The RDS file**

RDS is just R's native file format for saving a single object — in this case the entire merged panel dataset. It's like a save file. Once it exists on your computer you can load it instantly in any future R session with one line of code rather than rerunning the entire hour-long BACI loading process. It's purely a practical efficiency thing.

## 1.3  Built the Estimation Script (02_estimate_gravity.R)

Estimated a structural gravity model using PPML via fixest::fepois(). Ran five models: baseline PPML, PPML with IT Share, the main interaction specification (EPA × IT Share), IT Intensity robustness check, and OLS on log trade. Added lagged IT Share and regional subsample robustness checks.

***
Built the estimation script (`02_estimate_gravity.R`)** Structural gravity model estimated with PPML using `fixest::fepois()`. Fixed effects: exporter-year + ACP country + year (split importer FE to avoid absorbing ACP-varying treatment variables). Five models: baseline, IT share, main interaction, IT intensity, OLS robustness.

**The estimation script and PPML**

The gravity model is essentially a statistical equation that tries to explain why some country pairs trade more than others. The dependent variable is the actual dollar value of bilateral trade between an EU member and an ACP country in a given year. The independent variables are things that theory says should matter — distance, shared language, colonial history, GDP, and crucially your variables of interest: whether an EPA is in force and how regionally integrated the ACP country is.

PPML stands for Poisson Pseudo-Maximum Likelihood. It's the estimation method — essentially the statistical technique used to fit the model to the data. The reason we use it instead of ordinary linear regression is that trade data has two awkward features: a lot of country pairs have zero trade in a given year, and the distribution of trade values is very skewed (a few pairs trade enormous amounts, most trade very little). PPML handles both of these correctly whereas standard OLS on logged trade would either drop the zeros or produce biased estimates.

`fixest` is an R package that makes PPML fast and practical with large datasets. `fepois()` is the specific function within it for Poisson estimation.


## 1.4  Fixed a Collinearity Problem

The original fixed effects specification used exporter-year and importer-year FEs. The importer-year FE absorbed the EPA dummy and IT Share entirely since both only vary at the ACP country × year level, causing them to be silently dropped. Fixed by splitting the importer FE into acp_iso3 + year separately, following Baier, Yotov and Zylkin (2019). GDP added back explicitly since it was no longer absorbed.

***
Original spec used full importer-year FEs which absorbed `epa` and `it_share` entirely — they only vary at ACP × year level. Fixed by splitting importer FE into `acp_iso3 + year` separately, following Baier et al. (2019).

**Fixed Effects and the Collinearity Problem**

Fixed effects are a way of controlling for everything about a country or year that we can't directly measure. An exporter-year fixed effect, for example, absorbs every single thing about France in 2015 that affects how much France exports — its economic conditions, its trade policy, its currency, everything — without us having to measure any of it explicitly. This is standard practice in gravity models following Anderson and van Wincoop.

The original plan was to use both an exporter-year FE and an importer-year FE — the latter absorbing everything about each ACP country in each year. The problem we ran into is that our two key variables — EPA status and IT Share — also only vary at the ACP country × year level. So the importer-year FE was perfectly explaining those variables before the regression even got to estimate them, leaving nothing for the coefficients to be estimated from. They were being silently dropped. This is called collinearity.

The fix was to split the importer fixed effect into two separate ones: one for the ACP country itself (absorbing time-invariant country characteristics like geography and institutional quality) and one for the year (absorbing global shocks like financial crises or commodity price cycles). Together these control for most of what the importer-year FE was doing, but they don't perfectly predict EPA status or IT Share because those vary in different ways across countries and years. So now the coefficients can actually be estimated.


## 1.5  Extended to REC-Level Analysis

Rather than grouping results by broad ACP region (Africa, Caribbean, Pacific), produced a faceted scatter plot comparing all seven major RECs directly against each other: ECOWAS, SADC, EAC, CEMAC, COMESA, CARICOM, and PIF. This revealed important heterogeneity in the direction of the relationship across RECs that the broad regional breakdown obscured.




#### 7. Ran results and interpreted findings

Main results from M3 (PPML, full ACP sample):

- `ln(Distance) = -1.57*`
- `Common Language = 1.18***`
- `ln(GDP ACP) = 0.48***`
- `EPA = 0.003` (not significant)
- `IT Share = -1.35***` ← main finding
- `EPA × IT Share = 0.20` (not significant)

**Results**

Each coefficient tells you the estimated relationship between that variable and trade, holding everything else constant.

`ln(Distance) = -1.57*` means that a 1% increase in distance between capitals is associated with roughly a 1.57% fall in bilateral trade. The asterisk means it's statistically significant at the 5% level. This is the classic gravity result — distance kills trade.

`Common Language = 1.18***` means sharing an official language is associated with trade being about three times higher (e^1.18 ≈ 3.25). Three stars means very high confidence in this result. Makes intuitive sense — France trades far more with Francophone Africa than with countries where French isn't spoken.

`ln(GDP ACP) = 0.48***` means larger ACP economies trade more with the EU. Also very intuitive and expected.

`EPA = 0.003` means that having an EPA in force is associated with essentially no change in trade on its own, and this is nowhere near statistically significant. EPAs alone don't seem to boost trade.

`IT Share = -1.35***` is your main finding. For every 10 percentage point increase in intra-REC trade share, EU-ACP bilateral trade falls by about 13%. This is highly significant — three stars — and robust across all your checks. It means countries that are more embedded in their regional bloc trade less with the EU, which is the stumbling block result.

`EPA × IT Share = 0.20` is the interaction — the test of whether EPAs work better for more regionally integrated countries. It's positive, meaning the direction supports your original hypothesis, but the standard error is larger than the coefficient so we can't be confident it's a real effect rather than noise. This is what not significant means — it could plausibly be zero.

#### 8. Robustness checks

- Lagged IT Share: coefficients virtually identical, rules out reverse causality
- Regional subsamples: stumbling block effect is Africa-specific and robust; Caribbean and Pacific results noisy

**Robustness Checks**

Robustness checks are essentially ways of stress-testing your main finding. The question they answer is: does this result hold up when we change something about how we measured or estimated it, or does it fall apart? If the finding survives multiple different approaches, you can be much more confident it reflects something real rather than being an artifact of one particular methodological choice.

---

**Lagged IT Share — ruling out reverse causality**

The concern with the main result is a chicken-and-egg problem. We found that higher intra-REC trade share is associated with lower EU-ACP trade. But what if the causation runs the other way — what if countries that happen to trade less with the EU end up trading more within their region simply because the EU isn't an option for them? In that case we'd be misreading the direction of the relationship.

Lagging fixes this by using last year's IT Share to explain this year's trade. Since last year's regional integration level cannot be caused by this year's EU trade flows — time only moves in one direction — you've ruled out that reverse causality story. The fact that our lagged results came back virtually identical to the main results (`-1.337***` vs `-1.347***`) means the stumbling block finding is not a reverse causality artifact. The regional integration is genuinely preceding and predicting lower EU trade, not the other way around.

---

**Regional Subsamples — where the effect actually lives**

Rather than assuming the relationship is the same everywhere across all 79 ACP countries, we split the sample into Africa, Caribbean, and Pacific and ran the model separately on each group. This tests whether the overall result is being driven by one particular region or is genuinely uniform.

What came back was that the stumbling block effect — the strong negative IT Share coefficient — is entirely concentrated in Africa. The Africa-only result was `-1.303***`, almost identical to the full sample result of `-1.347***`, which makes sense given Africa accounts for the majority of ACP observations. The Caribbean and Pacific results were statistically noisy — large standard errors, coefficients jumping around — meaning we can't draw reliable conclusions from those subsamples on their own. The Caribbean has too few countries and the Pacific states are so tiny that their trade patterns are dominated by PNG and Fiji, making the estimates unstable.

This is actually a useful finding in itself. It means your paper is really a paper about African ACP countries and their relationship with EU trade integration. The Caribbean and Pacific are contextually different enough that the same mechanism doesn't cleanly apply — CARICOM is a much more functional integration arrangement than most African RECs, and Pacific states have trade dynamics dominated by geography and size rather than regional integration depth.

---

### Key findings

#### Primary result:
Deeper intra-REC integration is associated with _less_ EU-ACP bilateral trade, not more. Effect is concentrated in Africa and robust to lagging. This is a **stumbling block** result consistent with Standaert (2015).

**Primary Result — The Stumbling Block Finding**

The building block vs stumbling block debate goes back to Frankel and Wei in the 1990s and is one of the central questions in the regionalism literature. The building block argument says that regional integration is a stepping stone toward broader global trade — countries that learn to trade with their neighbours develop the institutions, infrastructure, and habits that make them better at trading with everyone, including the EU. The stumbling block argument says the opposite — that regional integration diverts trade inward, creates preferential relationships within the bloc, and actually makes countries less oriented toward external partners.

Your primary result comes down firmly on the stumbling block side, at least for Africa. What the data shows is that ACP countries with higher intra-REC trade shares — meaning more of their total trade happens within their regional bloc — systematically trade less with the EU. A country that sends 15% of its trade to regional partners trades significantly less with France or Germany than a comparable country that sends only 5% regionally. This holds up when you lag the measure, so it's not just a statistical artifact.

The connection to Standaert (2015) is important here. Standaert's paper on African trade agreements found that regional integration in Africa tends to be dominated by hegemons, creates uneven benefit distribution, and in many cases functions more as a political arrangement than a genuine trade-creating one. Your finding is consistent with his argument — African RECs are pulling trade inward in ways that crowd out EU-ACP flows, even if the welfare implications of that are ambiguous.

#### Secondary result:

EPA × IT Share interaction is consistently positive but not statistically significant. Cannot confirm the building block amplification hypothesis, but direction is consistent with it.

**Secondary Result — The Interaction**

You set out to test whether being more regionally integrated makes EPAs more effective at boosting EU trade — the idea being that a well-integrated regional bloc would be better positioned to take advantage of preferential EU market access. The interaction term EPA × IT Share tests exactly this.

The coefficient came back positive — 0.20 — which means the direction is consistent with your original hypothesis. Countries with higher IT Share do appear to get slightly more trade boost from their EPA. But the standard error is 0.25, larger than the coefficient itself, which means statistically you cannot rule out that the true effect is zero. In academic terms you fail to reject the null hypothesis of no interaction effect.

This is not a failure — it's an honest result. What you can say is that the data does not provide evidence strong enough to confirm the building block amplification story, but it also doesn't contradict it. The effect might be real but your sample size and the noisiness of the data don't give you enough statistical power to pin it down precisely. This is worth stating clearly in the paper rather than glossing over.

**Implication:** The paper's framing should shift from "regional openness amplifies EPA effects" to "testing the building block vs stumbling block hypothesis — evidence favours stumbling blocks in the African ACP context."

#### The Framing Implication

This is about how you position the paper's contribution. Your original research question was essentially optimistic about regionalism — does deeper integration help ACP countries get more out of their EU trade agreements? The answer the data gives you is more complicated and arguably more interesting.

What the evidence actually supports is a reframing toward the classic debate. Rather than assuming regionalism is beneficial and asking how beneficial, you're now in a position to contribute to the longstanding building block vs stumbling block question with a specific, well-identified empirical test using EU-ACP data and a continuous measure of integration depth rather than the binary dummies most of the prior literature uses.

The Africa-specific nature of the finding also gives you something precise to say — this isn't a uniform result across all developing regions, it's specific to the African REC context, which connects directly to Standaert's work on why African integration agreements often don't function the way their treaties suggest they should. The Caribbean result being flat and noisy is itself informative — CARICOM functions differently from ECOWAS or SADC, and the EU trade relationship with the Caribbean is dominated by CARIFORUM's EPA which came into force much earlier and more uniformly than the fragmented African EPAs.

So the paper's contribution becomes: the first study to test building block vs stumbling block in the EU-ACP context using a continuous de facto integration measure, finding stumbling block effects concentrated in Africa and robust to alternative specifications, with EPA amplification effects positive in direction but not statistically confirmed.

### Files produced

- `REC_Depth_Index_Coding.xlsx` — coding sheet with methodology, ACP country assignments, gravity model spec tab
- `01_build_panel.R` — full data pipeline
- `02_estimate_gravity.R` — estimation and robustness
- `eu_acp_panel.rds` — final merged panel dataset
- Figures: IT share distribution, IT share time series, marginal effects, stumbling block scatter

**REC_Depth_Index_Coding.xlsx** is the Excel workbook built at the start of the session. It has three tabs. The methodology tab explains the two-layer index design — the Baier et al. (2014) ordinal typology for de jure institutional depth and the Standaert-informed de facto implementation correction — with the literature grounding each choice. The ACP country coding tab has all 79 ACP countries assigned to their primary and secondary RECs with de jure scores, EPA dates, overlap resolution notes, and fields marked for manual verification. The gravity model spec tab has the full estimating equation written out with every variable defined and sourced, plus the R code. In the end we used IT Share as the main variable instead of this index, so the spreadsheet's role in the paper is as an appendix or robustness check rather than the primary analysis — but it's a well-documented methodological resource.

**01_build_panel.R** is the data construction script. It does everything needed to go from raw downloaded files to a clean analysis-ready dataset. It reads all 25 years of BACI trade data, computes IT Share and IT Intensity for every ACP country in every year, extracts EU-ACP bilateral trade flows, loads the CEPII Gravity file for distance and language and colonial variables and GDP, constructs the EPA dummy variable from the entry-into-force dates, and merges everything together into one rectangular panel dataset. It then saves that panel as an RDS file. This script only needs to be run once — after that you always work from the saved panel.

**02_estimate_gravity.R** is the analysis script. It loads the saved panel and runs everything from there. It produces the diagnostic plots first — the IT share distribution and time series — then estimates all five regression models, prints the results tables, computes the marginal effects of the EPA at different IT Share levels, and then runs the robustness checks — the lagged specification and the three regional subsamples — before producing the stumbling block scatter plot. This is the script you'd rerun if you wanted to try a different specification or add a new robustness check without touching the data construction.

**eu_acp_panel.rds** is the actual dataset that sits between those two scripts. It contains roughly 42,000 observations — every combination of EU member country, ACP country, and year from 2000 to 2024 — with all the variables merged in: bilateral trade flows, IT Share, IT Intensity, EPA status, distance, language, colonial tie, GDP. It's the single most important file in the project from a reproducibility standpoint. If you lose it you'd have to rerun the hour-long BACI loading process to get it back, so keep it backed up.

**The figures** are your visual outputs. The IT Share distribution shows how intra-REC trade share is spread across countries within each REC — SADC and CARICOM show broader distributions while CEMAC and IGAD are heavily concentrated near zero. The IT Share time series shows how mean regional integration has evolved over 2000–2024 by REC — SADC sits consistently highest, CEMAC lowest, with most RECs showing mild decline over time. The marginal effects plot was flat because of the collinearity problem with the first FE specification — it would need to be rerun with the corrected model if you want to use it. The stumbling block scatter is your best figure and the one most likely to appear in the paper — it shows the negative relationship between regional integration and EU trade clearly and separately for each ACP region, with Africa's negative slope visually obvious.

---

### Next steps

- Write up empirical section using the stumbling block framing
- REC coding sheet → appendix or robustness check
- Reference: Standaert (2015), Baier et al. (2014, 2019), Frankel/Wei (1995), UNU-CRIS (2009)

Writing up the empirical section means translating all of this into prose. The structure would be: a data section describing the BACI source, the IT Share construction, and the panel structure; a methodology section explaining the PPML gravity framework and the FE choices; a results section presenting the main table and walking through each coefficient; a robustness section covering the lag and regional subsamples; and a discussion section interpreting the stumbling block finding in light of Standaert and the Frankel/Wei debate.

The REC coding sheet moving to an appendix means it doesn't disappear from the paper — it becomes the place where you document how you would have operationalised a de jure depth index, and you can briefly report that the qualitative ordering from that index is consistent with the IT Share rankings your data produces. That's actually a useful validation point.

The four references to anchor the paper in the literature are Standaert (2015) for the African RIA context and the stumbling block mechanism; Baier, Bergstrand and Feng (2014) for the integration typology and the heterogeneous effects framework; Baier, Yotov and Zylkin (2019) for the gravity estimation methodology and the FE strategy; Frankel and Wei (1995) for the original building block vs stumbling block framing that your paper is directly contributing to; and the UNU-CRIS (2009) working paper for the IT Share and IT Intensity formulas. Those five form the core methodological and theoretical spine of what you've done.

### Docx

[Docx](C:\Users\ndams\Documents\Erol\output\Session_Notes_19Feb2026.docx)


Continue filling in the day report.

How i make a new chart like i have for Africa/Caribbean/Pacific but for the RECs rather?