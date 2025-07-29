# Not working yet. Sad face.

#!/usr/bin/env Rscript
# 11_run_all

# ───────────────────────────────────────────────────────
# Master driver script to execute the full wildfire analysis pipeline
# Assumes working directory is project root

# ───────────────────────────────────────────────────────
# Load required libraries
suppressPackageStartupMessages({
  library(glue)
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(stringr)
  library(sf)
  library(raster)
  library(viridis)
})

# ───────────────────────────────────────────────────────
# Check working directory
if (!file.exists("00_fire_list.R")) {
  stop("❗ Please run this script from the project root.")
}

# Helper to source scripts and show progress
run_step <- function(script) {
  cat(glue::glue('\n▶️ Running {script}...\n'))
  tryCatch({
    source(script)
    cat(glue::glue('\n✅ Finished {script}\n'))
  }, error = function(e) {
    cat(glue::glue('\n❌ Error in {script}: {e$message}\n'))
  })
}

# ───────────────────────────────────────────────────────
# Sequentially run each script in correct order

run_step('00_fire_list.R')
run_step('01_run_ics209_ros.R')
run_step('02_summary_table_three_fires.R')
run_step('03_2020_MTBS_Mosaic_CO.R')
run_step('04_MTBS_Perim_Info.R')
run_step('05_VIIRS_FRP_Info.R')
run_step('06_Graph_FRP_w_FRE.R')
run_step('08_dNBR_values_&_plot.R')
run_step('09_compare_FRE_dNBR.R')
run_step('10_compare_ROS_vs_FRE.R')

cat('\n🎉 All scripts executed successfully.\n')
