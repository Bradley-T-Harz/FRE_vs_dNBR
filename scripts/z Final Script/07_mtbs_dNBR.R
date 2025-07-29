# 07_mtbs_dNBR.R

library(raster)
library(dplyr)
library(ggplot2)
library(lubridate)

mtbs <- st_read("MTBS_Datasets/mtbs_perimeter_data/mtbs_perims_DD.shp")
str(mtbs)

mtbs_year <- year(mtbs$Ig_Date)
mtbs$year <- mtbs_year

# Collect all your filenames
mtbs_fnames <- list.files(path = "MTBS_Datasets/Fire_data_bundles_Wz7hRM68vPvQtkJ4Ywj5/composite_data/MTBS_BSmosaics/2020/mtbs_CO_2020", 
#                          pattern = "mtbs_[A-Z]{2}_[0-9]{4}.tif",
                          pattern = "\\.tif$",
                          recursive = TRUE, 
                          full.names = TRUE)

stopifnot(length(mtbs_fnames) > 0)

mtbs_fnames

years <- str_extract(mtbs_fnames, pattern = "2[0-9]{3}")
years

count <- 1
dNBR_list <- list()

i <- 1
# Decision: should we iterate through the individual fires or years (and then fires) or MTBS rasters?
# for (i in 1:length(mtbs_fnames)){
# I do think it's good to only open the MTBS raster for a given year once




# We can see the East Troublesome Fire
r <- raster(mtbs_fnames[i])
r

r_crs <- crs(r)

plot(r)

year <- years[i]


# Somehow... get the fire you want... and transform to the same coordinate reference system as the raster data
target_fire <- "East Troublesome"

pgon <- mtbs %>%
  mutate(Incid_Name = stringr::str_to_title(Incid_Name)) %>%
  filter(Incid_Name == stringr::str_to_title(target_fire)) %>%
  st_transform(crs = r_crs)

# Crop the dNBR raster to our polygon and remove the offset (the dNBR for unburned pixels in the surrounding area)*
# *we don't want to attribute that part of the change to the fire
dNBR <- crop(r, pgon) - pgon$dNBR_offst

plot(dNBR)

dNBR_xy <- as.data.frame(dNBR, xy = TRUE)
names(dNBR_xy)[3] <- "layer"
ggplot() + geom_raster(data = dNBR_xy, mapping = aes(x = x, y = y, fill = layer)) +
  scale_fill_viridis_c()


# Research question and carefulness - make sure we can use these values without any additional changes;
# e.g. are they supposed to scale from 0 to 6 and then -1 to 4 after the adjustment?
mean_dNBR <- raster::extract(dNBR, pgon, fun = mean)
sd_dNBR <- raster::extract(dNBR, pgon, fun = sd)
max_dNBR <- raster::extract(dNBR, pgon, fun = max)
min_dNBR <- raster::extract(dNBR, pgon, fun = min)

temp_df <- mutate(pgon, mean_dNBR, max_dNBR, min_dNBR, sd_dNBR)

dNBR_list[[count]] <- temp_df
count <- count + 1


#}

plot(dNBR)

# Next step: match to FRE... quick way to compute FRE is to sum the FL_FRP for a single satellite name for each
# fire and multiply by 12 hours (in seconds...), FL_FRP stands for fire line fire radiative power; it's not accurately
# named right now; then you can add it to temp_df and do it again for another fire

# Learning goal: find a tutorial in R on writing for-loops...

for (i in 1:10){
  print(i)
}
