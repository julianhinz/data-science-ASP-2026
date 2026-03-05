###
# 02 - Nightlights Analysis: Raster Operations with terra
# 260226
###

# This script covers:
# 1. Loading and inspecting raster data (elevation, nightlights)
# 2. Stacking and aggregating nightlight images across time
# 3. Comparing changes in light intensity (pixel-wise difference)
# 4. Cropping and masking rasters using vector boundaries
# 5. Extracting zonal statistics for further analysis

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(terra)
p_load(sf)
p_load(stringr)
p_load(ggplot2)
p_load(rnaturalearth)
p_load_current_gh("ropensci/rnaturalearthhires")

# 0 - settings ----
setwd("07-spatial-satellite-data")
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# 1 - load and plot elevation raster ----

img = rast(system.file("ex/elev.tif", package = "terra"))
plot(img, main = "Elevation (Luxembourg)")

# inspect
dim(img)
res(img)
crs(img, describe = TRUE)$name

# 2 - load and plot a single nightlight image ----

# nightlight .tif: each pixel = numeric light intensity
img_nightlight = rast("input/20210404_4x.tif")
plot(log(img_nightlight), main = "Single Nightlight Image (log scale)")

# why is it hard to see anything with a single image?
# answer: noise from clouds, moonlight, etc. -- need to aggregate

# 3 - stack and aggregate nightlight images ----

list_images = list.files("input", pattern = "\\.tif$", full.names = TRUE)
length(list_images)

# filter for May 2022 and May 2021
list_may22 = list_images[str_detect(list_images, "202205")]
list_may21 = list_images[str_detect(list_images, "202105")]

# stack and compute median (reduces cloud/noise artifacts)
images_may22 = rast(list_may22)
images_may22_median = median(images_may22)
plot(log(images_may22_median), main = "May 2022 Median Nightlights (log)")

images_may21 = rast(list_may21)
images_may21_median = median(images_may21)
plot(log(images_may21_median), main = "May 2021 Median Nightlights (log)")

# 4 - pixel-wise difference ----

# difference = 2021 - 2022 (positive = brighter in 2021, i.e. dimmer now)
images_diff = images_may21_median - images_may22_median
plot(images_diff, main = "Nightlight Change: May 2021 minus May 2022")

# 5 - compare pixel intensity distributions ----

images_may21_mean = mean(images_may21)
images_may22_mean = mean(images_may22)

# extract pixel values for plotting
plot_may22 = terra::values(images_may22_mean, dataframe = TRUE) %>% setDT()
plot_may21 = terra::values(images_may21_mean, dataframe = TRUE) %>% setDT()

p_density = ggplot() +
  geom_density(data = plot_may22, aes(x = mean), n = 50,
               color = "red", linewidth = 0.8) +
  geom_density(data = plot_may21, aes(x = mean), n = 50,
               color = "blue", linewidth = 0.8) +
  scale_y_log10("PDF") +
  scale_x_continuous("Avg. Nightlight Intensity") +
  annotate("text", x = Inf, y = Inf, label = "Blue = May 2021\nRed = May 2022",
           hjust = 1.1, vjust = 1.5, size = 3.5) +
  labs(title = "Nightlight Intensity Distributions") +
  theme_minimal()
ggsave("output/figures/260226_nightlight_density.png", p_density,
       width = 8, height = 5, dpi = 300)
rm(p_density, plot_may21, plot_may22)

# 6 - focused analysis on Ukraine ----

# load country boundaries
shape_ukraine = ne_countries(country = "Ukraine", returnclass = "sf")
plot(st_geometry(shape_ukraine), main = "Ukraine")

# 7 - align coordinate reference systems ----

st_crs(shape_ukraine)$epsg
crs(images_may22_median, describe = TRUE)$name

# reproject the vector data to match the raster CRS
shape_ukraine = st_transform(shape_ukraine, st_crs(images_may22_median))

# 8 - crop and mask raster to Ukraine ----

# crop: cut raster to bounding box of Ukraine
ukraine_may22_crop = crop(images_may22_median, shape_ukraine)
plot(log(ukraine_may22_crop), main = "Ukraine Nightlights (Cropped)")

# mask: set pixels outside Ukraine's border to NA
ukraine_may22_masked = mask(ukraine_may22_crop, shape_ukraine)
plot(log(ukraine_may22_masked), main = "Ukraine Nightlights (Masked)")

# same for May 2021
ukraine_may21_crop = crop(images_may21_median, shape_ukraine)
ukraine_may21_masked = mask(ukraine_may21_crop, shape_ukraine)

# 9 - difference map for Ukraine ----

ukraine_diff = ukraine_may21_masked - ukraine_may22_masked
plot(ukraine_diff, main = "Ukraine: Nightlight Change (May 2021 - May 2022)")

# positive values = areas that got darker (potential conflict damage)

# 10 - extract zonal statistics ----

# mean nightlight intensity within Ukraine
mean(values(ukraine_may21_masked), na.rm = TRUE)
mean(values(ukraine_may22_masked), na.rm = TRUE)
mean(values(ukraine_diff), na.rm = TRUE)

# for panel regressions, extract by subnational region:
# regions = st_read("input/ukraine_oblasts.shp")
# stats = terra::extract(ukraine_may22_masked, vect(regions),
#                        fun = mean, na.rm = TRUE)

# 11 - cleanup ----

rm(img, img_nightlight, images_may21, images_may22)
rm(images_may21_median, images_may22_median, images_diff)
rm(images_may21_mean, images_may22_mean)
rm(ukraine_may21_crop, ukraine_may21_masked)
rm(ukraine_may22_crop, ukraine_may22_masked, ukraine_diff)
rm(shape_ukraine)
gc()
