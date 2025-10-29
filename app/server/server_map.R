# ============================================================================
# server/server_map.R - FIXED VERSION
# 修复：处理Windows回车符(\r)导致时间解析失败的问题
# ============================================================================
# ---------- Helper: Operating Hours Filter (ANY Overlap) -------------------
# ============================================================================
`%||%` <- function(a, b) if (is.null(a)) b else a

# ============================================================================
# ---------- Helper: Operating Hours Filter (STRICT COVERAGE) ---------------
# 餐厅必须在用户选择的整个时间段内都营业
# ============================================================================
`%||%` <- function(a, b) if (is.null(a)) b else a

filter_by_operating_hours_csv <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  if (!("opening_time" %in% names(df)) || !("closing_time" %in% names(df))) return(df)
  
  # 讀取 UI 狀態（小時 -> 分鐘）
  rng <- tryCatch(input$time_filter %||% c(0, 24), error = function(e) c(0, 24))
  include_unknown <- tryCatch(isTRUE(input$include_unknown_hours), error = function(e) TRUE)
  range_min <- as.integer(rng[1] * 60L)
  range_max <- as.integer(rng[2] * 60L)
  
  # ---- Helper: Parse time string to minutes --------------------------------
  to_minutes_one <- function(x) {
    if (is.na(x)) return(NA_integer_)
    
    # 强力清理 - 删除所有空白字符
    s <- gsub("[\\s\\r\\n\\t]+", "", as.character(x))
    
    if (identical(s, "") || tolower(s) %in% c("na","nan","none")) return(NA_integer_)
    
    # 如果看起来像评分，返回NA
    if (grepl("^[0-9]+(\\.[0-9]+)?$", s)) return(NA_integer_)
    
    parts <- strsplit(s, ":", fixed = TRUE)[[1]]
    h <- suppressWarnings(as.integer(parts[1]))
    m <- if (length(parts) > 1) suppressWarnings(as.integer(parts[2])) else 0L
    if (is.na(h) || is.na(m) || h < 0L || h > 24L || m < 0L || m > 59L) return(NA_integer_)
    
    # 24:00 treated as end of day (23:59)
    if (h == 24L && m == 0L) return(23L*60L + 59L)
    h*60L + m
  }
  to_minutes <- function(v) vapply(v, to_minutes_one, integer(1))
  
  # ---- Convert times to minutes ---------------------------------------------
  df$open_min  <- to_minutes(df$opening_time)
  df$close_min <- to_minutes(df$closing_time)
  
  # ---- Main filtering logic (STRICT COVERAGE) -------------------------------
  keep <- logical(nrow(df))
  match_count <- 0
  no_match_count <- 0
  
  for (i in seq_len(nrow(df))) {
    o <- df$open_min[i]
    c <- df$close_min[i]
    
    # Unknown hours
    if (is.na(o) || is.na(c)) {
      keep[i] <- include_unknown
      next
    }
    
    # Normal case: does not cross midnight (open <= close)
    if (c >= o) {
      # ⭐ STRICT COVERAGE: 餐厅必须在用户选择的整个时间段内营业
      # 开门时间 <= 用户开始时间 AND 关门时间 >= 用户结束时间
      coverage <- (o <= range_min) && (c >= range_max)
      keep[i] <- coverage
      
      # Debug first few matches and non-matches
      if (coverage && match_count < 5) {
        match_count <- match_count + 1
        cat(sprintf("✅ Match #%d: %02d:%02d-%02d:%02d covers %02d:%02d-%02d:%02d\n",
                    match_count,
                    o %/% 60, o %% 60, c %/% 60, c %% 60,
                    range_min %/% 60, range_min %% 60,
                    range_max %/% 60, range_max %% 60))
      }
      if (!coverage && no_match_count < 5) {
        no_match_count <- no_match_count + 1
        reason <- ""
        if (o > range_min) reason <- "(opens too late)"
        else if (c < range_max) reason <- "(closes too early)"
        cat(sprintf("❌ No match #%d: %02d:%02d-%02d:%02d vs %02d:%02d-%02d:%02d %s\n",
                    no_match_count,
                    o %/% 60, o %% 60, c %/% 60, c %% 60,
                    range_min %/% 60, range_min %% 60,
                    range_max %/% 60, range_max %% 60,
                    reason))
      }
    } else {
      # Crosses midnight (e.g., 22:00-02:00)
      if (range_max > range_min) {
        # 用户时间不跨午夜
        # 跨午夜的餐厅很难"完全覆盖"用户的白天时段
        # 只有当用户时间完全在午夜前或午夜后才可能
        # 这里采用保守策略：排除
        keep[i] <- FALSE
      } else {
        # 用户时间也跨午夜（罕见）
        keep[i] <- TRUE
      }
    }
  }
  
  filtered <- df[keep, , drop = FALSE]
  
  # ---- Debug output ---------------------------------------------------------
  total <- nrow(df)
  n_unknown <- sum(is.na(df$open_min) | is.na(df$close_min))
  n_normal  <- sum(!is.na(df$open_min) & !is.na(df$close_min) & (df$close_min >= df$open_min))
  n_overn   <- sum(!is.na(df$open_min) & !is.na(df$close_min) & (df$close_min <  df$open_min))
  
  cat("\n📊 Hours filter [STRICT coverage]  ",
      sprintf("%02d:%02d–%02d:%02d", range_min%/%60, range_min%%60, range_max%/%60, range_max%%60),
      " | include_unknown:", include_unknown, "\n")
  cat("   Total:", total,
      "| Unknown:", n_unknown,
      "| Normal:", n_normal,
      "| Overnight:", n_overn,
      "| Kept:", nrow(filtered), "\n")
  
  filtered
}
# ---------- Travel mode colors -----------------------------------------------

