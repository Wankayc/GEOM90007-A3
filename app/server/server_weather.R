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
# Trip tab UI

trip_tab_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h2("Trip-Weather Planner"),
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
        tags$small(class="text-muted d-block mb-2","Drag options into each date box"),
        fluidRow(
          column(6, h5("Outdoor activities"), uiOutput(ns("outdoor_list"))),
          column(6, h5("Indoor activities"),  uiOutput(ns("indoor_list")))
        )
    ),
    
    div(class = "card p-3",
        h4("Activity Planner"),
        uiOutput(ns("itinerary_boards"))
    ),
    
    tags$style(HTML("
      /* cards: minimal design */
      .card { border:1px solid #e5e7eb; border-radius:14px; box-shadow:none; }
    
      /* datepicker size adjustments */
      .air-datepicker-global-container, .air-datepicker { font-size:16px; }
      .air-datepicker--content { padding:14px 16px; }
      .air-datepicker-cell.-day- { height:44px; position:relative; }
      .air-datepicker-cell.-disabled- { color:#9aa3ad!important; background:#f3f5f7!important; cursor:not-allowed!important; opacity:.7; }
    
      /* itinerary board layout */
      .itinerary-row {
        display:flex; gap:16px; flex-wrap:nowrap;
        overflow-x:auto; padding-bottom:6px;
      }
      .board-col { flex:1 0 14%; min-width:220px; }
      .board-col h6 { margin:0 0 .4rem 0; font-weight:700; color:#111827; }
      .board-col .rank-list.dropzone {
        min-height:92px; border:1px dashed #d1d5db;
        border-radius:12px; background:#fafafa;
      }
    
      /* drag lists (pool/board) styled as chips */
      .rank-list.chips.pool {
        min-height:84px; border:1px dashed #d1d5db;
        border-radius:12px; padding:8px; background:#fff;
      }
      .rank-list.chips.board {
        min-height:92px; border:1px dashed #d1d5db;
        border-radius:12px; padding:8px; background:#fafafa;
      }
      .rank-list .rank-list-item {
        padding:6px 10px; border-radius:9999px;
        border:1px solid #e5e7eb; background:#fff; font-weight:600;
      }
    
      /* chip bar for daily weather summary */
      .metrics-row {
        display:flex; gap:8px; flex-wrap:wrap;
        margin:.25rem 0 .5rem 0;
      }
      .chip {
        display:inline-flex; align-items:center; gap:6px;
        padding:6px 10px; border:1px solid #e5e7eb;
        border-radius:9999px; background:#fff;
      }
      .chip .ico { font-size:1.05rem; line-height:1; }
      .chip .val { font-weight:700; font-size:.95rem; color:#111827; }
      .chip .sub { font-size:.75rem; color:#6b7280; }
      .chip.muted { background:#f8fafc; border-color:#e5e7eb; }
    
      /* ===== simple, compact tables ===== */
      .table-clean.table-sm>tbody>tr>td,
      .table-clean>thead>tr>th {
        padding: .25rem .6rem;   /* tighter cell padding */
        vertical-align: middle;  /* center vertically */
      }
      .table-clean {
        border-collapse: separate;
        border-spacing: 0;
      }
      .text-right { text-align: right; }
      
            
      /* ---- compact data table tweaks ---- */
      .table-clean th,
      .table-clean td { vertical-align: middle; }
      
      .col-num { text-align: right; white-space: nowrap; }
      .col-left { text-align: left;  }
      
      .wx-cell { display:flex; align-items:center; gap:.4rem; }
      .wx-ico  { font-size:1.05rem; line-height:1; }
      
      .temp-cell .mean { font-weight:800; }
      .temp-cell .min  { color:#2563eb; font-weight:600; }  /* blue */
      .temp-cell .max  { color:#ef4444; font-weight:600; }  /* red  */
      
      .pm-badge{ display:inline-flex; align-items:center; gap:.35rem; }
      
      /* activity chips — keep the original look */
      .rank-list.chips.pool .rank-list-item{
        display:inline-block;
        margin:6px 8px 0 0; padding:8px 12px;
        background:#eaf7f0;
        color:#0f5132; border:1px solid #b7e4c7;
        border-radius:999px; font-weight:600;
        box-shadow:0 2px 6px rgba(16,185,129,.10);
        cursor:grab; user-select:none;
      }
      .rank-list.chips.board .rank-list-item{
        display:inline-block;
        margin:6px 8px 0 0; padding:8px 12px;
        background:#f1edff;
        color:#3b3070; border:1px solid #d6ccff;
        border-radius:999px; font-weight:600;
        box-shadow:0 2px 6px rgba(99,102,241,.12);
        cursor:grabbing; user-select:none;
      }
      
      /* stacked chip: value on top, small caption below */
      .chip.stack{
        display:inline-flex; flex-direction:column; align-items:flex-start;
        gap:2px; padding:6px 10px; border:1px solid #e5e7eb;
        border-radius:9999px; background:#fff;
      }
      .chip.stack .row1{display:flex; align-items:center; gap:6px; line-height:1}
      .chip .ico{font-size:1.05rem; line-height:1}
      .chip .val{font-weight:700; font-size:.95rem; color:#111827}
      .chip .unit{font-size:.8rem; color:#6b7280}
      .chip .cap{
        display:block; font-size:.70rem; color:#94a3b8;
        text-transform:uppercase; letter-spacing:.04em; font-weight:700;
      }
      
      .wx-ico { font-size:1.05rem; line-height:1; margin-right:.15rem; }
      
      /* summary row cards */
      .summary-list{ display:flex; flex-direction:column; gap:10px; }
      .row-card{
        display:flex; align-items:center; gap:12px; padding:10px 12px;
        background:#fff; border:1px solid #e5e7eb; border-radius:14px;
      }
      .row-card .date{ width:140px; font-weight:700; }
      .row-card .wx{ display:flex; align-items:center; gap:6px; width:110px; color:#334155; }
      .row-card .chips{ display:flex; flex-wrap:wrap; gap:8px; }

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
    
    tags$script(HTML("
    (function(){
      function esc(id){ return '#'+id.replace(/([:\\.\\[\\],])/g, '\\\\$1'); }
  
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
  
      function findNode(id){
        var el = document.querySelector(esc(id));
        if (el) return el;
        var air = document.querySelector(esc(id + '-air'));
        if (air) return air;
        var el2 = document.querySelector(esc(id) + ' + .air-datepicker');
        if (el2) return el2;
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
          var nodeAir = findNode(id + '-air');
          dp = getInstanceFromNode(nodeAir);
        }
        if (!dp) return false;
  
        var d = new Date(y, (m||1)-1, 1);
  
        if (typeof dp.setViewDate === 'function'){ dp.setViewDate(d); return true; }
        if ('viewDate' in dp && typeof dp.update === 'function'){ dp.viewDate = d; dp.update(); return true; }
        if (typeof dp.selectDate === 'function'){
          var curValue = (node.tagName === 'INPUT') ? node.value : undefined;
          dp.selectDate(d, { silent: true });
          if (curValue !== undefined) node.value = curValue;
          return true;
        }
        return false;
      }
  
      Shiny.addCustomMessageHandler('airdp-set-view', function(p){
        var ok = setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month);
        if (ok) return;
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 50);
        setTimeout(function(){ setViewById(p.id, p.year, p.month) || setViewById(p.id + '-air', p.year, p.month); }, 150);
      });
    })();
  ")),
    
    tags$script(HTML("
  (function(){
    //debug
    //console.log('Activity planner loaded');
    
    function valuesOf($list){
      return $list.find('.rank-list-item')
                  .map(function(){ return $(this).text().trim(); })
                  .get();
    }
    
    function pushState($list){
      if (!$list || $list.length === 0) return;
      var id = $list.attr('id'); 
      if(!id) return;
      
      var vals = valuesOf($list);
      
      //console.log('pushState:', id, '| Count:', vals.length);
      
      // send status to Shiny
      Shiny.setInputValue(id, vals.length > 0 ? vals : null, {priority:'event'});
      Shiny.setInputValue(id + '_length', vals.length, {priority:'event'});
      Shiny.setInputValue(id + '_changed', Math.random(), {priority:'event'});
      
      // if zero activity, remove it
      if (vals.length === 0) {
        var adviceId = id.replace('rank-list-trip-board_', 'trip-advice_');
        
        console.log('Original ID:', id);
        console.log('Advice ID:', adviceId);
        
        setTimeout(function(){
          var el = document.getElementById(adviceId);
          if (el) {
            el.innerHTML = '';
            console.log('Advice cleared!');
          } else {
            console.log('Not found:', adviceId);
          }
        }, 10);
      }
    }
  
    // when click
    $(document).on('click', '.rank-list.chips.board .rank-list-item', function(e){
      console.log('CLICK DETECTED!');
      e.preventDefault();
      e.stopPropagation();
      
      var $item = $(this);
      var $list = $item.closest('.rank-list.chips.board');
      
      console.log('List ID:', $list.attr('id'));
      console.log('Removing item:', $item.text().trim());
      
      $item.remove();
      pushState($list);
      
      return false;
    });
  
    const obs = new MutationObserver(function(muts){
      muts.forEach(function(m){
        if (m.type === 'childList') {
          var list = m.target.closest('.rank-list.chips.board');
          if (list && list.id) {
            pushState($(list));
          }
        }
      });
    });

  })();
  ")),
    
    tags$style(HTML("
    .rank-list.chips.board .rank-list-item{ cursor:pointer; }
  "))
    
  )
}

trip_tab_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Activity list (all)
    activities <- tibble::tibble(
      key   = c("barbecue","hiking","picnic","climbing","swimming",
                "museum","exhibition","cafe","restaurant"),
      label = c("🍖 barbecue","🥾 hiking","🧺 picnic","🧗 climbing","🏊️ swimming",
                "🏛️ museum","🖼️ exhibition","☕️ cafe","🍽️ restaurant"),
      type  = c(rep("outdoor",5), rep("indoor",4))
    )
    
    # to handle emozi -> convert UTF-8
    activities$label <- enc2utf8(activities$label)
    
    label_to_key <- setNames(activities$key, activities$label)
    outdoor_keys <- activities |> dplyr::filter(type=="outdoor") |> dplyr::pull(key)
    to_keys <- function(lbls) {
      v <- unname(label_to_key[lbls])
      v[is.na(v)] <- lbls
      v
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
      noise_ico<- if(is.na(wx$noise_mean)) "🔇"
      else if(wx$noise_mean <= 55) "🔉"
      else if(wx$noise_mean <= 70) "🔊" else "📢"
      
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
          
          # Sunshine
          div(class="chip stack",
              div(class="row1",
                  span(class="ico","✨"),
                  span(class="val", if(is.na(wx$sun)) "–" else sprintf("%.1fh", wx$sun))
              ),
              span(class="cap","Sunshine")
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
          ),
          
          # Noise
          div(class="chip stack",
              div(class="row1",
                  span(class="ico", noise_ico),
                  span(class="val", if(is.na(wx$noise_mean)) "–" else sprintf("%.0f", wx$noise_mean)),
                  span(class="unit","dB")
              ),
              span(class="cap","Noise")
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
          temp = round(coalesce(airtemperature_bom, (tmin + tmax)/2), 1),
          pm25 = round(pm25_mean, 1)
        ) |>
        select(date, weather, temp, pm25, air)
    })
    
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
                  
                  div(class="chips",
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
                      # Sunshine
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico","✨"),
                              span(class="val", if(is.na(r$sun)) "–" else sprintf("%.1fh", r$sun))
                          ),
                          span(class="cap","Sunshine")
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
                      ),
                      # Noise
                      div(class="chip stack",
                          div(class="row1",
                              span(class="ico", if(is.na(r$noise_mean)) "🔇" else if(r$noise_mean<=55) "🔉" else if(r$noise_mean<=70) "🔊" else "📢"),
                              span(class="val", if(is.na(r$noise_mean)) "–" else sprintf("%.0f", r$noise_mean)),
                              span(class="unit","dB")
                          ),
                          span(class="cap","Noise")
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
                  options = sortable_options(group = list(name="act", pull=TRUE, put=TRUE))
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
            },
            {
              output[[paste0("advice_", dd)]] <- renderUI({
                labels <- input[[paste0("board_", dd)]] %||% character(0)
                
                # for debugging
                # cat("Date:", dd, "| Activities:", length(labels), "| Labels:", paste(labels, collapse=", "), "\n")
                
                if (length(labels) == 0) {
                  cat("Returning NULL - no activities\n")
                  return(tags$div())
                }
                
                wx <- calendar_feed |> dplyr::filter(date == dd) |> dplyr::slice(1)
                advice_result <- day_advice(wx, labels)
                
                # for debugging
                # cat("Advice result is NULL:", is.null(advice_result), "\n")
                
                if (is.null(advice_result)) {
                  return(tags$div())
                }
                
                return(advice_result)
              })
            },
            ignoreNULL = FALSE,
            ignoreInit = TRUE
          )
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
