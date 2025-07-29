#!/usr/bin/env Rscript
# 04_MTBS_Perim_Info.R

# 0) load libraries
library(dplyr)
library(sf)
library(lubridate)

# 1) read the full MTBS perimeter dataset
mtbs <- st_read(
  "/home/ojiji-chhaya/Projects/RECCS Forest Fire Project/MTBS_Datasets/mtbs_perimeter_data/mtbs_perims_DD.shp",
  quiet = TRUE
)

print(names(mtbs))

# Add year safely
if ("Ig_Date" %in% names(mtbs)) {
  mtbs$year <- year(mtbs$Ig_Date)
} else {
  stop("Column 'Ig_Date' not found in MTBS shapefile.")
}

# 2) grab fire names from fire list
fires_of_interest <- fires_tbl$INCIDENT_NAME %>%
  stringr::str_to_title() %>%
  stringr::str_squish()

mtbs <- mtbs %>%
  mutate(Incid_Name = stringr::str_to_title(Incid_Name) %>% stringr::str_squish())

# 3) now filter & select works on an sf
valid_cols <- c(
  "Event_ID",
  "irwinID",
  "Incid_Name",
  "Map_ID",
  "Map_Prog",
  "Asmnt_Type",
  "BurnBndLat",
  "BurnBndLon",
  "Ig_Date",
  "Pre_ID",
  "Post_ID",
  "Perim_ID",
  "dNBR_offst",
  "dNBR_stdDv",
  "NoData_T",
  "IncGreen_T",
  "Low_T",
  "Mod_T",
  "High_T",
  "Comment",
  "year"
  )

# Check which of these columns actually exist
available_cols <- intersect(valid_cols, names(mtbs))

# Do the filtering and selecting
mtbs_fires <- mtbs %>%
  filter(Incid_Name %in% fires_of_interest) %>%
  dplyr::select(all_of(available_cols))  # safe, avoids typos

cat("\n--- Matching MTBS Fire Records ---\n")
print(mtbs_fires)

cat("\n--- Fires of Interest ---\n")
print(fires_of_interest)

# Optional: for checking structure or debugging
mtbs_df <- as.data.frame(mtbs)
print(names(mtbs_df))

st_write(mtbs_fires, "Tables/filtered_mtbs_fires.geojson", quiet = TRUE)

missing <- setdiff(fires_of_interest, unique(mtbs$Incid_Name))
if (length(missing) > 0) {
  warning("These fire names were not found in MTBS shapefile: ", paste(missing, collapse = ", "))
}
