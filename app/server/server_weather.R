# Weather server logic will go here
library(dplyr)
library(readr)
library(stringr)
library(lubridate)
library(tibble)
library(purrr)
library(bslib)
library(shinyWidgets)
library(sortable)



# Summarise metrics for a selected period
summarise_period_box <- function(feed, start_date, end_date) {
  d <- feed |> filter(date >= start_date, date <= end_date)
  tibble::tibble(
    avg_max_temp = mean(d$tmax, na.rm=TRUE),
    avg_min_temp = mean(d$tmin, na.rm=TRUE),
    avg_rain_mm  = mean(d$rain, na.rm=TRUE),
    pm25_text  = if (all(is.na(d$pm25_mean))) "—"
    else sprintf("%.1f µg/m3 (%.0f–%.0f)",
                 mean(d$pm25_mean, na.rm=TRUE),
                 min(d$pm25_min,  na.rm=TRUE),
                 max(d$pm25_max,  na.rm=TRUE)),
    noise_text = if (all(is.na(d$noise_mean))) "—"
    else sprintf("%.1f dB (%.0f–%.0f)",
                 mean(d$noise_mean, na.rm=TRUE),
                 min(d$noise_min,  na.rm=TRUE),
                 max(d$noise_max,  na.rm=TRUE))
  )
}

#------------------------------------------------------------#
# File paths
BOM_DIR  <- here("data", "raw", "weather_and_air")
SENSOR_CSV <- here("data", "raw", "weather_and_air", "microclimate-sensors-data.csv")


# BOM loader
read_bom_month <- function(path) {
  lines <- readr::read_lines(path, n_max = 60, locale = locale(encoding = "latin1"))
  hdr_idx <- which(stringr::str_detect(lines, "^,?\\s*Date\\b"))[1]
  if (is.na(hdr_idx)) hdr_idx <- 8
  
  df <- readr::read_csv(
    path,
    skip = hdr_idx - 1,
    locale = locale(encoding = "latin1"),
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE
  )
  
  df <- df |>
    dplyr::mutate(date = as.Date(Date)) |>
    transmute(
      date,
      tmin = `Minimum temperature (°C)`,
      tmax = `Maximum temperature (°C)`,
      rain = `Rainfall (mm)`,
      sun  = `Sunshine (hours)`,
      t9   = `9am Temperature (°C)`,
      t3   = `3pm Temperature (°C)`,
      rh9  = `9am relative humidity (%)`,
      rh3  = `3pm relative humidity (%)`,
      ws9  = `9am wind speed (km/h)`,
      ws3  = `3pm wind speed (km/h)`,
      cl9   = `9am cloud amount (oktas)`,
      cl3   = `3pm cloud amount (oktas)`
    )
  
  num_cols <- c("tmin","tmax","rain", "sun", "t9","t3","rh9","rh3","ws9","ws3","cl9","cl3")
  
  df <- df |>
    mutate(
      across(
        all_of(num_cols),
        ~ {
          x <- .x
          x <- stringr::str_replace_all(x, regex("^\\s*Calm\\s*$", ignore_case = TRUE), "0")
          readr::parse_number(x, na = c("", "NA", "-", "—", " ", "\t"))
        }
      )
    )
  
  dplyr::arrange(df, date)
}

# Microclimate (15-min) -> daily summary
read_microclimate_daily <- function(path, start = as.Date("2024-09-01"),
                                    end = as.Date("2025-10-31")) {
  raw <- readr::read_csv(path, show_col_types = FALSE)
  raw |>
    mutate(
      ts_utc  = lubridate::ymd_hms(received_at, tz = "UTC", quiet = TRUE),
      ts_melb = with_tz(ts_utc, "Australia/Melbourne"),
      date    = as.Date(ts_melb)
    ) |>
    filter(date >= start, date <= end) |>
    select(date, pm25, pm10, noise) |>
    group_by(date) |>
    summarise(
      across(c(pm25, pm10, noise),
             list(mean = ~mean(., na.rm=TRUE),
                  min  = ~min(.,  na.rm=TRUE),
                  max  = ~max(.,  na.rm=TRUE)),
             .names = "{.col}_{.fn}"),
      .groups = "drop"
    )
}

