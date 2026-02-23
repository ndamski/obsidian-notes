# Steps 1-4

## Step 1: Create Directory Structure

```r
# In RStudio or terminal:
usethis::create_package("gravitas")
```

This creates the full structure (DESCRIPTION, R/, man/, etc.) automatically.

---

## Step 2: Refactor Scripts into Functions

Copy your existing code into separate R files in the `R/` folder:

| File | Content |
|------|---------|
| `R/data.R` | Hardcoded lists (EU members, ACP, EPA dates, RECs) |
| `R/load_data.R` | `load_trade_data()`, `load_gravity_vars()` |
| `R/build_panel.R` | `build_gravity_panel()`, `compute_it_share()` |
| `R/estimate.R` | `estimate_gravity()`, `marginal_effects()` |
| `R/plot.R` | `plot_coefficients()`, `plot_event_study()` |

Key function structure:

```r
#' Build Gravity Panel
#' @param trade_data tibble from load_trade_data()
#' @param bloc_a character vector of ISO3 codes
#' @param bloc_b character vector of ISO3 codes
#' @param agreements tibble (iso3, agreement_date) or NULL
#' @param recs tibble (iso3, rec) or NULL
#' @export
build_gravity_panel <- function(trade_data, bloc_a, bloc_b,
                                 agreements = NULL, recs = NULL) {
  # Your panel construction code here
}
```

---

## Step 3: Document with Roxygen2

Add roxygen2 comments above each function (as shown above), then run:

```r
devtools::document()  # Generates NAMESPACE and man/ files
```

---

## Step 4: Test

```r
devtools::load_all()          # Load package locally
devtools::check()              # Run all checks
```

Fix any errors. Then it's ready to share on GitHub.


# Complete Setup Commands

## Terminal Commands (Run in Order)

```powershell
# ===== 1. Navigate to your Documents folder =====
cd C:\Users\ndams\Documents

# ===== 2. Install usethis if not installed (run in R first) =====
# Open R or RStudio and run:
# install.packages("usethis")

# ===== 3. Create package =====
R -e "usethis::create_package('gravitas')"

# ===== 4. Enter package directory =====
cd gravitas

# ===== 5. Initialize git =====
git init

# ===== 6. Create GitHub remote (run in R after, see below) =====

# ===== 7. First commit =====
git add .
git commit -m "Initial commit: gravitas package"
```

---

## R Commands to Run After

```r
# ===== Run these in RStudio with gravitas project open =====

# 1. Create github remote (opens browser to authenticate)
usethis::create_github_remote()

# 2. Create directory structure
dir.create("R", showWarnings = FALSE)
dir.create("vignettes", showWarnings = FALSE)
dir.create("tests/testthat", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)

# 3. Create LICENSE file
writeLines('YEAR 2024 Your Name
MIT License
Permission is hereby granted...', "LICENSE")

# 4. Update DESCRIPTION
desc <- packageDescription("gravitas")
desc$License <- "MIT + file LICENSE"
desc$Authors@R <- 'person("Your", "Name", email = "your@email.edu", role = c("aut", "cre"))'
desc$Encoding <- "UTF-8"
desc$RoxygenNote <- "7.3.1"
write.dcf(desc, "DESCRIPTION")
```

---

## Data Fetching Functions (R/load_data.R)

Create file `R/load_data.R`:

