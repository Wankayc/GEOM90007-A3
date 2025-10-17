# Main Shiny app file

# Source the global configuration
source("global.R")

# Source the main UI and server files
source("ui/ui_main.R")
source("server/server_main.R")

# Run the application
shinyApp(ui, server, options=list(launch.browser=TRUE))