MODE_COLORS <- list(
  driving = "#2ca02c",    # Green
  transit = "#1f77b4",    # Blue
  walking = "#ff7f0e",    # Orange
  bicycling = "#9467bd"   # Purple
)

# ---------- Map state --------------------------------------------------------

map_rv <- reactiveValues(
  start = NULL,
  end = NULL,
  search_results = NULL,
  route_summaries = list(),
  filtered_places = NULL,
  all_locations = NULL,
  selected_location = NULL,  # 存储用户点击的地点信息
  current_display_data = NULL,  # 当前地图显示的原始数据（未经时间筛选）
  display_source = NULL  # 数据来源: "category" / "wordcloud" / "search"
)

# ---------- Render Google Map ------------------------------------------------

# 可保留樣式（隱藏高速路圖標/POI），不影響功能
style_json_string <- '[
  {"featureType":"road.highway","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.arterial","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"on"}]}
]'

output$google_map <- renderGoogle_map({
  google_map(
    key = GOOGLE_MAPS_API_KEY,
    location = c(-37.8136, 144.9631),
    zoom = 13,
    search_box = FALSE,
    libraries = "places",
    event_return_type = "list",
    map_type_control = FALSE,
    styles = style_json_string
  )
})

# ---------- Load CSV data on startup (DO NOT auto-display) ------------------

observe({
  if (is.null(map_rv$all_locations) && exists("theme_data")) {
    map_rv$all_locations   <- theme_data
    map_rv$filtered_places <- NULL  # ★ 不自动载入任何地点
    cat("CSV Columns Loaded:\n"); print(names(map_rv$all_locations))
    cat("Loaded", nrow(theme_data), "locations from CSV\n")
    cat("⚠️ No markers displayed - waiting for user to select category\n")
  }
}, priority = 100)

# ---------- Operating Hours Filter (auto refresh) ----------------------------

