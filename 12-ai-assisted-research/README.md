# AI-Assisted Research

This module demonstrates how AI coding assistants and agentic tools can be integrated into an applied economics research workflow. Rather than treating AI as a black box for generating text, the focus is on using these tools as interactive collaborators for writing, debugging, and running code.

## Tools covered

- **Claude Code** — an agentic coding assistant running in the terminal that can read, write, and execute code, explore repositories, and interact with APIs and the file system directly
- **ChatGPT / Canvas** — conversational AI for brainstorming, drafting code snippets, and iterating on analysis ideas
- **Codex (OpenAI)** — an autonomous software engineering agent that can work on tasks asynchronously in a sandboxed cloud environment

## Example analysis

The module includes a worked example analyzing spatial heterogeneity in Colombian imports and the 2018 presidential election. The script `code/01-spatial_heterogeneity.R` merges Colombian customs data with department-level election results to produce:

- Bar charts comparing import volumes by political leaning
- Scatter plots of vote share vs. import intensity
- Ranked department-level import profiles
- Firm-level distribution comparisons
- Choropleth maps of vote share and import value

Results were written up in a short paper using Overleaf. This demonstrates how an AI coding assistant can help build a complete data pipeline — from raw data ingestion through visualization and write-up — in an interactive, iterative workflow.

## Topics

- Setting up and configuring AI coding assistants for research projects
- Prompting strategies: how to give context, break down tasks, and iterate
- Using AI assistants to clean and transform data (e.g. with R or Python)
- Code review and debugging with AI support
- Generating reproducible analysis pipelines with human oversight
- Limitations, pitfalls, and when not to trust the output

## Folder structure

```
11-ai-assisted-research/
├── code/       # Scripts and notebooks
├── input/      # Raw data and source files (not tracked)
├── output/     # Results, figures, tables (not tracked)
└── temp/       # Intermediate and scratch files (not tracked)
```

## Data

The example script reads Colombian import records from `../03-large-structured-data/temp/Impo_2018/`. Run the data-preparation scripts in module `03-large-structured-data` first to generate these files.

## Requirements

- R with packages: `data.table`, `ggplot2`, `scales`, `sf`, `rnaturalearth`, `rnaturalearthdata`, `patchwork`
- Packages are installed automatically via `pacman::p_load()`
