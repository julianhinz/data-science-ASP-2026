## ----------------------------------------------------------
## 01-spatial_heterogeneity.R
## Spatial heterogeneity in Colombian imports × 2018 election
## ----------------------------------------------------------

# 0 - Settings -------------------------------------------------------

pacman::p_load(data.table, ggplot2, scales, sf, rnaturalearth, rnaturalearthdata, patchwork)

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables",  recursive = TRUE, showWarnings = FALSE)

# 1 - Load import data ------------------------------------------------

data_dir <- "../03-large-structured-data/temp/Impo_2018"
csv_files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

keep_cols <- c("DEPTODES", "VADUA", "NIT", "FECH", "VAFODO")

read_one <- function(f) {
  first_line <- readLines(f, n = 1, warn = FALSE)
  sep <- if (grepl(";", first_line)) ";" else ","
  dt <- fread(f, sep = sep, select = keep_cols, showProgress = FALSE)
  dt
}

imports <- rbindlist(lapply(csv_files, read_one))

imports[, `:=`(
  DEPTODES = as.integer(DEPTODES),
  VADUA    = as.numeric(VADUA),
  VAFODO   = as.numeric(VAFODO)
)]

imports <- imports[DEPTODES > 0 & !is.na(DEPTODES) & !is.na(VADUA)]

cat("Loaded", format(nrow(imports), big.mark = ","), "import records\n")

# 2 - Election data ---------------------------------------------------

election <- data.table(
  dept_code = c(5L, 8L, 11L, 13L, 15L, 17L, 18L, 19L, 20L, 23L,
                25L, 27L, 41L, 44L, 47L, 50L, 52L, 54L, 63L, 66L,
                68L, 70L, 73L, 76L, 81L, 85L, 86L, 88L, 91L, 94L,
                95L, 97L, 99L),
  dept_name = c("Antioquia", "Atlantico", "Bogota", "Bolivar", "Boyaca",
                "Caldas", "Caqueta", "Cauca", "Cesar", "Cordoba",
                "Cundinamarca", "Choco", "Huila", "La Guajira", "Magdalena",
                "Meta", "Narino", "Norte de Santander", "Quindio", "Risaralda",
                "Santander", "Sucre", "Tolima", "Valle del Cauca", "Arauca",
                "Casanare", "Putumayo", "San Andres", "Amazonas", "Guainia",
                "Guaviare", "Vaupes", "Vichada"),
  petro_pct = c(36.5, 55.2, 43.0, 63.7, 37.0,
                30.1, 46.2, 57.2, 58.2, 62.5,
                35.4, 79.6, 42.6, 58.9, 62.3,
                38.7, 64.3, 50.3, 29.8, 37.2,
                40.2, 65.1, 41.3, 47.3, 52.5,
                32.7, 56.2, 38.2, 55.0, 54.0,
                50.8, 55.0, 47.0)
)

election[, leaning := fifelse(
  petro_pct > 50,
  "Left-leaning (Petro)",
  "Right-leaning (Duque)"
)]

# 3 - Aggregate imports by department ----------------------------------

dept_agg <- imports[, .(
  total_customs_value = sum(VADUA, na.rm = TRUE),
  total_fob_value     = sum(VAFODO, na.rm = TRUE),
  n_firms             = uniqueN(NIT),
  n_transactions      = .N,
  mean_value_per_firm = sum(VADUA, na.rm = TRUE) / uniqueN(NIT)
), by = .(dept_code = DEPTODES)]

# 4 - Merge election × trade ------------------------------------------

merged <- merge(dept_agg, election, by = "dept_code", all.x = FALSE)

cat("Merged", nrow(merged), "departments\n")

# Colour palette: red = left (Petro), blue = right (Duque)
lean_colors <- c("Left-leaning (Petro)"  = "#D32F2F",
                 "Right-leaning (Duque)" = "#1565C0")

# 5 - Figures ----------------------------------------------------------

theme_clean <- theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "bottom"
  )

# --- Figure 1: Bar chart – total imports by political leaning ----------

fig1_data <- merged[, .(
  total_value = sum(total_customs_value)
), by = leaning]

p1 <- ggplot(fig1_data, aes(x = leaning, y = total_value, fill = leaning)) +
  geom_col(width = 0.6) +
  scale_fill_manual(values = lean_colors) +
  scale_y_continuous(labels = label_comma(scale = 1e-9, suffix = "B")) +
  labs(
    title    = "Total Imports by Political Leaning",
    subtitle = "Colombian departments, 2018 customs value (USD)",
    x = NULL, y = "Total customs value (billions USD)"
  ) +
  theme_clean +
  theme(legend.position = "none")

ggsave("output/figures/fig1_imports_by_leaning.png", p1, width = 6, height = 5, dpi = 300)
ggsave("output/figures/fig1_imports_by_leaning.pdf", p1, width = 6, height = 5)

# --- Figure 2: Scatter – Petro vote share vs mean import value ---------

p2 <- ggplot(merged, aes(x = petro_pct, y = mean_value_per_firm,
                          color = leaning, size = n_firms)) +
  geom_point(alpha = 0.7) +
  geom_smooth(aes(x = petro_pct, y = mean_value_per_firm),
              method = "lm", se = TRUE, color = "grey30",
              linewidth = 0.8, linetype = "dashed",
              inherit.aes = FALSE) +
  scale_y_log10(labels = label_comma()) +
  scale_color_manual(values = lean_colors) +
  scale_size_continuous(range = c(2, 12), labels = label_comma()) +
  labs(
    title    = "Petro Vote Share vs Mean Import Value per Firm",
    subtitle = "Each point is a department; size = number of importing firms",
    x = "Petro vote share (%)", y = "Mean customs value per firm (log scale)",
    color = "Political leaning", size = "Number of firms"
  ) +
  theme_clean

