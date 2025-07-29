# 02_summary_table_three_fires.R

# grab just those three from the CO summary
many_names <- fires_tbl$INCIDENT_NAME

special_tbl <- max_growth %>%
  filter(INCIDENT_NAME %in% many_names) %>%
  dplyr::select(INCIDENT_NUMBER, INCIDENT_NAME, growth_start, growth_end) %>%
  left_join(
    peak_sitreps %>% 
      filter(INCIDENT_NAME %in% many_names) %>%
      rename(ROS = acres_per_day) %>%
      dplyr::select(INCIDENT_NUMBER, rpt_dt, POO_LONGITUDE, POO_LATITUDE, ACRES, ROS),
    by = "INCIDENT_NUMBER"
  ) %>%
  dplyr::select(
    INCIDENT_NUMBER,
    INCIDENT_NAME,
    growth_start,
    growth_end,
    rpt_dt,
    POO_LONGITUDE,
    POO_LATITUDE,
    ACRES,
    ROS
  )

print(special_tbl)
