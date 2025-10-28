summary_server <- function(input, output, session, user_behavior) {
  
  # Get weather data from the global environment or module
  weather_data <- reactive({
    if (exists("calendar_feed")) {
      calendar_feed
    } else {
      # Fallback data structure
      data.frame(
        date = as.Date(character()),
        tmin = numeric(),
        tmax = numeric(),
        rain = numeric(),
        pm25_mean = numeric(),
        averagewindspeed_bom = numeric(),
        sun = numeric(),
        pm10_mean = numeric(),
        stringsAsFactors = FALSE
      )
    }
  })
  
  # Get selected dates from weather module - default to current week if none selected
  selected_dates <- reactive({
    # Try to get dates from weather module
    if (!is.null(session$userData$weather_dates)) {
      return(session$userData$weather_dates)
    }
    
    # Default: use current week (today + next 6 days)
    today <- Sys.Date()
    seq(today, today + 6, by = "day")
  })
  
  # Weather icon function (same as in weather module)
  weather_emoji <- function(rain, tmax){
    if (!is.na(rain) && rain >= 1) return("🌧️")
    if (!is.na(tmax) && tmax >= 25) return("☀️")
    "⛅️"
  }
  
  weather_label <- function(rain, tmax){
    if (!is.na(rain) && rain >= 1) return("Rainy")
    if (!is.na(tmax) && tmax >= 25) return("Sunny")
    "Cloudy"
  }
  
  # Get weather data for specific date
  get_weather_for_date <- function(date) {
    weather_df <- weather_data()
    weather_row <- weather_df[weather_df$date == date, ]
    if (nrow(weather_row) == 0) {
      return(list(
        emoji = "⛅️",
        label = "Cloudy",
        temp_min = NA,
        temp_max = NA,
        rain = NA
      ))
    }
    
    list(
      emoji = weather_emoji(weather_row$rain, weather_row$tmax),
      label = weather_label(weather_row$rain, weather_row$tmax),
      temp_min = weather_row$tmin,
      temp_max = weather_row$tmax,
      rain = weather_row$rain
    )
  }
  
  # FIXED: Create itinerary table with proper error handling
  output$itinerary_table <- renderUI({
    dates <- selected_dates()
    
    # Validate we have dates
    if (length(dates) == 0) {
      return(div("No dates selected", style = "color: #999; font-style: italic;"))
    }
    
    tags$table(
      class = "itinerary-table",
      tags$thead(
        tags$tr(
          lapply(dates, function(date) {
            weather <- get_weather_for_date(date)
            tags$th(
              div(class = "weather-icon", weather$emoji),
              div(class = "day-date", format(date, "%A")),
              div(format(date, "%d %b"))
            )
          })
        )
      ),
      tags$tbody(
        tags$tr(
          lapply(dates, function(date) {
            # FIXED: Safe activity retrieval with tryCatch
            activities <- tryCatch({
              get_activities_for_date(date, user_behavior)
            }, error = function(e) {
              # Return empty list if there's any error
              list()
            })
            
            tags$td(
              if (length(activities) > 0) {
                lapply(activities, function(activity) {
                  # FIXED: Validate activity structure
                  if (!is.null(activity$name) && !is.null(activity$time) && !is.null(activity$location)) {
                    div(
                      class = "event-title",
                      activity$name,
                      div(class = "event-time", activity$time),
                      div(class = "event-location", activity$location)
                    )
                  }
                })
              } else {
                div(
                  class = "no-activities",
                  "No activities planned",
                  style = "color: #999; font-style: italic;"
                )
              }
            )
          })
        )
      )
    )
  })
  
  # FIXED: Enhanced helper function with proper error handling
  get_activities_for_date <- function(date, user_behavior) {
    # Always return at least an empty list as fallback
    activities <- list()
    
    tryCatch({
      day_of_week <- weekdays(date)
      weather <- get_weather_for_date(date)
      
      # FIXED: Safe personality data retrieval
      personality_info <- personality_data()
      personality <- if (!is.null(personality_info) && !is.null(personality_info$type)) {
        personality_info$type
      } else {
        "Melbourne Explorer"  # Default fallback
      }
      
      # Base activities that work for any weather
      base_activities <- list(
        list(name = "Melbourne Museum", time = "10:00 AM - 5:00 PM", location = "Cultural & Natural History", type = "indoor"),
        list(name = "State Library Victoria", time = "10:00 AM - 6:00 PM", location = "Historic Library & Exhibitions", type = "indoor"),
        list(name = "National Gallery of Victoria", time = "10:00 AM - 5:00 PM", location = "Art Museum", type = "indoor"),
        list(name = "Queen Victoria Market", time = "9:00 AM - 3:00 PM", location = "Local Market & Food Stalls", type = "indoor"),
        list(name = "Royal Botanic Gardens", time = "7:30 AM - Sunset", location = "Botanical Gardens", type = "outdoor"),
        list(name = "Fitzroy Gardens", time = "All Day", location = "Historic Gardens", type = "outdoor"),
        list(name = "Victoria Park", time = "All Day", location = "Barbecue & Picnic Spot", type = "outdoor"),
        list(name = "Brunetti Flinders Lane", time = "7:00 AM - 10:00 PM", location = "Italian Cafe & Pastries", type = "food"),
        list(name = "Italian Restaurant", time = "6:00 PM", location = "Fine Dining Experience", type = "food"),
        list(name = "Lygon Street Restaurants", time = "12:00 PM - 10:00 PM", location = "Little Italy", type = "food")
      )
      
      # FIXED: Safe activity selection
      if (personality == "Food Lover") {
        food_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "food")]
        if (length(food_activities) > 0) {
          activities <- c(activities, food_activities[1])
        }
      } else if (personality == "Nature Enthusiast") {
        outdoor_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "outdoor")]
        if (length(outdoor_activities) > 0) {
          activities <- c(activities, outdoor_activities[1])
        }
      } else if (personality == "Culture Connoisseur") {
        indoor_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "indoor")]
        if (length(indoor_activities) > 0) {
          activities <- c(activities, indoor_activities[1])
        }
      } else {
        # Default: indoor activity
        indoor_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "indoor")]
        if (length(indoor_activities) > 0) {
          activities <- c(activities, indoor_activities[1])
        }
      }
      
      # FIXED: Safe weather adjustments
      if (!is.na(weather$rain) && weather$rain >= 1) {
        # Rainy day - add indoor activity
        indoor_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "indoor")]
        if (length(indoor_activities) > 0 && length(activities) < 3) {
          for (activity in indoor_activities) {
            if (!any(sapply(activities, function(x) !is.null(x$name) && x$name == activity$name))) {
              activities <- c(activities, list(activity))
              break
            }
          }
        }
      } else if (!is.na(weather$tmax) && weather$tmax >= 25) {
        # Hot day - add outdoor activity
        outdoor_activities <- base_activities[sapply(base_activities, function(x) !is.null(x$type) && x$type == "outdoor")]
        if (length(outdoor_activities) > 0 && length(activities) < 3) {
          for (activity in outdoor_activities) {
            if (!any(sapply(activities, function(x) !is.null(x$name) && x$name == activity$name))) {
              activities <- c(activities, list(activity))
              break
            }
          }
        }
      }
      
      # FIXED: Safe day-specific activities
      if (day_of_week == "Saturday" && length(activities) < 3) {
        activities <- c(activities, list(
          list(name = "Queen Victoria Market", time = "6:00 AM - 3:00 PM", location = "Saturday Market", type = "market")
        ))
      } else if (day_of_week == "Sunday" && length(activities) < 3) {
        activities <- c(activities, list(
          list(name = "Southbank Sunday Market", time = "10:00 AM - 4:00 PM", location = "Arts & Crafts Market", type = "market")
        ))
      }
      
      # Remove type field before returning
      clean_activities <- lapply(activities, function(activity) {
        if (!is.null(activity)) {
          activity[c("name", "time", "location")]
        }
      })
      
      # Filter out any NULL activities and limit to 3
      clean_activities <- Filter(Negate(is.null), clean_activities)
      if (length(clean_activities) > 3) {
        clean_activities <- clean_activities[1:3]
      }
      
      return(clean_activities)
      
    }, error = function(e) {
      # Return empty list if anything goes wrong
      return(list())
    })
  }
  
  # FIXED: Personality data with better validation
  personality_data <- reactive({
    tryCatch({
      # Validate user_behavior structure
      if (is.null(user_behavior) || is.null(user_behavior$category_clicks)) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("binoculars"),
          color = "#036B55", 
          description = "Start exploring Melbourne!"
        ))
      }
      
      # Get the current click counts safely
      clicks <- list(
        accommodation = user_behavior$category_clicks$accommodation %||% 0,
        transport = user_behavior$category_clicks$transport %||% 0,
        attractions = user_behavior$category_clicks$attractions %||% 0,
        arts_culture = user_behavior$category_clicks$arts_culture %||% 0,
        food_drink = user_behavior$category_clicks$food_drink %||% 0,
        heritage = user_behavior$category_clicks$heritage %||% 0,
        leisure = user_behavior$category_clicks$leisure %||% 0,
        public_service = user_behavior$category_clicks$public_service %||% 0,
        shopping = user_behavior$category_clicks$shopping %||% 0,
        health_services = user_behavior$category_clicks$health_services %||% 0
      )
      
      # Calculate scores
      scores <- list(
        foodie = clicks$food_drink * 2,
        culture_seeker = clicks$arts_culture + clicks$heritage,
        nature_lover = clicks$attractions + clicks$leisure,
        urban_explorer = clicks$transport + clicks$shopping,
        wellness_enthusiast = clicks$health_services + clicks$leisure,
        practical_traveler = clicks$accommodation + clicks$public_service
      )
      
      # Safe max score calculation
      score_values <- unlist(scores)
      if (length(score_values) == 0 || all(is.na(score_values))) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("compass"),
          color = "#036B55",
          description = "You're exploring everything! Click more to reveal your favorite side of Melbourne."
        ))
      }
      
      max_score <- max(score_values, na.rm = TRUE)
      dominant <- names(scores)[which.max(score_values)]
      
      # Personality mapping
      total_clicks <- sum(unlist(clicks))
      if (total_clicks == 0) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("binoculars"),
          color = "#036B55", 
          description = "Start clicking categories to discover your Melbourne personality!"
        ))
      } else if (max_score == 0 || is.na(max_score) || max_score < 1) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("compass"),
          color = "#036B55",
          description = "You're exploring everything! Click more to reveal your favorite side of Melbourne."
        ))
      } else if (dominant == "foodie") {
        list(type = "Food Lover", icon = icon("coffee"), color = "#6f4e37", description = "You're always searching for the next great meal or perfect brew!")
      } else if (dominant == "culture_seeker") {
        list(type = "Culture Connoisseur", icon = icon("landmark"), color = "#4B0082", description = "You appreciate art, history, and cultural experiences!")
      } else if (dominant == "nature_lover") {
        list(type = "Nature Enthusiast", icon = icon("tree"), color = "#228B22", description = "You love exploring parks, gardens, and outdoor spaces!")
      } else if (dominant == "urban_explorer") {
        list(type = "Urban Adventurer", icon = icon("city"), color = "#4169E1", description = "You thrive in the city and love discovering urban gems!")
      } else if (dominant == "wellness_enthusiast") {
        list(type = "Wellness Seeker", icon = icon("heart"), color = "#FF6B6B", description = "You prioritize health and relaxation in your travels!")
      } else if (dominant == "practical_traveler") {
        list(type = "Practical Traveler", icon = icon("map-signs"), color = "#FF8C00", description = "You're organized and plan your trips carefully!")
      } else {
        list(
          type = "Melbourne Adventurer",
          icon = icon("star"),
          color = "#036B55",
          description = "You're discovering the many faces of Melbourne!"
        )
      }
    }, error = function(e) {
      # Fallback if anything goes wrong
      return(list(
        type = "Melbourne Explorer",
        icon = icon("binoculars"),
        color = "#036B55",
        description = "Start exploring Melbourne!"
      ))
    })
  })
  
  # Rest of your outputs remain the same...
  output$personality_title <- renderText({
    data <- personality_data()
    if (is.null(data)) return("You are a Melbourne Explorer!")
    paste("Based on your searches you are a", data$type, "!")
  })
  
  output$personality_icon <- renderUI({
    data <- personality_data()
    if (is.null(data)) return(div(icon("binoculars"), style = "color: #036B55; font-size: 2.5em;"))
    div(style = paste0("color:", data$color, "; font-size: 2.5em;"),
        data$icon)
  })
  
  output$personality_description <- renderText({
    data <- personality_data()
    if (is.null(data)) return("Start clicking categories to discover your Melbourne personality!")
    data$description
  })
  
  # Placeholder handlers
  observeEvent(input$export_pdf, {
    showNotification("PDF export will be implemented soon!", type = "message")
  })
  
  observeEvent(input$prev_image, {
    showNotification("Previous image - carousel to be implemented")
  })
  
  observeEvent(input$next_image, {
    showNotification("Next image - carousel to be implemented") 
  })
}