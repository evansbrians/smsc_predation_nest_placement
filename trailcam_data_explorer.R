# Dashboard script for playing with predator camera data

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

