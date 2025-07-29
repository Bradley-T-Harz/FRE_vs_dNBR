# 00_fire_list.R

# Inside any script that uses fire lists:
fires_tbl <- tibble::tribble(
  ~INCIDENT_NUMBER, ~INCIDENT_NAME,
  "000479", "CALDWELL",
  "000408", "EAST TROUBLESOME",
  "000360", "Watson Creek",
  "000636", "Cameron Peak",
  "001039", "JENNIES PEAK 1039 RN",
  "000326", "Chetco Bar",
  "000307", "Pine Gulch"
)
