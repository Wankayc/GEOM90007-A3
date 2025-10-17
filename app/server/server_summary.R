# Summary tab server logic
observeEvent(input$goto_wordcloud, {
  navigate_to_tab("Word Cloud", session)
})

observeEvent(input$goto_map, {
  navigate_to_tab("Map", session)
})

# Example: Access data from other tabs
output$summary_stats <- renderUI({
  req(shared$data_loaded)
  
  project_data <- get_transport_data()
  if (!is.null(project_data)) {
    tagList(
      h4("Transport Summary"),
      p(paste("Total stops:", nrow(project_data))),
      p(paste("Unique locations:", length(unique(project_data$location))))
    )
  }
})
