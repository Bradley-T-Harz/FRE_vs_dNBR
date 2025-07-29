# There will be warnings because some of the plots were set diagonal to lat/lon. I am unsure how.
# 08_dNBR_values_&_plot.R

#!/usr/bin/env Rscript
library(sf)
library(raster)
library(dplyr)
library(ggplot2)
library(glue)
library(stringr)
library(readr)
library(viridis)

# ─────────────────────────────────────────────────────────────────────────────
# 1) Load MTBS fire perimeter shapefile
# ─────────────────────────────────────────────────────────────────────────────
mtbs <- suppressWarnings(
  st_read("MTBS_Datasets/mtbs_perimeter_data/mtbs_perims_DD.shp", quiet=TRUE) %>%
  # override bad metadata: this geometry *is* Albers metres
    st_set_crs(4269) %>%      
    st_transform(5070) %>%
  mutate(
    Incid_Name = str_to_upper(Incid_Name) %>% str_squish(),
    across(where(is.numeric), ~ na_if(., -9999) %>% na_if(9999)),
    across(matches("_T$"), ~ .x / 100)
  )
)

# ─────────────────────────────────────────────────────────────────────────────
# 2) File path setup
# ─────────────────────────────────────────────────────────────────────────────
fires <- list.dirs("Fire GeoTIFFs", full.names = FALSE, recursive = FALSE)
out_dir <- "plots/dNBR_perimeter_maps"
dir.create(out_dir, showWarnings=FALSE, recursive=TRUE)

# Option 2: limit to known fire names from your fire list
target_fires <- fires_tbl$INCIDENT_NAME %>%
  stringr::str_squish() %>%
  stringr::str_to_upper()
fires <- fires[fires %in% target_fires]

# ─────────────────────────────────────────────────────────────────────────────
# 3) Process each fire
# ─────────────────────────────────────────────────────────────────────────────
all_stats <- list()
skipped_fires <- list()

