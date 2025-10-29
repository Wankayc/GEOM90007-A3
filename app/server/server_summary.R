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
  
  output$has_dates_selected <- reactive({
    dates <- selected_dates()
    length(dates) > 0
  })
  
  # Required for conditionalPanel to work
  outputOptions(output, "has_dates_selected", suspendWhenHidden = FALSE)
  
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
    
    # Default: empty (no dates selected)
    return(as.Date(character()))
  })
  
  # Simple wrapper that uses shared function
  get_weather_for_date_safe <- function(date) {
    tryCatch({
      get_weather_for_date(date, weather_data())
    }, error = function(e) {
      list(emoji = "⛅️", label = "Cloudy", temp_min = NA, temp_max = NA, rain = NA)
    })
  }
  
  # Track clicked day for carousel - FIXED to properly update
  clicked_day <- reactiveVal(1)
  
  # NEW: Track whether we're showing default recommendations
  showing_default_recommendations <- reactiveVal(TRUE)
  
  # Store itinerary data separately to prevent re-rendering
  itinerary_data <- reactiveValues(
    activities = list(),
    last_updated = NULL
  )
  
  # Update itinerary data only when dates or user behavior changes
  observe({
    dates <- selected_dates()
    if (length(dates) > 0) {
      activities_list <- lapply(dates, function(date) {
        tryCatch({
          get_activities_for_date(date, user_behavior)
        }, error = function(e) {
          list()
        })
      })
      itinerary_data$activities <- activities_list
      itinerary_data$last_updated <- Sys.time()
      showing_default_recommendations(FALSE)
    } else {
      showing_default_recommendations(TRUE)
    }
  })
  
  # OPTION 1: Simplified itinerary showing only top activity per day
  output$itinerary_table <- renderUI({
    dates <- selected_dates()
    
    # Validate we have dates
    if (length(dates) == 0) {
      return(
        div(
          class = "empty-itinerary-message",
          h3("📅 Plan Your Melbourne Adventure"),
          p("To get started with your personalized itinerary:"),
          tags$ul(
            tags$li("Visit the Weather tab to select your travel dates"),
            tags$li("Choose activities that interest you in the Explore tab"),
            tags$li("Your recommended itinerary will appear here automatically")
          ),
          p("Once you've selected dates, you'll see daily recommendations that you can click to explore related places!")
        )
      )
    }
    
    # Use stored activities to prevent re-rendering
    activities_list <- itinerary_data$activities
    
    # Check if we have any activities at all
    has_any_activities <- any(sapply(activities_list, length) > 0)
    
    if (!has_any_activities) {
      return(
        div(
          class = "empty-itinerary-message",
          h3("✨ Building Your Personalized Itinerary"),
          p("We're creating your perfect Melbourne experience based on:"),
          tags$ul(
            tags$li("Your selected dates in the Weather tab"),
            tags$li("Your interests from the Explore tab"),
            tags$li("Current weather conditions and local insights")
          ),
          p("Your activities will appear here shortly. Click on any day to discover related places!")
        )
      )
    }
    
    tags$table(
      class = "itinerary-table simplified",
      tags$thead(
        tags$tr(
          lapply(seq_along(dates), function(i) {
            date <- dates[i]
            weather <- get_weather_for_date_safe(date)
            tags$th(
              `data-day` = i,
              class = paste("itinerary-day-header", if(i == clicked_day()) "active-day" else ""),
              style = "cursor: pointer; padding: 15px;",
              div(class = "weather-icon", weather$emoji),
              div(class = "day-date", format(date, "%A")),
              div(class = "date-number", format(date, "%d %b"))
            )
          })
        )
      ),
      tags$tbody(
        tags$tr(
          lapply(seq_along(dates), function(i) {
            date <- dates[i]
            activities <- if (length(activities_list) >= i) activities_list[[i]] else list()
            
            # Take only the first (top) activity
            top_activity <- if (length(activities) > 0) activities[[1]] else NULL
            
            tags$td(
              `data-day` = i,
              class = paste("itinerary-day-cell", if(i == clicked_day()) "active-day" else ""),
              style = "cursor: pointer; padding: 0;",
              if (!is.null(top_activity)) {
                div(
                  class = "top-activity",
                  div(class = "event-title", top_activity$name),
                  div(class = "event-time", top_activity$time),
                  div(class = "event-location", top_activity$location)
                )
              } else {
                div(
                  class = "no-activities",
                  "No activities planned",
                  style = "color: #999; font-style: italic; padding: 40px 20px;"
                )
              }
            )
          })
        )
      )
    )
  })
  
  # Observe day clicks for carousel - FIXED to properly update carousel
  observeEvent(input$day_clicked, {
    cat("Day clicked before update:", clicked_day(), "->", input$day_clicked, "\n")
    clicked_day(input$day_clicked)
    cat("Day clicked after update:", clicked_day(), "\n")
    showing_default_recommendations(FALSE)
    
    # Force carousel to update by triggering reactivity
    carousel_data()
  })
  
  # NEW: Get default recommendations when no itinerary exists
  get_default_recommendations <- function() {
    # Get popular Melbourne places across different categories
    default_places <- theme_data %>%
      filter(!Theme %in% c("Public Services", "Health Services", "Transport")) %>%
      filter(!grepl("hospital|clinic|police|fire station", Name, ignore.case = TRUE)) %>%
      distinct(Name, .keep_all = TRUE) %>%
      arrange(desc(Google_Rating)) %>%
      head(9)
    
    return(default_places)
  }
  
  # Carousel data reactive - UPDATED to include the actual itinerary activity as first card
  carousel_data <- reactive({
    # If we have dates selected and user clicked a day, show day-specific recommendations
    dates <- selected_dates()
    if (length(dates) > 0 && !showing_default_recommendations()) {
      day <- clicked_day()
      cat("Carousel data requested for day:", day, "\n")
      
      if (length(dates) >= day) {
        date <- dates[day]
        
        # Use stored activities instead of re-fetching
        activities <- if (length(itinerary_data$activities) >= day) {
          itinerary_data$activities[[day]]
        } else {
          list()
        }
        
        cat("Activities found:", length(activities), "\n")
        
        if (length(activities) > 0) {
          # Get the main activity for that day
          main_activity <- activities[[1]]$name
          cat("Main activity:", main_activity, "\n")
          
          # Find the main activity in theme_data to get its actual details
          main_activity_info <- theme_data %>%
            filter(Name == main_activity) %>%
            head(1)
          
          # Get related places based on the actual activity's theme and sub-theme
          if (nrow(main_activity_info) > 0) {
            cat("Found main activity in theme_data:", main_activity_info$Theme, "-", main_activity_info$Sub_Theme, "\n")
            
            related_places <- theme_data %>%
              filter(Name != main_activity) %>%
              # Match by same theme or sub-theme for more relevant results
              filter(
                Theme == main_activity_info$Theme |
                  Sub_Theme == main_activity_info$Sub_Theme
              ) %>%
              head(8)  # Reduced to 8 to make room for main activity
            
          } else {
            # Fallback: use activity-based matching
            cat("Main activity not found in theme_data, using activity-based matching\n")
            activity_theme <- get_activity_theme(main_activity)
            cat("Guessed theme:", activity_theme, "\n")
            
            related_places <- theme_data %>%
              filter(Name != main_activity) %>%
              filter(Theme == activity_theme) %>%
              head(8)  # Reduced to 8 to make room for main activity
          }
          
          # CREATE COMBINED DATA: Main activity first, then related places
          if (nrow(main_activity_info) > 0) {
            # Use the actual activity details from theme_data
            main_activity_row <- main_activity_info
          } else {
            # Create a placeholder for the main activity if not found in theme_data
            main_activity_row <- data.frame(
              Name = main_activity,
              Theme = get_activity_theme(main_activity),
              Sub_Theme = "Recommended Activity",
              Google_Rating = NA,
              opening_time = NA,
              closing_time = NA,
              Business_address = "Location details available after selection",
              stringsAsFactors = FALSE
            )
          }
          
          # Mark the main activity as the primary recommendation
          main_activity_row$is_primary <- TRUE
          
          # Mark related places as secondary
          if (nrow(related_places) > 0) {
            related_places$is_primary <- FALSE
          }
          
          # Combine main activity with related places
          all_places <- if (nrow(related_places) > 0) {
            bind_rows(main_activity_row, related_places)
          } else {
            main_activity_row
          }
          
          cat("Total places for carousel:", nrow(all_places), "\n")
          if (nrow(all_places) > 0) {
            cat("First place (primary):", all_places$Name[1], "- Primary:", all_places$is_primary[1], "\n")
          }
          
          return(list(
            main_activity = main_activity,
            related_places = all_places,
            date = date,
            day_name = format(date, "%A"),
            is_default = FALSE
          ))
        }
      }
    }
    
    # DEFAULT RECOMMENDATIONS: Show when no itinerary or no activities
    cat("Showing default recommendations\n")
    default_places <- get_default_recommendations()
    default_places$is_primary <- FALSE  # No primary in default mode
    
    return(list(
      main_activity = "Popular Melbourne Destinations",
      related_places = default_places,
      date = NULL,
      day_name = "Today",
      is_default = TRUE
    ))
  })
  
  # Get theme for an activity - IMPROVED matching
  get_activity_theme <- function(activity_name) {
    # Try to find the activity in theme_data to get its actual theme
    activity_info <- theme_data %>%
      filter(grepl(activity_name, Name, ignore.case = TRUE)) %>%
      head(1)
    
    if (nrow(activity_info) > 0) {
      return(activity_info$Theme)
    }
    
    # Fallback: guess based on activity name - IMPROVED logic
    if (grepl("park|garden|botanic|reserve", activity_name, ignore.case = TRUE)) {
      return("Parks & Gardens")
    } else if (grepl("cafe|restaurant|bar|food|coffee|dining|pub|bistro|eat", activity_name, ignore.case = TRUE)) {
      return("Food & Drink")
    } else if (grepl("museum|gallery|art|cultural|exhibition", activity_name, ignore.case = TRUE)) {
      return("Arts & Culture")
    } else if (grepl("shop|market|boutique|mall|retail|store", activity_name, ignore.case = TRUE)) {
      return("Shopping")
    } else if (grepl("theatre|cinema|concert|entertainment|show|performance", activity_name, ignore.case = TRUE)) {
      return("Entertainment")
    } else if (grepl("historic|heritage|monument|memorial", activity_name, ignore.case = TRUE)) {
      return("Heritage")
    } else {
      return("Attractions")  # Default
    }
  }
  
  # Carousel page management (each page shows 3 items)
  carousel_page <- reactiveVal(1)
  
  # Reset carousel when new day is clicked or when switching to default
  observeEvent(clicked_day(), {
    carousel_page(1)
    cat("Carousel page reset to 1\n")
  })
  
  observeEvent(showing_default_recommendations(), {
    carousel_page(1)
    cat("Carousel page reset to 1 (default mode change)\n")
  })
  
  # Calculate total pages
  total_pages <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(1)
    ceiling(nrow(data$related_places) / 3)
  })
  
  # Get current page items (3 items per page)
  current_page_items <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(NULL)
    
    current_page <- carousel_page()
    start_index <- (current_page - 1) * 3 + 1
    end_index <- min(start_index + 2, nrow(data$related_places))
    
    data$related_places[start_index:end_index, ]
  })
  
  # Carousel navigation
  observeEvent(input$carousel_prev, {
    current <- carousel_page()
    if (current > 1) {
      carousel_page(current - 1)
      cat("Carousel prev: page", current, "->", current - 1, "\n")
    }
  })
  
  observeEvent(input$carousel_next, {
    current <- carousel_page()
    if (current < total_pages()) {
      carousel_page(current + 1)
      cat("Carousel next: page", current, "->", current + 1, "\n")
    }
  })
  
  # Carousel output - UPDATED to highlight the primary recommendation
  output$activity_carousel <- renderUI({
    data <- carousel_data()
    
    if (is.null(data) || nrow(data$related_places) == 0) {
      return(div(
        class = "carousel-placeholder",
        h4("🎯 Discover Your Perfect Melbourne Experience"),
        p("Click on any day in your itinerary above to see personalized recommendations!"),
        p("Don't see any activities? Start by:"),
        tags$ul(
          tags$li("Exploring categories that interest you"),
          tags$li("Selecting your travel dates in the Weather tab"),
          tags$li("Building your preferences to get tailored suggestions")
        )
      ))
    }
    
    current_items <- current_page_items()
    current_page <- carousel_page()
    total_pages_val <- total_pages()
    
    # Different header based on whether we're showing default or day-specific recommendations
    header_text <- if (data$is_default) {
      "✨ Popular Melbourne Destinations"
    } else {
      paste("More recommendations for", data$day_name, format(data$date, "%d %B"))
    }
    
    subtitle_text <- if (data$is_default) {
      "Select dates in the Weather tab to get personalized daily recommendations"
    } else {
      paste("Similar places to:", data$main_activity)
    }
    
    tagList(
      # Header with conditional text
      div(
        class = "carousel-header",
        h4(header_text),
        p(subtitle_text, style = "margin: 5px 0 0 0; color: #666; font-size: 1rem;")
      ),
      
      # The carousel itself with 3 items
      div(
        class = "carousel-container",
        
        # Carousel items container
        div(
          class = "carousel-items-container",
          lapply(1:nrow(current_items), function(i) {
            place <- current_items[i, ]
            
            # Check if this is the primary recommendation
            is_primary <- !is.null(place$is_primary) && place$is_primary
            
            # Format hours to 12-hour AM/PM format
            formatted_hours <- if (!is.na(place$opening_time) && !is.na(place$closing_time)) {
              open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
              close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
              paste(open_time, "-", close_time)
            } else {
              NULL
            }
            
            # Generate helpful tips based on place type and characteristics
            tips <- generate_helpful_tips(place, is_primary)
            
            # Different styling for primary recommendation
            card_class <- if (is_primary) "carousel-item primary-recommendation" else "carousel-item"
            
            div(
              class = card_class,
              `data-place-name` = place$Name,
              `data-is-primary` = if (is_primary) "true" else "false",
              if (is_primary) {
                div(style = "background: #036B55; color: white; padding: 8px 12px; border-radius: 6px 6px 0 0; margin: -20px -20px 15px -20px; text-align: center; font-weight: 600; font-size: 0.9rem;",
                    "⭐ Your Itinerary Recommendation")
              },
              h5(place$Name),
              div(class = "place-category", place$Theme, " • ", place$Sub_Theme),
              if (!is.na(place$Google_Rating)) {
                div(class = "place-rating", paste("⭐", round(place$Google_Rating, 1), "/5"))
              },
              if (!is.null(formatted_hours)) {
                div(class = "place-hours", formatted_hours)
              },
              if (!is.null(place$Business_address) && !is.na(place$Business_address) && place$Business_address != "") {
                div(class = "place-address", place$Business_address)
              },
              # Add helpful tips section - UPDATED: Only show one tip with bigger font
              if (length(tips) > 0) {
                div(
                  class = "place-tips",
                  div(
                    class = "place-tip",
                    tips[1]  # Only show the first tip
                  )
                )
              }
            )
          })
        ),
        
        # Simple navigation (only show if we have multiple pages)
        if (total_pages_val > 1) {
          div(
            class = "carousel-nav",
            actionButton("carousel_prev", "◀ Previous", 
                         class = "carousel-nav-button",
                         disabled = current_page == 1),
            span(class = "carousel-page-info",
                 paste(current_page, "of", total_pages_val)),
            actionButton("carousel_next", "Next ▶", 
                         class = "carousel-nav-button",
                         disabled = current_page == total_pages_val)
          )
        }
      )
    )
  })
  
  # Helper function to generate helpful tips based on place characteristics
  generate_helpful_tips <- function(place, is_primary = FALSE) {
    tips <- c()
    
    # Get place characteristics
    place_name <- tolower(place$Name)
    place_theme <- place$Theme
    place_subtheme <- tolower(place$Sub_Theme)
    rating <- place$Google_Rating
    has_high_rating <- !is.na(rating) && rating >= 4.0
    has_low_rating <- !is.na(rating) && rating < 3.5
    
    # General tips for primary recommendations
    if (is_primary) {
      tips <- c(tips, 
                "Plan to arrive 15-30 minutes early to avoid crowds")
    }
    
    # Tips based on theme
    if (place_theme == "Food & Drink") {
      if (grepl("cafe|coffee", place_subtheme)) {
        tips <- c(tips, "Morning hours are usually less crowded")
      } else if (grepl("restaurant|dining|bistro", place_subtheme)) {
        tips <- c(tips, "Make reservations for dinner service")
      } else if (grepl("bar|pub", place_subtheme)) {
        tips <- c(tips, "Happy hour typically offers the best deals")
      }
    }
    
    if (place_theme == "Parks & Gardens") {
      tips <- c(tips, "Early morning or late afternoon for best lighting")
    }
    
    if (place_theme == "Arts & Culture") {
      if (grepl("museum|gallery", place_subtheme)) {
        tips <- c(tips, "Free entry days are often on weekdays")
      }
    }
    
    if (place_theme == "Shopping") {
      if (grepl("market", place_subtheme)) {
        tips <- c(tips, "Arrive early for the best selection")
      } else {
        tips <- c(tips, "Check for seasonal sales and promotions")
      }
    }
    
    if (place_theme == "Entertainment") {
      tips <- c(tips, "Book tickets in advance for popular shows")
    }
    
    if (place_theme == "Heritage") {
      tips <- c(tips, "Guided tours provide the best insights")
    }
    
    # Tips based on rating
    if (has_high_rating) {
      tips <- c(tips, "Highly rated by visitors - expect quality experience")
    }
    
    if (has_low_rating && !is_primary) {
      tips <- c(tips, "Recent reviews suggest checking current service quality")
    }
    
    # Tips based on specific place names or characteristics
    if (grepl("botanic|garden", place_name)) {
      tips <- c(tips, "Spring and autumn offer the best floral displays")
    }
    
    if (grepl("beach|coast", place_name)) {
      tips <- c(tips, "Check tide times before visiting")
    }
    
    if (grepl("view|lookout", place_name)) {
      tips <- c(tips, "Clear days offer the best visibility")
    }
    
    if (grepl("walk|trail|hike", place_name)) {
      tips <- c(tips, "Wear appropriate footwear for the terrain")
    }
    
    # Return just one tip - choose the most relevant one
    if (length(tips) > 0) {
      return(tips[1])  # Only return the first tip
    } else {
      return(character(0))  # Return empty if no tips
    }
  }
  
  # Observer for carousel place clicks
  observeEvent(input$carousel_place_clicked, {
    place_data <- input$carousel_place_clicked
    if (!is.null(place_data)) {
      cat("Carousel place clicked:", place_data$name, "\n")
      cat("Is primary recommendation:", place_data$is_primary, "\n")
      
      # Here you can add logic to:
      # 1. Switch to the map tab
      # 2. Highlight the selected place on the map
      # 3. Show details about the place
      
      # Example implementation:
      # updateTabsetPanel(session, "main_nav", "map_tab")
      # session$userData$selected_place <- place_data$name
      
      showNotification(paste("Selected:", place_data$name), type = "message")
    }
  })
  
  # [Rest of your existing functions remain the same]
  # ... include all your existing helper functions here without changes ...
  
  get_activities_for_date <- function(date, user_behavior) {
    activities <- list()
    
    tryCatch({
      # FIRST PRIORITY: Check if user has manually dragged activities for this date
      manual_activities <- list()
      if (!is.null(weather_module)) {
        manual_activities <- weather_module$get_activities_for_date(date)
      }
      
      # If user has manually selected activities, use those directly
      if (length(manual_activities) > 0) {
        cat("Using manually selected activities for", as.character(date), "\n")
        return(manual_activities)
      }
      
      # Only proceed to personality-based recommendations if no manual activities
      day_of_week <- weekdays(date)
      weather <- get_weather_for_date_safe(date)
      
      # SIMPLE WEATHER CHECK with proper null checking
      is_bad_weather <- FALSE
      if (!is.null(weather$rain) && !is.na(weather$rain) && weather$rain > 5) {
        is_bad_weather = TRUE
        cat("Rainy day detected - avoiding outdoor activities\n")
      } else if (!is.null(weather$emoji) && !is.na(weather$emoji) && grepl("🌧|⛈|🌦", weather$emoji)) {
        is_bad_weather = TRUE
        cat("Rainy weather emoji detected - avoiding outdoor activities\n")
      }
      
      # personality data retrieval with proper null checking
      personality_info <- personality_data()
      personality <- "Melbourne Explorer"  # default
      if (!is.null(personality_info) && !is.null(personality_info$type)) {
        personality <- personality_info$type
      }
      
      # Check if user has any clicks at all with proper null checking
      total_clicks <- 0
      if (!is.null(user_behavior) && !is.null(user_behavior$category_clicks)) {
        total_clicks <- sum(unlist(user_behavior$category_clicks), na.rm = TRUE)
      }
      
      # ALWAYS get some activities - start with base query
      base_activities <- theme_data %>%
        filter(!Theme %in% c("Public Services", "Health Services", "Transport")) %>%
        filter(!grepl("hospital|clinic|police|fire station", Name, ignore.case = TRUE)) %>%
        distinct(Name, .keep_all = TRUE)
      
      # Safety check - if base_activities is empty, use fallback
      if (nrow(base_activities) == 0) {
        cat("No base activities found, using fallback\n")
        return(get_fallback_activities())
      }
      
      # If user has no clicks, use DEFAULT activities
      if (total_clicks == 0) {
        cat("No user data - using DEFAULT recommendations for", as.character(date), "\n")
        
        # Apply weather filter if needed
        if (is_bad_weather) {
          base_activities <- base_activities %>%
            filter(!grepl("barbecue|bbq|picnic|hiking|climbing|swimming|beach", Name, ignore.case = TRUE))
        }
        
        selected_places <- base_activities %>% 
          sample_n(min(3, nrow(.)))
        
      } else {
        # USER HAS DATA - Personality-based recommendations
        cat("Using personality-based recommendations for", as.character(date), "\n")
        cat("Personality detected:", personality, "\n")
        
        # Filter by personality type with proper error handling
        personality_places <- base_activities
        
        if (personality == "Urban Adventurer") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Attractions", "Shopping", "Food & Drink", "Arts & Culture", "Entertainment"))
        } else if (personality == "Practical Traveler") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Shopping", "Food & Drink", "Attractions", "Transport", "Markets"))
        } else if (personality == "Wellness Seeker") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Leisure", "Parks & Gardens", "Food & Drink", "Attractions"))
        } else if (personality == "Melbourne Explorer") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Arts & Culture", "Attractions", "Food & Drink", "Parks & Gardens", 
                                "Shopping", "Leisure", "Heritage", "Markets", "Entertainment"))
        } else if (personality == "Food Lover") {
          personality_places <- base_activities %>%
            filter(Theme == "Food & Drink")
        } else if (personality == "Nature Enthusiast") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Parks & Gardens", "Attractions", "Leisure"))
        } else if (personality == "Culture Connoisseur") {
          personality_places <- base_activities %>%
            filter(Theme %in% c("Arts & Culture", "Heritage", "Attractions"))
        }
        # else use default base_activities
        
        # Apply weather filter if needed
        if (is_bad_weather) {
          personality_places <- personality_places %>%
            filter(!grepl("barbecue|bbq|picnic|hiking|climbing|swimming|beach", Name, ignore.case = TRUE))
        }
        
        # ALWAYS get at least 3 places
        if (nrow(personality_places) >= 3) {
          selected_places <- personality_places %>% sample_n(min(3, nrow(.)))
        } else {
          cat("Not enough personality matches, supplementing with random activities\n")
          # Get what we can from personality matches
          personality_selected <- personality_places
          # Get remaining from base activities
          remaining_needed <- max(0, 3 - nrow(personality_selected))
          if (remaining_needed > 0) {
            supplemental_places <- base_activities %>%
              filter(!Name %in% personality_selected$Name) %>%
              sample_n(min(remaining_needed, nrow(.)))
            selected_places <- bind_rows(personality_selected, supplemental_places)
          } else {
            selected_places <- personality_selected
          }
        }
      }
      
      # FINAL SAFETY CHECK: If we still don't have 3 activities, get ANY random activities
      if (nrow(selected_places) < 3) {
        cat("Still not enough activities, getting random fallbacks\n")
        needed <- max(0, 3 - nrow(selected_places))
        if (needed > 0) {
          fallback_places <- base_activities %>%
            filter(!Name %in% selected_places$Name) %>%
            sample_n(min(needed, nrow(.)))
          selected_places <- bind_rows(selected_places, fallback_places)
        }
      }
      
      # Convert selected places to activities
      if (nrow(selected_places) > 0) {
        activities <- lapply(1:min(3, nrow(selected_places)), function(i) {
          place <- selected_places[i, ]
          
          place_name <- if (!is.null(place$Name) && !is.na(place$Name)) place$Name else "Melbourne Activity"
          place_subtheme <- if (!is.null(place$Sub_Theme) && !is.na(place$Sub_Theme)) place$Sub_Theme else "Activity"
          place_rating <- if (!is.null(place$Google_Rating) && !is.na(place$Google_Rating)) place$Google_Rating else NA
          
          # Create appropriate time slots based on place type and operating hours
          time_slot <- generate_time_slot(place, i)
          
          # Create location description
          location_desc <- place_subtheme
          if (!is.na(place_rating)) {
            location_desc <- paste(location_desc, "•", paste("⭐", round(place_rating, 1)))
          }
          
          list(
            name = place_name,
            time = time_slot,
            location = location_desc
          )
        })
      }
      
      cat("Final activities count:", length(activities), "\n")
      return(activities)
      
    }, error = function(e) {
      cat("ERROR in get_activities_for_date:", e$message, "\n")
      return(get_fallback_activities())
    })
  }
  
  # Helper function for fallback activities
  get_fallback_activities <- function() {
    fallback_activities <- theme_data %>%
      filter(!Theme %in% c("Public Services", "Health Services")) %>%
      distinct(Name, .keep_all = TRUE) %>%
      sample_n(min(3, nrow(.)))
    
    if (nrow(fallback_activities) > 0) {
      return(lapply(1:nrow(fallback_activities), function(i) {
        place <- fallback_activities[i, ]
        list(
          name = place$Name,
          time = "10:00 AM - 5:00 PM",
          location = if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
        )
      }))
    } else {
      # HARDCODED FALLBACK if everything fails
      return(list(
        list(name = "Royal Botanic Gardens", time = "10:00 AM - 5:00 PM", location = "Park"),
        list(name = "Queen Victoria Market", time = "9:00 AM - 2:00 PM", location = "Market"),
        list(name = "Federation Square", time = "All Day", location = "Landmark")
      ))
    }
  }
  
  # Helper function to generate time slots based on place type and operating hours
  generate_time_slot <- function(place, index) {
    # Check if we have operating hours data
    has_hours <- !is.null(place$opening_time) && !is.na(place$opening_time) && 
      !is.null(place$closing_time) && !is.na(place$closing_time)
    
    if (has_hours) {
      # Use actual operating hours if available
      open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
      close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
      return(paste(open_time, "-", close_time))
    }
    
    # Fallback to intelligent time slots based on place type
    place_theme <- if (!is.null(place$Theme)) place$Theme else "Attractions"
    place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else ""
    
    if (place_theme == "Food & Drink") {
      if (grepl("cafe|coffee|breakfast", place_subtheme, ignore.case = TRUE)) {
        time_slots <- c("7:00 AM - 9:00 AM", "9:00 AM - 11:00 AM", "3:00 PM - 5:00 PM")
      } else {
        time_slots <- c("12:00 PM - 2:00 PM", "1:00 PM - 3:00 PM", "6:00 PM - 8:00 PM", "7:00 PM - 9:00 PM")
      }
    } else if (place_theme == "Parks & Gardens") {
      time_slots <- c("6:00 AM - 9:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "4:00 PM - 6:00 PM")
    } else if (place_theme %in% c("Arts & Culture", "Heritage")) {
      time_slots <- c("10:00 AM - 12:00 PM", "11:00 AM - 1:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM")
    } else if (place_theme == "Shopping" || place_theme == "Markets") {
      time_slots <- c("9:00 AM - 11:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM")
    } else {
      # Default for attractions, leisure, etc.
      time_slots <- c("10:00 AM - 12:00 PM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
    }
    
    # Use index to pick different time slots for variety
    time_slot <- time_slots[(index - 1) %% length(time_slots) + 1]
    return(time_slot)
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
  
  # Personality outputs
  output$personality_title <- renderText({
    data <- personality_data()
    if (is.null(data)) return("You are a Melbourne Explorer!")
    paste("You are a", data$type, "!")
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
}