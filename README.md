# GEOM90007 Assignment 3 - Melbourne Explorer

## Installation & Running

**Clone the repository**
- git clone https://github.com/Wankayc/GEOM90007-A3.git

- Extract the entire zip folder to your desired location

---

**Run the app using one of these methods:**

Method 1: From RStudio Console
```
shiny::runApp("app")
```
Method 2: From R Script

```
setwd("path/to/your/project")
shiny::runApp("app")
```

Install these packages before running the application:

   ```
   install.packages(c(
     "shiny", "shinythemes", "shinyjs", "leaflet", "shinyWidgets",
     "shinydashboard", "dplyr", "ggplot2", "sf", "here", "bslib", 
     "sortable", "lubridate", "tidyr", "readr", "stringr", "later",
     "googleway", "ggiraph", "tibble", "purrr"
   ))

```

---

## Project Structure

   After extraction, your folder should contain:
```   
root/
|- app/ : Main Shiny application files
|- data/ : All application datasets
|- README.txt : This file
```
---

## Datasets

Cafe, Restaurant, Bistro seats (2023): https://data.melbourne.vic.gov.au/explore/dataset/cafes-and-restaurants-with-seating-capacity/information

Landmarks and places of interest, including schools, theatres, health services, sports facilities, places of worship, galleries and museums (2023): https://data.melbourne.vic.gov.au/explore/dataset/landmarks-and-places-of-interest-including-schools-theatres-health-services-spor

Public barbecues (2023): https://data.melbourne.vic.gov.au/explore/dataset/public-barbecues/information/

Weather and air data retrieveed from: https://data.gov.au/data/dataset/microclimate-sensors-data and https://www.bom.gov.au/jsp/ncc/cdio/calendar/climate-calendar?stn_num=086338&month=10&day=14
