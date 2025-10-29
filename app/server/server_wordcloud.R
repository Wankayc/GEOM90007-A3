# Wordcloud tab server logic

current_sub_theme <- reactiveVal(NULL)

# Create a reactive variable to share selected sub_theme with map module
selected_sub_theme_for_map <- reactiveVal(NULL)

# Create a reactive variable to store Top N ranking data for map
top_places_for_map <- reactiveVal(NULL)

# Create a trigger to force map refresh (increments on each "View on Map" click)
map_refresh_trigger <- reactiveVal(0)

observeEvent(input$nav, {
  runjs('dispatchEvent(new Event("resize"))')
})

# Dynamic title for sub word cloud section
output$dynamic_subcloud_title <- renderUI({
  selected_theme <- input$themeSingle
  if (is.null(selected_theme)) {
    h2(class='section-lead sub-cloud-title', 'Highlights in This Category')
  } else {
    h2(class='section-lead sub-cloud-title', 
       paste0('Highlights in ', selected_theme))
  }
})

output$dynamic_subcloud_desc <- renderUI({
  selected_theme <- input$themeSingle
  if (is.null(selected_theme)) {
    desc_text <- 'Click on any attraction type to view the highest-rated places.'
  } else {
    desc_text <- paste0('Exploring ', selected_theme, 
                        ' - Click on any attraction type to view rankings.')
  }
  p(class='section-desc sub-cloud-desc', 
    style='color:#666; font-size:14px; line-height:1.6; margin-bottom:16px;',
    desc_text)
})

# Dynamic title for ranking section
output$dynamic_ranking_title <- renderUI({
  sub_theme <- current_sub_theme()
  selected_theme <- input$themeSingle
  
  if (is.null(sub_theme)) {
    title_text <- 'Top Rated Places by Google Reviews'
  } else if (!is.null(selected_theme)) {
    title_text <- paste0('Top Rated ', sub_theme, ' in ', selected_theme)
  } else {
    title_text <- paste0('Top Rated ', sub_theme)
  }
  
  h2(title_text, style='display:inline-block; margin-right:0px;')
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

# Click Theme to jump to the sub theme wordcloud
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
  
  runjs(sprintf('
      (function(){
        let viz = document.getElementById("subCloudViz");
        if(!viz || !viz.workbook) return;
        let sheet = viz.workbook.activeSheet;
        sheet.applyFilterAsync("Theme", ["%s"], FilterUpdateType.Replace);
      })();
    ', gsub("'", "\\\\'", input$themeSingle)))
})

# Click sub theme to define Sub_Theme
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
  
  # Personality tracking
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
      HTML("<b>No selection detected</b><br>Please select an attraction type first by clicking on the word cloud above."),
      type = "warning",
      duration = 4
    )
    return()
  }
  
  # Ensure top_places_for_map has data before switching to map
  # (In case the ranking hasn't been rendered yet)
  current_top_places <- top_places_for_map()
  if (is.null(current_top_places) || nrow(current_top_places) == 0) {
    # Generate the Top N data if not available
    top_n_data <- theme_data %>%
      filter(Sub_Theme == sub_theme) %>%
      arrange(desc(Google_Rating)) %>%
      head(as.numeric(input$topN))
    
    if (nrow(top_n_data) > 0) {
      top_places_for_map(top_n_data)
    }
  }
  
  # 先跳转到地图页面
  updateNavbarPage(session, 'nav', selected = 'Map')
  
  shinyjs::delay(800, {
    # Update the sub_theme for map
    selected_sub_theme_for_map(sub_theme)
    
    # Increment trigger to force map refresh (even if sub_theme is the same)
    map_refresh_trigger(map_refresh_trigger() + 1)
    
    showNotification(
      paste0("Loading Top ", input$topN, " locations for: ", sub_theme),
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
      annotate('text', x=0.5, y=0.52,
               label='Click on a sub-theme above to view rankings',
               size=6, color='#999', fontface='italic') +
      annotate('text', x=0.5, y=0.48,
               label='Select from the word cloud to explore top-rated places',
               size=4.5, color='#bbb') +
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
  
  # Save the original data columns to top_places_for_map for map display
  if (nrow(ranking_data) > 0) {
    # Extract only the original theme_data columns (before all the display processing)
    top_places_for_map(ranking_data %>% 
      select(any_of(names(theme_data))))
  } else {
    top_places_for_map(NULL)
  }
  
  if (nrow(ranking_data) == 0) {
    p <- ggplot() +
      annotate('text', x=0.5, y=0.5,
               label=paste0('No data available for:\n', sub_theme),
               size=5, color='#999', lineheight=1.3) +
      theme_void()
    return(girafe(ggobj=p, height_svg=8))
  }
  
  # Get current theme for dynamic title
  current_theme <- input$themeSingle
  plot_title <- if (!is.null(current_theme)) {
    paste0('Top ', input$topN, ' ', sub_theme, ' in ', current_theme)
  } else {
    paste0('Top ', input$topN, ' Places in ', sub_theme)
  }
  
  p <- ggplot(ranking_data) +
    aes(x=Google_Rating_Display, y=Name_display,
        tooltip=paste0(
          '<b style="font-size:15px;color:#036B55;">', Name_clean, '</b><br>',
          '<span style="color:#ddd;">━━━━━━━━━━━━━━━━</span><br>',
          ifelse(!is.na(Business_address) & nchar(Business_address) > 0,
                 paste0('<b>Address:</b> ', Business_address, '<br>'), ''),
          '<b>Rating:</b> ',
          ifelse(Has_Rating, 
                 paste0('<span style="color:#FFD700;font-size:15px;font-weight:bold;">', 
                        sprintf('%.1f', Google_Rating), '</span> / 5.0'), 
                 '<span style="color:#ccc;">Not rated yet</span>'),
          '<br>',
          '<b>Category:</b> ', sub_theme,
          ifelse(!is.null(current_theme),
                 paste0('<br><b>Theme:</b> ', current_theme), '')
        ),
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
         title=plot_title) +
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
      opts_tooltip(css='background-color:#036B55;color:white;padding:14px 18px;border-radius:6px;font-size:14px;box-shadow:0 4px 12px rgba(0,0,0,0.25);line-height:1.6;', opacity=0.96)
    )
  )
})

# Personality Tracking - bar chart
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