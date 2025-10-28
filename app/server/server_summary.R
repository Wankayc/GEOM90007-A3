summary_server <- function(input, output, session, user_behavior, weather_module = NULL) {
  
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
    # Try to get dates from weather module first
    if (!is.null(weather_module)) {
      weather_dates <- weather_module$selected_dates()
      if (length(weather_dates) > 0) {
        return(weather_dates)
      }
    }
    
    # Fallback: try session userData
    if (!is.null(session$userData$weather_dates)) {
      return(session$userData$weather_dates)
    }
    
    # Default: use current week (today + next 6 days)
    today <- Sys.Date()
    seq(today, today + 6, by = "day")
  })
  
  # Simple wrapper that uses shared function
  get_weather_for_date_safe <- function(date) {
    tryCatch({
      get_weather_for_date(date, weather_data())
    }, error = function(e) {
      list(emoji = "⛅️", label = "Cloudy", temp_min = NA, temp_max = NA, rain = NA)
    })
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
            weather <- get_weather_for_date_safe(date)  # Use safe wrapper
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
  

  get_activities_for_date <- function(date, user_behavior) {
    activities <- list()
    
    tryCatch({
      day_of_week <- weekdays(date)
      weather <- get_weather_for_date_safe(date)
      
      # personality data retrieval
      personality_info <- personality_data()
      personality <- if (!is.null(personality_info) && !is.null(personality_info$type)) {
        personality_info$type
      } else {
        "Melbourne Explorer"
      }
      
      # Check if user has any clicks at all
      total_clicks <- 0
      if (!is.null(user_behavior) && !is.null(user_behavior$category_clicks)) {
        total_clicks <- sum(unlist(user_behavior$category_clicks), na.rm = TRUE)
      }
      
      # If user has no clicks, use random recommendations from theme_data
      if (total_clicks == 0) {
        cat("No user data - using random recommendations for", as.character(date), "\n")
        
        dates <- selected_dates()
        if (length(dates) > 0) {
          date_index <- which(dates == date)
          
          # Use actual theme_data
          all_places <- theme_data %>%
            distinct(Name, .keep_all = TRUE)
          
          # Apply weather filtering
          rain_amount <- if (!is.null(weather$rain) && !is.na(weather$rain)) weather$rain else 0
          temp_max <- if (!is.null(weather$tmax) && !is.na(weather$tmax)) weather$tmax else 20
          
          if (rain_amount >= 1) {
            filtered_places <- all_places %>%
              filter(Theme %in% c("Arts & Culture", "Shopping", "Food & Drink", "Public Services", "Attractions"))
          } else if (temp_max >= 25) {
            filtered_places <- all_places %>%
              filter(Theme %in% c("Parks & Gardens", "Attractions", "Leisure", "Food & Drink"))
          } else {
            filtered_places <- all_places
          }
          
          if (nrow(filtered_places) == 0) {
            filtered_places <- all_places
          }
          
          # Simple deterministic sampling based on date index
          sample_size <- min(3, nrow(filtered_places))
          start_idx <- ((date_index - 1) * sample_size) %% nrow(filtered_places) + 1
          end_idx <- min(start_idx + sample_size - 1, nrow(filtered_places))
          
          suggested_places <- filtered_places %>%
            slice(start_idx:end_idx)
          
          # Convert to activities
          if (nrow(suggested_places) > 0) {
            activities <- lapply(1:nrow(suggested_places), function(i) {
              place <- suggested_places[i, ]
              
              place_name <- if (!is.null(place$Name)) place$Name else "Melbourne Activity"
              place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
              place_rating <- if (!is.null(place$Google_Rating)) place$Google_Rating else NA
              
              time_slots <- c("9:00 AM - 11:00 AM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
              time_slot <- time_slots[min(i, length(time_slots))]
              
              location_desc <- place_subtheme
              if (!is.na(place_rating)) {
                location_desc <- paste(location_desc, "•", paste("⭐", place_rating))
              }
              
              list(
                name = place_name,
                time = time_slot,
                location = location_desc
              )
            })
          }
        }
        
      } else {
        # USER HAS DATA - Personality-based recommendations USING ACTUAL THEME_DATA
        cat("Using personality-based recommendations for", as.character(date), "\n")
        cat("Personality detected:", personality, "\n")
        
        # Use actual theme_data instead of hardcoded values
        all_places <- theme_data %>%
          distinct(Name, .keep_all = TRUE)
        
        # Filter by personality type with date-based variation
        date_index <- which(selected_dates() == date)
        
        if (personality == "Food Lover") {
          cat("Selecting food activities for Food Lover\n")
          food_places <- all_places %>%
            filter(Theme == "Food & Drink") %>%
            arrange(Name)  # Sort for consistent ordering
          
          # Use date index to select different food places each day
          start_idx <- ((date_index - 1) * 3) %% nrow(food_places) + 1
          end_idx <- min(start_idx + 2, nrow(food_places))
          selected_places <- food_places %>%
            slice(start_idx:end_idx)
          
        } else if (personality == "Nature Enthusiast") {
          cat("Selecting outdoor activities for Nature Enthusiast\n")
          nature_places <- all_places %>%
            filter(Theme %in% c("Parks & Gardens", "Attractions", "Leisure")) %>%
            arrange(Name)
          
          start_idx <- ((date_index - 1) * 3) %% nrow(nature_places) + 1
          end_idx <- min(start_idx + 2, nrow(nature_places))
          selected_places <- nature_places %>%
            slice(start_idx:end_idx)
          
        } else if (personality == "Culture Connoisseur") {
          cat("Selecting culture activities for Culture Connoisseur\n")
          culture_places <- all_places %>%
            filter(Theme %in% c("Arts & Culture", "Heritage", "Public Services")) %>%
            arrange(Name)
          
          start_idx <- ((date_index - 1) * 3) %% nrow(culture_places) + 1
          end_idx <- min(start_idx + 2, nrow(culture_places))
          selected_places <- culture_places %>%
            slice(start_idx:end_idx)
          
        } else if (personality == "Urban Adventurer") {
          cat("Selecting mixed activities for Urban Adventurer\n")
          urban_places <- all_places %>%
            filter(Theme %in% c("Shopping", "Transport", "Attractions", "Food & Drink")) %>%
            arrange(Name)
          
          start_idx <- ((date_index - 1) * 3) %% nrow(urban_places) + 1
          end_idx <- min(start_idx + 2, nrow(urban_places))
          selected_places <- urban_places %>%
            slice(start_idx:end_idx)
          
        } else {
          # Default for any other personality - mix of everything
          cat("Selecting default activities for", personality, "\n")
          default_places <- all_places %>%
            filter(Theme %in% c("Arts & Culture", "Attractions", "Food & Drink")) %>%
            arrange(Name)
          
          start_idx <- ((date_index - 1) * 3) %% nrow(default_places) + 1
          end_idx <- min(start_idx + 2, nrow(default_places))
          selected_places <- default_places %>%
            slice(start_idx:end_idx)
        }
        
        # Convert selected places to activities
        if (nrow(selected_places) > 0) {
          activities <- lapply(1:nrow(selected_places), function(i) {
            place <- selected_places[i, ]
            
            place_name <- if (!is.null(place$Name)) place$Name else "Melbourne Activity"
            place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
            place_rating <- if (!is.null(place$Google_Rating)) place$Google_Rating else NA
            
            # Create appropriate time slots based on place type
            if (!is.null(place$Theme) && place$Theme == "Food & Drink") {
              if (grepl("cafe|coffee", place_subtheme, ignore.case = TRUE)) {
                time_slot <- if (i == 1) "9:00 AM - 11:00 AM" else "3:00 PM - 5:00 PM"
              } else {
                time_slot <- if (i == 1) "12:00 PM - 2:00 PM" else "6:00 PM - 8:00 PM"
              }
            } else if (!is.null(place$Theme) && place$Theme == "Parks & Gardens") {
              time_slot <- if (i == 1) "10:00 AM - 12:00 PM" else "2:00 PM - 4:00 PM"
            } else {
              time_slots <- c("10:00 AM - 12:00 PM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
              time_slot <- time_slots[min(i, length(time_slots))]
            }
            
            # Create location description
            location_desc <- place_subtheme
            if (!is.na(place_rating)) {
              location_desc <- paste(location_desc, "•", paste("⭐", place_rating))
            }
            
            list(
              name = place_name,
              time = time_slot,
              location = location_desc
            )
          })
        }
        
        # Weather adjustments using actual data
        rain_amount <- if (!is.null(weather$rain) && !is.na(weather$rain)) weather$rain else 0
        temp_max <- if (!is.null(weather$tmax) && !is.na(weather$tmax)) weather$tmax else 20
        
        # Add weather-appropriate activities if we have fewer than 3
        if (length(activities) < 3) {
          if (rain_amount >= 1) {
            # Add indoor activity for rain
            indoor_places <- all_places %>%
              filter(Theme %in% c("Arts & Culture", "Shopping", "Public Services")) %>%
              filter(!Name %in% sapply(activities, function(x) x$name)) %>%
              slice(1)
            
            if (nrow(indoor_places) > 0) {
              activities <- c(activities, list(
                list(
                  name = indoor_places$Name[1],
                  time = "1:00 PM - 3:00 PM",
                  location = paste(indoor_places$Sub_Theme[1], ifelse(!is.na(indoor_places$Google_Rating[1]), 
                                                                      paste("• ⭐", indoor_places$Google_Rating[1]), ""))
                )
              ))
            }
          } else if (temp_max >= 25 && length(activities) < 3) {
            # Add outdoor activity for hot weather
            outdoor_places <- all_places %>%
              filter(Theme %in% c("Parks & Gardens", "Leisure")) %>%
              filter(!Name %in% sapply(activities, function(x) x$name)) %>%
              slice(1)
            
            if (nrow(outdoor_places) > 0) {
              activities <- c(activities, list(
                list(
                  name = outdoor_places$Name[1],
                  time = "4:00 PM - 6:00 PM",
                  location = paste(outdoor_places$Sub_Theme[1], ifelse(!is.na(outdoor_places$Google_Rating[1]), 
                                                                       paste("• ⭐", outdoor_places$Google_Rating[1]), ""))
                )
              ))
            }
          }
        }
        
        # Day-specific activities using actual data
        if (!is.null(day_of_week) && length(activities) < 3) {
          if (day_of_week == "Saturday") {
            market_places <- all_places %>%
              filter(grepl("market|Market", Name) | grepl("market|Market", Sub_Theme)) %>%
              slice(1)
            
            if (nrow(market_places) > 0) {
              activities <- c(activities, list(
                list(
                  name = market_places$Name[1],
                  time = "9:00 AM - 1:00 PM",
                  location = paste("Saturday Market •", market_places$Sub_Theme[1])
                )
              ))
            }
          } else if (day_of_week == "Sunday") {
            sunday_places <- all_places %>%
              filter(Theme %in% c("Arts & Culture", "Shopping") | 
                       grepl("art|craft|Art|Craft", Sub_Theme)) %>%
              slice(1)
            
            if (nrow(sunday_places) > 0) {
              activities <- c(activities, list(
                list(
                  name = sunday_places$Name[1],
                  time = "10:00 AM - 4:00 PM",
                  location = paste("Sunday Activity •", sunday_places$Sub_Theme[1])
                )
              ))
            }
          }
        }
        
        # Limit to 3 activities
        if (length(activities) > 3) {
          activities <- activities[1:3]
        }
        
        cat("Final activities count:", length(activities), "\n")
      }
      
      return(activities)
      
    }, error = function(e) {
      cat("ERROR in get_activities_for_date:", e$message, "\n")
      cat("Date:", as.character(date), "Personality:", personality, "\n")
      # Return guaranteed fallback activities from theme_data
      fallback_places <- theme_data %>%
        distinct(Name, .keep_all = TRUE) %>%
        slice(1:2)
      
      fallback_activities <- lapply(1:min(2, nrow(fallback_places)), function(i) {
        list(
          name = fallback_places$Name[i],
          time = "10:00 AM - 5:00 PM",
          location = fallback_places$Sub_Theme[i]
        )
      })
      
      return(fallback_activities)
    })
  }
  
  # Personality data with better validation
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