# CLAUDE.md

## Project overview

This is a module in a "Data Science for Economists" course at the Kiel Institute. The folder `11-ai-assisted-research` demonstrates how AI coding assistants can be used in applied economics research workflows.

## Current content

- `code/01-spatial_heterogeneity.R` — Merges Colombian customs import data (2018) with department-level presidential election results. Produces five figures (bar chart, scatter, ranked bars, boxplot, choropleth maps) and a summary table.
- Input data: Colombian import CSVs read from `../03-large-structured-data/temp/Impo_2018/`
- Outputs: PNG + PDF figures in `output/figures/`, summary CSV in `output/tables/`
- Write-up: Results written up in Overleaf; PDF figures are copied to the Overleaf project directory

## Repository conventions

- **Primary language**: R (tidyverse style). Python is used occasionally.
- **Script naming**: Numbered prefixes (`01-`, `02-`, ...) to indicate execution order.
- **Folder layout**: Each module uses `code/`, `input/`, `output/`, `temp/`.
  - `input/` — raw data and source files (gitignored)
  - `output/` — results, figures, tables (gitignored)
  - `temp/` — intermediate/scratch files (gitignored)
  - `code/` — scripts and notebooks (version-controlled)

## Coding style

- R code should follow tidyverse style (pipes `|>` or `%>%`, snake_case, etc.)
- Use `pacman::p_load()` calls at the top of scripts
- Prefer `data.table` for data manipulation; `dplyr` is acceptable
- Keep scripts self-contained: each script should be runnable on its own
- Use relative paths from the module root (e.g. `input/data.csv`, not absolute paths)

### Script structure

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

- Section comments with trailing `----` for code folding
- Create output directories at script start: `dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)`
- Save figures as both PNG (viewing) and PDF (publication)
- Clean up large objects with `rm()` after use

## What to avoid

- Do not write to `code/` from scripts — only `output/` and `temp/`
- Do not commit large data files; they belong in `input/` or `temp/` (both gitignored)
- Do not add unnecessary dependencies; keep things simple and reproducible
