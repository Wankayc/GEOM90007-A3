# Wordcloud tab server logic

current_sub_theme <- reactiveVal(NULL)

# Create a reactive variable to share selected sub_theme with map module
selected_sub_theme_for_map <- reactiveVal(NULL)

observeEvent(input$nav, {
  runjs('dispatchEvent(new Event("resize"))')
})

# Main wordcloud
observeEvent(input$mainCloudViz_mark_selection_changed, {
  selected_theme <- input$mainCloudViz_mark_selection_changed$Theme[1]
  if (is.null(selected_theme)) return()
  
  updateNavbarPage(session, 'nav', selected = 'Popular Attractions')
  updateRadioButtons(session, 'themeSingle', selected = selected_theme)
  
  runjs(sprintf('
      (function(){
        let viz = document.getElementById("subCloudViz");
        if(!viz || !viz.workbook) return;
        let sheet = viz.workbook.activeSheet;
        sheet.applyFilterAsync("Theme", ["%s"], FilterUpdateType.Replace);
      })();
    ', gsub("'", "\\\\'", selected_theme)))
})

# Click Theme to jump to the sun theme wordcolud
observeEvent(input$themeSingle, {
  req(input$themeSingle)
  
  # Skip personality tracking on first load
  if (exists("user_behavior") && !is.null(user_behavior) && isTRUE(user_behavior$first_load)) {
    user_behavior$first_load <- FALSE
    return()
  }
  
  # --------- Personality tracking ----------
  # This covers both direct radio button clicks AND wordcloud clicks that update radios
  category_mapping <- list(
    "Accommodation" = "accommodation",
    "Transport" = "transport", 
    "Attractions" = "attractions",
    "Arts & Culture" = "arts_culture",
    "Food & Drink" = "food_drink",
    "Heritage" = "heritage",
    "Leisure" = "leisure",
    "Public Service" = "public_service",
    "Shopping" = "shopping",
    "Health Services" = "health_services"
  )
  
  if (input$themeSingle %in% names(category_mapping)) {
    category_name <- category_mapping[[input$themeSingle]]
    if (exists("user_behavior") && !is.null(user_behavior)) {
      user_behavior$category_clicks[[category_name]] <- user_behavior$category_clicks[[category_name]] + 1
    }
  }
  # ---------------------------------
  
  runjs(sprintf('
      (function(){
        let viz = document.getElementById("subCloudViz");
        if(!viz || !viz.workbook) return;
        let sheet = viz.workbook.activeSheet;
        sheet.applyFilterAsync("Theme", ["%s"], FilterUpdateType.Replace);
      })();
    ', gsub("'", "\\\\'", input$themeSingle)))
})

# click sub theme to define Sub_Theme
observeEvent(input$subCloudViz_mark_selection_changed, {
  click_data <- input$subCloudViz_mark_selection_changed
  if (is.null(click_data) || length(click_data) == 0) return()
  
  selected_sub <- NULL
  possible_names <- c("Sub Theme", "Sub_Theme", "Sub-Theme", "SUB THEME")
  for (field_name in possible_names) {
    if (!is.null(click_data[[field_name]]) && length(click_data[[field_name]]) > 0) {
      selected_sub <- as.character(click_data[[field_name]][1]); break
    }
  }
  if (is.null(selected_sub) && length(click_data) > 0) {
    for (field_name in names(click_data)) {
      tryCatch({
        val <- click_data[[field_name]][1]
        if (!is.null(val) && !is.na(val) && nchar(as.character(val)) > 0) {
          selected_sub <- as.character(val); break
        }
      }, error = function(e) {})
    }
  }
  
  # --------- Personality tracking -----------
  if (!is.null(selected_sub) && nchar(selected_sub) > 0) {
    # Get the current theme to know which category we're in
    current_theme <- input$themeSingle
    category_mapping <- list(
      "Accommodation" = "accommodation",
      "Transport" = "transport", 
      "Attractions" = "attractions",
      "Arts & Culture" = "arts_culture",
      "Food & Drink" = "food_drink",
      "Heritage" = "heritage",
      "Leisure" = "leisure",
      "Public Service" = "public_service",
      "Shopping" = "shopping",
      "Health Services" = "health_services"
    )
    
    if (!is.null(current_theme) && current_theme %in% names(category_mapping)) {
      category_name <- category_mapping[[current_theme]]
      if (exists("user_behavior") && !is.null(user_behavior)) {
        user_behavior$category_clicks[[category_name]] <- user_behavior$category_clicks[[category_name]] + 1
      }
    }
  }

  if (!is.null(selected_sub) && nchar(selected_sub) > 0) current_sub_theme(selected_sub) else current_sub_theme(NULL)
})


# Handle "View on Map" button click
observeEvent(input$showMapBtn, {
  # Get the currently selected sub_theme
  sub_theme <- current_sub_theme()
  
  # If no sub_theme is selected, show a warning notification
  if (is.null(sub_theme)) {
    showNotification(
      "Please select an attraction type first by clicking on the word cloud above.",
      type = "warning",
      duration = 3
    )
    return()
  }
  
  # 先跳转到地图页面
  updateNavbarPage(session, 'nav', selected = 'Map')
  
  # 延迟更新，等地图加载完成
  shinyjs::delay(800, {
    selected_sub_theme_for_map(sub_theme)
    
    showNotification(
      paste0("Loading locations for: ", sub_theme),
      type = "message",
      duration = 2
    )
  })
})

# The top 5-20 ranking
output$plot_ranking <- renderGirafe({
  sub_theme <- current_sub_theme()
  
  if (is.null(sub_theme)) {
    p <- ggplot() +
      annotate('text', x=0.5, y=0.5,
               label='Click on a sub theme above to view rankings',
               size=6, color='#999', fontface='italic') +
      theme_void()
    return(girafe(ggobj=p, height_svg=8))
  }
  
  is_bbq_or_police <- sub_theme %in% c("BBQ", "Police Station", "Railway Station")
  
  ranking_data <- theme_data %>%
    filter(Sub_Theme == sub_theme) %>%
    arrange(desc(Google_Rating)) %>%
    head(as.numeric(input$topN)) %>%
    mutate(
      Name = sub("^Barbeque - ", "", Name),    
      Rank = row_number(),
      Name_clean = gsub("['\"`]", "", Name),
      Name_trunc = ifelse(nchar(Name_clean) > 45,
                          paste0(substr(Name_clean, 1, 45), "..."),
                          Name_clean)
    ) %>%
    group_by(Name_clean) %>%
    mutate(
      dup_count = n(),
      suffix = case_when(
        dup_count == 1 ~ "",
        is_bbq_or_police ~ paste0(" (location ", LETTERS[pmin(row_number(), length(LETTERS))], ")"),
        row_number() == 1 ~ " (indoor)",
        row_number() == 2 ~ " (outdoor)",
        TRUE ~ paste0(" (location ", LETTERS[pmin(row_number(), length(LETTERS))], ")")
      ),
      Name_display = paste0(Name_trunc, suffix),
      Has_Rating = !is.na(Google_Rating),
      Google_Rating_Display = ifelse(is.na(Google_Rating), 0.1, Google_Rating),
      Rating_Label = ifelse(is.na(Google_Rating), "N/A", sprintf('%.1f', Google_Rating))
    ) %>%
    ungroup() %>%
    arrange(Google_Rating_Display) %>%
    mutate(Name_display = factor(Name_display, levels = Name_display))
  
  if (nrow(ranking_data) == 0) {
    p <- ggplot() +
      annotate('text', x=0.5, y=0.5,
               label=paste0('No data available for:\n', sub_theme),
               size=5, color='#999', lineheight=1.3) +
      theme_void()
    return(girafe(ggobj=p, height_svg=8))
  }
  
  p <- ggplot(ranking_data) +
    aes(x=Google_Rating_Display, y=Name_display,
        tooltip=paste0(Name_clean,
                       ifelse(!is.na(Business_address) & nchar(Business_address) > 0,
                              paste0('\n', Business_address), ''),
                       '\nRating: ',
                       ifelse(Has_Rating, sprintf('%.1f', Google_Rating), 'Not rated')),
        data_id=Name_clean) +
    geom_bar_interactive(
      aes(fill=Has_Rating, color=Has_Rating),
      stat='identity', 
      width=0.7,
      alpha=0.9
    ) +
    scale_fill_manual(
      values=c('TRUE'='#036B55', 'FALSE'='white'),
      guide='none'
    ) +
    scale_color_manual(
      values=c('TRUE'='#036B55', 'FALSE'='#036B55'),
      guide='none'
    ) +
    geom_text(aes(label=Rating_Label),
              hjust=-0.25, size=12, color='#333', fontface='bold') +
    scale_x_continuous(limits=c(0, 5.5), breaks=seq(0, 5, 1), expand=c(0, 0)) +
    labs(x='Google Maps Rating', y='',
         title=paste0('Top ', input$topN, ' Places in ', sub_theme)) +
    theme(
      text = element_text(size = 28),
      panel.background = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color='#e5e5e5', linetype='dotted'),
      panel.grid.minor = element_blank(),
      axis.ticks = element_blank(),
      axis.text.y = element_text(size=30, color='#333', hjust=1, face='plain', margin=margin(r=12)),
      axis.text.x = element_text(size=26, color='#666'),
      axis.title.x = element_text(size=28, color='#666', margin=margin(t=20)),
      plot.title = element_text(size=34, face='bold', color='#036B55', margin=margin(b=28)),
      plot.margin = margin(30, 70, 30, 30)
    )
  
  girafe(
    ggobj = p,
    height_svg = 16,
    width_svg = 22,
    options = list(
      opts_hover(css='fill:#05A882;stroke:#036B55;stroke-width:2px;cursor:pointer;'),
      opts_tooltip(css='background-color:#036B55;color:white;padding:12px 16px;border-radius:6px;font-size:14px;box-shadow:0 4px 12px rgba(0,0,0,0.2);', opacity=0.95)
    )
  )
})

# ---------- Personality Tracking - bar chart ---------
observeEvent(input$plot_ranking_selected, {
  if (!is.null(input$plot_ranking_selected)) {
    # Get the current sub-theme to know which category we're in
    current_theme <- input$themeSingle
    category_mapping <- list(
      "Accommodation" = "accommodation",
      "Transport" = "transport", 
      "Attractions" = "attractions",
      "Arts & Culture" = "arts_culture",
      "Food & Drink" = "food_drink",
      "Heritage" = "heritage",
      "Leisure" = "leisure",
      "Public Service" = "public_service",
      "Shopping" = "shopping",
      "Health Services" = "health_services"
    )
    
    if (!is.null(current_theme) && current_theme %in% names(category_mapping)) {
      category_name <- category_mapping[[current_theme]]
      if (exists("user_behavior") && !is.null(user_behavior)) {
        user_behavior$category_clicks[[category_name]] <- user_behavior$category_clicks[[category_name]] + 1
      }
    }
  }
})