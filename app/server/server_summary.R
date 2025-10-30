# Summary server
summary_server <- function(input, output, session, user_behavior, weather_module = NULL) {
  
  #  ------ Reactive data and state management ---------------------------------
  
  # Weather data
  weather_data <- reactive({
    if (exists("calendar_feed")) {
      calendar_feed
    } else {
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
  
  # Selected dates
  selected_dates <- reactive({
    if (!is.null(weather_module)) {
      weather_dates <- weather_module$selected_dates()
      if (length(weather_dates) > 0) return(weather_dates)
    }
    
    if (!is.null(session$userData$weather_dates)) {
      return(session$userData$weather_dates)
    }
    
    return(as.Date(character()))
  })
  
  # Track clicked day for carousel
  clicked_day <- reactiveVal(1)
  showing_default_recommendations <- reactiveVal(TRUE)
  
  # Store itinerary data
  itinerary_data <- reactiveValues(
    activities = list(),
    last_updated = NULL
  )
  
  # Personality data
  personality_data <- reactive({
    tryCatch({
      if (is.null(user_behavior) || is.null(user_behavior$category_clicks)) {
        return(default_personality())
      }
      
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
      
      scores <- calculate_personality_scores(clicks)
      determine_personality(scores, clicks)
      
    }, error = function(e) {
      default_personality()
    })
  })
  
  # ------- Observers and Event Handlers ---------------------------------------
  
  # Update itinerary when dates change
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
  
  # Day click handler
  observeEvent(input$day_clicked, {
    clicked_day(input$day_clicked)
    showing_default_recommendations(FALSE)
  })
  
  # Carousel place click handler
  observeEvent(input$carousel_place_clicked, {
    place_data <- input$carousel_place_clicked
    if (!is.null(place_data)) {
      place_name <- place_data$name
      
      place_info <- theme_data %>%
        filter(Name == place_name) %>%
        head(1)
      
      if (nrow(place_info) > 0) {
        updateNavbarPage(session, 'nav', selected = 'Map')
        
        shinyjs::delay(800, {
          google_map_update("google_map") %>%
            clear_markers(layer_id = "carousel_highlight")
          
          single_place_data <- data.frame(
            name = place_info$Name,
            lat = as.numeric(place_info$Latitude),
            lng = as.numeric(place_info$Longitude)
          )
          
          # Update map state
          map_rv$current_display_data <- place_info  
          map_rv$display_source <- "carousel"        
          map_rv$filtered_places <- place_info       
          
          # Add marker to map
          google_map_update("google_map") %>%
            add_markers(
              data = single_place_data,
              lat = "lat",
              lon = "lng",
              id = "name",
              layer_id = "carousel_highlight",
              update_map_view = TRUE
            )
          
          showNotification(
            paste0("Showing: ", place_name),
            type = "message",
            duration = 2
          )
        })
      }
    }
  })
  
  #  --------- Render outputs --------------------------------------------------
  
  output$has_dates_selected <- reactive({
    length(selected_dates()) > 0
  })
  outputOptions(output, "has_dates_selected", suspendWhenHidden = FALSE)
  
  # Itinerary table
  output$itinerary_table <- renderUI({
    dates <- selected_dates()
    
    if (length(dates) == 0) {
      return(empty_itinerary_message())
    }
    
    activities_list <- itinerary_data$activities
    has_any_activities <- any(sapply(activities_list, length) > 0)
    
    if (!has_any_activities) {
      return(building_itinerary_message())
    }
    
    create_itinerary_table(dates, activities_list)
  })
  
  # Carousel
  output$activity_carousel <- renderUI({
    data <- carousel_data()
    
    if (is.null(data) || nrow(data$related_places) == 0) {
      return(carousel_placeholder())
    }
    
    create_carousel_ui(data)
  })
  
  # Personality outputs
  output$personality_title <- renderText({
    data <- personality_data()
    if (is.null(data)) "You are a Melbourne Explorer!" else paste("You are a", data$type, "!")
  })
  
  output$personality_icon <- renderUI({
    data <- personality_data()
    if (is.null(data)) return(div(icon("binoculars"), style = "color: #036B55; font-size: 2.5em;"))
    div(style = paste0("color:", data$color, "; font-size: 2.5em;"), data$icon)
  })
  
  output$personality_description <- renderText({
    data <- personality_data()
    if (is.null(data)) "Start clicking categories to discover your Melbourne personality!" else data$description
  })
  
  # -------- Carousel Management -----------------------------------------------
  
  carousel_page <- reactiveVal(1)
  
  observeEvent(clicked_day(), {
    carousel_page(1)
  })
  
  observeEvent(showing_default_recommendations(), {
    carousel_page(1)
  })
  
  observeEvent(input$carousel_prev, {
    current <- carousel_page()
    if (current > 1) carousel_page(current - 1)
  })
  
  observeEvent(input$carousel_next, {
    current <- carousel_page()
    if (current < total_pages()) carousel_page(current + 1)
  })
  
  carousel_data <- reactive({
    dates <- selected_dates()
    if (length(dates) > 0 && !showing_default_recommendations()) {
      day <- clicked_day()
      if (length(dates) >= day) {
        activities <- if (length(itinerary_data$activities) >= day) {
          itinerary_data$activities[[day]]
        } else {
          list()
        }
        
        if (length(activities) > 0) {
          return(create_day_specific_carousel(activities[[1]]$name, dates[day]))
        }
      }
    }
    
    # Default recommendations
    create_default_carousel()
  })
  
  total_pages <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(1)
    ceiling(nrow(data$related_places) / 3)
  })
  
  current_page_items <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(NULL)
    
    current_page <- carousel_page()
    start_index <- (current_page - 1) * 3 + 1
    end_index <- min(start_index + 2, nrow(data$related_places))
    
    data$related_places[start_index:end_index, ]
  })
  
  # ------ Helper functions ----------------------------------------------------
  
  get_weather_for_date_safe <- function(date) {
    tryCatch({
      get_weather_for_date(date, weather_data())
    }, error = function(e) {
      list(emoji = "⛅️", label = "Cloudy", temp_min = NA, temp_max = NA, rain = NA)
    })
  }
  
  get_default_recommendations <- function() {
    theme_data %>%
      filter(!Theme %in% c("Public Services", "Health Services", "Transport")) %>%
      filter(!grepl("hospital|clinic|police|fire station", Name, ignore.case = TRUE)) %>%
      distinct(Name, .keep_all = TRUE) %>%
      arrange(desc(Google_Rating)) %>%
      head(9)
  }
  
  get_activity_theme <- function(activity_name) {
    activity_info <- theme_data %>%
      filter(grepl(activity_name, Name, ignore.case = TRUE)) %>%
      head(1)
    
    if (nrow(activity_info) > 0) return(activity_info$Theme)
    
    # Fallback theme detection
    if (grepl("park|garden|botanic|reserve", activity_name, ignore.case = TRUE)) return("Parks & Gardens")
    if (grepl("cafe|restaurant|bar|food|coffee|dining|pub|bistro|eat", activity_name, ignore.case = TRUE)) return("Food & Drink")
    if (grepl("museum|gallery|art|cultural|exhibition", activity_name, ignore.case = TRUE)) return("Arts & Culture")
    if (grepl("shop|market|boutique|mall|retail|store", activity_name, ignore.case = TRUE)) return("Shopping")
    if (grepl("theatre|cinema|concert|entertainment|show|performance", activity_name, ignore.case = TRUE)) return("Entertainment")
    if (grepl("historic|heritage|monument|memorial", activity_name, ignore.case = TRUE)) return("Heritage")
    
    "Attractions"
  }
  
  generate_helpful_tips <- function(place, is_primary = FALSE) {
    tips <- c()
    place_name <- tolower(place$Name)
    place_theme <- place$Theme
    place_subtheme <- tolower(place$Sub_Theme)
    rating <- place$Google_Rating
    has_high_rating <- !is.na(rating) && rating >= 4.0
    
    if (is_primary) tips <- c(tips, "Plan to arrive 15-30 minutes early to avoid crowds")
    
    # Theme-based tips
    theme_tips <- list(
      "Food & Drink" = list(
        "cafe|coffee" = "Morning hours are usually less crowded",
        "restaurant|dining|bistro" = "Make reservations for dinner service",
        "bar|pub" = "Happy hour typically offers the best deals"
      ),
      "Parks & Gardens" = "Early morning or late afternoon for best lighting",
      "Arts & Culture" = list("museum|gallery" = "Free entry days are often on weekdays"),
      "Shopping" = list("market" = "Arrive early for the best selection", "default" = "Check for seasonal sales and promotions"),
      "Entertainment" = "Book tickets in advance for popular shows",
      "Heritage" = "Guided tours provide the best insights"
    )
    
    if (place_theme %in% names(theme_tips)) {
      theme_tip <- theme_tips[[place_theme]]
      if (is.character(theme_tip)) {
        tips <- c(tips, theme_tip)
      } else if (is.list(theme_tip)) {
        for (pattern in names(theme_tip)) {
          if (grepl(pattern, place_subtheme)) {
            tips <- c(tips, theme_tip[[pattern]])
            break
          }
        }
        if ("default" %in% names(theme_tip)) {
          tips <- c(tips, theme_tip[["default"]])
        }
      }
    }
    
    if (has_high_rating) tips <- c(tips, "Highly rated by visitors - expect quality experience")
    if (grepl("botanic|garden", place_name)) tips <- c(tips, "Spring and autumn offer the best floral displays")
    if (grepl("beach|coast", place_name)) tips <- c(tips, "Check tide times before visiting")
    if (grepl("view|lookout", place_name)) tips <- c(tips, "Clear days offer the best visibility")
    if (grepl("walk|trail|hike", place_name)) tips <- c(tips, "Wear appropriate footwear for the terrain")
    
    if (length(tips) > 0) tips[1] else character(0)
  }
  
  # ------ UI component functions (Empty state handling) -----------------------
  
  empty_itinerary_message <- function() {
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
  }
  
  building_itinerary_message <- function() {
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
  }
  
  create_itinerary_table <- function(dates, activities_list) {
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
  }
  
  create_carousel_ui <- function(data) {
    current_items <- current_page_items()
    current_page <- carousel_page()
    total_pages_val <- total_pages()
    
    header_text <- if (data$is_default) "✨ Popular Melbourne Destinations" else paste("More recommendations for", data$day_name, format(data$date, "%d %B"))
    subtitle_text <- if (data$is_default) "Select dates in the Weather tab to get personalized daily recommendations" else paste("Similar places to:", data$main_activity)
    
    tagList(
      div(
        class = "carousel-header",
        h4(header_text),
      ),
      
      div(
        class = "carousel-container",
        div(
          class = "carousel-items-container",
          lapply(1:nrow(current_items), function(i) {
            place <- current_items[i, ]
            is_primary <- !is.null(place$is_primary) && place$is_primary
            
            formatted_hours <- if (!is.na(place$opening_time) && !is.na(place$closing_time)) {
              open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
              close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
              paste(open_time, "-", close_time)
            } else NULL
            
            tips <- generate_helpful_tips(place, is_primary)
            card_class <- if (is_primary) "carousel-item primary-recommendation" else "carousel-item"
            
            div(
              class = card_class,
              `data-place-name` = place$Name,
              `data-is-primary` = if (is_primary) "true" else "false",
              onclick = sprintf(
                "Shiny.setInputValue('carousel_place_clicked', {name: '%s', is_primary: %s}, {priority: 'event'})",
                gsub("'", "\\\\'", place$Name),
                tolower(is_primary)
              ),
              style = "cursor: pointer;",
              if (is_primary) {
                div(style = "background: #036B55; color: white; padding: 8px 12px; border-radius: 6px 6px 0 0; margin: -20px -20px 15px -20px; text-align: center; font-weight: 600; font-size: 0.9rem;",
                    "⭐ Your Itinerary Recommendation")
              },
              h5(place$Name),
              div(class = "place-category", place$Theme, " • ", place$Sub_Theme),
              if (!is.na(place$Google_Rating)) div(class = "place-rating", paste("⭐", round(place$Google_Rating, 1), "/5")),
              if (!is.null(formatted_hours)) div(class = "place-hours", formatted_hours),
              if (!is.null(place$Business_address) && !is.na(place$Business_address) && place$Business_address != "") {
                div(class = "place-address", place$Business_address)
              },
              if (length(tips) > 0) {
                div(
                  class = "place-tips",
                  div(class = "place-tip", tips[1])
                )
              }
            )
          })
        ),
        
        if (total_pages_val > 1) {
          div(
            class = "carousel-nav",
            actionButton("carousel_prev", "◀ Previous", class = "carousel-nav-button", disabled = current_page == 1),
            span(class = "carousel-page-info", paste(current_page, "of", total_pages_val)),
            actionButton("carousel_next", "Next ▶", class = "carousel-nav-button", disabled = current_page == total_pages_val)
          )
        }
      )
    )
  }
  
  create_day_specific_carousel <- function(main_activity, date) {
    main_activity_info <- theme_data %>% filter(Name == main_activity) %>% head(1)
    
    if (nrow(main_activity_info) > 0) {
      related_places <- theme_data %>%
        filter(Name != main_activity) %>%
        filter(Theme == main_activity_info$Theme | Sub_Theme == main_activity_info$Sub_Theme) %>%
        head(8)
    } else {
      activity_theme <- get_activity_theme(main_activity)
      related_places <- theme_data %>%
        filter(Name != main_activity) %>%
        filter(Theme == activity_theme) %>%
        head(8)
    }
    
    if (nrow(main_activity_info) > 0) {
      main_activity_row <- main_activity_info
    } else {
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
    
    main_activity_row$is_primary <- TRUE
    if (nrow(related_places) > 0) related_places$is_primary <- FALSE
    
    all_places <- if (nrow(related_places) > 0) bind_rows(main_activity_row, related_places) else main_activity_row
    
    list(
      main_activity = main_activity,
      related_places = all_places,
      date = date,
      day_name = format(date, "%A"),
      is_default = FALSE
    )
  }
  
  create_default_carousel <- function() {
    default_places <- get_default_recommendations()
    default_places$is_primary <- FALSE
    
    list(
      main_activity = "Popular Melbourne Destinations",
      related_places = default_places,
      date = NULL,
      day_name = "Today",
      is_default = TRUE
    )
  }
  
  # ------- PERSONALITY FUNCTIONS ----------------------------------------------
  
  calculate_personality_scores <- function(clicks) {
    list(
      foodie = clicks$food_drink * 2,
      culture_seeker = clicks$arts_culture + clicks$heritage,
      nature_lover = clicks$attractions + clicks$leisure,
      urban_explorer = clicks$transport + clicks$shopping,
      wellness_enthusiast = clicks$health_services + clicks$leisure,
      practical_traveler = clicks$accommodation + clicks$public_service
    )
  }
  
  determine_personality <- function(scores, clicks) {
    score_values <- unlist(scores)
    if (length(score_values) == 0 || all(is.na(score_values))) return(default_personality())
    
    max_score <- max(score_values, na.rm = TRUE)
    dominant <- names(scores)[which.max(score_values)]
    total_clicks <- sum(unlist(clicks))
    
    if (total_clicks == 0) return(default_personality("binoculars", "Start clicking categories to discover your Melbourne personality!"))
    if (max_score == 0 || is.na(max_score) || max_score < 1) return(default_personality("compass", "You're exploring everything! Click more to reveal your favorite side of Melbourne."))
    
    personality_map <- list(
      foodie = list("Food Lover", "coffee", "#6f4e37", "You're always searching for the next great meal or perfect brew!"),
      culture_seeker = list("Culture Connoisseur", "landmark", "#4B0082", "You appreciate art, history, and cultural experiences!"),
      nature_lover = list("Nature Enthusiast", "tree", "#228B22", "You love exploring parks, gardens, and outdoor spaces!"),
      urban_explorer = list("Urban Adventurer", "city", "#4169E1", "You thrive in the city and love discovering urban gems!"),
      wellness_enthusiast = list("Wellness Seeker", "heart", "#FF6B6B", "You prioritize health and relaxation in your travels!"),
      practical_traveler = list("Practical Traveler", "map-signs", "#FF8C00", "You're organized and plan your trips carefully!")
    )
    
    if (dominant %in% names(personality_map)) {
      pers <- personality_map[[dominant]]
      return(list(type = pers[[1]], icon = icon(pers[[2]]), color = pers[[3]], description = pers[[4]]))
    }
    
    list(type = "Melbourne Adventurer", icon = icon("star"), color = "#036B55", description = "You're discovering the many faces of Melbourne!")
  }
  
  default_personality <- function(icon_name = "binoculars", description = "Start exploring Melbourne!") {
    list(
      type = "Melbourne Explorer",
      icon = icon(icon_name),
      color = "#036B55", 
      description = description
    )
  }
  
  # ------- Activity Planning functions ----------------------------------------
  
  get_activities_for_date <- function(date, user_behavior) {
    tryCatch({
      # Check for manual activities first
      if (!is.null(weather_module)) {
        manual_activities <- weather_module$get_activities_for_date(date)
        if (length(manual_activities) > 0) return(manual_activities)
      }
      
      # Personality-based recommendations
      day_of_week <- weekdays(date)
      weather <- get_weather_for_date_safe(date)
      is_bad_weather <- check_bad_weather(weather)
      
      personality_info <- personality_data()
      personality <- if (!is.null(personality_info) && !is.null(personality_info$type)) personality_info$type else "Melbourne Explorer"
      
      total_clicks <- if (!is.null(user_behavior) && !is.null(user_behavior$category_clicks)) sum(unlist(user_behavior$category_clicks), na.rm = TRUE) else 0
      
      base_activities <- get_base_activities()
      if (nrow(base_activities) == 0) return(get_fallback_activities())
      
      if (total_clicks == 0) {
        # Default recommendations
        if (is_bad_weather) base_activities <- filter_outdoor_activities(base_activities)
        selected_places <- base_activities %>% sample_n(min(3, nrow(.)))
      } else {
        # Personality-based recommendations
        personality_places <- filter_by_personality(base_activities, personality)
        if (is_bad_weather) personality_places <- filter_outdoor_activities(personality_places)
        
        if (nrow(personality_places) >= 3) {
          selected_places <- personality_places %>% sample_n(min(3, nrow(.)))
        } else {
          selected_places <- supplement_activities(personality_places, base_activities, 3)
        }
      }
      
      # Final safety check
      if (nrow(selected_places) < 3) {
        selected_places <- supplement_activities(selected_places, base_activities, 3)
      }
      
      convert_places_to_activities(selected_places)
      
    }, error = function(e) {
      get_fallback_activities()
    })
  }
  
  check_bad_weather <- function(weather) {
    (!is.null(weather$rain) && !is.na(weather$rain) && weather$rain > 5) ||
      (!is.null(weather$emoji) && !is.na(weather$emoji) && grepl("🌧|⛈|🌦", weather$emoji))
  }
  
  get_base_activities <- function() {
    theme_data %>%
      filter(!Theme %in% c("Public Services", "Health Services", "Transport")) %>%
      filter(!grepl("hospital|clinic|police|fire station", Name, ignore.case = TRUE)) %>%
      distinct(Name, .keep_all = TRUE)
  }
  
  filter_outdoor_activities <- function(activities) {
    activities %>%
      filter(!grepl("barbecue|bbq|picnic|hiking|climbing|swimming|beach", Name, ignore.case = TRUE))
  }
  
  filter_by_personality <- function(activities, personality) {
    personality_filters <- list(
      "Urban Adventurer" = c("Attractions", "Shopping", "Food & Drink", "Arts & Culture", "Entertainment"),
      "Practical Traveler" = c("Shopping", "Food & Drink", "Attractions", "Transport", "Markets"),
      "Wellness Seeker" = c("Leisure", "Parks & Gardens", "Food & Drink", "Attractions"),
      "Melbourne Explorer" = c("Arts & Culture", "Attractions", "Food & Drink", "Parks & Gardens", "Shopping", "Leisure", "Heritage", "Markets", "Entertainment"),
      "Food Lover" = "Food & Drink",
      "Nature Enthusiast" = c("Parks & Gardens", "Attractions", "Leisure"),
      "Culture Connoisseur" = c("Arts & Culture", "Heritage", "Attractions")
    )
    
    if (personality %in% names(personality_filters)) {
      themes <- personality_filters[[personality]]
      activities %>% filter(Theme %in% themes)
    } else {
      activities
    }
  }
  
  supplement_activities <- function(main_activities, all_activities, target_count) {
    current_count <- nrow(main_activities)
    if (current_count >= target_count) return(main_activities)
    
    needed <- target_count - current_count
    supplemental <- all_activities %>%
      filter(!Name %in% main_activities$Name) %>%
      sample_n(min(needed, nrow(.)))
    
    bind_rows(main_activities, supplemental)
  }
  
  convert_places_to_activities <- function(places) {
    lapply(1:min(3, nrow(places)), function(i) {
      place <- places[i, ]
      
      place_name <- place$Name %||% "Melbourne Activity"
      place_subtheme <- place$Sub_Theme %||% "Activity"
      place_rating <- place$Google_Rating
      
      location_desc <- place_subtheme
      if (!is.na(place_rating)) location_desc <- paste(location_desc, "•", paste("⭐", round(place_rating, 1)))
      
      list(
        name = place_name,
        time = generate_time_slot(place, i),
        location = location_desc
      )
    })
  }
  
  generate_time_slot <- function(place, index) {
    # Check for actual operating hours
    if (!is.null(place$opening_time) && !is.na(place$opening_time) && 
        !is.null(place$closing_time) && !is.na(place$closing_time)) {
      open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
      close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
      return(paste(open_time, "-", close_time))
    }
    
    # Fallback time slots based on theme
    place_theme <- place$Theme %||% "Attractions"
    
    time_slots <- switch(
      place_theme,
      "Food & Drink" = if (grepl("cafe|coffee|breakfast", place$Sub_Theme %||% "", ignore.case = TRUE)) {
        c("7:00 AM - 9:00 AM", "9:00 AM - 11:00 AM", "3:00 PM - 5:00 PM")
      } else {
        c("12:00 PM - 2:00 PM", "1:00 PM - 3:00 PM", "6:00 PM - 8:00 PM", "7:00 PM - 9:00 PM")
      },
      "Parks & Gardens" = c("6:00 AM - 9:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "4:00 PM - 6:00 PM"),
      "Arts & Culture" = c("10:00 AM - 12:00 PM", "11:00 AM - 1:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM"),
      "Heritage" = c("10:00 AM - 12:00 PM", "11:00 AM - 1:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM"),
      "Shopping" = c("9:00 AM - 11:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM"),
      "Markets" = c("9:00 AM - 11:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM"),
      # Default
      c("10:00 AM - 12:00 PM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
    )
    
    time_slots[(index - 1) %% length(time_slots) + 1]
  }
  
  get_fallback_activities <- function() {
    fallback_activities <- theme_data %>%
      filter(!Theme %in% c("Public Services", "Health Services")) %>%
      distinct(Name, .keep_all = TRUE) %>%
      sample_n(min(3, nrow(.)))
    
    if (nrow(fallback_activities) > 0) {
      lapply(1:nrow(fallback_activities), function(i) {
        place <- fallback_activities[i, ]
        list(
          name = place$Name,
          time = "10:00 AM - 5:00 PM",
          location = place$Sub_Theme %||% "Activity"
        )
      })
    } else {
      # Hardcoded fallback
      list(
        list(name = "Royal Botanic Gardens", time = "10:00 AM - 5:00 PM", location = "Park"),
        list(name = "Queen Victoria Market", time = "9:00 AM - 2:00 PM", location = "Market"),
        list(name = "Federation Square", time = "All Day", location = "Landmark")
      )
    }
  }
}