observeEvent(list(input$time_filter, input$include_unknown_hours), {
  cat("\n🕐 Hours filter changed:", input$time_filter[1], "-", input$time_filter[2], "\n")
  cat("📍 Current display source:", map_rv$display_source, "\n")
  
  # ★ 如果没有当前显示的数据，不做任何操作
  if (is.null(map_rv$current_display_data)) {
    cat("⚠️ No data currently displayed, skipping filter\n")
    return()
  }
  
  # ★ 从当前显示的原始数据进行时间筛选
  filtered_data <- filter_by_operating_hours_csv(map_rv$current_display_data)
  
  if (nrow(filtered_data) == 0) {
    # 清除所有标记
    google_map_update("google_map") %>%
      clear_markers(layer_id = "csv_places") %>%
      clear_markers(layer_id = "wordcloud_places") %>%
      clear_markers(layer_id = "search_results")
    
    showNotification(
      "No locations match the selected operating hours", 
      type = "warning", 
      duration = 3
    )
    return()
  }
  
  # 根据数据来源使用不同的 layer_id
  layer_id <- switch(
    map_rv$display_source,
    "wordcloud" = "wordcloud_places",
    "search" = "search_results",
    "category" = "csv_places",
    "csv_places"  # 默认
  )
  
  cat("🗺️ Displaying", nrow(filtered_data), "locations with layer:", layer_id, "\n")
  
  # 准备数据
  display_data <- filtered_data %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat = as.numeric(Latitude),
      lng = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  # 清除旧标记并添加新标记
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    clear_markers(layer_id = "search_results") %>%
    add_markers(
      data = display_data,
      lat = "lat",
      lon = "lng",
      id = "name",
      layer_id = layer_id,
      update_map_view = FALSE
    )
  
  showNotification(
    sprintf("Showing %d locations (after hours filter)", nrow(display_data)),
    type = "message",
    duration = 2
  )
}, ignoreInit = TRUE, ignoreNULL = FALSE)

# ---------- Reset Map button -------------------------------------------------

observeEvent(input$reset_map, {
  cat("\n🔄 Resetting map...\n")
  
  # 清除所有标记层和路线
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    clear_markers(layer_id = "search_results") %>%
    clear_markers(layer_id = "route_markers") %>%
    clear_polylines()
  
  # ★ 清空所有数据，不显示任何地点
  map_rv$filtered_places <- NULL
  map_rv$selected_location <- NULL
  map_rv$current_display_data <- NULL
  map_rv$display_source <- NULL
  
  # 重置类别选择为 "All Categories"
  updateSelectInput(session, "category_filter", selected = "all")
  
  # 清空搜索框
  updateTextInput(session, "search_text", value = "")
  
  cat("✓ Map cleared - no markers displayed\n")
  
  showNotification(
    "✓ Map reset. Please select a category to display locations.", 
    type = "message", 
    duration = 3
  )
})

# ---------- Marker Click Event (获取详细信息) --------------------------------

observeEvent(input$google_map_marker_click, {
  click_data <- input$google_map_marker_click
  if (is.null(click_data)) return()
  
  cat("\n🖱️ Marker clicked:", click_data$id, "\n")
  
  # 从 all_locations 中查找该地点的完整信息
  location_data <- map_rv$all_locations %>%
    dplyr::filter(Name == click_data$id)
  
  if (nrow(location_data) == 0) {
    showNotification("Location data not found", type = "error", duration = 3)
    return()
  }
  
  location <- location_data[1, ]
  
  # 安全地提取值，处理 NA 和空值
  safe_extract <- function(value, default = "Unknown") {
    if (is.null(value) || length(value) == 0) return(default)
    char_value <- as.character(value)
    if (is.na(char_value) || char_value == "NA" || nchar(trimws(char_value)) == 0) {
      return(default)
    }
    return(char_value)
  }
  
  # 保存选中的地点信息
  map_rv$selected_location <- list(
    name = safe_extract(location$Name, "Unknown Location"),
    lat = as.numeric(location$Latitude),
    lng = as.numeric(location$Longitude),
    rating = if("Google_Rating" %in% names(location)) safe_extract(location$Google_Rating, "N/A") else "N/A",
    opening = if("opening_time" %in% names(location)) safe_extract(location$opening_time, "Unknown") else "Unknown",
    closing = if("closing_time" %in% names(location)) safe_extract(location$closing_time, "Unknown") else "Unknown",
    theme = if("Theme" %in% names(location)) safe_extract(location$Theme, "Unknown") else "Unknown",
    sub_theme = if("Sub_Theme" %in% names(location)) safe_extract(location$Sub_Theme, "Unknown") else "Unknown"
  )
  
  cat("✓ Location selected:", map_rv$selected_location$name, "\n")
  
  # 显示通知 - 信息会在侧边栏显示
    showNotification(
    paste0("Selected: ", map_rv$selected_location$name),
      type = "message",
      duration = 2
    )
})

