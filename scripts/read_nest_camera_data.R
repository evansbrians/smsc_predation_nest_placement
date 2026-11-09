# This script: reads nest locations and predator camera data from the nest
# study database.

# setup -------------------------------------------------------------------

library(DBI)
library(googledrive)
library(googlesheets4)
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

# predator cameras --------------------------------------------------------

# Camera locations:

predator_cameras <-
  tbl(con, "predator_camera") %>%
  left_join(
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
    event_date = as_date(event_date)
  )

# nests -------------------------------------------------------------------

# Nest locations:

nests <-
  tbl(con, "nest") %>%
  left_join(
    gps_points,
    join_by(gps_point_id)
  ) %>%
  select(
    nest_id:species_code,
    discovery_date,
    height_m,
    nest_fate,
    longitude,
    latitude
  ) %>%
  collect() %>%
  
  # Remove artificial nests:
  
  filter(species_code != "ARNE") %>% 
  
  # Convert dates:
  
  mutate(
    discovery_date = as_date(discovery_date)
  ) %>%
  
  # Convert to spatial points:
  
  st_as_sf(
    coords = c("longitude", "latitude"),
    crs = 4326
  ) %>%

  # Add patch trail camera locations:

  left_join(
    predator_cameras %>%
      as_tibble() %>%
      mutate(
        tc = str_extract(camera_id, "\\d$")
      ) %>%
      pivot_wider(
        id_cols = patch_id,
        names_from = tc,
        names_prefix = "tc_",
        names_sort = TRUE,
        values_from = geometry
      ),
    join_by(patch_id)
  ) %>%

  # Distance to each trail camera (m):

  mutate(
    across(
      starts_with("tc_"),
      \(.x) {
        st_distance(
          geometry,
          .x,
          by_element = TRUE
        ) %>%
          as.numeric()
      },
      .names = "dist_{.col}"
    )
  ) %>%
  select(!starts_with("tc_"))

# Disconnect:

dbDisconnect(con)

rm(con)

# camera observations -----------------------------------------------------

camera_data <- 
  
  # Convert the Google ID of the folder to a `drive_id`:
  
  as_id("1lEv6L4Y7TglNxu9SBBC8RGKyeXxkVR79") %>% 
  
  # Get a tibble of file names and ids in the folder:
  
  drive_ls(
    type = "spreadsheet"
  ) %>% 
  select(!drive_resource) %>% 
  
  # Cross with the trailcam sheets:
  
  crossing(
    cam = str_c("trailcam_", 0:2)
  ) %>% 
  
  # Read in each file:
  
  pmap(
    \(name, id, cam) {
      
      # Read the sheet:
      
      read_sheet(
        id, 
        sheet = cam,
        col_types = "c"
      ) %>% 
        
        # Add patch and camera information:
        
        mutate(
          patch = name,
          trailcam = cam,
          .before = 1
        ) %>% 
        
        # Remove rows that haven't yet been observed:
        
        filter(
          !cumall(
            is.na(species_1)
          )
        )
    }
  ) %>% 
  list_rbind() %>% 
  
  # Convert columns:
  
  type_convert() %>% 
  
  # Reshape data:
  
  pivot_longer(
    matches("^(species|count)_\\d$"),
    names_to = c(".value", NA),
    names_sep = "_"
  ) %>% 
  relocate(
    notes,
    .after = last_col()
  ) %>% 
  
  # Remove the blank rows:
  
  drop_na(species)
  