```r
#' Load Trade Data from BACI (CEPII)
#'
#' @param years numeric vector of years
#' @param baci_dir path to BACI directory (or NULL to prompt user)
#' @export
load_baci <- function(years = 1995:2022, baci_dir = NULL) {

  if (is.null(baci_dir)) {
    baci_dir <- file.path(tempdir(), "baci_cache")
    dir.create(baci_dir, showWarnings = FALSE)
    message("BACI data will be cached to: ", baci_dir)
  }

  # Check for cached data
  cache_file <- file.path(baci_dir, "baci_combined.rds")
  if (file.exists(cache_file)) {
    message("Loading BACI from cache...")
    return(readRDS(cache_file))
  }

  message("Loading BACI data from files...")

  baci_cc <- read_csv(file.path(baci_dir, "country_codes_V202601.csv"),
                      col_types = cols(.default = "c"),
                      show_col_types = FALSE) |>
    select(numeric_code = country_code, iso3 = country_iso3)

  # Load all years
  baci <- map_dfr(years, function(yr) {
    f <- file.path(baci_dir, paste0("BACI_HS, "_V202601.csv"))
   92_Y", yr if (!file.exists(f)) {
      warning("File not found: ", f)
      return(NULL)
    }
    read_csv(f, col_types = cols(t="i", i="c", j="c", k="c", v="d", q="d"),
             show_col_types = FALSE) |>
      select(t, i, j, v) |>
      group_by(t, i, j) |>
      summarise(v = sum(v, na.rm = TRUE), .groups = "drop")
  })

  # Join country codes
  baci <- baci |>
    left_join(baci_cc, by = c("i" = "numeric_code")) |>
    rename(iso3_exp = iso3) |>
    left_join(baci_cc, by = c("j" = "numeric_code")) |>
    rename(iso3_imp = iso3) |>
    filter(!is.na(iso3_exp), !is.na(iso3_imp)) |>
    rename(year = t, trade_value = v) |>
    select(year, iso3_exp, iso3_imp, trade_value)

  # Cache result
  saveRDS(baci, cache_file)
  message("BACI cached to: ", cache_file)

  return(baci)
}


#' Load Gravity Variables from CEPII
#'
#' @param gravity_file path to gravity.rds file (or NULL to prompt)
#' @export
load_gravity <- function(gravity_file = NULL) {

  if (is.null(gravity_file)) {
    stop("Please provide path to CEPII Gravity file")
  }

  message("Loading CEPII gravity data from: ", gravity_file)

  gravity_full <- readRDS(gravity_file)

  # Extract structural variables
  gravity_structural <- gravity_full |>
    select(iso3_o, iso3_d, year, distcap, comlang_off, contig, col_dep_ever) |>
    mutate(across(distcap, as.numeric),
           across(c(comlang_off, contig, col_dep_ever), ~as.integer(na_if(., "")))) |>
    rename(distance = distcap,
           lang = comlang_off,
           contiguity = contig,
           colonial = col_dep_ever)

  # Extract GDP/pop
  gravity_econ <- gravity_full |>
    select(iso3_o, iso3_d, year, gdp_o, gdp_d, pop_o, pop_d) |>
    mutate(across(c(gdp_o, gdp_d, pop_o, pop_d), as.numeric)) |>
    rename(gdp_exporter = gdp_o,
           gdp_importer = gdp_d,
           pop_exporter = pop_o,
           pop_importer = pop_d)

  list(
    structural = gravity_structural,
    economic = gravity_econ
  )
}


#' Load GDP and Population from World Bank WDI
#'
#' @param years numeric vector of years
#' @export
load_wdi <- function(years = 1995:2022) {

  message("Downloading WDI data (this may take a minute)...")

  # Set timeout
  old_opts <- options(timeout = 300)
  on.exit(options(old_opts), add = TRUE)

  wdi_raw <- WDI(
    country = "all",
    indicator = c(gdp_wdi = "NY.GDP.MKTP.CD", pop_wdi = "SP.POP.TOTL"),
    start = min(years),
    end = max(years),
    extra = TRUE
  )

  wdi_clean <- wdi_raw |>
    filter(region != "Aggregates", !is.na(iso3c)) |>
    select(iso3 = iso3c, year, gdp = gdp_wdi, pop = pop_wdi)

  message("WDI loaded: ", nrow(wdi_clean), " observations")

  return(wdi_clean)
}


#' Example Data: Small EU-ACP Subset
#'
#' A small example dataset for testing and documentation.
#' @format tibble with ~5000 rows
"eu_acp_example"
```

---

## Then Create Your Main Function (R/build_panel.R)