# ---------- Set as Start Location --------------------------------------------

observeEvent(input$set_as_start, {
  if (is.null(map_rv$selected_location)) {
    showNotification("Please click on a location on the map first", type = "warning", duration = 3)
    return()
  }
  
  # 使用选中的位置
  map_rv$start <- c(
    lat = map_rv$selected_location$lat,
    lng = map_rv$selected_location$lng,
    name = map_rv$selected_location$name
  )
  
  updateTextInput(session, "start_input", value = as.character(map_rv$start["name"]))
  draw_start_end_markers()
  
  showNotification(paste0("✓ Start location set to: ", map_rv$selected_location$name), 
                   type = "message", duration = 3)
})

# ---------- Set as End Location ----------------------------------------------

observeEvent(input$set_as_end, {
  if (is.null(map_rv$selected_location)) {
    showNotification("Please click on a location on the map first", type = "warning", duration = 3)
    return()
  }
  
  # 使用选中的位置
  map_rv$end <- c(
    lat = map_rv$selected_location$lat,
    lng = map_rv$selected_location$lng,
    name = map_rv$selected_location$name
  )
  
  updateTextInput(session, "end_input", value = as.character(map_rv$end["name"]))
  draw_start_end_markers()
  
  showNotification(paste0("✓ End location set to: ", map_rv$selected_location$name), 
                   type = "message", duration = 3)
})

# ---------- Category filter ---------------------------------------------------

observeEvent(input$category_filter, {
  if (is.null(map_rv$all_locations)) return()
  category <- input$category_filter
  
  # ★ 如果选择 "all"，清空地图，不显示任何地点
  if (category == "all") {
    google_map_update("google_map") %>%
      clear_markers(layer_id = "csv_places")
    
    map_rv$filtered_places <- NULL
    map_rv$selected_location <- NULL
    map_rv$current_display_data <- NULL
    map_rv$display_source <- NULL
    
    showNotification(
      "Please select a specific category to view locations", 
      type = "message", 
      duration = 2
    )
    return()
  }
  
  # 根据类别筛选
  map_rv$filtered_places <- dplyr::filter(map_rv$all_locations, Theme == category)
  
  # ★ 设置当前显示的原始数据
  map_rv$current_display_data <- map_rv$filtered_places
  map_rv$display_source <- "category"
  
  # 清除选中的地点信息
  map_rv$selected_location <- NULL
  
  cat("📂 Category filter: Set current_display_data to", nrow(map_rv$current_display_data), "locations\n")
  
  # 加载该类别的地点
  load_csv_places()
  
  showNotification(
    sprintf("Showing %d locations in %s", nrow(map_rv$filtered_places), category), 
    type = "message", 
    duration = 2
  )
}, ignoreInit = TRUE)

# ---------- Load CSV places -> markers ---------------------------------------

