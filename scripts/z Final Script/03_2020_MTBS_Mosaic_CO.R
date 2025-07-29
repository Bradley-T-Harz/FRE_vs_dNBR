#!/usr/bin/env Rscript
# 03_2020_MTBS_Mosaic_CO.R

# 0) load only the libraries we need for this plot
library(raster)
library(glue)

# ────────────────────────────────────────────────────────────────────────
# 1) Find the 2020 MTBS mosaic for Colorado
mtbs_fnames <- list.files(
  path      = "/home/ojiji-chhaya/Projects/RECCS Forest Fire Project/MTBS_Datasets/Fire_data_bundles_Wz7hRM68vPvQtkJ4Ywj5/composite_data/MTBS_BSmosaics",
  pattern   = "mtbs_CO_2020\\.tif$",
  recursive  = TRUE,
  full.names = TRUE
)

if (length(mtbs_fnames) == 0) {
  stop("No mtbs_CO_2020.tif found in the mosaics folder")
}

# ────────────────────────────────────────────────────────────────────────
# 2) Load the raster and set the plotting year
r <- raster(mtbs_fnames[[1]])
plot_year <- 2020

# ────────────────────────────────────────────────────────────────────────
# 3) Save to correct folder
out_dir <- "plots/dNBR_perimeter_maps"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ────────────────────────────────────────────────────────────────────────
# 4) Plot and save
library(viridis)

png(file.path(out_dir, "0_Colorado_Mosaic.png"), height = 450, width = 450, bg = "black")
par(bg = "black", col.axis = "white", col.lab = "white", col.main = "white", col.sub = "white")
plot(r, col = viridis(50), main = glue("MTBS {plot_year} Mosaic — {plot_year}"), sub = "Raw dNBR mosaic")
box(col = "white")

dev.off()
