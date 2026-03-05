###
# 01 - Spatial Vector Operations with sf
# 260226
###

# This script covers:
# 1. sf basics: reading, inspecting, and plotting spatial data
# 2. CRS transformations and reprojection
# 3. Geometric operations: centroids, buffers, area, distance
# 4. Spatial joins
# 5. Mapping with ggplot2 + geom_sf
# 6. Satellite data access with rsi
# 7. Band composites and spectral indices
# 8. End-to-end satellite → extraction → regression workflow

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(sf)
p_load(ggplot2)
p_load(rnaturalearth)
p_load_current_gh("ropensci/rnaturalearthhires")
p_load(rsi)
p_load(terra)

# 0 - settings ----
setwd("07-spatial-satellite-data")
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("temp", showWarnings = FALSE)

# 1 - load vector data ----

# rnaturalearth provides country/state boundaries as sf objects
world = ne_countries(scale = "medium", returnclass = "sf")

# inspect
class(world)        # "sf" "data.frame"
st_geometry(world)   # geometry column summary
st_crs(world)        # CRS: WGS 84 (EPSG:4326)

# basic columns
names(world)[1:15]

# 2 - simple map with ggplot2 + geom_sf ----

p_world = ggplot(world) +
  geom_sf(aes(fill = gdp_md), color = "grey30", linewidth = 0.1) +
  scale_fill_viridis_c(trans = "log10", name = "GDP (M USD)",
                       na.value = "grey80") +
  labs(title = "World GDP") +
  theme_minimal()
ggsave("output/figures/260226_world_gdp.png", p_world,
       width = 12, height = 6, dpi = 300)
rm(p_world)

# 3 - subsetting and filtering ----

# extract European countries
europe = world[world$continent == "Europe", ]

