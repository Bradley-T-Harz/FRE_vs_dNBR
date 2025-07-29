#!/usr/bin/env Rscript
# 05_VIIRS_FRP_Info.R

# 0) load just what we need, and make sure sf comes before dplyr
library(sf)
library(dplyr)
library(lubridate)
library(stringr)

# 1) read the full VIIRS FRP dataset
frp_all <- st_read(
  "/home/ojiji-chhaya/Projects/RECCS Forest Fire Project/VIIRS/perim_polygons_viirs.geojson",
  quiet = TRUE
)

# 1a) Print column names to inspect what actually exists
cat("\n--- Column names in FRP GeoJSON ---\n")
print(names(frp_all))

# 2) define fire names from shared fire list
fires_of_interest <- fires_tbl$INCIDENT_NAME %>%
  stringr::str_to_title() %>%
  stringr::str_squish()

# 3) Define the desired columns (double-check these names in your output above)
valid_cols <- c(
  "ACQ_DATE",
  "ACQ_TIME",
  "SATELLITE",
  "INSTRUMENT",
  "DAYNIGHT",
  "ACQ_DATETIME",
  "DATE_DECIMAL",
  "time_start",
  "N_pts",
  "FL_SCAN",
  "FL_TRACK",
  "Incid_Name",
  "Incid_Type",
  "Ig_Date",
  "New_ID",
  "irwinID",
  "FL_FRP",
  "FL_AREA",
  "event_perim",
  "geometry"
)

# 3a) Check which of those columns actually exist in frp_all
existing_cols <- valid_cols[valid_cols %in% names(frp_all)]

# 3b) Optionally diagnose any missing columns (typo? unexpected name?)
missing_cols <- setdiff(valid_cols, names(frp_all))

if (length(missing_cols) > 0) {
  cat("\n⚠️  These columns are MISSING from the dataset:\n")
  print(missing_cols)
}

# 3c) Always include geometry if present
if ("geometry" %in% names(frp_all)) {
  existing_cols <- c(existing_cols, "geometry")
}

# 4) Safely filter and select only the existing columns
frp_fires <- frp_all %>%
  mutate(Incid_Name = stringr::str_to_title(Incid_Name)) %>%
  filter(Incid_Name %in% fires_of_interest) %>%
  dplyr::select(all_of(existing_cols))

# 5) Print result summary
cat("\n✅ Extracted VIIRS FRP records for selected fires:\n")
print(frp_fires)

st_write(frp_fires, "Tables/viirs_fires_subset.geojson", quiet = TRUE)
