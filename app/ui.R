# Dashboard UI
ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(
    title = "GEOM90007 Assignment 3",
    titleWidth = 300
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      menuItem("Melbourne Map", tabName = "map", icon = icon("map")),
      menuItem("Transport & Directions", tabName = "directions", icon = icon("route"))
    ),
    
    # Simple controls for Map Tab
    conditionalPanel(
      'input.tabs == "map"',
      sliderInput(
        "map_zoom",
        "Map Zoom Level:",
        min = 10,
        max = 18,
        value = 13,
        step = 1
      ),
      actionButton("reset_map", "Reset View", icon = icon("globe"))
    ),
    
    # Simplified controls for Directions Tab
    conditionalPanel(
      'input.tabs == "directions"',
      
      # Route planning inputs
      pickerInput(
        "start_location",
        "Start Location:",
        choices = if(exists("project_data") && !is.null(project_data)) {
          unique(project_data$location)
        } else {
          "Loading..."
        },
        selected = if(exists("project_data") && !is.null(project_data) && 
                      "Flinders Street Station" %in% project_data$location) {
          "Flinders Street Station"
        } else {
          NULL
        },
        options = list(`live-search` = TRUE)
      ),
      pickerInput(
        "end_location", 
        "End Location:",
        choices = if(exists("project_data") && !is.null(project_data)) {
          unique(project_data$location)
        } else {
          "Loading..."
        },
        selected = if(exists("project_data") && !is.null(project_data) && 
                      "Southern Cross Station" %in% project_data$location) {
          "Southern Cross Station"
        } else {
          NULL
        },
        options = list(`live-search` = TRUE)
      ),
      
      radioButtons(
        "travel_mode",
        "Travel Mode:",
        choices = c(
          "Walking" = "walking",
          "Public Transport" = "transit",
          "Cycling" = "cycling"
        ),
        selected = "walking"
      ),
      
      actionButton("calculate_route", "Get Directions", 
                   icon = icon("directions"), 
                   class = "btn-primary"),
      
      hr(),
      
      # FUNCTIONAL LEGEND THAT ACTUALLY WORKS
      h4("Map Layers", style = "margin-top: 20px;"),
      
      # Transport Lines Toggles
      h5("Transport Lines:", style = "margin-top: 15px; margin-bottom: 10px;"),
      awesomeCheckboxGroup(
        "transport_lines",
        label = NULL,
        choices = c(
          "Train Lines" = "train_lines",
          "Tram Lines" = "tram_lines", 
          "Bus Lines" = "bus_lines",
          "SkyBus" = "skybus_lines"
        ),
        selected = character(0),  # CHANGE FROM c("train_lines", "tram_lines", "bus_lines", "skybus_lines") TO character(0)
        inline = FALSE
      ),
      
      # Transport Stops Toggles - CHANGE THIS:
      awesomeCheckboxGroup(
        "transport_stops", 
        label = NULL,
        choices = c(
          "Train Stations" = "train_stops",
          "Tram Stops" = "tram_stops",
          "Bus Stops" = "bus_stops"
        ),
        selected = character(0),  # CHANGE FROM c("train_stops", "tram_stops", "bus_stops") TO character(0)
        inline = FALSE
      ),
      
      # Quick toggle buttons
      div(style = "text-align: center; margin-top: 15px;",
          actionButton("toggle_lines", "Toggle All Lines", class = "btn-xs", style = "margin-right: 5px;"),
          actionButton("toggle_stops", "Toggle All Stops", class = "btn-xs")
      ),
      
      # Error message display
      uiOutput("data_status_ui")
    )
  ),
  
  # Main body
  dashboardBody(
    useShinyjs(),
    shinyWidgets::useShinydashboard(),
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "style.css"),
      tags$style(HTML("
        /* Better checkbox styling */
        .checkbox {
          margin-bottom: 8px;
        }
        .checkbox label {
          font-size: 13px;
          display: flex;
          align-items: center;
        }
      "))
    ),
    
    tabItems(
      # Simple Map Tab
      tabItem(
        tabName = "map",
        fluidRow(
          box(
            width = 12,
            title = "Melbourne Map",
            status = "primary",
            solidHeader = TRUE,
            leafletOutput("simple_map", height = "600px")
          )
        ),
        fluidRow(
          valueBoxOutput("melbourne_info", width = 4),
          valueBoxOutput("city_center", width = 4),
          valueBoxOutput("map_status", width = 4)
        )
      ),
      
      # Comprehensive Transport & Directions Tab
      tabItem(
        tabName = "directions",
        fluidRow(
          box(
            width = 8,
            title = "Transport Network & Directions",
            status = "primary",
            solidHeader = TRUE,
            leafletOutput("transport_map", height = "600px")
          ),
          box(
            width = 4,
            title = "Route Information",
            status = "info",
            solidHeader = TRUE,
            htmlOutput("route_info"),
            br(),
            hr(),
            h4("Transport Statistics"),
            valueBoxOutput("total_stops", width = 12),
            valueBoxOutput("train_stops", width = 12),
            valueBoxOutput("tram_stops", width = 12),
            valueBoxOutput("bus_stops", width = 12)
          )
        )
      )
    ),
    
    # Loading screen
    uiOutput("loading_screen")
  )
)