```r
#' Build Gravity Panel
#'
#' @param trade_data tibble from load_baci()
#' @param gravity structural and economic gravity data from load_gravity()
#' @param wdi GDP/pop data from load_wdi()
#' @param bloc_a character vector of ISO3 codes (e.g., EU members)
#' @param bloc_b character vector of ISO3 codes (e.g., ACP countries)
#' @param agreements tibble with columns: iso3, agreement_date
#' @param recs tibble with columns: iso3, rec
#' @param years numeric vector
#' @export
build_gravity_panel <- function(trade_data, gravity, wdi,
                                 bloc_a, bloc_b,
                                 agreements = NULL, recs = NULL,
                                 years = 1995:2022) {

  # 1. Filter to bilateral trade between blocs
  panel <- trade_data |>
    filter(
      (iso3_exp %in% bloc_a & iso3_imp %in% bloc_b) |
      (iso3_exp %in% bloc_b & iso3_imp %in% bloc_a)
    ) |>
    mutate(
      iso3_a = if_else(iso3_exp %in% bloc_a, iso3_exp, iso3_imp),
      iso3_b = if_else(iso3_exp %in% bloc_a, iso3_imp, iso3_exp)
    )

  # 2. Add gravity variables
  panel <- panel |>
    left_join(
      gravity$structural |>
        rename(iso3_a = iso3_o, iso3_b = iso3_d),
      by = c("iso3_a", "iso3_b", "year")
    )

  # 3. Add GDP/pop
  panel <- panel |>
    left_join(
      wdi |>
        rename(iso3_a = iso3, gdp_a = gdp, pop_a = pop),
      by = c("iso3_a", "year")
    ) |>
    left_join(
      wdi |>
        rename(iso3_b = iso3, gdp_b = gdp, pop_b = pop),
      by = c("iso3_b", "year")
    )

  # 4. Add treatment variable if agreements provided
  if (!is.null(agreements)) {
    panel <- panel |>
      left_join(
        agreements |>
          mutate(treatment = 1L),
        by = c("iso3_b" = "iso3")
      ) |>
      mutate(
        treatment = if_else(
          !is.na(treatment) & year >= as.integer(format(agreement_date, "%Y")),
          1L, 0L
        )
      )
  }

  # 5. Add REC variable if provided
  if (!is.null(recs)) {
    panel <- panel |>
      left_join(recs, by = c("iso3_b" = "iso3"))
  }

  return(panel)
}
```

---

## After Creating Files, Run

```r
devtools::document()     # Generate docs
devtools::check()        # Check for errors

# If all clear, commit and push:
git add .
git commit -m "Add data loading and panel building functions"
git push origin main
```


# Package Creation: What You Need to Know

## 1. Data Handling

**CRAN has a 5MB file size limit.** Options:

| Approach | How | Trade-off |
|----------|-----|-----------|
| **Code-only** | Package fetches data at runtime | Users need internet, slower first run |
| **Subsetted data** | Include small example dataset | Users can test immediately |
| **External citation** | Users download separately | More work for users |

**Recommendation:** Code-only. Include small example dataset (~1000 rows) for vignettes/documentation.

---

## 2. Licensing

| Data Source | License | What You Can Do |
|-------------|---------|-----------------|
| CEPII Gravity | Free for academic use | Include code to fetch, cite them |
| BACI (CEPII) | Free for academic use | Include code to fetch, cite them |
| WDI (World Bank) | CC-BY | Include code to fetch, cite |

**In your DESCRIPTION:**

```yaml
License: MIT + file LICENSE
```

**Create LICENSE file:**

```
YEAR (2024) YOUR NAME

Permission is hereby granted... [MIT license text]
```

---

## 3. Setup Commands (Terminal)

```bash
# 1. Install usethis if needed
R -e "install.packages('usethis')"

# 2. Create package in your project folder
cd /path/to/your/project
R -e "usethis::create_package('gravitas')"

# 3. Initialize git
cd gravitas
git init

# 4. Create GitHub repo (opens browser - authenticate first)
R -e "usethis::create_github_remote()"

# 5. Create initial commit
git add .
git commit -m "Initial commit: gravitas package skeleton"
git branch -M main
git push -u origin main
```

---

## 4. What Your Package Will Include

```
gravitas/
├── DESCRIPTION           # Metadata + licenses
├── LICENSE               # MIT license
├── LICENSE.md            # Full license text
├── README.md             # Landing page
│
├── R/                    # Your functions (code-only, no raw data)
│   ├── data.R            # Hardcoded lookups (EPA dates, EU members, etc.)
│   ├── load_data.R       # Functions to fetch BACI/CEPII/WDI at runtime
│   ├── build_panel.R
│   ├── estimate.R
│   └── plot.R
│
├── data/
│   └── eu_acp_example.rda  # Small example dataset (optional, <5MB)
│
├── man/                  # Auto-generated (don't edit)
│
├── vignettes/
│   ├── intro.Rmd
│   └── eu_acp_replication.Rmd
│
└── tests/
    └── testthat/
```

---

## 5. Before First Upload

```r
# In R, run these checks:
devtools::check()              # Must pass with 0 errors
devtools::build_readme()       # Check README renders
```

**Common issues to fix:**
- Missing dependencies in DESCRIPTION
- Undocumented functions (run `devtools::document()`)
- Broken URLs

---

## 6. Upload to GitHub

```bash
# After your first commit and local git is set up:
git add .
git commit -m "First functional version"
git push origin main
```

Then share via:
```
https://github.com/YOURUSERNAME/gravitas
```

