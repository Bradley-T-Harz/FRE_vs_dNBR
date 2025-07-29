# 🔥 Wildfire Analysis Pipeline — Run Order & Summary

This document outlines the script dependencies and the order in which to run each script for full pipeline execution and reproducibility.

## ✅ Run Order

1. `00_fire_list.R`
   - Defines the fires of interest (incident names and numbers).

2. `01_run_ics209_ros.R`
   - Analyzes ICS-209 sitreps for growth rate and peak ROS.
   - Outputs growth plots and top 50 ROS fires in Colorado.

3. `02_summary_table_three_fires.R`
   - Summarizes key metrics for EAST TROUBLESOME, CAMERON PEAK, and PINE GULCH.

4. `03_2020_MTBS_Mosaic_CO.R`
   - Optional: plots the 2020 MTBS Colorado mosaic.

5. `04_MTBS_Perim_Info.R`
   - Filters MTBS fire perimeters by name.

6. `05_VIIRS_FRP_Info.R`
   - Filters VIIRS FRP data for fires of interest.

7. `06_Graph_FRP_w_FRE.R`
   - Computes trapezoidal FRE for each fire using FRP time series.
   - Saves plots and FRE summary to `plots/frp-w-fre_trapezoids/` and CSV file.

8. `08_dNBR_values_&_plot.R`
   - Loads and rescales MTBS dNBR rasters per fire.
   - Saves dNBR and dNBR6 maps and summary stats to `plots/dNBR_perimeter_maps/`.

9. `09_compare_FRE_dNBR.R`
   - Joins FRE and dNBR mean stats.
   - Computes correlation and fits linear model.
   - Saves output plot to `plots/dNBR_vs_FRE/FRE_vs_dNBR.png`.

## 🧪 Optional Add-ons

- `07a_CO_proj_Fire_bbox.R` — Projects bounding boxes for Colorado fires.
- `07b_detailed_CO_bboxes.R` — Generates more detailed bounding box outputs.

## 💾 Logging Output Summaries

- Save summaries as CSV for future reference:
  ```r
  write_csv(special_tbl, "plots/dNBR_vs_FRE/summary_top3_fires.csv")
  write_csv(top50_co_tbl, "plots/3_CO_Fast_ROS/top50_peak_growth_CO.csv")
  ```

## 🏁 Driver Script

- You can automate execution using a `run_all.R` that `source()`s each script in order.
  Ensure that all scripts use non-interactive execution and save output files cleanly.

## 📂 Notes

- FRE values are in gigajoules (GJ)
- dNBR mean is computed within fire perimeters using MTBS data
- All outputs are stored in organized `plots/` subfolders