# Map Tab
tabPanel(
  "Map",
  icon = icon("map"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      # Map Controls
      sliderInput(
        "map_zoom",
        "Map Zoom Level:",
        min = 10,
        max = 18,
        value = 13,
        step = 1
      ),
      actionButton("reset_map", "Reset View", icon = icon("globe")),
      
      # Route planning
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
      
      # Map Layers
      h4("Map Layers"),
      awesomeCheckboxGroup(
        "transport_lines",
        label = "Transport Lines:",
        choices = c(
          "Train Lines" = "train_lines",
          "Tram Lines" = "tram_lines", 
          "Bus Lines" = "bus_lines",
          "SkyBus" = "skybus_lines"
        ),
        selected = character(0),
        inline = FALSE
      ),
      awesomeCheckboxGroup(
        "transport_stops", 
        label = "Transport Stops:",
        choices = c(
          "Train Stations" = "train_stops",
          "Tram Stops" = "tram_stops",
          "Bus Stops" = "bus_stops"
        ),
        selected = character(0),
        inline = FALSE
      ),
      
      div(style = "text-align: center; margin-top: 15px;",
          actionButton("toggle_lines", "Toggle All Lines", class = "btn-xs", style = "margin-right: 5px;"),
          actionButton("toggle_stops", "Toggle All Stops", class = "btn-xs")
      )
    ),
    
    mainPanel(
      width = 9,
      fluidRow(
        column(
          width = 8,
          box(
            width = 12,
            title = "Transport Network & Directions",
            status = "primary",
            solidHeader = TRUE,
            leafletOutput("transport_map", height = "600px")
          )
        ),
        column(
          width = 4,
          box(
            width = 12,
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
    )
  )
)