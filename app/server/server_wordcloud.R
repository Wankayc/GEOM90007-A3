# Word Cloud server logic will go here
server <- function(input, output, session) {
  
  # Fix for Tableau viz sizing issues on different tabs
  observeEvent(input$mynav, {
    runjs('dispatchEvent(new Event("resize"))')
  })
  
  # React to clicks on the main theme cloud
  observeEvent(input$mainCloudViz_mark_selection_changed, {
    # Get the selected tourist theme from the main cloud
    selected_theme <- input$mainCloudViz_mark_selection_changed[["Tourist Theme"]][1]
    
    # If no theme is selected, stop
    if(is.null(selected_theme)) return()
    
    # Debug: print the selected theme
    print(paste("Selected Tourist Theme:", selected_theme))
    
    # Filter the sub cloud by the selected tourist theme
    runjs(sprintf('
      let viz = document.getElementById("subCloudViz");
      let sheet = viz.workbook.activeSheet;
      sheet.applyFilterAsync("Tourist Theme", ["%s"], FilterUpdateType.Replace);
    ', selected_theme))
    
    # Switch to the Sub Themes tab (just like the teacher's example!)
    updateNavbarPage(session, 'mynav', selected='Sub Themes')
  })
  
  # Optional: react to clicks on sub cloud
  observeEvent(input$subCloudViz_mark_selection_changed, {
    # Get the selected sub theme
    selected_sub <- input$subCloudViz_mark_selection_changed[["Sub Theme"]][1]
    
    if(!is.null(selected_sub)) {
      print(paste("Selected sub theme:", selected_sub))
    }
  })
}
