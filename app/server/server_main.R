server <- function(input, output, session) {
  
  # for carousel redirection to map
  selected_sub_theme_for_map <- reactiveVal("")
  map_refresh_trigger <- reactiveVal(0)
  
  # ------ shared weather functions for weather tab and summary tab ------------
  weather_emoji <- function(rain, tmax) {
    if (!is.na(rain) && rain >= 1) return("🌧️")
    if (!is.na(tmax) && tmax >= 25) return("☀️")
    "⛅️"
  }
  
  weather_label <- function(rain, tmax) {
    if (!is.na(rain) && rain >= 1) return("Rainy") 
    if (!is.na(tmax) && tmax >= 25) return("Sunny")
    "Cloudy"
  }
  
  get_weather_for_date <- function(date, weather_df = calendar_feed) {
    if (nrow(weather_df) == 0) {
      return(list(emoji = "⛅️", label = "Cloudy", temp_min = NA, 
                  temp_max = NA, rain = NA))
    }
    
    weather_row <- weather_df[weather_df$date == date, ]
    if (nrow(weather_row) == 0) {
      return(list(emoji = "⛅️", label = "Cloudy", temp_min = NA, 
                  temp_max = NA, rain = NA))
    }
    
    list(
      emoji = weather_emoji(weather_row$rain, weather_row$tmax),
      label = weather_label(weather_row$rain, weather_row$tmax),
      temp_min = weather_row$tmin,
      temp_max = weather_row$tmax, 
      rain = weather_row$rain
    )
  }
  
  # ----------------------------------------------------------------------------
  
  # Rule-based approach for determining Personality based on categories
  user_behavior <- reactiveValues(
    category_clicks = list(
      accommodation = 0,
      transport = 0,
      attractions = 0,
      arts_culture = 0,
      food_drink = 0,
      heritage = 0,
      leisure = 0,
      public_service = 0,
      shopping = 0,
      health_services = 0
    ),
    current_personality = "Melbourne Explorer",
    first_load = TRUE
  )
  
  # Server logic
  
  source("server/server_weather.R", local = TRUE)
  session$userData$calendar_feed <- calendar_feed
  weather_selected_dates <- reactiveVal(NULL)
  
  # Only show dashboard when data is fully loaded
  observe({
    # Wait for the main dataset to load to avoid data corruption
    req(theme_data)
    
    # loading screen
    runjs('
      document.getElementById("loading-screen").style.display = "none";
      document.getElementById("app-content").style.display = "block";
    ')
  })
  
  # Render Tab UI
  output$weather_ui <- renderUI({
    source("ui/ui_weather.R", local = TRUE) 
    weather_tab_ui()                  
  })
  
  output$map_ui <- renderUI({ 
    source("ui/ui_map.R", local = TRUE)$value 
  })
  
  output$summary_ui <- renderUI({ 
    source("ui/ui_summary.R", local = TRUE)$value 
  })
  
  # Load all server logic
  source("server/server_wordcloud.R", local = TRUE)
  source("server/server_map.R", local = TRUE)
  source("server/server_summary.R", local = TRUE)
  
  weather_module <- trip_tab_server("trip") 
  summary_server(input, output, session, user_behavior, weather_module)
}