load_csv_places <- function() {
  places <- map_rv$filtered_places
  if (is.null(places) || nrow(places) == 0) {
    google_map_update("google_map") %>% clear_markers(layer_id = "csv_places")
    return()
  }
  
  # Apply operating hours filter
  places <- filter_by_operating_hours_csv(places)
  
  if (nrow(places) == 0) {
    google_map_update("google_map") %>% clear_markers(layer_id = "csv_places")
    showNotification("No locations match the selected operating hours", type = "warning", duration = 3)
    return()
  }
  
  places_clean <- places %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat  = as.numeric(Latitude),
      lng  = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  cat("Displaying", nrow(places_clean), "markers on map (after hours filter)\n")
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    add_markers(
      data = places_clean,
      lat = "lat",
      lon = "lng",
      id  = "name",
      layer_id = "csv_places",
      update_map_view = FALSE
      # ★ 不预加载 info_window，等用户点击时再获取
    )
}

# ---------- Geolocation (My Location) ----------------------------------------

observeEvent(input$start_my_location, {
  showNotification(
    HTML("<b>Location Permission Required</b><br><small>If denied: Use 'Pick on Map' or type address instead</small>"),
    type = "warning", duration = 6, id = "geo_warning"
  )
  session$sendCustomMessage("requestGeolocation", list(callback = "start_geo_result"))
})

observeEvent(input$end_my_location, {
  showNotification(
    HTML("<b>Location Permission Required</b><br><small>If denied: Use 'Pick on Map' or type address instead</small>"),
    type = "warning", duration = 6, id = "geo_warning"
  )
  session$sendCustomMessage("requestGeolocation", list(callback = "end_geo_result"))
})

observeEvent(input$start_geo_result, {
  result <- input$start_geo_result
  removeNotification(id = "geo_warning")
  if (!is.null(result$error)) {
    showNotification(
      HTML(paste0("<b>Geolocation Failed</b><br>", result$error, "<br><small>Use 'Pick on Map' instead</small>")),
      type = "error", duration = 6
    )
    return()
  }
  map_rv$start <- c(lat = result$lat, lng = result$lng, name = "My Current Location")
  updateTextInput(session, "start_input", value = as.character(map_rv$start["name"]))
  draw_start_end_markers()
  showNotification("✓ Start location set", type = "message", duration = 2)
})

observeEvent(input$end_geo_result, {
  result <- input$end_geo_result
  removeNotification(id = "geo_warning")
  if (!is.null(result$error)) {
    showNotification(
      HTML(paste0("<b>Geolocation Failed</b><br>", result$error, "<br><small>Use 'Pick on Map' instead</small>")),
      type = "error", duration = 6
    )
    return()
  }
  map_rv$end <- c(lat = result$lat, lng = result$lng, name = "My Current Location")
  updateTextInput(session, "end_input", value = as.character(map_rv$end["name"]))
  draw_start_end_markers()
  showNotification("✓ End location set", type = "message", duration = 2)
})

# ---------- Draw start/end markers (no info window) --------------------------

draw_start_end_markers <- function() {
  map_update <- google_map_update("google_map") %>% clear_markers(layer_id = "route_markers")
      
      if (!is.null(map_rv$start)) {
    map_update <- add_markers(
      map_update,
          data = data.frame(
        lat  = as.numeric(map_rv$start["lat"]),
        lng  = as.numeric(map_rv$start["lng"])
      ),
      lat = "lat", lon = "lng",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/green-dot.png"),
      layer_id = "route_markers", update_map_view = FALSE
        )
      }
      
      if (!is.null(map_rv$end)) {
    map_update <- add_markers(
      map_update,
          data = data.frame(
        lat  = as.numeric(map_rv$end["lat"]),
        lng  = as.numeric(map_rv$end["lng"])
      ),
      lat = "lat", lon = "lng",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/red-dot.png"),
      layer_id = "route_markers", update_map_view = FALSE
    )
  }
  
  map_update
}

# ---------- CSV search (by name/theme/subtheme) ------------------------------