Users install with:
```r
devtools::install_github("YOURUSERNAME/gravitas")
```

---

## Summary Checklist

- [ ] Check data licenses allow redistribution (or code-only approach)
- [ ] Add LICENSE file (MIT)
- [ ] Cite data sources in README/vignettes
- [ ] Keep raw data external (code fetches it)
- [ ] Include small example dataset if helpful
- [ ] Run `devtools::check()` before first upload
- [ ] Initialize git, create GitHub remote, push

***
---

# Phase 1: Setup & Prerequisites

### 1. Install Required Software

| Software | What it does | Download |
|----------|--------------|----------|
| **R** | The language | [cran.r-project.org](https://cran.r-project.org) |
| **RStudio** | IDE (you already have this) | [posit.co](https://posit.co/download) |
| **Git** | Version control | [git-scm.com](https://git-scm.com) |
| **Rtools** | Build packages (Windows) | Install via `install.packages("Rtools")` |

### 2. Configure Git in RStudio

```
Tools → Global Options → Git/SVN
```

- Enable version control
- Set Git executable path (e.g., `C:/Program Files/Git/bin/git.exe`)
- Restart RStudio

### 3. Install Development Packages

```r
install.packages(c("devtools", "usethis", "roxygen2", "testthat", "pkgload"))
```

---

## Phase 2: Create the Package

### Option A: Using usethis (Recommended)

```r
library(usethis)

# Creates folder structure in current working directory
create_package("path/to/mypackage")
```

### Option B: Manual Structure

```
mypackage/
├── DESCRIPTION      # Package metadata
├── NAMESPACE        # Exports (auto-generated)
├── R/
│   └── hello.R      # Your functions here
├── man/
│   └── hello.Rd     # Documentation (auto-generated)
├── tests/
│   └── testthat/
│       └── test_hello.R
└── README.md
```

---

## Phase 3: Write Your Functions

### Create a new R file in the `R/` folder

```r
# R/hello.R

#' Say Hello
#'
#' Returns a friendly greeting.
#'
#' @param name A character string (default: "World")
#' @return A character string greeting
#' @export
#' @examples
#' hello()
#' hello("Alice")

hello <- function(name = "World") {
  paste0("Hello, ", name, "!")
}
```

### Key Roxygen2 Tags

| Tag | Purpose |
|-----|---------|
| `@title` | Short title |
| `@description` | Longer description |
| `@param` | Describe inputs |
| `@return` | What the function returns |
| `@export` | Makes function available to users |
| `@examples` | Runnable examples |

---

## Phase 4: Document

```r
library(devtools)

# Generates documentation from roxygen2 comments
document()

# Or use Ctrl+Shift+D shortcut
```

---

## Phase 5: Test Your Package

### Set up testthat

```r
use_testthat()
```

### Create a test file

```r
# tests/testthat/test_hello.R

test_that("hello works correctly", {
  expect_equal(hello(), "Hello, World!")
  expect_equal(hello("Alice"), "Hello, Alice!")
})
```

### Run tests

```r
test()  # Run all tests
test_file("tests/testthat/test_hello.R")  # Run specific file
```

---

## Phase 6: Version Control with Git

### Initialize repo (do once per project)

```r
library(usethis)

use_git()          # Initialize Git
use_github()       # Push to GitHub (requires Git configured)
```

### Typical workflow

```r
# Check status
status()

# Stage files
add("R/hello.R")

# Commit
commit(message = "Add hello function")

# Push to GitHub
push()
```

---

## Phase 7: Build & Install

```r
# Load package (dev mode - like reinstall)
load_all()

# Install package to your R library
install()

# Build package (creates .tar.gz)
build()

# Build binary (for sharing)
build(binary = TRUE)
```

---

## Phase 8: Common Shortcuts (RStudio)

| Action | Shortcut |
|--------|----------|
| Load package | `Ctrl + Shift + L` |
| Document | `Ctrl + Shift + D` |
| Run tests | `Ctrl + Shift + T` |
| Install | `Ctrl + Shift + B` |
| Check package | `Ctrl + Shift + E` |

---

## Checklist Before Sharing

- [ ] Functions documented with roxygen2
- [ ] Tests written and passing
- [ ] DESCRIPTION filled out (title, author, license)
- [ ] README.md added
- [ ] Pushed to GitHub

---

## Quick Reference: Essential Commands

```r
library(devtools)
library(usethis)

load_all()      # Load package without installing
document()      # Generate docs
check()         # Run R CMD check
install()       # Install to library
test()          # Run tests
build()         # Build package file
```

---