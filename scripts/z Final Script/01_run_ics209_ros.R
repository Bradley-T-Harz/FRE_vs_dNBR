#!/usr/bin/env Rscript
# 01_run_ics209_ros.R


# 0) install if needed:
# install.packages(c("readr","dplyr","stringr","lubridate","ggplot2","glue"))

# 0) load libraries ------------------------------------------------------
library(readr)
library(dplyr)
library(stringr)
library(lubridate)
library(ggplot2)
library(glue)



# 1) load & parse SITREPS -----------------------------------------------
sitreps_file <- "ICS-209-Plus_Datasets/ics209plus-wildfire/ics209plus-wildfire/ics209-plus-wf_sitreps_1999to2023.csv"
stopifnot(file.exists(sitreps_file))
probs <- problems(sitreps_file)
print(probs)



fires <- fires_tbl  # from fire_list.R
three_ids <- fires$INCIDENT_NUMBER

# 2) define our three 2020 giants ----------------------------------------
#three_ids   <- c("000408","000636","000307")
#three_names <- c("EAST TROUBLESOME","Cameron Peak","Pine Gulch")
#fires <- tibble(INCIDENT_NUMBER = three_ids,
#                INCIDENT_NAME   = three_names)



# 3) peek at header
header <- read_csv(sitreps_file, n_max=0, show_col_types=FALSE)
print(colnames(header))



