# **ROS, FRE, & dNBR COMPARISON INSTRUCTIONAL**

<u>———————————————————————————————</u>



📝 Comprehensive Project Overview:
This project analyzes wildfire data using:

ICS-209-Plus reports (growth rate and rate of spread (ROS)).

MTBS (Monitoring Trends in Burn Severity) fire perimeters and burn severity.

VIIRS satellite-derived Fire Radiative Power (FRP) and total Fire Radiative Energy (FRE).

Derived statistics like mean dNBR (Normalized Burn Ratio difference), growth rate, and peak ROS.

These are integrated to understand relationships between fire energy (FRE), fire severity (dNBR), and fire growth (ROS).



📂 Directory Structure:
bash
Copy
Edit
├── ICS-209-Plus_Datasets/
│   └── ics209-plus-wf_sitreps_1999to2023.csv
│
├── MTBS_Datasets/
│   ├── Fire_data_bundles/
│   │   └── composite_data/MTBS_BSmosaics/2020/mtbs_CO_2020/mtbs_CO_2020.tif
│   └── mtbs_perimeter_data/mtbs_perims_DD.shp
│
├── VIIRS/
│   └── perim_polygons_viirs.geojson
│
├── Fire GeoTIFFs/
│   └── [Fire-specific folders with dNBR rasters]
│
├── Tables/
│   ├── filtered_mtbs_fires.geojson
│   └── viirs_fires_subset.geojson
│
└── plots/
    ├── 3_CO_Fast_ROS/
    ├── dNBR_perimeter_maps/
    ├── frp-w-fre_trapezoids/
    └── dNBR_vs_FRE/



🔥 Analysis Workflow & Scripts:
✅ 00_fire_list.R:
Defines the specific fires for analysis.

Located in root.

Creates a tidy data table fires_tbl with fire IDs and names.


✅ 01_run_ics209_ros.R:
Reads ICS-209-Plus SITREP data, computes wildfire growth metrics (ROS), and generates ROS plots.

Input:

ICS-209-Plus_Datasets/ics209-plus-wf_sitreps_1999to2023.csv

Outputs:

Plots: plots/3_CO_Fast_ROS/ (growth curves, peak ROS).

CSV: plots/dNBR_vs_FRE/ROS_values_summary.csv.

Computes max growth rates and identifies peak ROS.

Filters top fires in Colorado based on peak growth rates.

Creates visualizations for fire growth (ROS) with annotations.


✅ 02_summary_table_three_fires.R:
Extracts and summarizes detailed ROS data specifically for your chosen fires.

Reads data from previous steps to summarize ROS clearly.

Useful for quick reference.


✅ 03_2020_MTBS_Mosaic_CO.R:
Generates a Colorado-wide mosaic of MTBS dNBR for 2020.

Input:

mtbs_CO_2020.tif

Output:

Image: plots/dNBR_perimeter_maps/0_Colorado_Mosaic.png.

Provides context of burn severity for Colorado during 2020.


✅ 04_MTBS_Perim_Info.R:
Filters MTBS perimeter shapefile to your fires of interest.

Input: MTBS perimeter shapefile (mtbs_perims_DD.shp).

Output: Tables/filtered_mtbs_fires.geojson.

Checks perimeter data availability, highlighting missing fires.


✅ 05_VIIRS_FRP_Info.R:
Extracts VIIRS-derived FRP data for selected fires.

Input: VIIRS data (perim_polygons_viirs.geojson).

Output: Tables/viirs_fires_subset.geojson.

Highlights any missing VIIRS data columns clearly.


✅ 06_Graph_FRP_w_FRE.R:
Calculates total FRE (energy release) from VIIRS FRP data and generates visual plots.

Input: VIIRS FRP GeoJSON.

Outputs:

Plots: plots/frp-w-fre_trapezoids/.

CSV: plots/dNBR_vs_FRE/FRE_values_summary.csv.

Visualizes instantaneous FRP over time and the cumulative FRE for each fire.

Uses trapezoidal numerical integration to estimate total FRE.


✅ 08_dNBR_values_&_plot.R:
Processes dNBR raster data, aligns it with MTBS perimeters, and generates burn severity statistics and visualizations.

Input:

Fire GeoTIFFs/[fire]_dnbr.tif

Fire GeoTIFFs/[fire]_dnbr6.tif

Outputs:

Plots: plots/dNBR_perimeter_maps/ (severity maps).

CSV: dNBR_summary_stats_all_fires.csv.

Computes mean, standard deviation, min, max of dNBR for each fire.

Handles reprojection and cropping/masking issues robustly.


✅ 09_compare_FRE_dNBR.R:
Analyzes relationships between total fire radiative energy (FRE) and burn severity (mean dNBR).

Inputs:

FRE_values_summary.csv

dNBR stats CSVs (from previous step)

Output:

Plot: plots/dNBR_vs_FRE/FRE_vs_dNBR.png

CSV: plots/dNBR_vs_FRE/FRE_dNBR_combined_table.csv

Computes Pearson correlation and fits a linear model between FRE and mean dNBR.

Visualizes this relationship with clear annotations.


✅ 10_compare_ROS_vs_FRE.R:
Analyzes relationships between fire growth rate (peak ROS) and total FRE.

Inputs:

ROS_values_summary.csv

FRE_values_summary.csv

Output:

Plot: plots/dNBR_vs_FRE/ROS_vs_FRE.png

Computes Pearson correlation and linear regression between ROS and FRE.

Provides a graphical representation of this relationship.



🎨 Visualization Explained:
Growth Curves (ROS): Show rapid expansion phases for each fire.

FRP vs. FRE plots: Illustrate instantaneous FRP values over time, with shaded area representing cumulative energy release (FRE).

dNBR maps: Display spatial burn severity.

Scatterplots (FRE vs dNBR, ROS vs FRE): Show statistical relationships between total energy, fire growth, and burn severity clearly, highlighting key insights.



📌 Important Files:
ICS-209-Plus SITREPS: Fire growth and response data.

/ICS-209-Plus_Datasets/

MTBS Shapefiles and GeoTIFFs: Fire perimeters and burn severity.

/MTBS_Datasets/

VIIRS GeoJSON: Satellite-derived FRP data.

/VIIRS/

Processed data tables:

/Tables/

Generated visualizations:

/plots/



⚠️ Troubleshooting Notes:
Always ensure the CRS (coordinate reference system) is consistent:

Shapefiles and rasters must both use the Albers Equal Area (EPSG:5070).

Confirm file paths carefully, especially when working across multiple scripts and directories.



🚀 Running the Project:
Recommended script execution order:

00_fire_list.R (setup)

01_run_ics209_ros.R (ROS)

03_2020_MTBS_Mosaic_CO.R (MTBS mosaic)

04_MTBS_Perim_Info.R (perimeters)

05_VIIRS_FRP_Info.R (VIIRS)

06_Graph_FRP_w_FRE.R (FRE calculation)

08_dNBR_values_&_plot.R (dNBR analysis)

09_compare_FRE_dNBR.R (FRE vs dNBR)

10_compare_ROS_vs_FRE.R (ROS vs FRE)



🧑‍💻 GitHub Documentation (Suggested):
Include:

Clear setup instructions (file paths, data sources).

Detailed workflow overview.

Visualization examples (embed key plots).

Common errors & fixes.

Recommended script execution order.

Brief glossary explaining acronyms (dNBR, FRE, ROS, MTBS, VIIRS).



🎯 Outcome: 

You have a clearly defined data pipeline and visual analysis framework to quantify wildfire characteristics, energy, severity, and growth.
