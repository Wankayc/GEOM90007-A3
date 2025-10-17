# Weather server logic will go here

# install.packages(c("shiny","bslib","shinyWidgets","sortable","lubridate","dplyr","tidyr","stringr"))

library(shiny)
library(bslib)
library(shinyWidgets)
library(sortable)
library(readr)
library(dplyr)
library(lubridate)
library(tidyr)
library(stringr)
library(later)

# Summarise metrics for a selected period
summarise_period_box <- function(feed, start_date, end_date) {
  d <- feed |> filter(date >= start_date, date <= end_date)
  tibble::tibble(
    avg_max_temp = mean(d$tmax, na.rm=TRUE),
    avg_min_temp = mean(d$tmin, na.rm=TRUE),
    avg_rain_mm  = mean(d$rain, na.rm=TRUE),
    pm25_text  = if (all(is.na(d$pm25_mean))) "—"
    else sprintf("%.1f µg/m³ (%.0f–%.0f)",
                 mean(d$pm25_mean, na.rm=TRUE),
                 min(d$pm25_min,  na.rm=TRUE),
                 max(d$pm25_max,  na.rm=TRUE)),
    noise_text = if (all(is.na(d$noise_mean))) "—"
    else sprintf("%.1f dB (%.0f–%.0f)",
                 mean(d$noise_mean, na.rm=TRUE),
                 min(d$noise_min,  na.rm=TRUE),
                 max(d$noise_max,  na.rm=TRUE)),
    dry_0mm    = mean(d$rain == 0, na.rm=TRUE) * 100,
    rain_ge_2  = mean(d$rain >= 2,  na.rm=TRUE) * 100,
    rain_ge_5  = mean(d$rain >= 5,  na.rm=TRUE) * 100,
    rain_ge_10 = mean(d$rain >= 10, na.rm=TRUE) * 100,
    rain_ge_25 = mean(d$rain >= 25, na.rm=TRUE) * 100
  )
}

#------------------------------------------------------------#
## ---- File paths (adjust for your folders) ----
BOM_DIR   <- "./"
SENSOR_CSV<- "microclimate-sensors-data.csv"

## ---- BOM loader ----
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
      t9   = `9am Temperature (°C)`,
      t3   = `3pm Temperature (°C)`,
      rh9  = `9am relative humidity (%)`,
      rh3  = `3pm relative humidity (%)`,
      ws9  = `9am wind speed (km/h)`,
      ws3  = `3pm wind speed (km/h)`,
      p9   = `9am MSL pressure (hPa)`,
      p3   = `3pm MSL pressure (hPa)`,
      sun  = `Sunshine (hours)`
    )
  
  num_cols <- c("tmin","tmax","rain","t9","t3","rh9","rh3","ws9","ws3","p9","p3","sun")
  
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