observeEvent(input$search_places, {
  req(input$search_text)
  search_term <- tolower(trimws(input$search_text))
  if (is.null(map_rv$all_locations) || !nzchar(search_term)) return()
  
  # ★ 获取原始搜索结果（未经时间筛选的）
  search_results_raw <- map_rv$all_locations %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude) &
                    (grepl(search_term, tolower(Name),       fixed = TRUE) |
                       grepl(search_term, tolower(Sub_Theme),  fixed = TRUE) |
                       grepl(search_term, tolower(Theme),      fixed = TRUE)))
  
  if (nrow(search_results_raw) == 0) {
    showNotification("No matching locations found", type = "warning", duration = 3)
    return()
  }
  
  # ★ 保存原始搜索结果，用于后续时间筛选
  map_rv$current_display_data <- search_results_raw
  map_rv$display_source <- "search"
  
  cat("🔍 Search: Set current_display_data to", nrow(map_rv$current_display_data), "locations\n")
  
  # Apply operating hours filter
  search_results <- filter_by_operating_hours_csv(search_results_raw)
  
  if (nrow(search_results) == 0) {
    showNotification("No matching locations found (check operating hours filter)", type = "warning", duration = 3)
    return()
  }
  
  search_results <- search_results %>%
    dplyr::mutate(
      lat  = as.numeric(Latitude),
      lng  = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::slice_head(n = 50) %>%
    dplyr::select(name, lat, lng)
  
  map_rv$search_results <- search_results
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "search_results") %>%
    add_markers(
      data = search_results,
      lat = "lat", lon = "lng",
      id  = "name",
      layer_id = "search_results",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/blue-dot.png")
      # 不预加载 info window
    )
  
  showNotification(sprintf("Found %d matching locations (after hours filter)", nrow(search_results)), type = "message", duration = 3)
})

# ---------- Wordcloud -> show locations (no window) --------------------------

observeEvent(map_refresh_trigger(), {
  sub_theme <- selected_sub_theme_for_map()
  if (is.null(sub_theme) || sub_theme == "") return()
  
  if (!exists("theme_data")) {
    showNotification("Data not loaded", type = "error", duration = 3)
    return()
  }
  
  top_places_data <- NULL
  if (exists("top_places_for_map") && is.function(top_places_for_map)) {
    top_places_data <- top_places_for_map()
  }
  
  # ★ 获取原始数据（未经时间筛选的）
  places_raw <- if (!is.null(top_places_data) && nrow(top_places_data) > 0) {
    top_places_data
  } else {
    dplyr::filter(theme_data, Sub_Theme == sub_theme)
  }
  
  # ★ 保存原始数据，用于后续时间筛选
  map_rv$current_display_data <- places_raw
  map_rv$display_source <- "wordcloud"
  
  cat("☁️ Wordcloud: Set current_display_data to", nrow(map_rv$current_display_data), "locations\n")
  
  # Apply operating hours filter
  places <- filter_by_operating_hours_csv(places_raw)
  
  if (nrow(places) == 0) {
    showNotification(paste0("No locations found for: ", sub_theme, " (check operating hours filter)"), type = "warning", duration = 3)
    return()
  }
  
  places <- places %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat  = as.numeric(Latitude),
      lng  = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    add_markers(
      data = places,
      lat = "lat", lon = "lng",
      id  = "name",
      layer_id = "wordcloud_places",
      update_map_view = FALSE
      # 不预加载 info window
    )
  
  # Update filtered_places for consistent state
  map_rv$filtered_places <- places_raw
  
  showNotification(paste0("✓ Showing ", nrow(places), " places: ", sub_theme, " (after hours filter)"), type = "message", duration = 3)
}, ignoreNULL = TRUE, ignoreInit = TRUE)

# ---------- Directions -------------------------------------------------------