p_europe = ggplot(europe) +
  geom_sf(aes(fill = pop_est), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(name = "Population", labels = scales::comma) +
  coord_sf(xlim = c(-25, 45), ylim = c(35, 72)) +
  labs(title = "Europe: Population") +
  theme_minimal()
ggsave("output/figures/260226_europe_pop.png", p_europe,
       width = 10, height = 8, dpi = 300)
rm(p_europe)

# 4 - CRS transformation ----

# check current CRS
st_crs(europe)$epsg  # 4326 (WGS 84, unprojected)

# reproject to ETRS89 / Lambert Azimuthal Equal-Area (EPSG:3035)
# equal-area projections are needed for correct area calculations
europe_proj = st_transform(europe, crs = 3035)

# compare: unprojected vs projected
par(mfrow = c(1, 2))
plot(st_geometry(europe), main = "WGS 84 (unprojected)")
plot(st_geometry(europe_proj), main = "ETRS89-LAEA (projected)")
par(mfrow = c(1, 1))

# 5 - centroids ----

centroids = st_centroid(europe_proj)

p_centroids = ggplot() +
  geom_sf(data = europe_proj, fill = "lightblue", color = "grey50") +
  geom_sf(data = centroids, color = "red", size = 2) +
  labs(title = "Country Centroids (ETRS89-LAEA)") +
  theme_minimal()
ggsave("output/figures/260226_centroids.png", p_centroids,
       width = 10, height = 8, dpi = 300)
rm(p_centroids)

# 6 - buffers ----

# create 500 km buffer around Germany's centroid
germany = europe_proj[europe_proj$name == "Germany", ]
germany_centroid = st_centroid(germany)
buffer_500km = st_buffer(germany_centroid, dist = 500000)  # meters

p_buffer = ggplot() +
  geom_sf(data = europe_proj, fill = "grey90", color = "grey50") +
  geom_sf(data = buffer_500km, fill = NA, color = "red",
          linewidth = 1, linetype = "dashed") +
  geom_sf(data = germany, fill = "steelblue", alpha = 0.5) +
  geom_sf(data = germany_centroid, color = "red", size = 3) +
  coord_sf(xlim = st_bbox(europe_proj)[c(1, 3)],
           ylim = st_bbox(europe_proj)[c(2, 4)]) +
  labs(title = "500 km Buffer Around Germany's Centroid") +
  theme_minimal()
ggsave("output/figures/260226_buffer.png", p_buffer,
       width = 10, height = 8, dpi = 300)
rm(p_buffer, buffer_500km)

# 7 - area calculation ----

# area requires a projected CRS (equal-area)
europe_proj$area_km2 = as.numeric(st_area(europe_proj)) / 1e6

area_dt = as.data.table(europe_proj)[, .(name, area_km2)] %>%
  .[order(-area_km2)]
area_dt[1:10]

# 8 - distance matrix ----

# pairwise distances between centroids (in km)
dist_matrix = st_distance(centroids) / 1000  # convert m to km
rownames(dist_matrix) = centroids$name
colnames(dist_matrix) = centroids$name

# distance from Germany to other centroids
dist_from_germany = sort(dist_matrix["Germany", ])
head(dist_from_germany, 10)

# 9 - spatial join ----

# example: assign random points to countries
set.seed(42)
random_points = st_as_sf(
  data.frame(
    lon = runif(100, -10, 40),
    lat = runif(100, 35, 70),
    value = rnorm(100)
  ),
  coords = c("lon", "lat"),
  crs = 4326
)
random_points_proj = st_transform(random_points, crs = 3035)

# spatial join: which country does each point fall in?
points_joined = st_join(random_points_proj, europe_proj[, "name"])

points_dt = as.data.table(points_joined)
points_dt[!is.na(name), .N, by = name][order(-N)]

# 10 - satellite data access with rsi ----

# rsi provides access to Sentinel-2 and other satellite imagery
# via STAC (SpatioTemporal Asset Catalog) APIs

# define area of interest (bounding box around Kiel, Germany)
aoi = st_bbox(c(xmin = 10.0, ymin = 54.2, xmax = 10.3, ymax = 54.4),
              crs = 4326) %>%
  st_as_sfc() %>%
  st_transform(32632)  # UTM zone 32N (covers Kiel)

# download Sentinel-2 imagery
imagery = get_sentinel2_imagery(
  aoi = aoi,
  start_date = "2026-02-15",
  end_date = "2026-03-03",
  output_filename = "temp/sentinel2_kiel.tif"
)

# load and plot
img = rast(imagery)
names(img)  # check band names and order
plot(img)

plotRGB(img, r = 4, g = 3, b = 2, stretch = "lin")  # B04/B03/B02

# 11 - band composites ----

# extract individual bands
A  = img[["A"]]    # B01 (60m)
B  = img[["B"]]    # B02 (10m)
G  = img[["G"]]    # B03 (10m)
R  = img[["R"]]    # B04 (10m)
N  = img[["N"]]    # B08 (10m)
N2 = img[["N2"]]   # B8A (20m)
S1 = img[["S1"]]   # B11 (20m)
S2 = img[["S2"]]   # B12 (20m)

# resample coarser bands to 10m grid
S1_10 = resample(S1, R, method = "bilinear")
S2_10 = resample(S2, R, method = "bilinear")
N2_10 = resample(N2, R, method = "bilinear")
A_10  = resample(A, R, method = "bilinear")

# natural color (B4, B3, B2)
rgb_nat = c(R, G, B)
names(rgb_nat) = c("R", "G", "B")
plotRGB(rgb_nat, r = 1, g = 2, b = 3, stretch = "hist",
        main = "Natural Color (R, G, B)")

# color infrared (B8, B4, B3)
rgb_cir = c(N, R, G)
names(rgb_cir) = c("R", "G", "B")
plotRGB(rgb_cir, r = 1, g = 2, b = 3, stretch = "hist",
        main = "Color Infrared (N, R, G)")

# SWIR (B12, B8A, B4)
rgb_swir = c(S2_10, N2_10, R)
names(rgb_swir) = c("R", "G", "B")
plotRGB(rgb_swir, r = 1, g = 2, b = 3, stretch = "hist",
        main = "SWIR (S2, N2, R)")

# agriculture (B11, B8, B2)
rgb_agri = c(S1_10, N, B)
names(rgb_agri) = c("R", "G", "B")
plotRGB(rgb_agri, r = 1, g = 2, b = 3, stretch = "hist",
        main = "Agriculture (S1, N, B)")

# geology (B12, B11, B2)
rgb_geo = c(S2_10, S1_10, B)
names(rgb_geo) = c("R", "G", "B")
plotRGB(rgb_geo, r = 1, g = 2, b = 3, stretch = "hist",
        main = "Geology (S2, S1, B)")

# bathymetric (B4, B3, B1)
rgb_bathy = c(R, G, A_10)
names(rgb_bathy) = c("R", "G", "B")
plotRGB(rgb_bathy, r = 1, g = 2, b = 3, stretch = "hist",
        main = "Bathymetric (R, G, A)")

# 12 - spectral indices ----

# NDVI = (NIR - Red) / (NIR + Red), both 10m
ndvi = (N - R) / (N + R)
plot(ndvi, main = "NDVI (N - R) / (N + R)")

# NDMI = (NIR narrow - SWIR1) / (NIR narrow + SWIR1), both 20m
N2_on_S1 = resample(N2, S1, method = "bilinear")
ndmi = (N2_on_S1 - S1) / (N2_on_S1 + S1)
plot(ndmi, main = "NDMI (N2 - S1) / (N2 + S1)")

# 13 - end-to-end workflow: satellite data → regression ----

# conceptual workflow (data-dependent, so shown as pseudocode):
#
# 1. Define AOI and time period
# aoi = st_bbox(...) %>% st_as_sfc()
#
# 2. Download satellite imagery
# imagery = get_sentinel2_imagery(aoi, start_date, end_date, output)
#
# 3. Load raster and vector data
# img = rast(imagery)
# regions = st_read("input/regions.shp") %>% st_transform(st_crs(img))
#
# 4. Extract zonal statistics (mean brightness per region)
# stats = terra::extract(img, vect(regions), fun = mean, na.rm = TRUE)
#
# 5. Join to panel data and run regression
# panel = merge(panel_dt, stats_dt, by = "region_id")
# model = fixest::feols(gdp ~ nightlight_mean | region + year, data = panel)

# 14 - cleanup ----

rm(world, europe, europe_proj, centroids, germany, germany_centroid)
rm(random_points, random_points_proj, points_joined)
rm(aoi, imagery, img)
rm(A, B, G, R, N, N2, S1, S2, A_10, S1_10, S2_10, N2_10, N2_on_S1)
rm(rgb_nat, rgb_cir, rgb_swir, rgb_agri, rgb_geo, rgb_bathy)
rm(ndvi, ndmi)
gc()