read_bom_range <- function(dir_path) {
  ym <- seq(lubridate::ymd("2024-09-01"), lubridate::ymd("2025-10-01"), by = "1 month")
  files <- file.path(dir_path, paste0("IDCJDW3050.", format(ym, "%Y%m"), ".csv"))
  files <- files[file.exists(files)]
  if (!length(files)) {
    stop("No BOM files found. Check BOM_DIR and file names.")
  }
  dplyr::bind_rows(purrr::map(files, read_bom_month)) |> dplyr::arrange(date)
}

## Data preprocessing 
bom_daily <- read_bom_range(BOM_DIR)

bom_for_join <- bom_daily |>
  mutate(
    airtemperature_bom   = rowMeans(cbind(t9, t3),  na.rm=TRUE),
    relativehumidity_bom = rowMeans(cbind(rh9, rh3),na.rm=TRUE),
    averagewindspeed_bom = rowMeans(cbind(ws9, ws3),na.rm=TRUE),
    averagecloud_bom = rowMeans(cbind(cl9, cl3),na.rm=TRUE)
  ) |>
  select(date, tmin, tmax, rain, sun,
         t9, t3, rh9, rh3, ws9, ws3, cl9, cl3,
         airtemperature_bom, relativehumidity_bom,
         averagewindspeed_bom, averagecloud_bom)

sensor_daily <- read_microclimate_daily(SENSOR_CSV)

make_calendar_feed <- function(bom_for_join, sensor_daily) {
  bom_for_join |>
    left_join(sensor_daily, by = "date") |>
    transmute(
      date,
      pm25_mean,  pm25_min,  pm25_max,
      pm10_mean,  pm10_min,  pm10_max,
      noise_mean, noise_min, noise_max,
      airtemperature_bom,relativehumidity_bom,averagewindspeed_bom,averagecloud_bom,
      tmin, tmax, rain,
      sun, t9, rh9, cl9, ws9, t3, rh3, cl3, ws3 # added
    )
}

calendar_feed <- make_calendar_feed(bom_for_join, sensor_daily)

#------------------------------------------------------------#

