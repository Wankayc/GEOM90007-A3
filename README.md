# GEOM90007 Assignment 3

## Installation & Running
- Download or clone this repository

- Open RStudio and set your working directory to the project folder

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
The app will automatically:

- Install any missing required packages

- Load transport data from GeoJSON files

- Process data within specified radii of Melbourne CBD

---

## Project Structure

- Core App Files (in app/ folder)

- ui.R - User interface and layout

- server.R - App logic and functionality

- global.R - Data loading and preprocessing

- www/style.css - Custom styling

- Support Files (in R/ folder)

- setup.R - Package installation and loading

- data_import.R - Data loading functions

- data_processing.R - Data transformation functions

- functions.R - Reusable utility functions

- Data Files (in data/ folder)

raw/Public Transport Lines.geojson - [Route data](https://opendata.transport.vic.gov.au/dataset/6d36dfd9-8693-4552-8a03-05eb29a391fd/resource/52e5173e-b5d5-4b65-9b98-89f225fc529c/download/public_transport_lines.geojson)

raw/Public Transport Stops.geojson - [Stop location data](https://opendata.transport.vic.gov.au/dataset/6d36dfd9-8693-4552-8a03-05eb29a391fd/resource/afa7b823-0c8b-47a1-bc40-ada565f684c7/download/public_transport_stops.geojson)
