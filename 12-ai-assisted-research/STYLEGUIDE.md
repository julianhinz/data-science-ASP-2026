# Repository Style Guide

**Author:** Julian Hinz
**Version:** 1.2.0
**Last updated:** 2026-02-26
**Formerly:** `REPOSTYLE.md`

An opinionated style guide for R-based research projects (simulation and empirical work). These are my conventions — the way I organize code, data, and outputs. Not every choice will suit every project or person, but consistency within and across my repositories is the point.

---

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Directory Structure](#directory-structure)
3. [File Naming Conventions](#file-naming-conventions)
4. [R Code Style](#r-code-style)
5. [Commenting Style](#commenting-style)
6. [Project Settings](#rstudio-project-settings)
7. [Git Configuration](#git-configuration)
8. [Workflow Pattern](#workflow-pattern)
9. [Empirical Work](#empirical-work-regressions)
10. [Data Organization](#data-organization-patterns)
11. [Output Standards](#output-standards)
12. [Dependencies](#dependencies)
13. [Command-Line Execution](#command-line-execution)
14. [Build Orchestration](#build-orchestration-with-make)
15. [README Documentation](#readme-documentation)
16. [CLAUDE.md](#claudemd--llm-project-context)
17. [Citation](#citation-file-optional)
18. [Git Branching](#git-branching-strategy)
19. [GitHub Actions](#github-actions-automated-latex-builds)
20. [Development Notes](#development-notes-optional)
21. [Summary Checklist](#summary-checklist)

---

## Quick Reference

### File Naming
```
code/NN-description.R          # Numbered scripts (01-, 02-, ...)
output/YYMMDD_description.ext  # Date-prefixed outputs
```

### Script Structure
```r
###
# NN - Script Title
# YYMMDD
###

pacman::p_load(data.table, ggplot2)

# 0 - settings ----
# 1 - load data ----
# 2 - process ----
# 3 - output ----
```

### Key Patterns
```r
# Data manipulation: data.table with native pipe
result <- dt[filter] |> _[, .(x = sum(y)), by = group]

# Figures: subset → plot → save PNG+PDF → cleanup
plot_data <- dt[, .(needed_cols)]
p <- ggplot(plot_data, ...)
ggsave("output/figures/YYMMDD_name.png", p)
ggsave("output/figures/YYMMDD_name.pdf", p)
rm(plot_data, p)

# Large files
fwrite(dt, "file.csv.gz")  # compressed CSV
arrow::write_parquet(dt, "file.parquet")
```

### Commands
```bash
Rscript code/01-script.R   # Run single script
make                       # Build all targets
make clean                 # Remove generated files
```

---

## Directory Structure

```
project-root/
├── .git/                          # Git version control
├── .github/                       # GitHub configuration (optional)
│   └── workflows/
│       └── build.yml              # CI/CD for LaTeX builds
├── .gitignore                     # Git ignore rules
├── .Rprofile                      # R startup (renv activation)
├── .Rproj.user/                   # RStudio user settings (ignored)
├── .Rhistory                      # R command history (ignored)
├── project-name.Rproj             # RStudio project file
├── CITATION.cff                   # Citation metadata (optional)
├── CITATION.bib                   # BibTeX citation (optional)
├── CLAUDE.md                      # Project context for LLM assistants
├── Makefile                       # Build orchestration
├── README.md                      # Project documentation
├── STYLEGUIDE.md                  # This style guide
├── renv.lock                      # Package versions (optional)
├── renv/                          # renv configuration (optional)
│
├── dev-notes/                     # Development session notes (optional)
│   └── YYMMDD_HHMM_description.md
│
├── code/                          # All source code
│   ├── 00-helper_functions.R      # Shared utility functions
│   ├── 01-prepare_initial_conditions.R
│   ├── 02-prepare_scenarios.R
│   ├── 03-run_simulations.R
│   ├── 04-generate_output.R
│   ├── dependencies/              # External packages/tarballs
│   │   └── package_version.tar.gz
│   └── functions/                 # Reusable function modules
│       ├── extract_initial_conditions.R
│       └── extract_output.R
│
├── input/                         # Raw/source data (read-only, git-ignored)
│   ├── initial_conditions/        # Baseline model inputs
│   │   └── *.rds
│   ├── metadata/                  # Reference data and lookups
│   │   ├── countrygroups.R        # Country group definitions
│   │   └── *.xlsx                 # External documentation
│   └── projections/               # External projection data
│       └── source_name/
│           └── *.csv
│
├── output/                        # Generated outputs (git-ignored)
│   ├── figures/                   # Generated plots
│   │   └── YYMMDD_description.png
│   ├── tables/                    # Generated data tables
│   │   └── YYMMDD_description.csv
│   ├── initial_conditions/        # Processed model inputs
│   │   └── scenario_name/
│   │       └── *.rds
│   └── presentations/             # Report outputs
│       ├── YYMMDD_name.qmd        # Quarto source
│       ├── YYMMDD_name.tex        # LaTeX intermediate
│       └── YYMMDD_name.pdf        # Final output
│
└── temp/                          # Temporary/intermediate files (git-ignored)
    ├── scenarios/                 # Scenario definitions
    │   └── YYMMDD_scenario_name.rds
    ├── simulations/               # Raw simulation outputs
    │   └── scenario_name/
    │       └── *.rds
    └── results_list_*.rds         # Aggregated results
```

---

## File Naming Conventions

### Code Files

- **Numbered prefix**: Scripts are numbered to indicate execution order
  - Format: `NN-descriptive_name.R`
  - Examples: `00-helper_functions.R`, `01-prepare_initial_conditions.R`
  - `00-` prefix reserved for shared utilities/helpers

- **Snake case**: Use underscores to separate words
  - Correct: `prepare_initial_conditions.R`
  - Avoid: `prepareInitialConditions.R`, `prepare-initial-conditions.R`

### Data Files

- **Date prefix**: Output files include creation date
  - Format: `YYMMDD_description.ext`
  - Examples: `250704_real_gdp_change.png`, `250723_scenarios_trade_policy_v7.rds`

- **Version suffix**: When iterating on outputs
  - Format: `YYMMDD_description_vN.ext`
  - Examples: `250711_scenarios_trade_policy_v2.rds`

- **Descriptive naming**: File names should indicate content
  - Include: metric name, transformation type
  - Examples: `real_gdp_change`, `nominal_exports_change`, `welfare_change`

### Output Formats

| Purpose | Format | Extension |
|---------|--------|-----------|
| R objects | RDS (compressed) | `.rds` |
| Small tabular data | CSV | `.csv` |
| Large tabular data | Compressed CSV or Parquet | `.csv.gz`, `.parquet` |
| Figures (default) | PNG | `.png` |
| Figures (publication) | PDF | `.pdf` |
| Figure data | Minimal CSV | `.csv` |
| Documents | PDF via Quarto | `.qmd`, `.pdf` |

### Large File Handling

For datasets exceeding ~50MB, prefer compressed formats:

```r
# Compressed CSV (good compatibility)
fwrite(dt, "output/tables/large_data.csv.gz")
dt <- fread("output/tables/large_data.csv.gz")

# Parquet (best performance for very large files)
arrow::write_parquet(dt, "output/tables/large_data.parquet")
dt <- arrow::read_parquet("output/tables/large_data.parquet")
```

---

## R Code Style

### File Header

Every R script begins with a header block:

```r
###
# NN - Script Title
# YYMMDD
###
```

### Package Management

Use `pacman` for package loading:

```r
if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(ggplot2)
# ... additional packages
```

For custom/local packages:

```r
if (!require("PackageName")) devtools::install_local("code/dependencies/Package_version.tar.gz")
```

### Section Organization

Use commented section headers with trailing dashes:

```r
# 0 - settings ----
# 1 - load data ----
# 2 - prepare data ----
# 3 - run analysis ----
# 4 - save output ----
```

Subsections use nested numbering:

```r
## 2.1 - GDP ----
## 2.2 - Trade flows ----
```

### Directory Creation

Create output directories at script start with warnings suppressed:

```r
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
```

### Sourcing Dependencies

Source helper files at the beginning of scripts:

```r
source("code/00-helper_functions.R")
source("code/functions/extract_output.R")
source("input/metadata/countrygroups.R")
```

### Variable Naming

- **Snake case** for variables and functions: `initial_conditions`, `real_gdp`, `extract_output`
- **SCREAMING_SNAKE_CASE** for constants/country groups: `EU27`, `BRICS`, `ASEAN`
- **Descriptive names**: Prefer clarity over brevity

### Function Documentation

Functions in `code/functions/` use roxygen2-style documentation:

```r
#' Function Title
#' @param param_name Description of parameter.
#' @param param2 Another parameter description.
#' @return Description of return value.
#' @examples
#' # Example usage
#' result <- function_name(arg1, arg2)
#' @export
function_name <- function(param_name, param2) {
  # implementation
}
```

### Assignment Operator

- Use `=` for assignment within function arguments
- Use `<-` or `=` for variable assignment (project uses both, be consistent within files)

### Data Manipulation with data.table

Primary tool is `data.table`, with the native pipe `|>` for readability:

```r
# Basic data.table syntax
dt[country %in% countries_list]
dt[, new_col := computation]
dt[, `:=`(col1 = val1, col2 = val2)]
dt[, .(sum_col = sum(value)), by = .(group1, group2)]

# Chaining with native pipe for complex operations
result <- dt[year >= 2020] |>
  _[, .(total = sum(value)), by = .(country, sector)] |>
  _[order(-total)] |>
  _[1:10]

# Merging pattern
merged <- dt1[dt2, on = .(country, year)]
```

Note: `magrittr` is still loaded in some projects for `%>%` compatibility. New code should prefer `|>`.

### Custom Operators

Define custom operators at script top:

```r
`%nin%` <- Negate(`%in%`)
# or
`%nin%` = function(x, y) !x %in% y
```

### Memory Management

Explicit garbage collection for large objects:

```r
rm(large_object)
gc()
```

---

## Commenting Style

### File Header

Every script starts with a triple-hash block:

```r
###
# NN - Script Title
# YYMMDD
###
```

### Section Comments

Use trailing dashes for RStudio code folding:

```r
# 1 - load data ----
# 2 - prepare data ----

## 2.1 - GDP ----
## 2.2 - Trade flows ----

### - Tariffs ----
```

### Inline Comments

**After code** - brief explanations on the same line:

```r
value := value + 0.30]  # +30%
sector %nin% service_sectors,  # exclude services
```

**Code definitions** - explain codes, sectors, or country groups:

```r
critical_sectors = c(
  "B05T09",  # Mining and quarrying, non-energy
  "C24",     # Basic metals (steel)
  "C26",     # Computer, electronic products (semiconductors)
  "C29",     # Motor vehicles
)
```

**Action headers** - brief description before a code block:

```r
# US tariffs on China: 30%
scenario$tariff_new[destination == "USA" & origin == "CHN",
                    value := value + 0.30]

# prettify
plot_data[, country_names := countrycode(country, "iso3c", "country.name")]

# save data as csv
fwrite(result, "output/tables/results.csv")
```

### Progress Markers

In loops, use `cat()` to track progress:

```r
for (s in names(scenarios)) {
  cat("Running scenario:", s)
  # ... processing ...
  cat(" - 2025")
  cat(" - 2026")
  cat(" - done\n")
}
```

### Commented-Out Code

Keep disabled alternatives with explanation:

```r
# Alternative model (slower but more accurate)
# results = update_equilibrium(model = alternative_model,
#                              initial_conditions = ic,
#                              settings = list(tolerance = 1e-6))
```

### What NOT to Comment

- Obvious operations (`# increment i` before `i <- i + 1`)
- Self-documenting code with clear variable names
- Every line - comments should add information, not noise

---

## RStudio Project Settings

The `.Rproj` file configures:

```
Version: 1.0
RestoreWorkspace: Default
SaveWorkspace: Default
AlwaysSaveHistory: Default
EnableCodeIndexing: Yes
UseSpacesForTab: Yes
NumSpacesForTab: 2
Encoding: UTF-8
AutoAppendNewline: Yes
StripTrailingWhitespace: Yes
```

Key settings:
- **2-space indentation** (spaces, not tabs)
- **UTF-8 encoding**
- **Auto-append newline** at end of files
- **Strip trailing whitespace**

---

## Git Configuration

### .gitignore

```
.DS_Store
.Rproj.user
.Rhistory
/input
/output
/temp
```

The `input/` directory is (almost) always git-ignored. Raw data and metadata are typically too large or externally sourced to track in version control. Distribute input data separately (shared drives, data repositories, README instructions).

Metadata (country groups, sector classifications, lookup tables) lives inside `input/metadata/` rather than in a separate top-level directory. This keeps all external/reference data in one place and ensures it is covered by the same gitignore rule.

### What to Commit

| Include | Exclude |
|---------|---------|
| Source code (`code/`) | Input data (`input/`) |
| Project file (`.Rproj`) | Generated outputs (`output/`) |
| Documentation (`*.md`) | Temporary files (`temp/`) |
| Build files (`Makefile`) | R history (`.Rhistory`) |
| Dev notes (`dev-notes/`) | User settings (`.Rproj.user`) |

### Commit Practices

- **First commit**: The initial commit message should be extensive — describe the full project scope, pipeline stages, and infrastructure in the commit body
- Commit logical units of work
- Reference version numbers in output file names for traceability
- Keep input data stable; version through file naming
- **No `Co-Authored-By` trailers** — never include `Co-Authored-By` lines in commit messages

---

## Workflow Pattern

### Pipeline Stages

1. **Prepare Initial Conditions** (`01-`)
   - Load raw input data
   - Clean and transform
   - Save processed `.rds` files

2. **Prepare Scenarios** (`02-`)
   - Define scenario parameters
   - Create scenario variations
   - Save scenario definitions

3. **Run Simulations** (`03-`)
   - Load scenarios and conditions
   - Execute model
   - Save simulation results

4. **Generate Output** (`04-`)
   - Load simulation results
   - Compute derived metrics
   - Create visualizations
   - Export tables and figures

### Reproducibility

- Scripts are designed to run sequentially
- Each script produces outputs consumed by later scripts
- Date-versioned outputs enable tracking iterations

---

## Empirical Work (Regressions)

### Package: fixest

Use `fixest` for all regression analysis:

```r
p_load(fixest)

# Basic fixed effects regression
model <- feols(outcome ~ treatment + controls | country + year, data = dt)

# Multiple outcomes
models <- feols(c(outcome1, outcome2) ~ treatment | country + year, data = dt)

# Clustered standard errors
model <- feols(outcome ~ treatment | country + year,
               data = dt,
               cluster = ~ country)

# Interaction with fixed effects
model <- feols(outcome ~ treatment:factor(period) | country + year, data = dt)
```

### Regression Tables

Export results with `etable()` or `modelsummary`:

```r
# fixest native
etable(model1, model2, model3,
       tex = TRUE,
       file = "output/tables/regression_results.tex")

# With modelsummary for more control
modelsummary(list("Model 1" = model1, "Model 2" = model2),
             output = "output/tables/regression_results.tex")
```

### Empirical Pipeline Structure

```r
# 01-prepare_data.R      - Clean and merge datasets
# 02-descriptive.R       - Summary statistics, balance tables
# 03-main_regressions.R  - Primary specifications
# 04-robustness.R        - Alternative specifications, placebo tests
# 05-figures.R           - Coefficient plots, event studies
```

---

## Data Organization Patterns

### Scenario Structure

Scenarios stored as named lists in `.rds` files:

```r
scenarios <- list(
  baseline = list(...),
  scenario_a = list(...),
  scenario_b = list(...)
)
```

### Initial Conditions

Structured as named lists containing data.tables:

```r
initial_conditions <- list(
  trade_balance = data.table(...),
  tariff = data.table(...),
  trade_elasticity = data.table(...)
)
```

### Country/Region Groupings

Defined as character vectors in `input/metadata/`:

```r
# input/metadata/countrygroups.R
EU27 = c("DEU", "FRA", "ITA", ...)
BRICS = c("BRA", "RUS", "IND", "CHN", "ZAF", ...)
ASEAN = c("BRN", "KHM", "IDN", ...)
```

### Sector Classifications

Defined as character vectors in `input/metadata/`, with inline comments:

```r
# input/metadata/sectors.R
critical_sectors = c(
  "B05T09",  # Mining and quarrying
  "C24",     # Basic metals (steel)
  "C26",     # Computer, electronic products
  # ...
)
```

---

## Output Standards

### Figures with ggplot2

All visualizations use `ggplot2`. Follow this pattern for reproducible figures:

```r
## Figure: Description ----

# 1. Prepare minimal plot data
plot_data <- full_data[relevant_filter] |>
  _[, .(x_var, y_var, group_var)] |>
  _[order(x_var)]

# 2. Create the plot
p <- ggplot(plot_data, aes(x = x_var, y = y_var, color = group_var)) +
  geom_line() +
  geom_point() +
  labs(title = "Figure Title",
       x = "X Label",
       y = "Y Label") +
  theme_minimal()

# 3. Save as PNG (default) and PDF (publication)
ggsave("output/figures/YYMMDD_figure_name.png", p, width = 8, height = 6, dpi = 300)
ggsave("output/figures/YYMMDD_figure_name.pdf", p, width = 8, height = 6)

# 4. Save minimal data for reproduction (on demand)
fwrite(plot_data, "output/figures/YYMMDD_figure_name_data.csv")

# 5. Clean up
rm(plot_data, p)
```

Key principles:
- **Subset first**: Create `plot_data` with only the columns and rows needed
- **Dual format**: Save both PNG (for quick viewing) and PDF (for publication)
- **Reproducible data**: On demand, save minimal CSV containing exactly what the figure shows
- **Clean up**: Remove plot objects after saving to free memory

### Tables

- Format: CSV for portability, `.csv.gz` for large files
- Naming: `YYMMDD_description.csv`
- Created with `data.table::fwrite()`

```r
fwrite(results_table, "output/tables/YYMMDD_results.csv")
fwrite(large_table, "output/tables/YYMMDD_large_results.csv.gz")  # auto-compressed
```

### Presentations

- Source: Quarto (`.qmd`)
- Intermediate: LaTeX (`.tex`)
- Output: PDF (`.pdf`)

---

## Dependencies

### Core Packages

- `data.table` - Data manipulation
- `ggplot2` - Visualization
- `fixest` - Regression analysis
- `stringr` - String operations
- `readr` - File I/O
- `arrow` - Parquet file support
- `scales` - Axis formatting
- `countrycode` - Country code conversion

### Project-Specific

- Custom packages stored in `code/dependencies/`
- Installed via `devtools::install_local()`

### Environment Reproducibility with renv (Optional)

Use `renv` to lock package versions for exact reproducibility:

```r
# Initialize renv in a new project
renv::init()

# After installing/updating packages, snapshot the environment
renv::snapshot()

# Collaborators restore the exact environment with
renv::restore()
```

#### Files to Commit

| File | Commit? | Purpose |
|------|---------|---------|
| `renv.lock` | Yes | Package versions (the lockfile) |
| `.Rprofile` | Yes | Auto-activates renv |
| `renv/settings.json` | Yes | Project settings |
| `renv/library/` | No | Local package cache (add to `.gitignore`) |

#### Updated .gitignore

```
# renv
renv/library/
renv/staging/
renv/sandbox/
```

#### When to Use renv

- Collaborative projects with multiple contributors
- Long-running projects where packages may update
- Publications requiring exact reproducibility
- Skip for quick, solo analyses

---

## Command-Line Execution

All scripts must run from the command line without interaction:

```bash
# Run a single script
Rscript code/01-prepare_data.R

# Run with specific working directory
Rscript --vanilla code/01-prepare_data.R
```

### Script Requirements

- No interactive prompts or `readline()` calls
- No `setwd()` - use relative paths from project root
- No hardcoded absolute paths
- Exit cleanly on completion or error

### Command-Line Arguments (Optional)

For scripts that accept parameters:

```r
args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]
output_dir <- args[2]
```

---

## Build Orchestration with Make

Use `Makefile` to define the pipeline and dependencies:

```makefile
# Makefile

.PHONY: all clean

all: output/figures/main_results.png output/tables/regression_results.csv

# Data preparation
temp/clean_data.rds: input/raw_data.csv code/01-prepare_data.R
	Rscript code/01-prepare_data.R

# Analysis
temp/model_results.rds: temp/clean_data.rds code/02-run_analysis.R
	Rscript code/02-run_analysis.R

# Figures
output/figures/main_results.png: temp/model_results.rds code/03-generate_figures.R
	Rscript code/03-generate_figures.R

# Tables
output/tables/regression_results.csv: temp/model_results.rds code/04-generate_tables.R
	Rscript code/04-generate_tables.R

# Clean generated files
clean:
	rm -rf temp/*
	rm -rf output/figures/*
	rm -rf output/tables/*
```

### Make Commands

```bash
make          # Build all targets
make clean    # Remove generated files
make -j4      # Parallel execution (4 jobs)
make -n       # Dry run (show what would be done)
```

### Benefits

- **Dependency tracking**: Only rebuild what changed
- **Parallelization**: Independent steps run concurrently
- **Documentation**: Makefile documents the pipeline
- **Reproducibility**: Single command rebuilds everything

---

## README Documentation

The `README.md` provides a quick overview for interested readers:

### Required Sections

```markdown
# Project Title

Brief description of the research question and findings.

## Overview

- What is this project about?
- What are the main results?
- Link to paper/preprint if available

## Data

- Description of data sources
- How to obtain the data (if not included)
- Data dictionary or link to documentation

## Repository Structure

project-root/
├── code/           # Analysis scripts
├── input/          # Raw data
├── output/         # Generated outputs
└── temp/           # Intermediate files

## Reproduction

How to reproduce the results:

1. Install R and required packages
2. Place data in `input/`
3. Run `make` (or run scripts in order)

## Requirements

- R version X.X
- Key packages: data.table, ggplot2, fixest, ...
- System tools: 7z, pandoc, make, ... (list any non-R dependencies)

## Authors

- Name (affiliation, email)

## License

Specify license (MIT, CC-BY, etc.)
```

### Keep It Concise

- Focus on what readers need to understand and reproduce
- Link to detailed documentation rather than including everything
- Update when major changes occur

---

## CLAUDE.md — LLM Project Context

Each project includes a `CLAUDE.md` file at the root. This provides project-specific context for LLM assistants (Claude Code, Cursor, etc.) and complements the generic `STYLEGUIDE.md`.

### What Goes in CLAUDE.md

- Project description and scope
- Repository structure (project-specific, not the generic template)
- Build commands and `make` targets
- Key parameters and configuration
- Project-specific conventions or deviations from STYLEGUIDE.md
- Gotchas, known issues, and technical notes

### What Does NOT Go in CLAUDE.md

- Generic R code style (that's in STYLEGUIDE.md)
- Reusable templates or patterns
- Anything already covered by STYLEGUIDE.md unless the project deviates from it

### Relationship to Other Files

| File | Audience | Scope |
|------|----------|-------|
| `README.md` | Humans (readers, collaborators) | Project overview, reproduction |
| `CLAUDE.md` | LLM assistants | Project-specific context for code generation |
| `STYLEGUIDE.md` | Both | Generic conventions across all projects |

---

## Citation File (Optional)

Add a `CITATION.cff` file to enable GitHub's "Cite this repository" feature and provide machine-readable citation metadata.

### CITATION.cff Template

```yaml
cff-version: 1.2.0
title: "Project Title: Subtitle"
message: "If you use this code, please cite it as below."
type: software
authors:
  - family-names: "LastName"
    given-names: "FirstName"
    orcid: "https://orcid.org/0000-0000-0000-0000"
    affiliation: "University Name"
  - family-names: "CoAuthor"
    given-names: "Name"
    affiliation: "Institution"
repository-code: "https://github.com/username/repo-name"
url: "https://project-website.com"
abstract: >-
  Brief description of the project and what
  the code does.
keywords:
  - economics
  - trade
  - simulation
license: MIT
version: 1.0.0
date-released: "2025-01-01"
preferred-citation:
  type: article
  authors:
    - family-names: "LastName"
      given-names: "FirstName"
    - family-names: "CoAuthor"
      given-names: "Name"
  title: "Paper Title"
  journal: "Journal Name"
  year: 2025
  doi: "10.1000/example.doi"
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `authors` | List all contributors with ORCID if available |
| `preferred-citation` | Points to the paper (if different from repo) |
| `doi` | Add when paper is published |
| `version` | Update with major releases |
| `date-released` | Date of current version |

### Companion BibTeX File

Also provide a `CITATION.bib` file for direct use in LaTeX:

```bibtex
@article{lastname2025paper,
  author    = {LastName, FirstName and CoAuthor, Name},
  title     = {Paper Title},
  journal   = {Journal Name},
  year      = {2025},
  volume    = {1},
  number    = {1},
  pages     = {1--50},
  doi       = {10.1000/example.doi}
}

@software{lastname2025code,
  author    = {LastName, FirstName and CoAuthor, Name},
  title     = {Project Title: Replication Code},
  year      = {2025},
  url       = {https://github.com/username/repo-name},
  version   = {1.0.0}
}
```

### Citation Section in README.md

Include a citation block in the README for easy copy-paste:

````markdown
## Citation

If you use this code, please cite:

```bibtex
@article{lastname2025paper,
  author    = {LastName, FirstName and CoAuthor, Name},
  title     = {Paper Title},
  journal   = {Journal Name},
  year      = {2025},
  doi       = {10.1000/example.doi}
}
```

For the code specifically:

```bibtex
@software{lastname2025code,
  author    = {LastName, FirstName and CoAuthor, Name},
  title     = {Project Title: Replication Code},
  year      = {2025},
  url       = {https://github.com/username/repo-name}
}
```
````

### Benefits

- GitHub displays "Cite this repository" button
- BibTeX file ready for direct `\bibliography{}` use
- README provides copy-paste citation for visitors
- Machine-readable for citation tools
- Links code to published paper

---

## Git Branching Strategy

### Branch Types

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready code |
| `feature/*` | New features or analyses |
| `experiment/*` | Exploratory work, may be discarded |
| `fix/*` | Bug fixes |

### Workflow

```bash
# Create feature branch
git checkout -b feature/add-robustness-checks

# Work on the feature
git add .
git commit -m "Add placebo regression"

# Merge back to main when complete
git checkout main
git merge feature/add-robustness-checks

# Delete the branch
git branch -d feature/add-robustness-checks
```

### Branch Naming

- Use lowercase with hyphens: `feature/add-event-study`
- Be descriptive but concise
- Include issue number if applicable: `fix/123-data-merge-error`

### When to Branch

- **Always branch** for new features or experiments
- **Direct to main** only for trivial fixes (typos, comments)
- **Keep branches short-lived**: merge or delete within days/weeks

---

## GitHub Actions: Automated LaTeX Builds

If LaTeX source files are tracked in the repository, use GitHub Actions to automatically build PDFs.

### Directory Structure

```
.github/
└── workflows/
    └── build.yml
```

### Workflow File

Create `.github/workflows/build.yml`:

```yaml
name: Build Paper and Slides

on:
  push:
    branches:
      - main
    paths:
      - 'output/**'
      - 'Makefile'
      - '.github/workflows/build.yml'
  pull_request:
    branches:
      - main
    paths:
      - 'output/**'
      - 'Makefile'
      - '.github/workflows/build.yml'
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    if: github.event_name != 'pull_request'

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Install TeX Live and Pandoc
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            texlive-latex-base \
            texlive-latex-extra \
            texlive-latex-recommended \
            texlive-fonts-recommended \
            texlive-fonts-extra \
            texlive-bibtex-extra \
            texlive-luatex \
            texlive-science \
            texlive-publishers \
            pandoc \
            poppler-utils

      - name: Build paper
        run: make paper

      - name: Build slides
        run: make slides

      - name: Generate preview images
        run: make previews

      - name: Commit and push changes
        run: |
          git config --local user.email "github-actions[bot]@users.noreply.github.com"
          git config --local user.name "github-actions[bot]"
          git add output/paper.pdf output/slides.pdf output/paper-preview.png output/slides-preview.png
          if ! git diff --staged --quiet; then
            git commit -m "Build paper and slides [skip ci]"
            git push
          else
            echo "No changes to commit"
          fi

  build-pr:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install TeX Live and Pandoc
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            texlive-latex-base \
            texlive-latex-extra \
            texlive-latex-recommended \
            texlive-fonts-recommended \
            texlive-fonts-extra \
            texlive-bibtex-extra \
            texlive-luatex \
            texlive-science \
            texlive-publishers \
            pandoc \
            poppler-utils

      - name: Build paper
        run: make paper

      - name: Build slides
        run: make slides

      - name: Upload paper PDF
        uses: actions/upload-artifact@v4
        with:
          name: paper
          path: output/paper.pdf
          retention-days: 30

      - name: Upload slides PDF
        uses: actions/upload-artifact@v4
        with:
          name: slides
          path: output/slides.pdf
          retention-days: 30
```

### Workflow Behavior

| Event | Action |
|-------|--------|
| Push to `main` | Build PDFs, commit back to repo |
| Pull request | Build PDFs, upload as artifacts (no commit) |
| Manual trigger | Build PDFs, commit back to repo |

### Required Makefile Targets

The workflow expects these targets in your `Makefile`:

```makefile
paper: output/paper.pdf
slides: output/slides.pdf
previews: output/paper-preview.png output/slides-preview.png

output/paper.pdf: output/paper.tex output/figures/*.pdf
	cd output && latexmk -pdf paper.tex

output/slides.pdf: output/slides.tex output/figures/*.pdf
	cd output && latexmk -pdf slides.tex

output/%-preview.png: output/%.pdf
	pdftoppm -png -f 1 -singlefile $< output/$*-preview
```

### Key Features

- **Path filtering**: Only runs when relevant files change
- **Separate PR job**: PRs get artifacts instead of commits (avoids merge conflicts)
- **Skip CI tag**: `[skip ci]` prevents infinite build loops
- **Preview images**: First page of PDFs converted to PNG for README display

---

## Development Notes (Optional)

Maintain a `dev-notes/` directory with timestamped session logs. This helps humans and LLMs pick up context from previous work sessions.

### Directory Structure

```
dev-notes/
├── 260112_1430_initial_setup.md
├── 260113_0900_add_robustness_checks.md
├── 260115_1600_fix_convergence_issue.md
└── 260120_1100_reviewer_comments.md
```

### File Naming

Format: `YYMMDD_HHMM_short_description.md`

- **YYMMDD**: Date (year-month-day)
- **HHMM**: Time in 24h format (hour-minute)
- **short_description**: 2-4 words, snake_case

### Template

```markdown
# Session: Short Description

**Date:** 2026-01-12 14:30
**Duration:** ~2 hours

## Context

Brief description of what this session is about and any relevant background.

## What Was Done

- [ ] Task 1 completed
- [ ] Task 2 completed
- [x] Task 3 in progress (partial)

### Details

More detailed notes on implementation decisions, problems encountered, etc.

## Key Decisions

- Decision 1: Chose approach X because Y
- Decision 2: Deferred Z until after review

## Issues Encountered

- Issue 1: Description and how it was resolved
- Issue 2: Still open, needs investigation

## Next Steps

1. Immediate next task
2. Follow-up task
3. Items to discuss with collaborators

## Files Changed

- `code/03-run_simulations.R` - Added new scenario
- `output/figures/` - Regenerated all plots

## Notes for Future Sessions

Any context that would help picking up this work later.
```

### Benefits

| Benefit | Description |
|---------|-------------|
| **Session continuity** | Pick up exactly where you left off |
| **LLM context** | AI assistants can read notes to understand project state |
| **Decision log** | Remember why choices were made |
| **Collaboration** | Team members can follow progress |
| **Debugging** | Track when issues were introduced |

### Best Practices

- Create a new note at the **start** of each work session
- Update the "What Was Done" section as you work
- Write "Next Steps" **before** ending the session
- Keep notes concise but complete enough to resume cold
- Commit notes to git (they're documentation, not secrets)

### Git Integration

Add to `.gitignore` only if notes contain sensitive information:

```
# Usually DO commit dev-notes (recommended)
# dev-notes/  # Uncomment only if notes contain sensitive info
```

---

## Summary Checklist

### Code Organization
- [ ] Scripts numbered in execution order (`01-`, `02-`, ...)
- [ ] File names use snake_case with date prefix
- [ ] Headers include script name and date (`###` block)
- [ ] Sections marked with `# N - description ----`
- [ ] Inline comments explain non-obvious code
- [ ] Constants in SCREAMING_SNAKE_CASE
- [ ] Functions documented with roxygen2 style

### Data and Memory
- [ ] Use `data.table` with native `|>` pipe
- [ ] Large files saved as `.csv.gz` or `.parquet`
- [ ] Large objects cleaned with `rm()` and `gc()`
- [ ] Packages loaded via pacman

### Figures
- [ ] All plots created with `ggplot2`
- [ ] Figures saved as both PNG and PDF
- [ ] Plot data subsetted before plotting
- [ ] Minimal CSV saved for figure reproduction (on demand)
- [ ] Plot objects cleaned up after saving

### Reproducibility
- [ ] All scripts run from command line (`Rscript`)
- [ ] No `setwd()` or hardcoded paths
- [ ] Makefile defines pipeline and dependencies
- [ ] Output directories created at script start
- [ ] `input/`, `output/`, `temp/` excluded from git

### Documentation
- [ ] README covers: overview, data, structure, reproduction, system dependencies
- [ ] README is concise and up-to-date
- [ ] `CLAUDE.md` with project-specific context for LLM assistants

### Version Control
- [ ] First commit message is extensive (full project scope)
- [ ] Feature branches for new work
- [ ] Main branch stays stable
- [ ] Branches merged or deleted promptly

### CI/CD (if LaTeX tracked)
- [ ] GitHub Actions workflow in `.github/workflows/build.yml`
- [ ] Makefile targets for `paper`, `slides`, `previews`
- [ ] PDFs auto-built on push to main
- [ ] PR builds uploaded as artifacts

### Optional Enhancements
- [ ] `renv.lock` for package version reproducibility
- [ ] `CITATION.cff` for machine-readable citation
- [ ] `CITATION.bib` for direct LaTeX use
- [ ] Citation block in README.md
- [ ] `dev-notes/` for session continuity (human + LLM)
- [ ] GitHub Actions for automated LaTeX builds