# 4) pull only the fields we care about, with appropriate types:
raw_sitreps <- read_csv(
  sitreps_file,
  show_col_types = FALSE,
  col_select = c(
    # 1) identifiers & classification
    "INCIDENT_NUMBER","INCIDENT_ID","INCIDENT_NAME","INCIDENT_DESCRIPTION",
    "COMPLEX","COMPLEX_NAME","COMPLEXITY_LEVEL_NARR",
    "INCTYP_DESC","INCTYP_ABBREVIATION",
    # 2) dates & timing
    "DISCOVERY_DATE","REPORT_TO_DATE",
    "EXPECTED_CONTAINMENT_DATE","ANTICIPATED_COMPLETION_DATE",
    "REPORT_DAY_SPAN","DISCOVERY_DOY","REPORT_DOY",
    # 3) location
    "POO_LONGITUDE","POO_LATITUDE","POO_STATE","POO_COUNTY",
    "POO_US_NGR_XCOORD","POO_UTM_EASTING","POO_UTM_NORTHING",
    "TERRAIN","FUEL_MODEL","ADDNTL_FUEL_MODEL","SECNDRY_FUEL_MODEL",
    # 4) size & growth
    "ACRES","NEW_ACRES","EVENT_FINAL_ACRES","WF_FSR",
    "CURR_INCIDENT_AREA","PROJ_INCIDENT_AREA","GROWTH_POTENTIAL",
    "PCT_CONTAINMENT","PCT_CONTAINED_COMPLETED","MAX_FIRE_PCT_FINAL_SIZE",
    # 5) behavior & resources
    "FIRE_BEHAVIOR_1","FIRE_BEHAVIOR_2","FIRE_BEHAVIOR_3","GEN_FIRE_BEHAVIOR",
    "FB_RUNNING","FB_CROWNING","FB_BACKING","FB_CREEPING",
    "FB_SMOLDERING","FB_SPOTTING","FB_TORCHING","FB_WIND_DRIVEN",
    "TOTAL_PERSONNEL","TOTAL_AERIAL","NUM_EVACUATED","TOTAL_EVACUATIONS",
    "SUPPRESSION_METHOD","IMT_MGMT_ORG_DESC","INCIDENT_COMMANDERS_NARR",
    # 6) impacts & costs
    "FATALITIES","INJURIES","RPT_FATALITIES","RPT_P_FATALITIES","RPT_P_INJURIES",
    "EST_IM_COST_TO_DATE","PROJECTED_FINAL_IM_COST",
    # 7) narrative & evaluation
    "REMARKS","PLANNED_ACTIONS","STRATEGIC_NARR","SIGNIF_EVENTS_SUMMARY",
    "RISK_ASSESSMENT","HAZARDS_MATLS_INVOLVMENT_NARR","CURRENT_THREAT_NARR"
  ),
  col_types = cols_only(
    # 1) ids & class
    INCIDENT_NUMBER           = col_character(),
    INCIDENT_ID               = col_character(),
    INCIDENT_NAME             = col_character(),
    INCIDENT_DESCRIPTION      = col_character(),
    COMPLEX                   = col_logical(),
    COMPLEX_NAME              = col_character(),
    COMPLEXITY_LEVEL_NARR     = col_character(),
    INCTYP_DESC               = col_character(),
    INCTYP_ABBREVIATION       = col_character(),
    # 2) dates
    DISCOVERY_DATE            = col_datetime(format=""),
    REPORT_TO_DATE            = col_character(),   # we’ll parse below
    EXPECTED_CONTAINMENT_DATE = col_datetime(format=""),
    ANTICIPATED_COMPLETION_DATE = col_datetime(format=""),
    REPORT_DAY_SPAN           = col_double(),
    DISCOVERY_DOY             = col_double(),
    REPORT_DOY                = col_double(),
    # 3) location
    POO_LONGITUDE             = col_double(),
    POO_LATITUDE              = col_double(),
    POO_STATE                 = col_character(),
    POO_COUNTY                = col_character(),
    POO_US_NGR_XCOORD         = col_double(),
    POO_UTM_EASTING           = col_double(),
    POO_UTM_NORTHING          = col_double(),
    TERRAIN                   = col_character(),
    FUEL_MODEL                = col_character(),
    ADDNTL_FUEL_MODEL         = col_character(),
    SECNDRY_FUEL_MODEL        = col_character(),
    # 4) size & growth
    ACRES                     = col_double(),
    NEW_ACRES                 = col_double(),
    EVENT_FINAL_ACRES         = col_double(),
    WF_FSR                    = col_double(),
    CURR_INCIDENT_AREA        = col_double(),
    PROJ_INCIDENT_AREA        = col_character(),
    GROWTH_POTENTIAL          = col_character(),
    PCT_CONTAINMENT           = col_double(),
    PCT_CONTAINED_COMPLETED   = col_double(),
    MAX_FIRE_PCT_FINAL_SIZE   = col_double(),
    # 5) behavior & resources
    FIRE_BEHAVIOR_1           = col_character(),
    FIRE_BEHAVIOR_2           = col_character(),
    FIRE_BEHAVIOR_3           = col_character(),
    GEN_FIRE_BEHAVIOR         = col_character(),
    FB_RUNNING                = col_logical(),
    FB_CROWNING               = col_logical(),
    FB_BACKING                = col_logical(),
    FB_CREEPING               = col_logical(),
    FB_SMOLDERING             = col_logical(),
    FB_SPOTTING               = col_logical(),
    FB_TORCHING               = col_logical(),
    FB_WIND_DRIVEN            = col_logical(),
    TOTAL_PERSONNEL           = col_double(),
    TOTAL_AERIAL              = col_double(),
    NUM_EVACUATED             = col_double(),
    TOTAL_EVACUATIONS         = col_double(),
    SUPPRESSION_METHOD        = col_character(),
    IMT_MGMT_ORG_DESC         = col_character(),
    INCIDENT_COMMANDERS_NARR  = col_character(),
    # 6) impacts & costs
    FATALITIES                = col_double(),
    INJURIES                  = col_double(),
    RPT_FATALITIES            = col_double(),
    RPT_P_FATALITIES            = col_double(),
    RPT_P_INJURIES              = col_double(),
    EST_IM_COST_TO_DATE       = col_double(),
    PROJECTED_FINAL_IM_COST   = col_double(),
    # 7) narrative
    REMARKS                   = col_character(),
    PLANNED_ACTIONS           = col_character(),
    STRATEGIC_NARR            = col_character(),
    SIGNIF_EVENTS_SUMMARY     = col_character(),
    RISK_ASSESSMENT           = col_character(),
    HAZARDS_MATLS_INVOLVMENT_NARR = col_character(),
    CURRENT_THREAT_NARR       = col_character()
  )
)


  
# 5) now build a proper POSIX‐ct for each SITREP row:
sitreps <- raw_sitreps %>%
  mutate(
    dt_str = if_else(
      str_length(REPORT_TO_DATE)==10,
      paste0(REPORT_TO_DATE," 00:00:00"),
      REPORT_TO_DATE
    ),
    rpt_dt = ymd_hms(dt_str)
  ) %>%
  dplyr::select(-dt_str)

# sanity check
stopifnot(!any(is.na(sitreps$rpt_dt)))



# 6) compute growth rates & peak jumps ---------------------------------
safe_max <- function(x) if(all(is.na(x))) NA_real_ else max(x, na.rm=TRUE)
safe_max_dt <- function(dts, cond) {
  sel <- dts[cond]
  if (length(sel)==0) as.POSIXct(NA) else max(sel)
}

