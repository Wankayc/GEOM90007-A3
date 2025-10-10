summary_ui <- fluidPage(
  div(style = "text-align: center; padding: 100px;",
      h2("Summary Dashboard"),
      p("Feature to be implemented"),
      # Example navigation buttons
      fluidRow(
        column(6, actionButton("goto_wordcloud", "Go to Word Cloud", class = "btn-info")),
        column(6, actionButton("goto_map", "Go to Map", class = "btn-info"))
      )
  )
)