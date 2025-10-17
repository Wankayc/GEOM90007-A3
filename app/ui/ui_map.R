# Map Tab
tabPanel(
  "Map",
  icon = icon("map"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      # Route planning
      h4("Route Planning"),
      pickerInput(
        "start_location",
        "Start Location:",
        choices = "Loading...",
        options = list(`live-search` = TRUE)
      ),
      pickerInput(
        "end_location", 
        "End Location:",
        choices = "Loading...",
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
      
      # Places filter
      h4("Places Filter"),
      sliderInput("opening_hours", "Filter by Opening Time:",
                  min = 0, max = 24, value = c(9, 17),
                  step = 1, post = ":00"),
      
      awesomeCheckboxGroup(
        "place_types",
        "Place Types:",
        choices = c(
          "Cafes" = "cafe",
          "Restaurants" = "restaurant", 
          "Parks" = "park",
          "Public Toilets" = "toilet",
          "BBQ Spots" = "bbq",
          "Bars" = "bar",
          "Shopping" = "shopping"
        ),
        selected = c("cafe", "restaurant", "park", "toilet", "bbq", "bar", "shopping"),
        status = "primary"
      ),
      
      actionButton("toggle_places", "Toggle All Places", class = "btn-xs btn-info")
    ),
    
    mainPanel(
      width = 9,
      box(
        width = 12,
        title = "Interactive Map & Directions",
        status = "primary",
        solidHeader = TRUE,
        leafletOutput("transport_map", height = "700px")
      )
    )
  )
)