for (f in fires) {
  message("Processing ", f)
  
  file_base <- f
  
  dnbr_path <- list.files(
    file.path("Fire GeoTIFFs", file_base),
    pattern = "_dnbr\\.tif$",
    full.names = TRUE
  )
  
  dnbr6_path <- list.files(
    file.path("Fire GeoTIFFs", file_base),
    pattern = "_dnbr6\\.tif$",
    full.names = TRUE
  )
  
  # Optional: collect rdnbr (e.g. if you plan to analyze it later)
  rdnbr_path <- list.files(
    file.path("Fire GeoTIFFs", file_base),
    pattern = "_rdnbr\\.tif$",
    full.names = TRUE
  )
  
  if (length(dnbr_path) == 0 || length(dnbr6_path) == 0) {
    warning("Missing one or both raster files for fire: ", f)
    next
  }

  r_dnbr <- raster(dnbr_path)
  r_dnbr6 <- raster(dnbr6_path)
  r_crs <- crs(r_dnbr)
  
  NAvalue(r_dnbr) <- -32768
  
  # check range for scale (only once)
  r_vals <- getValues(r_dnbr)
  val_range <- range(r_vals, na.rm = TRUE)
  message("  Raw dNBR range: ", paste(round(val_range, 3), collapse = ", "))
  
  # Fix for MTBS dNBR scaling
  if (val_range[2] > 5000) {
    message("  Detected ×10000 scale — dividing by 10000")
    r_dnbr <- r_dnbr / 10000
  } else if (val_range[2] > 1000) {
    message("  Detected ×1000 scale — dividing by 1000")
    r_dnbr <- r_dnbr / 1000
  } else if (val_range[2] > 100) {
    message("  Detected ×10000 *mid‑range* scale — dividing by 10000")
    r_dnbr <- r_dnbr / 10000
  } else {
    message("  No scaling applied")
  }
  
  # 3) build & union the perimeter polygon
  pg_raw <- mtbs %>% filter(Incid_Name == f)
  if (nrow(pg_raw)==0) {
    warning("No MTBS perimeter for ", f, " – plotting full raster extents")
    r_dnbr_crop  <- r_dnbr
    r_dnbr6_crop <- r_dnbr6
  } else {
    pg    <- st_union(pg_raw)      # still in EPSG:5070
    pg_sp <- as(st_as_sf(pg), "Spatial")

    # test overlap *once*
    intr <- try(raster::intersect(r_dnbr, pg_sp), silent=TRUE)
    if (inherits(intr, "try-error") || intr@nrows == 0) {
      warning("❗ No overlap for ", f, " – plotting full raster extents")
      r_dnbr_crop  <- r_dnbr
      r_dnbr6_crop <- r_dnbr6
    } else {
      # safe crop & mask
      r_dnbr_crop  <- crop(r_dnbr,  pg_sp) %>% mask(pg_sp)
      r_dnbr6_crop <- crop(r_dnbr6, pg_sp) %>% mask(pg_sp)
    }
  }
  
  # 6) (optional) project to lat/long if you want
  r_dnbr_plot  <- projectRaster(r_dnbr_crop,  crs=CRS("+proj=longlat +datum=WGS84"))
  r_dnbr6_plot <- projectRaster(r_dnbr6_crop, crs=CRS("+proj=longlat +datum=WGS84"))
  
  # Reproject rasters for plotting with lat/lon axes
  r_dnbr_plot <- projectRaster(
    r_dnbr_crop, 
    crs = CRS("+proj=longlat +datum=WGS84"))
  r_dnbr6_plot <- projectRaster(
    r_dnbr6_crop, 
    crs = CRS("+proj=longlat +datum=WGS84"))
  
  # summary stats
  stats <- c(
    mean = cellStats(r_dnbr_crop, 'mean', na.rm=TRUE),
    sd   = cellStats(r_dnbr_crop, 'sd',   na.rm=TRUE),
    min  = cellStats(r_dnbr_crop, 'min',  na.rm=TRUE),
    max  = cellStats(r_dnbr_crop, 'max',  na.rm=TRUE)
  )
  
  stats_tbl <- tibble(
    fire      = f,
    mean_dNBR = stats['mean'],
    sd_dNBR   = stats['sd'],
    min_dNBR  = stats['min'],
    max_dNBR  = stats['max']
  )
  
  write_csv(stats_tbl, file.path(out_dir, sprintf("%s_dNBR_stats.csv", str_replace_all(f," ","_"))))
  
  # Accumulate all results
  all_stats[[f]] <- stats_tbl
  
  # Optional: Handle rDNBR raster if available
  if (length(rdnbr_path) > 0) {
    r_rdnbr <- raster(rdnbr_path)
    if (exists("pg_sp") && inherits(intr, "Spatial") && intr@nrows > 0) {
      # only crop/mask if we actually have a perimeter & overlap
      r_rdnbr_crop <- crop(r_rdnbr, pg_sp) %>% mask(pg_sp)
    } else {
      # no overlap or no perimeter: just use the full raster
      r_rdnbr_crop <- r_rdnbr
    }
    r_rdnbr_plot <- projectRaster(r_rdnbr_crop, crs=CRS("+proj=longlat +datum=WGS84"))
    
    png(file.path(out_dir, sprintf("%s_rDNBR_map.png", str_replace_all(f, " ", "_"))),
        width=600, height=600, bg="black")
    par(bg="black", col.axis="white", col.lab="white", col.main="white", col.sub="white")
    plot(r_rdnbr_plot, col=NA, main=glue("{f}: rDNBR"), axes=TRUE)
    grid(col="white", lty="dotted")
    image(r_rdnbr_plot, add=TRUE, useRaster=TRUE)
    box(col="white")
    dev.off()
  }
  
  # plot dNBR
  png(file.path(
    out_dir, 
    sprintf(
      "%s_dNBR_map.png", 
      str_replace_all(f," ","_"))), 
    width=600, height=600, bg="black")
  par(bg = "black", col.axis = "white", col.lab = "white", col.main = "white", col.sub = "white")
  
  plot(
    r_dnbr_plot, 
    col = NA, main = glue("{f}: dNBR (mean={round(stats['mean'],2)})"), 
    axes = TRUE)
  grid(
    col = "white", 
    lty = "dotted")  # draw grid first
  image(
    r_dnbr_plot, 
    col = viridis(50), 
    add = TRUE, 
    useRaster = TRUE)  # draw raster on top
  box(col = "white")
  
  dev.off()
  
  # plot dNBR6 with legend
  png(file.path(
    out_dir, 
    sprintf(
      "%s_dNBR6_map.png", 
      str_replace_all(f," ","_"))), 
    width=900, height=535, bg="black")
  
  par(
    bg = "black", 
    col.axis = "white", 
    col.lab = "white", 
    col.main = "white", 
    col.sub = "white",
    mar = c(5, 4, 4, 12),
    oma = c(0, 0, 0, 5),
    xpd = FALSE
  )
  
  severity_colors <- c(
    "green3",   # 1: Unburned to Low
    "khaki",  # 2: Low severity
    "yellow",      # 3: Moderate severity
    "darkorange2",      # 4: High severity
    "darkgreen",        # 5: Increased Greenness
    "white"        # 6: NA / Unprocessed
  )
  
  severity_labels <- c(
    "Unburned to Low",     # 1
    "Low severity",        # 2
    "Moderate severity",   # 3
    "High severity",       # 4
    "Increased Greenness", # 5
    "Unprocessed / NA"     # 6
  )
  
  # Expand the plot extent manually
  ext_exp <- extent(r_dnbr6_plot)
  xrange <- ext_exp@xmax - ext_exp@xmin
  xpad <- 0.15 * xrange
  xlim_ext <- c(ext_exp@xmin, ext_exp@xmax + xpad)
  
  plot(
    r_dnbr6_plot, 
    col = NA,
    legend = FALSE,
    axes = TRUE,
    xlim = xlim_ext,
    xaxs = "i", yaxs = "i"
  )
  
  #/
  # Enable plotting outside region
  par(xpd = TRUE)
  
  # Restrict grid to original raster extent (avoid spilling into margin)
  longs <- seq(ext_exp@xmin, ext_exp@xmax, length.out = 11)
  lats  <- seq(ext_exp@ymin, ext_exp@ymax, length.out = 11)
  
  # Turn off plot clipping only AFTER gridlines
  par(xpd = FALSE)  # clip to plot region
  
  # Vertical lines
  for (x in longs) {
    if (x >= ext_exp@xmin && x <= ext_exp@xmax) {
      lines(x = c(x, x), y = c(ext_exp@ymin, ext_exp@ymax), col = "white", lty = "dotted")
    }
  }
  # Horizontal lines
  for (y in lats) {
    if (y >= ext_exp@ymin && y <= ext_exp@ymax) {
      lines(x = c(ext_exp@xmin, ext_exp@xmax), y = c(y, y), col = "white", lty = "dotted")
    }
  }
  
  par(xpd = TRUE)  # re-enable for title text outside the box
  #/
  
  image(
    r_dnbr6_plot, 
    col = severity_colors, 
    add = TRUE, 
    useRaster = TRUE)
  
  legend(
    "bottomleft", 
    legend = severity_labels,
    fill = severity_colors, 
    border = NA,
    text.col = "white", 
    box.col = "white", 
    bg = "black", 
    cex = 0.8
  )
  
  # Add 2-line horizontal title on the right
  text(
    x = ext_exp@xmax + 0.02 * xrange, 
    y = ext_exp@ymax - 0.06 * (ext_exp@ymax - ext_exp@ymin), 
    labels = f,
    col = "white", cex = 1.3, adj = c(0, 1)
  )
  
  text(
    x = ext_exp@xmax + 0.06 * xrange, 
    y = ext_exp@ymax - 0.10 * (ext_exp@ymax - ext_exp@ymin), 
    labels = "dNBR6 classification",
    col = "white", cex = 1, adj = c(0, 1)
  )
  
  box(col = "white")
  
  dev.off()
  
  message("Done — maps and stats saved to ", out_dir)
}  # end fire loop

print(glue("CRS raster: {r_crs}"))
print(glue("CRS perimeter: {st_crs(pg)$proj4string}"))

# Combine all individual fire stats into one summary table
summary_stats <- bind_rows(all_stats)
write_csv(summary_stats, file.path(out_dir, "dNBR_summary_stats_all_fires.csv"))

# Save skipped fires table if any
if (length(skipped_fires) > 0) {
  skipped_tbl <- bind_rows(skipped_fires)
  write_csv(skipped_tbl, file.path(out_dir, "skipped_fires.csv"))
}

message("🔥 All dNBR stats written to: ", out_dir)

st_crs(mtbs)

st_bbox(mtbs)
