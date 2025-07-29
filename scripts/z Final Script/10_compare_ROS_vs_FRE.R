#!/usr/bin/env Rscript
# 10_compare_ROS_vs_FRE.R

# 0) libraries
library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(glue)

# 1) where our stats live
stat_dir <- "plots/dNBR_vs_FRE"
fre_csv  <- file.path(stat_dir, "FRE_values_summary.csv")
ros_csv  <- file.path(stat_dir, "ROS_values_summary.csv")  # ← make this via special_tbl, see below

# 2) read FRE
fre_tbl <- read_csv(fre_csv, show_col_types = FALSE) %>%
  mutate(fire = str_to_title(fire))

# 3) read ROS
# If you haven’t yet, emit it from your special_tbl with:
# special_tbl %>%
#   distinct(INCIDENT_NAME, .keep_all=TRUE) %>%
#   transmute(fire = str_to_title(INCIDENT_NAME), ROS = ROS) %>%
#   write_csv(ros_csv)
ros_tbl <- read_csv(ros_csv, show_col_types = FALSE) %>%
  mutate(fire = str_to_title(fire))

# 4) combine
comp <- inner_join(fre_tbl, ros_tbl, by="fire")

# 5) correlation & linear fit
cor_val <- cor(comp$ROS, comp$FRE_GJ, method="pearson")
fit     <- lm(ROS ~ FRE_GJ, data = comp)

cat("\nPearson r (ROS vs FRE):", round(cor_val,3), "\n")
print(summary(fit))

# 6) make and save the plot
p <- ggplot(comp, aes(x = FRE_GJ, y = ROS, color = fire)) +
  geom_point(size = 4) +
  geom_smooth(method="lm", se=FALSE, color="white", linewidth=0.8) +
  scale_color_manual(
    name = "Fire",
    values = c(
      "Caldwell"             = "#E64B35",
      "East Troublesome"     = "#4DBBD5",
      "Watson Creek"         = "#00A087",
      "Cameron Peak"         = "#3C5488",
      "Jennies Peak 1039 Rn" = "#F39B7F",
      "Chetco Bar"           = "#8491B4",
      "Pine Gulch"           = "#91D1C2"
    )
  ) +
  labs(
    title    = "Peak ROS vs Total FRE",
    subtitle = glue("Pearson's r = {round(cor_val,3)}"),
    x        = "Total Fire Radiative Energy (GJ)",
    y        = "Peak ROS (acres/day)"
  ) +
  theme_minimal(base_size=14) +
  theme(
    panel.background = element_rect(fill="black", color=NA),
    plot.background  = element_rect(fill="black", color=NA),
    axis.text        = element_text(color="white"),
    axis.title       = element_text(color="white"),
    plot.title       = element_text(color="white", size=rel(1.1)),
    plot.subtitle    = element_text(color="white"),
    legend.title     = element_text(color="white"),
    legend.text      = element_text(color="white"),
    legend.background= element_rect(fill="transparent"),
    legend.key       = element_rect(fill="black"),
    panel.grid.major = element_line(color="grey50"),
    panel.grid.minor = element_line(color="grey60")
  )

out_file <- file.path(stat_dir, "ROS_vs_FRE.png")
ggsave(out_file, plot=p, width=6.5, height=5.5, bg="black")
cat("Wrote plot to:", out_file, "\n")
