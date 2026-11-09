# smsc_predation_nest_placement

Predation and nest placement analysis using data from the SMSC nest study.

## Contents

- `data/nest_study.sqlite`: snapshot of the nest study database (copied from
  `nest_study/data/nest_study.sqlite` on 2026-11-09; the `api_token` table was
  emptied).
- `scripts/read_nest_camera_data.R`: reads nest locations, predator camera
  locations, and camera maintenance events from the database.

## Updating the database

This repository holds a copy of the database, not a link to it. To refresh,
copy `nest_study/data/nest_study.sqlite` over `data/nest_study.sqlite`.
