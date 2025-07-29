#!/usr/bin/env Rscript
# 06_Graph_FRP_w_FRE.R

# ────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────

# 0) libraries + turn off s2 for planar ops
library(sf);     sf::sf_use_s2(FALSE)
library(dplyr)
library(ggplot2)
library(lubridate)
library(glue)
library(stringr)
library(readr)

# Midpoint Rule (returns MJ)
mid_FRE <- function(df) {
  df <- df %>% arrange(ACQ_DATETIME)
  if (nrow(df) < 2) return(0)
  dt <- as.numeric(diff(df$ACQ_DATETIME), units="secs")
  y  <- df$FL_FRP
  sum(y[-length(y)] * dt, na.rm=TRUE)
}

# 1) trapezoid‐integration helper (returns MJ)
trap_FRE <- function(df) {
  df <- df %>% arrange(ACQ_DATETIME)
  if (nrow(df) < 2) return(0)
  dt <- as.numeric(diff(df$ACQ_DATETIME), units="secs")
  y  <- df$FL_FRP
  sum((y[-1] + y[-length(y)])/2 * dt, na.rm=TRUE)
}

# Simpson's Rule (returns MJ)
simp_FRE <- function(df) {
  df <- df %>% arrange(ACQ_DATETIME)
  n <- nrow(df)
  if (n < 3 || n %% 2 == 0) return(NA)  # Simpson's rule needs odd n ≥ 3
  h <- as.numeric(diff(df$ACQ_DATETIME), units="secs")[1]  # assuming equal spacing
  y <- df$FL_FRP
  sum <- y[1] + y[n] + 4 * sum(y[seq(2, n - 1, 2)]) + 2 * sum(y[seq(3, n - 2, 2)])
  h * sum / 3
}

# 2) read & clean VIIRS FRP
frp <- st_read("VIIRS/perim_polygons_viirs.geojson", quiet=TRUE) %>%
  mutate(
    Incid_Name = stringr::str_to_title(Incid_Name),
    FL_FRP      = as.numeric(gsub("[^0-9\\.]", "", FL_FRP))
  ) %>%
  filter(!is.na(FL_FRP), !is.na(ACQ_DATETIME))

# 3) read MTBS perimeters
mtbs <- st_read("MTBS_Datasets/mtbs_perimeter_data/mtbs_perims_DD.shp", quiet=TRUE) %>%
  mutate(Incid_Name = stringr::str_to_title(Incid_Name)) %>%
  st_make_valid()

# 4) reproject both to an equal‐area Albers (EPSG:5070)
frp  <- st_transform(frp, 5070)
mtbs <- st_transform(mtbs, 5070)

# 5) fires + cutoffs
fires <- tibble(
  fire_name = c(
    "CALDWELL", "EAST TROUBLESOME", "Watson Creek",
    "Cameron Peak", "JENNIES PEAK 1039 RN",
    "Chetco Bar", "Pine Gulch"
  ),
  end_date = as.Date(c(
    "2022-05-03",  # CALDWELL
    "2020-11-15",  # EAST TROUBLESOME
    "2020-09-10",  # Watson Creek
    "2020-10-13",  # Cameron Peak
    "2018-08-20",  # JENNIES PEAK 1039 RN
    "2017-08-20",  # Chetco Bar
    "2020-10-06"   # Pine Gulch
  ))
) %>%
  mutate(fire_name = stringr::str_to_title(fire_name))

# 6) output folders
out_dir  <- "plots/frp-w-fre_trapezoids"
stat_dir <- "plots/dNBR_vs_FRE"
dir.create(out_dir, recursive=TRUE, showWarnings=FALSE)
dir.create(stat_dir, recursive=TRUE, showWarnings=FALSE)

# 7) sat types
sats <- c("ALL", "N", "N20")

# 8) prepare containers
fre_vals     <- numeric(nrow(fires))
frp_by_fire  <- vector("list", nrow(fires))
names(fre_vals) <- names(frp_by_fire) <- fires$fire_name