growth_rates <- sitreps %>%
  arrange(INCIDENT_NUMBER, rpt_dt) %>%
  group_by(INCIDENT_NUMBER, INCIDENT_NAME) %>%
  mutate(
    lag_acres     = lag(ACRES),
    lag_dt        = lag(rpt_dt),
    acres_diff    = ACRES - lag_acres,
    hours_diff    = as.numeric(difftime(rpt_dt, lag_dt, units="hours")),
    acres_per_day = if_else(hours_diff>=6,
                            acres_diff/(hours_diff/24),
                            NA_real_)
  ) %>%
  dplyr::select(-hours_diff) %>%
  ungroup()

max_growth <- growth_rates %>%
  group_by(INCIDENT_NUMBER, INCIDENT_NAME) %>%
  summarise(
    growth_start = min(rpt_dt, na.rm=TRUE),
    growth_end   = safe_max_dt(rpt_dt, acres_diff>0),
    final_report = max(rpt_dt, na.rm=TRUE),
    max_growth   = safe_max(acres_per_day),
    .groups      = "drop"
  ) %>%
  arrange(desc(max_growth))

peak_sitreps <- growth_rates %>%
  group_by(INCIDENT_NUMBER) %>%
  slice_max(acres_per_day, n=1, with_ties=FALSE) %>%
  ungroup()

fires <- sitreps %>%
  filter(INCIDENT_NUMBER %in% three_ids) %>%
  distinct(INCIDENT_NUMBER, INCIDENT_NAME)



# 7) pick only Colorado incidents by coordinates ------------------------
#  approx CO bounding box: lon [-109, -102], lat [37, 41]
co_incidents <- sitreps %>%
  filter(POO_LONGITUDE >= -109, POO_LONGITUDE <= -102,
         POO_LATITUDE  >=  37,  POO_LATITUDE  <=  41) %>%
  distinct(INCIDENT_NUMBER, INCIDENT_NAME)



# 8) Top-50 Colorado fires by peak jump ----------------------------------
top50_co_tbl <- max_growth %>%
  semi_join(co_incidents, by="INCIDENT_NUMBER") %>%
  slice_max(order_by=max_growth, n=50) %>%
  dplyr::select(INCIDENT_NUMBER, INCIDENT_NAME, growth_start, growth_end) %>%
  left_join(
    peak_sitreps %>%
      dplyr::select(INCIDENT_NUMBER, rpt_dt, POO_LONGITUDE, POO_LATITUDE, ACRES),
    by="INCIDENT_NUMBER"
  )

cat("\n--- Top 50 Colorado fires by peak jump ---\n")
print(top50_co_tbl)



# 9) make output dir -----------------------------------------------------
out_dir <- "plots/3_CO_Fast_ROS"
dir.create(out_dir, showWarnings=FALSE, recursive=TRUE)



# 10) Full SITREP plots ---------------------------------------------------
for(row in seq_len(nrow(fires))) {
  id        <- fires$INCIDENT_NUMBER[row]
  fire_name <- fires$INCIDENT_NAME[row]
  
  df <- growth_rates %>%
    filter(INCIDENT_NUMBER == id,
           INCIDENT_NAME   == fire_name)
  if(nrow(df)==0) next
  pk <- peak_sitreps %>%
    filter(INCIDENT_NUMBER == id,
           INCIDENT_NAME   == fire_name)
  if(nrow(pk)==0) next
  
  jump_dt  <- pk$rpt_dt[1]
  jump_val <- pk$acres_per_day[1]
  y_max    <- max(df$ACRES, na.rm=TRUE)
  annot_y  <- y_max * 0.9
  start_dt <- min(df$rpt_dt)
  end_dt   <- max(df$rpt_dt)
  
  p_full <- ggplot(df, aes(rpt_dt, ACRES)) +
    geom_line(aes(color="Cumulative\nacres")) +
    geom_point(aes(color="New\nreports")) +
    scale_color_manual(
      name   = NULL,
      values = c(
        `Cumulative\nacres`="orange",
        `New\nreports`       ="steelblue"
      )
    ) +
    geom_vline(xintercept=as.numeric(jump_dt),
               linetype="dashed", color="white") +
    annotate("text", x=jump_dt, y=annot_y,
             label=glue("peak {round(jump_val,1)} ac/d"),
             angle=360, hjust=1.1, color="white") +
    labs(
      title = glue("{fire_name} ({id}) — full SITREP"),
      subtitle = glue("{format(start_dt,'%Y-%m-%d')} → {format(end_dt,'%Y-%m-%d')}"),
      x     = "Report date",
      y     = "Cumulative acres"
    ) +
    theme_minimal(base_size = 12) %+replace%
    theme(
      panel.background    = element_rect(fill = "black", color = NA),
      plot.background     = element_rect(fill = "black", color = NA),
      panel.grid.major    = element_line(color = "grey50"),
      panel.grid.minor    = element_line(color = "grey60"),
      axis.title          = element_text(color = "white", size = rel(0.8)),
      axis.text           = element_text(color = "white", size = rel(0.7)),
      plot.title          = element_text(color = "white", size = rel(1.0)),
      plot.subtitle       = element_text(color = "white", size = rel(0.7)),
      legend.position.inside     = c(0.1, 0.9),
      legend.text         = element_text(color = "white", size = rel(0.7)),
      legend.background   = element_rect(fill = "transparent", color = NA),
      legend.key          = element_rect(fill = "transparent", color = NA)
    )
  print(p_full)
  ggsave(
    filename = glue("{id}_full_sitrep.png"),
    plot     = p_full,
    path     = out_dir,
    width    = 8, height = 5, bg = "black"
  )
}



