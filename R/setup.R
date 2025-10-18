# Package installation and loading
required_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "leaflet", "tidyverse", 
  "here", "sf", "readr", "shinycssloaders", "shinyjs")

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load all packages
invisible(lapply(required_packages, require, character.only = TRUE))

cat("Packages loaded successfully!\n")