#! /opt/homebrew/bin/Rscript

###
# 01 - spatial and satellite data
# 260304
###

# Load libraries
if (!require("pacman")) install.packages("pacman"); library("pacman")
p_load(ggplot2)
p_load(sf)
p_load(terra)
p_load(rsi)
p_load(rnaturalearth)
# p_load(rnaturalearthdata)

# Load world map data
world <- ne_countries(scale = "medium", returnclass = "sf")

# plot world map
ggplot() +
    geom_sf(data = world, color = "black", aes(fill = pop_est)) +
    geom_label(aes(x = label_x, y = label_y, label = name), data = world) +
    theme_minimal() +
    labs(title = "World Map")

class(world)
head(world)

world$geometry


# focus on europe
europe <- world[world$continent == "Europe", ]

ggplot() +
    geom_sf(data = europe, color = "black", aes(fill = pop_est)) +
    theme_minimal() +
    xlim(c(-10, 30)) + ylim(c(35, 70)) +
    labs(title = "Europe Map")


# buffers

iran  = world[world$name_en == "Iran", ]
# plot(iran$geometry)

iran_buffer <- st_buffer(iran$geometry, dist = 100000) # 100 km buffer

ggplot() +
    geom_sf(data = iran_buffer, fill = "lightblue", color = "blue", alpha = 0.5) +
    geom_sf(data = iran, fill = "lightgray", color = "black") +
    theme_minimal() +
    labs(title = "Iran and its 100 km Buffer Zone")


# working with satellite data
# Define the area of interest (AOI) as a bounding box

aoi = st_bbox(c(xmin = 10,
                ymin = 54.3,
                xmax = 10.3,
                ymax = 54.4), crs = 4326) %>%
    st_as_sfc() %>%
    st_transform(32632)

class(aoi)
plot(aoi)

kiel_image = get_sentinel2_imagery(aoi = aoi,
                     start_date = "2025-07-15",
                     end_date = "2025-07-30",
                     output_filename = "temp/sentinel2_image.tif")

# class(kiel_image)
# str(kiel_image)

img = rast(kiel_image)
class(img)
str(img)

plot(img)
plotRGB(img, r = 4, g = 3, b = 2, stretch = "lin")

# band composites
names(img)

# infrared composite
plotRGB(c(img[["S1"]], img[["N"]], img[["B"]]),
        r = 1, g = 2, b = 3, stretch = "lin")
