#!/usr/bin/env Rscript
# 09_compare_FRE_dNBR.R

# This script assumes:
#  - You've already run the FRE integration code (frp_by_fire contains each fire's FRP)
#  - You've already saved the dNBR stats tables per fire
#  - Run AFTER all your other processing

library(readr)
library(dplyr)
library(ggplot2)
library(glue)
library(stringr)


# ─────────────────────────────────────────────────────────────────────────────
# 0) auto‑discover fire names from your stats CSVs
# ─────────────────────────────────────────────────────────────────────────────
csv_dir  <- "plots/dNBR_perimeter_maps"
stat_dir <- "plots/dNBR_vs_FRE"
fre_path <- file.path(stat_dir, "FRE_values_summary.csv")

# get the full paths to each stats file
stat_files <- list.files(csv_dir,
                         pattern = "_dNBR_stats\\.csv$",
                         full.names = TRUE)

# extract fire names from filenames:
fires <- stat_files %>%
  basename() %>%                                   # e.g. "CALDWELL_dNBR_stats.csv"
  str_remove("_dNBR_stats\\.csv$") %>%             # "CALDWELL"
  str_replace_all("_", " ") %>%                    # "CALDWELL"
  str_to_title()                                   # "Caldwell"

# ─────────────────────────────────────────────────────────────────────────────
# 1) read FRE table
# ─────────────────────────────────────────────────────────────────────────────
fre_tbl  <- read_csv(fre_path, show_col_types = FALSE) %>%
  mutate(fire = str_to_title(fire))   # make sure it’s title‑case too

fre_vals <- setNames(fre_tbl$FRE_GJ, fre_tbl$fire)

# Safety check: warn if any fires are missing FRE values
missing_fires <- setdiff(fires, names(fre_vals))
if (length(missing_fires) > 0) {
  warning("These fires have no FRE value:", paste(missing_fires, collapse = ", "))
}

# ─────────────────────────────────────────────────────────────────────────────
# 2) Read dNBR stats
# ─────────────────────────────────────────────────────────────────────────────
dnbr_stats <- purrr::map2_dfr(
  stat_files,    # the actual CSV paths
  fires,         # the matching fire names
  ~ {
    df <- read_csv(.x, show_col_types = FALSE)
    df$fire <- .y
    df
  }
)

# 3. Add FRE
dnbr_stats <- dnbr_stats %>%
  mutate(FRE_GJ = fre_vals[fire])

# 4. Correlation and model
cor_val <- cor(dnbr_stats$FRE_GJ, dnbr_stats$mean_dNBR, method = "pearson")
fit <- lm(mean_dNBR ~ FRE_GJ, data = dnbr_stats)

# 5. Print and plot
cat("\nPearson correlation (FRE vs mean dNBR):", round(cor_val, 3), "\n")
print(summary(fit))

# 6. Plot with fire-specific colors and legend
ggplot(dnbr_stats, aes(x = FRE_GJ, y = mean_dNBR, color = fire)) +
  geom_point(size = 4) +
  geom_smooth(method = "lm", se = FALSE, color = "white", linewidth = 0.8) +
  scale_color_manual(
    name = "Fire Name",
    values = c(
      "Caldwell"             = "#E64B35",  # strong red
      "East Troublesome"     = "#4DBBD5",  # strong blue
      "Watson Creek"         = "#00A087",  # strong teal
      "Cameron Peak"         = "#3C5488",  # dark indigo
      "Jennies Peak 1039 Rn" = "#F39B7F",  # salmon
      "Chetco Bar"           = "#8491B4",  # gray-blue
      "Pine Gulch"           = "#91D1C2"   # light teal
    )
  ) +
  labs(
    title = "FRE vs Mean dNBR (7 Western U.S. Fires)",
    subtitle = glue("Pearson's r = {round(cor_val, 3)}"),
    x = "Total Fire Radiative Energy (GJ)",
    y = "Mean dNBR"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    panel.background = element_rect(fill = "black", color = NA),
    plot.background  = element_rect(fill = "black", color = NA),
    axis.text  = element_text(color = "white"),
    axis.title = element_text(color = "white"),
    plot.title    = element_text(color = "white", size = rel(1.1)),
    plot.subtitle = element_text(color = "white"),
    legend.title  = element_text(color = "white"),
    legend.text   = element_text(color = "white"),
    legend.background = element_rect(fill = "transparent"),
    legend.key    = element_rect(fill = "black"),
    panel.grid.major = element_line(color = "grey50"),
    panel.grid.minor = element_line(color = "grey60")
  )

# 7. Save plot
dir.create(stat_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(
  filename = file.path(stat_dir, "FRE_vs_dNBR.png"),
  width = 6.5, height = 5.5, bg = "black"
)

cat("\n--- Combined Summary Table ---\n")
print(dnbr_stats)

write_csv(dnbr_stats, file.path(stat_dir, "FRE_dNBR_combined_table.csv"))