# 11) Growth-to-peak plots -----------------------------------------------
for(row in seq_len(nrow(fires))) {
  id        <- fires$INCIDENT_NUMBER[row]
  fire_name <- fires$INCIDENT_NAME[row]
  
  jump_dt <- peak_sitreps$rpt_dt[peak_sitreps$INCIDENT_NUMBER == id][1]
  df2     <- growth_rates %>%
    filter(INCIDENT_NUMBER == id,
           INCIDENT_NAME   == fire_name,
           rpt_dt <= jump_dt)
  if(nrow(df2) < 2) next
  
  p_up <- ggplot(df2, aes(rpt_dt, ACRES)) +
    geom_line(aes(color="Cumulative\nacres")) +
    geom_point(aes(color="New\nreports")) +
    scale_color_manual(
      name   = NULL,
      values = c(
        `Cumulative\nacres`="orange",
        `New\nreports`       ="steelblue"
      )
    ) +
    labs(
      title    = glue("{fire_name} ({id}) — growth up to peak"),
      subtitle = glue("through {format(jump_dt,'%Y-%m-%d %H:%M')}"),
      x        = "Report date",
      y        = "Cumulative acres"
    ) +
    theme_minimal(base_size = 12) %+replace%
    theme(
      panel.background    = element_rect(fill = "black", color = NA),
      plot.background     = element_rect(fill = "black", color = NA),
      panel.grid.major    = element_line(color = "grey50"),
      panel.grid.minor    = element_line(color = "grey60"),
      axis.title          = element_text(color = "white", size = rel(0.8)),
      axis.text           = element_text(color = "white", size = rel(0.7)),
      plot.title          = element_text(color = "white", size = rel(1.0)),
      plot.subtitle       = element_text(color = "white", size = rel(0.7)),
      legend.position.inside     = c(0.1, 0.9),
      legend.text         = element_text(color = "white", size = rel(0.7)),
      legend.background   = element_rect(fill = "transparent", color = NA),
      legend.key          = element_rect(fill = "transparent", color = NA)
    )
  print(p_up)
  ggsave(
    filename = glue("{id}_growth_to_peak.png"),
    plot     = p_up,
    path     = out_dir,
    width    = 8, height = 5, bg = "black"
  )
}



# 12) Mini-table for those three ------------------------------------------
# Define spotlight fires (3 out of the 10 total)
fires <- fires %>% filter(INCIDENT_NUMBER %in% three_ids)
special_tbl <- max_growth %>%
  inner_join(fires, by=c("INCIDENT_NUMBER","INCIDENT_NAME")) %>%
  dplyr::select(INCIDENT_NUMBER, INCIDENT_NAME, growth_start, growth_end) %>%
  left_join(
    peak_sitreps %>%
      inner_join(fires, by="INCIDENT_NUMBER") %>%
      rename(ROS = acres_per_day) %>%
      dplyr::select(INCIDENT_NUMBER, rpt_dt, POO_LONGITUDE, POO_LATITUDE, ACRES, ROS) %>%
      distinct(INCIDENT_NUMBER, .keep_all = TRUE),
    by="INCIDENT_NUMBER"
  )

# Emit ROS_values_summary.csv for the comparison script
special_tbl %>%
  distinct(INCIDENT_NAME, .keep_all = TRUE) %>%
  transmute(
    fire = str_to_title(INCIDENT_NAME),
    ROS  = ROS
  ) %>%
  # this will live alongside your FRE summary
  write_csv("plots/dNBR_vs_FRE/ROS_values_summary.csv")

cat("\n--- Summary for those three fires ---\n")
print(special_tbl)
# done!
