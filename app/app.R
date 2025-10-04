# Main Shiny app file
library(shiny)

# Source all components
source("global.R")
source("ui.R")
source("server.R")

# Run the application
shinyApp(ui = ui, server = server)