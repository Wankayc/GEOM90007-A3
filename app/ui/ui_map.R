# Map Tab - Advanced Google Maps with Places & Autocomplete
tabPanel(
  "Map",
  icon = icon("map"),
  
  # Custom CSS
  tags$head(tags$style(
    HTML('
      #google_map_wrapper { 
        height: calc(100vh - 140px); 
        position: relative; 
      }
      
      /* Map controls container */
      #google_map_wrapper .map-controls {
        position: absolute;
        left: 16px;
        bottom: 16px;
        display: flex;
        gap: 40px;
        align-items: flex-start;
        pointer-events: none;
        width: calc(100% - 32px);
      }
      
      /* Control cards */
      #google_map_wrapper .map-controls .control-card {
        pointer-events: auto;
        background: #ffffff;
        border-radius: 10px;
        padding: 12px 14px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
      }
      
      /* Travel Modes card - fixed width */
      #google_map_wrapper .map-controls .control-card:first-child {
        min-width: 260px;
        max-width: 280px;
        flex-shrink: 0;
      }
      
      /* Operating Hours card - takes remaining space and aligns right */
      #google_map_wrapper .map-controls .control-card:last-child {
        flex: 1;
        min-width: 340px;
        max-width: 480px;
        margin-left: auto;
      }
      
      /* Responsive design for small devices */
      @media (max-width: 1100px) {
        #google_map_wrapper .map-controls {
          flex-wrap: wrap;
          right: 16px;
          left: 16px;
        }
        #google_map_wrapper .map-controls .control-card:last-child {
          margin-left: 0;
        }
      }
      
      /* Location buttons */
      .btn-location { 
        margin: 5px 2px; 
      }
      
      /* Search input with integrated button */
      .search-input-group {
        position: relative;
        margin-bottom: 10px;
      }
      
      .search-input-group .form-group {
        margin-bottom: 0;
      }
      
      .search-input-group input[type="text"] {
        padding-right: 50px !important;
      }
      
      .search-input-group .search-btn {
        position: absolute;
        right: 1px;
        top: 1px;
        bottom: 1px;
        padding: 0 14px;
        border-radius: 0 3px 3px 0;
        background: #007bff;
        color: white;
        border: none;
        cursor: pointer;
        transition: background-color 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10;
      }
      
      .search-input-group .search-btn:hover {
        background: #0056b3;
      }
      
      .search-input-group .search-btn:active {
        background: #004494;
      }
      
      .search-input-group .search-btn i {
        font-size: 15px;
      }
      
      /* Travel modes checkboxes styling */
      .map-legend #travel_modes {
        margin: 0;
      }
      
      .map-legend #travel_modes .shiny-options-group {
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: 6px;
      }
      
      .map-legend #travel_modes .checkbox {
        margin: 0;
        padding: 8px 12px;
        border-radius: 4px;
        transition: background-color 0.2s;
      }
      
      .map-legend #travel_modes .checkbox:hover {
        background-color: #f5f5f5;
      }
      
      .map-legend #travel_modes label {
        margin: 0;
        display: flex;
        align-items: center;
        cursor: pointer;
        font-size: 13px;
        font-weight: normal;
        width: 100%;
      }
      
      .map-legend #travel_modes input[type="checkbox"] {
        margin: 0;
        flex-shrink: 0;
        cursor: pointer;
        width: 16px;
        height: 16px;
      }
      
      .map-legend #travel_modes label span {
        display: inline-flex;
        align-items: center;
        margin-left: 8px;
        padding-left: 39px;
        position: relative;
      }
      
      .map-legend #travel_modes label span::before {
        content: "";
        position: absolute;
        left: 20px;
        width: 16px;
        height: 16px;
        border-radius: 3px;
        display: inline-block;
      }
      
      /* Color coding for travel modes */
      .map-legend #travel_modes .checkbox:nth-child(1) label span::before {
        background: #2ca02c; /* Driving - green */
      }
      
      .map-legend #travel_modes .checkbox:nth-child(2) label span::before {
        background: #1f77b4; /* Transit - blue */
      }
      
      .map-legend #travel_modes .checkbox:nth-child(3) label span::before {
        background: #ff7f0e; /* Walking - orange */
      }
      
      .map-legend #travel_modes .checkbox:nth-child(4) label span::before {
        background: #9467bd; /* Cycling - purple */
      }
    ')
  )),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      # Category Filter Section
      div(
        style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
        h4(style = "margin: 0;", icon("filter"), " Filter by Category"),
        actionButton(
          "reset_map",
          "Reset Map",
          icon = icon("refresh"),
          class = "btn-warning btn-sm"
        )
      ),
      selectInput(
        "category_filter",
        NULL,
        choices = c(
          "All Categories" = "all",
          "Arts & Culture" = "Arts & Culture",
          "Food & Drink" = "Food & Drink",
          "Leisure" = "Leisure",
          "Shopping" = "Shopping",
          "Transport" = "Transport"
        ),
        selected = "all"
      ),
      uiOutput("location_count"),
      
      # Selected Location Information Card
      uiOutput("selected_location_card"),
      
      hr(),
      
      # Search Places Section
      h4(icon("search"), " Search Places"),
      div(
        class = "search-input-group",
        textInput("search_text", NULL, placeholder = "Coffee, museum, restaurant..."),
        tags$button(
          id = "search_places",
          type = "button",
          class = "search-btn action-button",
          icon("search")
        )
      ),
      div(
        style = "display: flex; gap: 10px; margin-bottom: 10px;",
        actionButton(
          "set_as_start",
          "Set as Start",
          icon = icon("map-pin"),
          class = "btn btn-sm btn-success",
          style = "flex: 1;"
        ),
        actionButton(
          "set_as_end",
          "Set as End",
          icon = icon("flag-checkered"),
          class = "btn btn-sm btn-danger",
          style = "flex: 1;"
        )
      ),
      helpText("Search within 1.5km of start point or map center"),
      
      hr(),
      
      # Route Planning Section
      h4(icon("route"), " Route Planning"),
      
      tags$label("Start Location", class = "control-label"),
      textInput("start_input", NULL, placeholder = "Type address or place name"),
      div(
        style = "display: flex; gap: 5px; margin-bottom: 10px;",
        actionButton("start_my_location", "📍 My Location", 
                     class = "btn btn-sm btn-outline-secondary btn-location")
      ),
      
      tags$label("End Location", class = "control-label"),
      textInput("end_input", NULL, placeholder = "Type address or place name"),
      div(
        style = "display: flex; gap: 5px; margin-bottom: 10px;",
        actionButton("end_my_location", "📍 My Location", 
                     class = "btn btn-sm btn-outline-secondary btn-location")
      ),
      
      actionButton(
        "get_directions",
        "Get Directions",
        class = "btn btn-success btn-block",
        icon = icon("directions")
      )
    ),
    
    mainPanel(
      width = 9,
      
      # Map wrapper with floating controls
      div(
        id = "google_map_wrapper",
        style = "position: relative;",
        google_mapOutput("google_map", height = "80vh"),
        
        # Floating controls row (bottom left)
        div(
          id = "map_controls_row",
          class = "map-controls",
          
          # Travel Modes card
          div(
            class = "control-card",
            style = "min-width: 260px;",
            h5(style = "margin:0 0 10px 0; font-weight: 600;", icon("route"), " Travel Modes"),
            checkboxGroupInput(
              "travel_modes",
              NULL,
              choices = c(
                "Driving"  = "driving",
                "Transit"  = "transit",
                "Walking"  = "walking",
                "Cycling"  = "bicycling"
              ),
              selected = c("driving", "transit")
            ),
            tags$hr(style = "margin: 10px 0;"),
            htmlOutput("route_summary_text")
          ),
          
          # Operating Hours card
          div(
            class = "control-card",
            style = "min-width: 340px;",
            h5(style = "margin:0 0 20px 0; font-weight: 600;", icon("clock"), " Operating Hours"),
            sliderInput(
              "time_filter",
              "Show places open between:",
              min = 0,
              max = 24,
              value = c(7, 23),
              step = 1,
              post = ":00",
              dragRange = TRUE
            ),
            checkboxInput(
              "include_unknown_hours",
              "Include places with unknown hours",
              FALSE
            ),
            helpText("Drag to filter by operating hours. Supports cross-midnight.")
          )
        )
      )
    )
  ),
  
  # JavaScript for Places Autocomplete & Geolocation
  tags$script(
    HTML('
    // Enable Enter key for search
    $(document).on("keypress", "#search_text", function(e) {
      if(e.which === 13) {
        $("#search_places").click();
        return false;
      }
    });

    // Browser Geolocation
    Shiny.addCustomMessageHandler("requestGeolocation", function(config) {
      if (!navigator.geolocation) {
        Shiny.setInputValue(config.callback, {
          error: "Geolocation not supported"
        }, { priority: "event" });
        return;
      }

      navigator.geolocation.getCurrentPosition(
        function(position) {
          Shiny.setInputValue(config.callback, {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
            accuracy: position.coords.accuracy,
            timestamp: Date.now()
          }, { priority: "event" });
        },
        function(error) {
          var errorMsg = "Unknown error";
          switch(error.code) {
            case error.PERMISSION_DENIED:
              errorMsg = "Permission denied. Please allow location access in your browser.";
              break;
            case error.POSITION_UNAVAILABLE:
              errorMsg = "Position unavailable";
              break;
            case error.TIMEOUT:
              errorMsg = "Request timeout";
              break;
          }

          Shiny.setInputValue(config.callback, {
            error: errorMsg
          }, { priority: "event" });
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    });
  ')
  )
)