observeEvent(input$get_directions, {
  cat("\n===== GET DIRECTIONS CLICKED =====\n")
  
  if (is.null(map_rv$start) || is.null(map_rv$end)) {
    showNotification(
      HTML("<b>Missing Location</b><br>Please set both start and end locations"),
      type = "error", duration = 4
    )
    return()
  }
  
  # 简化的 API key 检查：只检查是否为空，不检查特定值
  if (is.null(GOOGLE_MAPS_API_KEY) || GOOGLE_MAPS_API_KEY == "") {
    showNotification(
      HTML("<b>API Key Error</b><br>Google Maps API key is not configured properly"),
      type = "error", duration = 6
    )
    cat("❌ API Key is missing or empty\n")
    return()
  }
  
  cat("🔑 Using API Key (first 20 chars):", substr(GOOGLE_MAPS_API_KEY, 1, 20), "...\n")
  
  google_map_update("google_map") %>% clear_polylines()
  
  modes <- input$travel_modes
  if (length(modes) == 0) modes <- "driving"
  cat("Selected travel modes:", paste(modes, collapse = ", "), "\n")
  
  route_summaries <- list()
  errors <- list()
  
  for (mode in modes) {
    cat("\nCalculating route for mode:", mode, "\n")
    direction <- try(
      google_directions(
        origin      = c(as.numeric(map_rv$start["lat"]), as.numeric(map_rv$start["lng"])),
        destination = c(as.numeric(map_rv$end["lat"]),   as.numeric(map_rv$end["lng"])),
        mode = mode, key = GOOGLE_MAPS_API_KEY, simplify = TRUE
      ),
      silent = TRUE
    )
    
    if (inherits(direction, "try-error")) {
      error_msg <- as.character(direction)
      cat("ERROR for", mode, ":", error_msg, "\n")
      errors[[mode]] <- error_msg
      next
    }
    
    if (is.null(direction$routes) || length(direction$routes) == 0) {
      cat("No routes found for", mode, "\n")
      errors[[mode]] <- "No routes available"
      next
    }
    
    polyline <- direction$routes$overview_polyline$points
    google_map_update("google_map") %>%
      add_polylines(
        polyline = polyline,
        stroke_weight = 5,
        stroke_colour = MODE_COLORS[[mode]],
        stroke_opacity = 0.8,
        layer_id = paste0("route_", mode)
      )
    
    legs <- direction$routes$legs
    if (!is.null(legs) && length(legs) > 0) {
      # legs[[1]] is a data.frame, not a nested list
      leg <- legs[[1]]
      
      # Extract distance and duration values
      distance_value <- tryCatch(as.numeric(leg$distance$value), error = function(e) NA)
      duration_value <- tryCatch(as.numeric(leg$duration$value), error = function(e) NA)
      
      if (!is.na(distance_value) && !is.na(duration_value)) {
      route_summaries[[mode]] <- list(
          distance_km  = round(distance_value / 1000, 1),
          duration_min = round(duration_value / 60)
      )
        cat("✓ Route summary for", mode, ":", route_summaries[[mode]]$distance_km, "km,",
            route_summaries[[mode]]$duration_min, "min\n")
      } else {
        cat("⚠️  Could not extract distance/duration for", mode, "\n")
      }
    }
  }
  
  map_rv$route_summaries <- route_summaries
  
  if (length(route_summaries) > 0) {
    showNotification(sprintf("✓ Calculated %d route(s)", length(route_summaries)), type = "message", duration = 3)
  } else {
    error_details <- if (length(errors) > 0) paste("<br><small>", names(errors)[1], ":", errors[[1]], "</small>") else ""
    showNotification(
      HTML(paste0("<b>❌ No routes found</b><br>Please check your API key and locations", error_details)),
      type = "error", duration = 8
    )
  }
  
  cat("===== GET DIRECTIONS COMPLETE =====\n\n")
}, ignoreInit = TRUE)

# ---------- Route summary text -----------------------------------------------