trip_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Activity list (all)
    activities <- tibble::tibble(
      key   = c("barbecue","hiking","picnic","climbing","swimming",
                "museum","exhibition","cafe"),
      label = c("🍖 barbecue","🥾 hiking","🧺 picnic","🧗 climbing","🏊️ swimming",
                "🏛️ museum","🖼️ exhibition","☕️ cafe & restaurant"),
      type  = c(rep("outdoor",5), rep("indoor",3))
    )
    
    # to handle emoji -> convert UTF-8
    activities$label <- enc2utf8(activities$label)
    
    label_to_key <- setNames(activities$key, activities$label)
    outdoor_keys <- activities |> dplyr::filter(type=="outdoor") |> dplyr::pull(key)
    to_keys <- function(lbls) {
      v <- unname(label_to_key[lbls])
      v[is.na(v)] <- lbls
      v
    }
    
    is_outdoor_present <- function(labels){
      if (length(labels) == 0) return(FALSE)
      any(to_keys(labels) %in% outdoor_keys)
    }
    
    day_badges <- function(row){
      if (nrow(row)==0) return(NULL)
      wx <- row
      
      temp_col <- if(wx$tmax > 30) "#ef4444" else if(wx$tmax > 25) "#f97316"
      else if(wx$tmax > 20) "#a16207" else "#2563eb"
      wind_ico <- if(is.na(wx$averagewindspeed_bom)) "💨"
      else if(wx$averagewindspeed_bom < 20) "🍃"
      else if(wx$averagewindspeed_bom < 40) "💨" else "🌬️"
      pm_ico   <- if(is.na(wx$pm25_mean)) "🌫️"
      else if(wx$pm25_mean <= 15) "🟢"
      else if(wx$pm25_mean <= 35) "🟡" else "🔴"
      rain_ico <- if(!is.na(wx$rain) && wx$rain >= 5) "🌧️"
      else if(!is.na(wx$rain) && wx$rain >= 1) "🌦️" else "☀️"
      
      div(class="metrics-row",
          # Temperature
          div(class="chip stack",
              div(class="row1",
                  span(class="ico","🌡️"),
                  span(class="val", style=sprintf("color:%s", temp_col),
                       sprintf("%.0f°", coalesce(wx$airtemperature_bom, (wx$tmin+wx$tmax)/2))),
                  span(class="unit",
                       sprintf("(%.0f°–%.0f°)", coalesce(wx$tmin, NA_real_), coalesce(wx$tmax, NA_real_)))
              ),
              span(class="cap","Temp")
          ),
          
          # Rainfall
          div(class="chip stack",
              div(class="row1",
                  span(class="ico", rain_ico),
                  span(class="val", if(is.na(wx$rain)) "–" else sprintf("%.0fmm", wx$rain))
              ),
              span(class="cap","Rainfall")
          ),
          
          # Wind
          div(class="chip stack",
              div(class="row1",
                  span(class="ico", wind_ico),
                  span(class="val", if(is.na(wx$averagewindspeed_bom)) "–" else sprintf("%.0f", wx$averagewindspeed_bom)),
                  span(class="unit","km/h")
              ),
              span(class="cap","Wind")
          ),
          
          # Sunshine
          div(class="chip stack",
              div(class="row1",
                  span(class="ico","✨"),
                  span(class="val", if(is.na(wx$sun)) "–" else sprintf("%.1fh", wx$sun))
              ),
              span(class="cap","Sunshine")
          ),
          
          
          # PM2.5 / PM10
          div(class="chip stack",
              div(class="row1",
                  span(class="ico", pm_ico),
                  span(class="val",
                       if(all(is.na(c(wx$pm25_mean, wx$pm10_mean)))) "–"
                       else sprintf("%s/%s",
                                    if(is.na(wx$pm25_mean)) "–" else sprintf("%.0f", wx$pm25_mean),
                                    if(is.na(wx$pm10_mean)) "–" else sprintf("%.0f", wx$pm10_mean)
                       ))
              ),
              span(class="cap","PM2.5 / PM10")
          )
      )
    }
    
    # Advisory function for warnings only
    day_advice <- function(row, acts_labels){
      
      if (nrow(row) == 0 || length(acts_labels) == 0) return(NULL)
      
      acts_keys <- unname(label_to_key[acts_labels])
      acts_keys <- acts_keys[!is.na(acts_keys)]
      
      if (length(acts_keys) == 0) return(NULL)
      
      rainy <- !is.na(row$rain) && row$rain >= 1
      maxT  <- row$tmax
      pm25  <- row$pm25_mean
      
      msgs <- character()
      is_outdoor <- any(acts_keys %in% outdoor_keys)
      
      if (rainy && is_outdoor)
        msgs <- c(msgs, "☔ Rain expected — bring an umbrella.")
      if (!is.na(maxT) && maxT < 12 && any(acts_keys %in% c("swimming","picnic","hiking")))
        msgs <- c(msgs, "🧥 It's quite cold for outdoor activities.")
      if (!is.na(maxT) && maxT >= 32 && any(acts_keys %in% c("hiking","climbing","barbecue","picnic")))
        msgs <- c(msgs, "🥵 Very hot — stay hydrated and take breaks.")
      if (!is.na(pm25) && pm25 > 35 && is_outdoor)
        msgs <- c(msgs, "😷 Poor air quality — wear a mask.")
      
      if (length(msgs) == 0) {
        return(NULL)
      }
      
      div(class="advice-warn", paste(msgs, collapse=" "))
    }
    
    # Date selection
    sel_dates <- reactive({
      req(input$range)
      rng <- as.Date(input$range)
      validate(need(diff(rng) <= 6, "You can select up to 7 days."))
      dates <- seq(rng[1], rng[2], by = "day")
      
      # Update the session data for summary tab
      session$userData$weather_dates <- dates
      if (!is.null(session$parent)) {
        session$parent$userData$weather_dates <- dates
      }
      
      dates
    })
    
    # Daily weather info
    daily <- reactive({
      ds <- sel_dates()
      calendar_feed |>
        filter(date %in% ds) |>
        mutate(
          weather = case_when(
            !is.na(rain) & rain >= 1 ~ "rainy",
            tmax >= 25 & (is.na(rain) | rain < 1) ~ "sunny",
            TRUE ~ "cloudy"
          ),
          air = case_when(
            is.na(pm25_mean) ~ "moderate",
            pm25_mean <= 15 ~ "good",
            pm25_mean <= 35 ~ "moderate",
            TRUE ~ "poor"
          ),
          temp = round(coalesce(airtemperature_bom, (tmin + tmax)/2), 1),
          pm25 = round(pm25_mean, 1)
        ) |>
        select(date, weather, temp, pm25, air)
    })
    
    air_badge <- function(a) c(good="🟢", moderate="🟡", poor="🔴")[a]
    
    # Summary table
    output$range_summary <- renderUI({
      ds <- sel_dates(); req(length(ds) > 0)
      rows <- calendar_feed |> dplyr::filter(date %in% ds) |> dplyr::arrange(date)
      
      pm_icon <- function(v){ if (is.na(v)) "⚪" else if (v<=15) "🟢" else if (v<=35) "🟡" else "🔴" }
      temp_col <- function(m){
        if (is.na(m)) "#111827" else if (m>=28) "#ef4444" else if (m>=20) "#f59e0b" else if (m>=12) "#0ea5e9" else "#2563eb"
      }
      
      tagList(
        div(class="summary-list",
            lapply(seq_len(nrow(rows)), function(i){
              r <- rows[i,]
              meanT <- coalesce(r$airtemperature_bom, (r$tmin + r$tmax)/2)
              
              div(class="row-card",
                  # date
                  div(class="date", format(r$date, "%a %d %b")),
                  # weather emoji + text
                  div(class="wx",
                      span(weather_emoji(r$rain, r$tmax)),
                      span(weather_label(r$rain, r$tmax))
                  ),
                  
                  div(class="chips summary-metrics",
                      # Temp
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico","🌡️"),
                              HTML(sprintf(
                                "<span class='val' style='color:%s'>%.0f°</span> <span class='unit'>(<span style='color:#2563eb'>%.0f°</span>–<span style='color:#ef4444'>%.0f°</span>)</span>",
                                temp_col(meanT),
                                coalesce(meanT, NA_real_),
                                coalesce(r$tmin, NA_real_), coalesce(r$tmax, NA_real_)
                              ))
                          ),
                          span(class="cap","Temp")
                      ),
                      # Rain
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico", "🌧️"),
                              span(class="val", if(is.na(r$rain)) "–" else sprintf("%.0fmm", r$rain))
                          ),
                          span(class="cap","Rainfall")
                      ),
                      # Wind
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico", "💨"),
                              span(class="val", if(is.na(r$averagewindspeed_bom)) "–" else sprintf("%.0f", r$averagewindspeed_bom)),
                              span(class="unit","km/h")
                          ),
                          span(class="cap","Wind")
                      ),
                      # Sunshine
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico","✨"),
                              span(class="val", if(is.na(r$sun)) "–" else sprintf("%.1fh", r$sun))
                          ),
                          span(class="cap","Sunshine")
                      ),
                      # PM
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico", pm_icon(r$pm25_mean)),
                              span(class="val",
                                   if(all(is.na(c(r$pm25_mean, r$pm10_mean)))) "–"
                                   else sprintf("%s / %s",
                                                if(is.na(r$pm25_mean)) "–" else sprintf("%.0f", r$pm25_mean),
                                                if(is.na(r$pm10_mean)) "–" else sprintf("%.0f", r$pm10_mean))
                              )
                          ),
                          span(class="cap","PM2.5 / PM10")
                      )
                  )
              )
            })
        )
      )
    })
    
    # Always show all activity options
    output$outdoor_list <- renderUI({
      outs <- activities |> filter(type=="outdoor") |> pull(label)
      rank_list(
        text = NULL, labels = outs, input_id = ns("pool_outdoor"),
        class = "rank-list chips pool",
        options = sortable_options(group = list(name="act", pull="clone", put=FALSE))
      )
    })
    output$indoor_list <- renderUI({
      ins <- activities |> filter(type=="indoor") |> pull(label)
      rank_list(
        text = NULL, labels = ins, input_id = ns("pool_indoor"),
        class = "rank-list chips pool",
        options = sortable_options(group = list(name="act", pull="clone", put=FALSE))
      )
    })
    
    # Build date boards
    output$itinerary_boards <- renderUI({
      ds <- sel_dates()
      div(class="itinerary-row",
          lapply(ds, function(d){
            row <- calendar_feed |> dplyr::filter(date == d) |> dplyr::slice(1)
            # NOW USES SHARED FUNCTIONS
            wx_ico <- if (nrow(row)) weather_emoji(row$rain, row$tmax) else "⛅️"
            wx_txt <- if (nrow(row)) weather_label(row$rain, row$tmax) else "Cloudy"
            
            div(class="board-col",
                tags$h6(
                  span(class="wx-ico", wx_ico), span(" "),
                  format(d, "%a %d %b")
                ),
                rank_list(
                  text = NULL, labels = NULL,
                  input_id = ns(paste0("board_", d)),
                  class = "rank-list chips board",
                  options = sortable_options(
                    group = list(name="act", pull=TRUE, put=TRUE),
                    delay = 100,
                    delayOnTouchOnly = TRUE,
                    filter = ".chip-remove",
                    preventOnFilter = TRUE,
                    onFilter = htmlwidgets::JS("
                      function(evt){
                        if (evt.target && evt.target.classList.contains('chip-remove')) {
                          var el = evt.item;
                          var list = el.closest('.rank-list.chips.board');
                          el.parentNode.removeChild(el);
                          if (list && list.id) { pushState($(list)); }
                        }
                      }
                    "),
                    onAdd = htmlwidgets::JS("
                    function(evt){
                      var list = evt.to;
                      var el   = evt.item;
                      if (!list || !list.id || !el) return;
                
                      var label = (el.textContent || '').trim();
                      var dup = Array.from(list.querySelectorAll('.rank-list-item'))
                        .some(function(n){ return n !== el && (n.textContent || '').trim() === label; });
                
                      if (dup){
                        if (el.parentNode) el.parentNode.removeChild(el); // remve
                      }
                
                      // sort by alphabet
                      var items = Array.from(list.querySelectorAll('.rank-list-item'));
                      items.sort(function(a,b){
                        var ta = (a.textContent || '').trim().toLowerCase();
                        var tb = (b.textContent || '').trim().toLowerCase();
                        return ta.localeCompare(tb);
                      });
                      items.forEach(function(n){ list.appendChild(n); });
                
                      // synchronised
                      if (typeof pushState === 'function') pushState($(list));
                    }
                  "),
                    onRemove = htmlwidgets::JS("
                    function(evt){ // moved away
                      var from = evt.from;
                      if (from && from.id) pushState($(from));
                    }
                  ")
                  )
                ),
                uiOutput(ns(paste0("advice_", d)))
            )
          })
      )
    })
    
    # Show/Remove advisory messages
    observe({
      ds <- sel_dates()
      lapply(ds, function(d){
        local({
          dd <- d
          
          observeEvent(
            {
              input[[paste0("board_", dd)]]
              input[[paste0("board_", dd, "_changed")]]
              input[[paste0("board_", dd, "_length")]]
              input[[paste0("board_", dd, "_has_outdoor")]] 
            },
            {
              output[[paste0("advice_", dd)]] <- renderUI({
                labels <- input[[paste0("board_", dd)]] %||% character(0)
                
                # for debugging
                # cat("Date:", dd, "| Activities:", length(labels), "| Labels:", paste(labels, collapse=", "), "\n")
                
                has_out <- input[[paste0("board_", dd, "_has_outdoor")]]
                if (identical(has_out, FALSE)) return(NULL)
                
                # If no outdoor activities, hide advice
                if (!is_outdoor_present(labels)) {
                  return(NULL)
                }
                
                wx <- calendar_feed |> dplyr::filter(date == dd) |> dplyr::slice(1)
                
                # Pass only outdoor activity labels to day_advice
                keys <- to_keys(labels)
                outdoor_labels <- labels[keys %in% outdoor_keys]
                advice_result <- day_advice(wx, outdoor_labels)
                
                # for debugging
                #cat("Advice result is NULL:", is.null(advice_result), "\n")
                
                if (is.null(advice_result)) return(NULL)
                advice_result
              })
            },
            ignoreNULL = FALSE,  # Changed to FALSE to track removals
            ignoreInit = FALSE   # Changed to FALSE to show advice on initial load
          )
        })
      })
    })
    
    # Return reactive values for external access
    return(
      list(
        selected_dates = reactive(sel_dates()),
        # NEW: Get activities for a specific date using theme_data
        get_activities_for_date = function(date) {
          date_str <- as.character(date)
          input_id <- paste0("board_", date_str)
          activity_labels <- input[[input_id]] %||% character(0)
          
          if (length(activity_labels) > 0) {
            # Map activity labels to theme_data categories
            activity_to_theme <- list(
              "🏛️ museum" = c("Arts & Culture", "Heritage"),
              "🖼️ exhibition" = c("Arts & Culture"),
              "☕️ cafe & restaurant" = c("Food & Drink"),
              "🍖 barbecue" = c("Leisure", "Parks & Gardens"),
              "🥾 hiking" = c("Parks & Gardens", "Leisure"),
              "🧺 picnic" = c("Parks & Gardens", "Leisure"),
              "🧗 climbing" = c("Leisure", "Sports"),
              "🏊️ swimming" = c("Leisure", "Sports")
            )
            
            # Get all relevant themes for the selected activities
            relevant_themes <- unique(unlist(activity_to_theme[activity_labels]))
            
            if (length(relevant_themes) > 0) {
              # Find matching places from theme_data
              matching_places <- theme_data %>%
                filter(Theme %in% relevant_themes) %>%
                distinct(Name, .keep_all = TRUE) %>%
                # Use date to create consistent but varied selection
                slice_sample(n = min(3, nrow(.))) %>%
                arrange(Name)
              
              # Convert to activity format
              if (nrow(matching_places) > 0) {
                activities <- lapply(1:nrow(matching_places), function(i) {
                  place <- matching_places[i, ]
                  
                  place_name <- if (!is.null(place$Name)) place$Name else "Melbourne Activity"
                  place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
                  place_rating <- if (!is.null(place$Google_Rating)) place$Google_Rating else NA
                  
                  # Create appropriate time slots
                  time_slots <- c("9:00 AM - 11:00 AM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
                  time_slot <- time_slots[min(i, length(time_slots))]
                  
                  # Special timing for food places
                  if (!is.null(place$Theme) && place$Theme == "Food & Drink") {
                    if (grepl("cafe|coffee", place_subtheme, ignore.case = TRUE)) {
                      time_slot <- if (i == 1) "9:00 AM - 11:00 AM" else "3:00 PM - 5:00 PM"
                    } else {
                      time_slot <- if (i == 1) "12:00 PM - 2:00 PM" else "6:00 PM - 8:00 PM"
                    }
                  }
                  
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
                return(activities)
              }
            }
          }
          
          list() # Return empty list if no activities or no matches
        }
      )
    )
  })
}