## ---- Microclimate (15-min) → daily summary ----
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
    select(date, averagewindspeed, airtemperature, relativehumidity,
           atmosphericpressure, pm25, pm10, noise) |>
    group_by(date) |>
    summarise(
      across(c(averagewindspeed, airtemperature, relativehumidity,
               atmosphericpressure, pm25, pm10, noise),
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

## ---- Data preprocessing ----
bom_daily <- read_bom_range(BOM_DIR)

bom_for_join <- bom_daily |>
  mutate(
    airtemperature_bom   = rowMeans(cbind(t9, t3),  na.rm=TRUE),
    relativehumidity_bom = rowMeans(cbind(rh9, rh3),na.rm=TRUE),
    averagewindspeed_bom = rowMeans(cbind(ws9, ws3),na.rm=TRUE),
    atmosphericpressure_bom = rowMeans(cbind(p9, p3),na.rm=TRUE)
  ) |>
  select(date, tmin, tmax, rain,
         airtemperature_bom, relativehumidity_bom,
         averagewindspeed_bom, atmosphericpressure_bom)

sensor_daily <- read_microclimate_daily(SENSOR_CSV)

make_calendar_feed <- function(bom_for_join, sensor_daily) {
  bom_for_join |>
    left_join(sensor_daily, by = "date") |>
    transmute(
      date,
      airtemperature       = coalesce(airtemperature_bom, airtemperature_mean),
      relativehumidity     = coalesce(relativehumidity_bom, relativehumidity_mean),
      averagewindspeed     = coalesce(averagewindspeed_bom, averagewindspeed_mean),
      atmosphericpressure  = coalesce(atmosphericpressure_bom, atmosphericpressure_mean),
      tmin, tmax, rain,
      pm25_mean,  pm25_min,  pm25_max,
      pm10_mean,  pm10_min,  pm10_max,
      noise_mean, noise_min, noise_max
    )
}

calendar_feed <- make_calendar_feed(bom_for_join, sensor_daily)

#------------------------------------------------------------#
# Trip tab UI

trip_tab_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Trip Planner"),
    fluidRow(
      column(
        width = 4,
        div(class = "card p-3",
            airDatepickerInput(
              inputId = ns("range"),
              label = NULL,
              value = NULL,
              minDate = as.Date("2024-09-01"),
              maxDate = as.Date("2025-10-31"),
              range = TRUE, inline = TRUE, autoClose = TRUE,
              width = "100%"
            )
        )
      ),
      column(
        width = 8,
        div(class = "card p-3",
            uiOutput(ns("range_summary"))
        )
      )
    ),
    
    br(),
    div(class = "card p-3",
        h4("Activity Planner (drag options into each date box)"),
        uiOutput(ns("itinerary_boards")),
        tags$hr(),
        fluidRow(
          column(6, h5("Outdoor activities"), uiOutput(ns("outdoor_list"))),
          column(6, h5("Indoor activities"),  uiOutput(ns("indoor_list")))
        )
    ),
    
    tags$style(HTML("
    .card { border:1px solid #1f334a20; border-radius:14px; box-shadow:0 2px 10px #0000000d;}
    .year-compact .bootstrap-select>.dropdown-toggle{
      padding:.25rem .5rem; font-size:.875rem; line-height:1.2; min-width:120px;
    }
  
    .air-datepicker-global-container, .air-datepicker { font-size:16px; }
    .air-datepicker--content { padding:14px 16px; }
    .air-datepicker-cell.-day- { height:44px; position:relative; }
    .air-datepicker-cell.-disabled- { color:#9aa3ad!important; background:#f3f5f7!important; cursor:not-allowed!important; opacity:.7; }
    .wd-sunny::after  { content:'☀️'; position:absolute; right:4px; bottom:2px; font-size:16px; }
    .wd-cloudy::after { content:'⛅️'; position:absolute; right:4px; bottom:2px; font-size:16px; }
    .wd-rainy::after  { content:'🌧️'; position:absolute; right:4px; bottom:2px; font-size:16px; }
  
    .itinerary-row{display:flex; gap:16px; flex-wrap:nowrap; overflow-x:auto; padding-bottom:6px;}
    .board-col{flex:1 0 14%; min-width:220px;}
    .board-col .rank-list.dropzone{min-height:120px; border:2px dashed #a6b4c8; border-radius:14px; background:#fafcff;}
  
    .rank-list.chips.pool { min-height: 120px; border:1px dashed #bcd; border-radius:12px; padding:10px; }
    .rank-list.chips.pool .rank-list-item{
      display:inline-block;
      margin:6px 8px 0 0; padding:8px 12px;
      background:#eaf7f0;              
      color:#0f5132; border:1px solid #b7e4c7;
      border-radius:999px; font-weight:500;
      box-shadow:0 2px 6px rgba(16,185,129,.10);
      cursor:grab; user-select:none;
    }
    .rank-list.chips.pool .rank-list-item:hover{ transform:translateY(-1px); }
    
    .rank-list.chips.board { min-height: 120px; border:1px dashed #9bb; border-radius:12px; padding:10px; }
    .rank-list.chips.board .rank-list-item{
      display:inline-block;
      margin:6px 8px 0 0; padding:8px 12px;
      background:#f1edff;           
      color:#3b3070; border:1px solid #d6ccff;
      border-radius:999px; font-weight:500;
      box-shadow:0 2px 6px rgba(99,102,241,.12);
      cursor:grabbing; user-select:none;
      }
      
    .rank-list .rank-list-item{ white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    
    .itinerary-row{ scrollbar-color:#c7d2fe transparent; scrollbar-width:thin; }
  
    .badges-row{display:flex; gap:8px; flex-wrap:wrap; margin:4px 0 10px 0;}
    .badge{display:inline-block; padding:4px 10px; border-radius:9999px; font-size:.85rem; font-weight:600;}
    .badge.wx{background:#e2e8f0; color:#111827;}
    
    .badge.info{
      background:#dbeafe; color:#0b3b7a; border:1px solid #93c5fd;
    }
  
    /* advice */
    .advice-warn{margin-top:8px; border-left:4px solid #f59e0b; background:#fff7ed; padding:8px 10px; border-radius:8px;}
    ")),
    
    tags$script(HTML("
      (function(){
        function decorate(map){
          if(!map) return;
          const cells = document.querySelectorAll('.air-datepicker .air-datepicker-cell.-day-');
          cells.forEach(function(cell){
            const d = cell.getAttribute('data-date');
            cell.classList.remove('wd-sunny','wd-cloudy','wd-rainy');
            for (let i=0;i<map.length;i++){
              if (map[i].date === d) { cell.classList.add(map[i].class); break; }
            }
          });
        }
        window.__wdMap = [];
        Shiny.addCustomMessageHandler('decorateCalendar', function(map){
          window.__wdMap = map || []; decorate(window.__wdMap);
        });
        const obs = new MutationObserver(function(){ decorate(window.__wdMap); });
        obs.observe(document.body, {subtree:true, childList:true});
      })();
    ")),
    
    # JS: move Air Datepicker's visible month/year (robust instance lookup)
    tags$script(HTML("
    (function(){
      function esc(id){ return '#'+id.replace(/([:\\.\\[\\],])/g, '\\\\$1'); }
  
      // Try to pull an ADP instance from a DOM node (many variants exist…)
      function getInstanceFromNode(node){
        if (!node) return null;
        var $n = $(node);
        return (
          $n.data('datepicker')    ||
          $n.data('airDatepicker') ||
          $n.data('adp')           ||
          node._airDatepicker      ||
          node.adp                 ||
          node.datepicker          ||
          null
        );
      }
  
      // Find a candidate element by id; also try sibling/nearby containers like '#id-air'
      function findNode(id){
        var el = document.querySelector(esc(id));
        if (el) return el;
        // inline container that shinyWidgets creates often uses '-air'
        var air = document.querySelector(esc(id + '-air'));
        if (air) return air;
        // sometimes the calendar is the next sibling with class 'air-datepicker'
        var el2 = document.querySelector(esc(id) + ' + .air-datepicker');
        if (el2) return el2;
        // last resort: any .air-datepicker under the same parent
        var parent = document.querySelector(esc(id))?.parentElement;
        if (parent){
          var any = parent.querySelector('.air-datepicker');
          if (any) return any;
        }
        return null;
      }
  
      function setViewById(id, y, m){
        var node = findNode(id);
        if (!node) return false;
  
        var dp = getInstanceFromNode(node) || getInstanceFromNode($(node).prev()[0]);
        if (!dp){
          // try also the '-air' container explicitly
          var nodeAir = findNode(id + '-air');
          dp = getInstanceFromNode(nodeAir);
        }
        if (!dp) return false;
  
        var d = new Date(y, (m||1)-1, 1);
  
        // v3 API
        if (typeof dp.setViewDate === 'function'){ dp.setViewDate(d); return true; }
        // some builds: viewDate + update()
        if ('viewDate' in dp && typeof dp.update === 'function'){ dp.viewDate = d; dp.update(); return true; }
        // last resort: selectDate silently (restore input text)
        if (typeof dp.selectDate === 'function'){
          var curValue = (node.tagName === 'INPUT') ? node.value : undefined;
          dp.selectDate(d, { silent: true });
          if (curValue !== undefined) node.value = curValue;
          return true;
        }
        return false;
      }
  
      Shiny.addCustomMessageHandler('airdp-set-view', function(p){
        // try both '#id' and '#id-air'
        var ok = setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month);
        if (ok) return;
        // widget not ready yet? retry a couple of times
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 50);
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 150);
      });
    })();
  "))
    
    
  )
}

trip_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Activity list (all always shown)
    activities <- tibble::tibble(
      key   = c("barbecue","hiking","picnic","climbing","swimming",
                "museum","exhibition","cafe_restaurant"),
      label = c("🍖 barbecue","🥾 hiking","🧺 picnic","🧗‍♀️ climbing","🏊‍♀️ swimming",
                "🏛️ museum","🖼️ exhibition","☕️ cafe/restaurant"),
      type  = c(rep("outdoor",5), rep("indoor",3))
    )
    
    label_to_key <- setNames(activities$key, activities$label)
    outdoor_keys <- activities |> dplyr::filter(type=="outdoor") |> dplyr::pull(key)
    to_keys <- function(lbls) {
      v <- unname(label_to_key[lbls])
      v[is.na(v)] <- lbls
      v
    }
    
    day_badges <- function(row){
      wx <- if (nrow(row)==0) return(NULL) else row
      icon <- if (!is.na(wx$rain) && wx$rain >= 1) "🌧️" else if (!is.na(wx$tmax) && wx$tmax >= 25) "☀️" else "⛅️"
      pm_txt <- if (is.na(wx$pm25_min) && is.na(wx$pm25_max)) "PM2.5 –"
      else sprintf("PM2.5 %.1f (%.0f–%.0f)", wx$pm25_mean, wx$pm25_min, wx$pm25_max)
      tagList(
        span(class="badge wx", icon),
        span(class="badge info", sprintf("Min %.1f°C", wx$tmin)),
        span(class="badge info", sprintf("Max %.1f°C", wx$tmax)),
        span(class="badge info", sprintf("Rain %.1f mm", coalesce(wx$rain,0))),
        span(class="badge info", pm_txt)
      )
    }
    
    # Advisory function for warnings only
    day_advice <- function(row, acts_labels){
      if (nrow(row)==0 || length(acts_labels)==0) return(NULL)
      acts_keys <- unname(label_to_key[acts_labels])
      acts_keys <- acts_keys[!is.na(acts_keys)]
      
      rainy <- !is.na(row$rain) && row$rain >= 1
      maxT  <- row$tmax
      pm25  <- row$pm25_mean
      
      msgs <- character()
      is_outdoor <- any(acts_keys %in% outdoor_keys)
      
      if (rainy && is_outdoor)
        msgs <- c(msgs, "☔ Rain expected — bring an umbrella.")
      if (!is.na(maxT) && maxT < 12 && any(acts_keys %in% c("swimming","picnic","hiking")))
        msgs <- c(msgs, "🧥 It’s quite cold for outdoor activities.")
      if (!is.na(maxT) && maxT >= 32 && any(acts_keys %in% c("hiking","climbing","barbecue","picnic")))
        msgs <- c(msgs, "🥵 Very hot — stay hydrated and take breaks.")
      if (!is.na(pm25) && pm25 > 35 && is_outdoor)
        msgs <- c(msgs, "😷 Poor air quality — wear a mask.")
      
      if (length(msgs))
        div(class="advice-warn", paste(msgs, collapse=" "))
    }
    
    # Date selection
    sel_dates <- reactive({
      req(input$range)
      rng <- as.Date(input$range)
      validate(need(diff(rng) <= 6, "You can select up to 7 days."))
      seq(rng[1], rng[2], by = "day")
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
          temp = round(coalesce(airtemperature, (tmin + tmax)/2), 1),
          pm25 = round(pm25_mean, 1)
        ) |>
        select(date, weather, temp, pm25, air)
    })
    
    weather_emoji <- function(w) c(sunny="☀️", cloudy="⛅️", rainy="🌧️")[w]
    air_badge <- function(a) c(good="🟢", moderate="🟡", poor="🔴")[a]
    
    # Summary table
    output$range_summary <- renderUI({
      df <- daily(); req(nrow(df) > 0)
      tags$table(class="table table-sm",
                 tags$thead(tags$tr(
                   tags$th("Date"),
                   tags$th("Weather"),
                   tags$th("Temp (°C)"),
                   tags$th("PM2.5"),
                   tags$th("Air Quality")
                 )),
                 tags$tbody(
                   lapply(seq_len(nrow(df)), function(i){
                     tags$tr(
                       tags$td(format(df$date[i], "%a %d %b")),
                       tags$td(paste0(weather_emoji(df$weather[i]), " ", str_to_title(df$weather[i]))),
                       tags$td(df$temp[i]),
                       tags$td(df$pm25[i]),
                       tags$td(paste0(air_badge(df$air[i]), " ", str_to_title(df$air[i])))
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
            row <- calendar_feed |> filter(date == d) |> slice(1)
            div(class="board-col",
                tags$h6(format(d, "%a %d %b")),
                div(class="badges-row", day_badges(row)),
                rank_list(
                  text = NULL, labels = NULL,
                  input_id = ns(paste0("board_", d)),
                  class = "rank-list chips board",
                  options = sortable_options(group = list(name="act", pull=TRUE, put=TRUE))
                )
                ,
                uiOutput(ns(paste0("advice_", d)))
            )
          })
      )
    })
    
    # Show advisory messages (no filtering)
    observe({
      ds <- sel_dates()
      lapply(ds, function(d){
        local({
          dd <- d
          output[[paste0("advice_", dd)]] <- renderUI({
            labels <- input[[paste0("board_", dd)]] %||% character(0)
            wx <- calendar_feed |> dplyr::filter(date == dd) |> dplyr::slice(1)
            day_advice(wx, labels)
          })
        })
      })
    })
  })
}

ui <- page_fillable(
  theme = bs_theme(version = 5, primary = "#1f334a"),
  trip_tab_ui("trip")
)
server <- function(input, output, session) {
  trip_tab_server("trip")
}
shinyApp(ui, server)