ggsave("output/figures/fig2_scatter_vote_imports.png", p2, width = 8, height = 6, dpi = 300)
ggsave("output/figures/fig2_scatter_vote_imports.pdf", p2, width = 8, height = 6)

# --- Figure 3: Horizontal bars – all departments ranked ----------------

merged_sorted <- merged[order(total_customs_value)]
merged_sorted[, dept_name := factor(dept_name, levels = dept_name)]

p3 <- ggplot(merged_sorted, aes(x = dept_name, y = total_customs_value,
                                 fill = leaning)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = lean_colors) +
  scale_y_continuous(labels = label_comma(scale = 1e-9, suffix = "B")) +
  labs(
    title    = "Import Value by Department",
    subtitle = "Ranked by total 2018 customs value, colored by 2018 election result",
    x = NULL, y = "Total customs value (billions USD)",
    fill = "Political leaning"
  ) +
  theme_clean

ggsave("output/figures/fig3_departments_ranked.png", p3, width = 8, height = 9, dpi = 300)
ggsave("output/figures/fig3_departments_ranked.pdf", p3, width = 8, height = 9)

# --- Figure 4: Box plots – firm-level distribution --------------------

firm_level <- imports[election, on = .(DEPTODES = dept_code), nomatch = 0]

p4 <- ggplot(firm_level[VADUA > 0], aes(x = leaning, y = VADUA, fill = leaning)) +
  geom_boxplot(outlier.alpha = 0.05, outlier.size = 0.3) +
  scale_y_log10(labels = label_comma()) +
  scale_fill_manual(values = lean_colors) +
  labs(
    title    = "Firm-Level Import Distribution by Political Leaning",
    subtitle = "Transaction-level customs value, log scale",
    x = NULL, y = "Customs value per transaction (log scale)"
  ) +
  theme_clean +
  theme(legend.position = "none")

ggsave("output/figures/fig4_boxplot_distribution.png", p4, width = 6, height = 5, dpi = 300)
ggsave("output/figures/fig4_boxplot_distribution.pdf", p4, width = 6, height = 5)

# --- Figure 5: Choropleth – vote share & imports on map ---------------

col_sf <- ne_states(country = "Colombia", returnclass = "sf")

# Strip accents for matching (iconv on macOS leaves ' and ~ artifacts)
strip_accents <- function(x) {
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  gsub("['^~\"]", "", x)
}

col_sf$name_clean <- strip_accents(col_sf$name)
col_sf$name_clean <- trimws(gsub("D\\.?C\\.?$", "", col_sf$name_clean))
col_sf$name_clean <- gsub(" y Providencia$", "", col_sf$name_clean)
col_sf$name_clean <- gsub("Archipielago de San Andres", "San Andres", col_sf$name_clean)

merged$name_clean <- strip_accents(merged$dept_name)

map_data <- merge(col_sf, merged, by = "name_clean", all.x = TRUE)

p5a <- ggplot(map_data) +
  geom_sf(aes(fill = petro_pct), color = "white", linewidth = 0.2) +
  scale_fill_gradient(low = "#FEE0D2", high = "#B71C1C",
                      na.value = "grey90", name = "Petro %") +
  labs(title = "Petro Vote Share (%)") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "bottom")

p5b <- ggplot(map_data) +
  geom_sf(aes(fill = log10(total_customs_value)), color = "white", linewidth = 0.2) +
  scale_fill_gradient(low = "#E3F2FD", high = "#0D47A1",
                      na.value = "grey90", name = "log10 USD") +
  labs(title = "Total Import Value (log10)") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "bottom")

p5 <- p5a + p5b +
  plot_annotation(
    title    = "Geographic Distribution of Vote Share and Import Value",
    subtitle = "Colombian departments, 2018",
    theme    = theme(plot.title    = element_text(face = "bold", size = 14),
                     plot.subtitle = element_text(size = 11, color = "grey40"))
  )

ggsave("output/figures/fig5_map_vote_imports.png", p5, width = 10, height = 7, dpi = 300)
ggsave("output/figures/fig5_map_vote_imports.pdf", p5, width = 10, height = 7)

# 6 - Summary table ----------------------------------------------------

summary_tbl <- merged[, .(
  n_departments   = .N,
  total_value     = sum(total_customs_value),
  total_firms     = sum(n_firms),
  total_txns      = sum(n_transactions),
  mean_value_dept = mean(total_customs_value),
  mean_firms_dept = mean(n_firms)
), by = leaning]

fwrite(summary_tbl, "output/tables/260304_summary_by_leaning.csv")

cat("\nSummary by political leaning:\n")
print(summary_tbl)

# 7 - Copy figures to Overleaf -----------------------------------------

overleaf_dir <- path.expand(
  "~/Dropbox/apps/Overleaf/260304 Colombia Imports Election/figures"
)

if (dir.exists(overleaf_dir)) {
  pdf_files <- list.files("output/figures", pattern = "\\.pdf$", full.names = TRUE)
  file.copy(pdf_files, overleaf_dir, overwrite = TRUE)
  cat("Copied", length(pdf_files), "PDF figures to Overleaf\n")
} else {
  cat("Overleaf directory not found:", overleaf_dir, "\n")
}

cat("\nDone. Figures saved to output/figures/, table to output/tables/\n")
