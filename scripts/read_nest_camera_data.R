# This script: reads nest locations and predator camera data from the nest
# study database.

# setup -------------------------------------------------------------------

library(DBI)
library(RSQLite)
library(sf)
library(tidyverse)

# Connect to the database:

con <-
  dbConnect(
    SQLite(),
    here::here("data", "nest_study.sqlite")
  )

# GPS point coordinates:

gps_points <-
  tbl(con, "gps_point") %>%
  select(
    gps_point_id = point_id,
    longitude,
    latitude
  )

# nests -------------------------------------------------------------------

# Nest locations:

nests <-
  tbl(con, "nest") %>%
  inner_join(
    gps_points,
    join_by(gps_point_id)
  ) %>%
  select(
    nest_id,
    patch_id,
    species_code,
    discovery_date,
    camera_or_control,
    camera_deployment_date,
    height_m,
    nest_fate,
    longitude,
    latitude
  ) %>%
  collect() %>%

  # Convert dates:

  mutate(
    across(
      c(discovery_date, camera_deployment_date),
      ymd
    )
  ) %>%

  # Convert to spatial points:

  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  )

# predator cameras --------------------------------------------------------

# Camera locations:

predator_cameras <-
  tbl(con, "predator_camera") %>%
  inner_join(
    gps_points,
    join_by(gps_point_id)
  ) %>%
  select(
    camera_id,
    patch_id,
    longitude,
    latitude
  ) %>%
  collect() %>%

  # Convert to spatial points:

  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  )

# Camera maintenance events:

camera_maintenance <-
  tbl(con, "camera_maintenance") %>%
  select(!maintenance_id) %>%
  collect() %>%
  mutate(
    event_date = ymd(event_date)
  )

# Disconnect:

dbDisconnect(con)