fre_results <- tibble(
  fire = character(),
  satellite = character(),
  FRE_Trapezoid_GJ = numeric(),
  FRE_Midpoint_GJ  = numeric(),
  FRE_Simpson_GJ   = numeric()
)

# 9) loop & plot
for (i in seq_len(nrow(fires))) {
  f <- fires$fire_name[i]
  cutoff <- fires$end_date[i]
  suf    <- str_replace_all(f, " ", "_")
  
  poly <- mtbs %>%
    filter(Incid_Name == f) %>%
    st_union()
  
  frp_fire_all <- frp %>%
    filter(ACQ_DATETIME <= cutoff) %>%
    st_filter(poly) %>%
    arrange(ACQ_DATETIME)
  
  frp_by_fire[[f]] <- frp_fire_all
  
  frp_sets <- list(
    ALL  = frp_fire_all,
    N    = filter(frp_fire_all, SATELLITE == "N"),
    N20  = filter(frp_fire_all, SATELLITE == "N20")
  )
  
  for (sat in sats) {
    df <- frp_sets[[sat]]
    if (nrow(df) < 2) {
      message("Skipping ", f, " / ", sat, " (only ", nrow(df), " point",
              if (nrow(df) == 1) "" else "s", ")")
      next
    }
    
    # Calculate FREs
    fre_trap <- trap_FRE(df) / 1000
    fre_mid  <- mid_FRE(df)  / 1000
    fre_simp <- simp_FRE(df) / 1000
    
    # Append to results
    fre_results <- bind_rows(
      fre_results,
      tibble(
        fire = f,
        satellite = sat,
        FRE_Trapezoid_GJ = fre_trap,
        FRE_Midpoint_GJ  = fre_mid,
        FRE_Simpson_GJ   = fre_simp
      )
    )
    
    p <- ggplot(df, aes(ACQ_DATETIME, FL_FRP)) +
      geom_area(aes(y = FL_FRP, fill = "FRE"), alpha = 0.4) +
      geom_line(aes(y = FL_FRP, color = "FRP"), linewidth = 0.35) +
      scale_fill_manual(name = NULL, values = c(FRE = "steelblue")) +
      scale_color_manual(name = NULL, values = c(FRP = "orange")) +
      labs(
        title    = glue("{f} FRP (VIIRS-{sat})"),
        subtitle = glue("FRE ≈ {round(fre_trap, 1)} GJ"),
        x        = "Acquisition Time",
        y        = "Fire Radiative Power (MW)"
      ) +
      theme_minimal(base_size = 12) %+replace% 
      theme(
        panel.background     = element_rect(fill = "black", color = NA),
        plot.background      = element_rect(fill = "black", color = NA),
        panel.grid.major     = element_line(color = "grey50"),
        panel.grid.minor     = element_line(color = "grey60"),
        axis.title           = element_text(color = "white", size = rel(0.8)),
        axis.text            = element_text(color = "white", size = rel(0.7)),
        plot.title           = element_text(color = "white", size = rel(1.0)),
        plot.subtitle        = element_text(color = "white", size = rel(0.8)),
        legend.text          = element_text(color = "white", size = rel(0.8)),
        legend.position.inside = c(0.1, 0.9),
        legend.background    = element_rect(fill = "transparent", color = NA),
        legend.key           = element_rect(fill = "transparent", color = NA)
      )
    
    ggsave(
      filename = file.path(out_dir, sprintf("%s_FRP_Trapezoids_%s.png", suf, sat)),
      plot     = p,
      width    = 4.5, height = 4.5, units = "in", bg = "black"
    )
  }
}

message("Done — plots in ", out_dir)

cat("\n--- FRE values (GJ) for all 7 fires ---\n")
print(fre_vals)

# Save comparison of all FRE methods
fre_outfile <- "/home/ojiji-chhaya/Projects/RECCS Forest Fire Project/Tables/FRE_values_comparison.csv"
dir.create(dirname(fre_outfile), recursive = TRUE, showWarnings = FALSE)
write_csv(fre_results, fre_outfile)

message("\n✔ Saved FRE method comparison table to:")
message(fre_outfile)
