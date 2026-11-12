# Dashboard script for playing with predator camera and nest data

# setup -------------------------------------------------------------------

# Libraries:

library(googledrive)
library(googlesheets4)
library(sf)
library(tidyverse)

# Authorize Google Drive and Sheets:

drive_auth()

gs4_auth(
  token = drive_token()
)

# Read in and pre-process the data:

source("scripts/read_nest_camera_data.R")

# Define predators:

predators <-
  c(
    "bear",
    "bobcat",
    "chipmunk",
    "coyote",
    "fox",
    "mouse",
    "opossum",
    "owl",
    "raccoon",
    "raptor",
    "skunk",
    "snake",
    "squirrel"
  )

# pre-process camera data -------------------------------------------------

camera_data_processed <-
  camera_data %>% 
  mutate(
    
    # Define time as date_time, rounded to 10-minute time windows:
    
    time = 
      str_c(date, time) %>% 
      ymd_hms() %>% 
      floor_date("10 minutes"),
    
    # Define predators and non-predators:
    
    predator = species %in% predators
  ) %>% 
  
  # Subset to the maximum number of individuals of a given species counted
  # within a 10-minute time window:
  
  slice_max(
    count,
    by = 
      c(patch:trailcam, time:species),
    with_ties = FALSE
  ) %>% 
  
  # Calculate the predator activity index as the number of predators per hour:
  
  summarize(
    hourly_predator_activity =
      sum(count[predator], na.rm = TRUE) / 24,
    .by = c(patch:subfolder, date)
  ) %>%
  
  # Add days without photos:
  
  group_by(
    patch,
    trailcam,
    subfolder
  ) %>%
  complete(
    date = full_seq(date, 1),
    fill = list(hourly_predator_activity = 0)
  ) %>%
  ungroup()