output$route_summary_text <- renderUI({
  summaries <- map_rv$route_summaries
  if (length(summaries) == 0) {
    return(HTML('<span style="color:#999; font-size: 12px;">Set start & end, then click "Get Directions"</span>'))
  }
  
  summary_html <- lapply(names(summaries), function(mode) {
    info <- summaries[[mode]]
    mode_label <- switch(
      mode,
      driving = "🚗 Driving",
      transit = "🚌 Transit",
      walking = "🚶 Walking",
      bicycling = "🚴 Cycling",
      mode
    )
    glue::glue(
      '<div style="margin: 5px 0; font-size: 13px;">
         <b>{mode_label}</b><br>{info$distance_km} km · {info$duration_min} min
       </div>'
    )
  })
  
  HTML(paste(summary_html, collapse = ""))
})

# ---------- Location count (small card) --------------------------------------

output$location_count <- renderUI({
  count <- if (!is.null(map_rv$filtered_places)) nrow(map_rv$filtered_places) else 0
  
  # 根据数量选择不同的颜色和提示
  color <- if (count == 0) "#999" else "#007bff"
  message <- if (count == 0) "No locations displayed" else "locations displayed"
  
  HTML(sprintf(
    '<div style="padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px; text-align: center;">
       <strong style="font-size: 16px; color: %s;">%d</strong>
       <br><small style="color: #666;">%s</small>
     </div>', color, count, message))
})

# ---------- Selected Location Info Card --------------------------------------

output$selected_location_card <- renderUI({
  if (is.null(map_rv$selected_location)) {
    return(NULL)  # 没有选中地点时不显示
  }
  
  loc <- map_rv$selected_location
  
  # 构建卡片内容
  div(
    style = "margin-top: 15px; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); color: white;",
    
    # 标题
    h5(
      style = "margin: 0 0 10px 0; font-weight: bold; font-size: 16px;",
      icon("map-marker-alt"), " Selected Location"
    ),
    
    # 地点名称
    div(
      style = "font-size: 15px; font-weight: 600; margin-bottom: 12px; padding-bottom: 10px; border-bottom: 1px solid rgba(255,255,255,0.3);",
      loc$name
    ),
    
    # 详细信息
    div(
      style = "font-size: 13px; line-height: 1.8;",
      
      # Category
      div(
        style = "margin-bottom: 6px;",
        icon("tag"), " ",
        tags$strong("Category: "), 
        if (!is.null(loc$theme) && !is.na(loc$theme) && 
            loc$theme != "Unknown" && nzchar(loc$theme)) {
          loc$theme
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      # Type
      div(
        style = "margin-bottom: 6px;",
        icon("info-circle"), " ",
        tags$strong("Type: "), 
        if (!is.null(loc$sub_theme) && !is.na(loc$sub_theme) && 
            loc$sub_theme != "Unknown" && nzchar(loc$sub_theme)) {
          loc$sub_theme
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      # Rating (始终显示，缺失时显示 Not Available)
      div(
        style = "margin-bottom: 6px;",
        icon("star"), " ",
        tags$strong("Rating: "),
        if (!is.null(loc$rating) && !is.na(loc$rating) && 
            loc$rating != "N/A" && loc$rating != "NA" && nzchar(loc$rating)) {
          loc$rating
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      # Operating Hours (始终显示，缺失时显示 Not Available)
      div(
        style = "margin-bottom: 6px;",
        icon("clock"), " ",
        tags$strong("Hours: "),
        if (!is.null(loc$opening) && !is.na(loc$opening) && 
            loc$opening != "Unknown" && nzchar(loc$opening)) {
          paste0(loc$opening, " - ", loc$closing)
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      )
    ),
    
    # 提示信息
    div(
      style = "margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.3); font-size: 12px; font-style: italic; opacity: 0.9;",
      icon("hand-point-down"), " Use buttons below to set as Start or End"
    )
  )
})
