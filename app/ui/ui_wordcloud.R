<<<<<<< Updated upstream
# Global page CSS styling (custom layout, colors, fonts)
page_css <- tags$head(
  tags$style(HTML("
    .page-wrap { max-width: 95vw; margin: 0 auto; padding: 0 20px; }
    .page-wrap h2 { color:#036B55; font-weight:700; margin:10px 0 12px 0; text-align:left; }
    .card { padding:15px; background:#f8f9fa; border-radius:8px; }
    .card h4 { color:#036B55; margin-bottom:12px; font-size:15px; font-weight:700; }
    .radio-scroll { max-height: 260px; overflow:auto; padding-right:4px; }
    .radio-scroll .radio { margin-bottom:6px; }
    .help-note { color:#666; font-size:11px; line-height:1.3; margin-top:8px; display:block; }
    .sub-cloud-title { margin-bottom: 2px !important; }
    .sub-cloud-desc { margin-bottom: 4px !important; }
    .full-bleed { margin-left: -20px; margin-right: -20px; width: calc(100% + 40px); }
    .full-bleed > * { width: 100% !important; display:block; }
    .main-cloud-container { max-width: 90%; margin: 0 auto; }
  "))
=======
# UI for wordcloud tabs

# JavaScript for collapsible functionality
collapsible_js <- tags$script(
  HTML(
    "
  $(document).ready(function() {
    // Main cloud page toggle
    $('#dataSourceToggleMain').click(function() {
      $(this).toggleClass('active');
      $('#dataSourceContentMain').toggleClass('show');
    });

    // Sub cloud page toggle
    $('#dataSourceToggleSub').click(function() {
      $(this).toggleClass('active');
      $('#dataSourceContentSub').toggleClass('show');
    });
  });
"
  )
)

# Additional CSS for collapsible button
collapsible_css <- tags$style(
  HTML(
    "
  /* Collapsible data source button styles */
  .wordcloud-container-wrapper {
    position: relative;
  }
  .data-source-toggle {
    position: absolute !important;
    bottom: 15px;
    left: 15px;
    background: rgba(255, 255, 255, 0.95);
    border: none;
    color: #036B55;
    width: 28px;
    height: 28px;
    min-width: 28px;
    padding: 0;
    border-radius: 50%;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
  }
  .data-source-toggle:hover {
    background: #036B55;
    color: white;
    transform: scale(1.1);
  }
  .data-source-toggle i {
    transition: transform 0.3s ease;
  }
  .data-source-toggle.active {
    background: #036B55;
    color: white;
  }
  .data-source-content {
    position: absolute;
    bottom: 55px;
    left: 15px;
    max-width: 350px;
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.3s ease;
    background: white;
    padding: 0;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 99;
  }
  .data-source-content.show {
    max-height: 200px;
    padding: 12px 15px;
    border: 1px solid #e0e0e0;
  }
  .data-source-content p {
    color: #666;
    font-size: 13px;
    line-height: 1.6;
    margin: 0;
  }
  .data-source-content a {
    color: #036B55;
    text-decoration: none;
    font-weight: 600;
  }
  .data-source-content a:hover {
    text-decoration: underline;
  }
"
  )
)

# Heading spacing CSS (unify title/subtitle gaps)
heading_spacing_css <- tags$style(
  HTML(
    "
  /* Control spacing between main titles and subtitles */
  h2.section-lead { margin: 0 0 8px 0 !important; }
  p.section-desc { margin: 0 0 16px 0 !important; }
"
  )
)

# View on Map button styling
map_button_css <- tags$style(
  HTML(
    "
  /* Enhanced 3D button styling */
  #showMapBtn {
    position: relative;
    transform: translateY(0);
    border-bottom: 2px solid #014839 !important;
  }
  #showMapBtn:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(3, 107, 85, 0.45), inset 0 1px 0 rgba(255,255,255,0.3) !important;
    background: linear-gradient(to bottom, #05a07d 0%, #048d6f 50%, #036B55 100%) !important;
  }
  #showMapBtn:active {
    transform: translateY(1px);
    box-shadow: 0 2px 8px rgba(3, 107, 85, 0.3), inset 0 1px 2px rgba(0,0,0,0.2) !important;
    border-bottom: 1px solid #014839 !important;
  }
  #showMapBtn::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
    transition: left 0.5s ease;
  }
  #showMapBtn:hover::before {
    left: 100%;
  }
"
  )
>>>>>>> Stashed changes
)

# Get unique theme values from theme_data for UI radio buttons
themes_available <- sort(unique(theme_data$Theme[!is.na(theme_data$Theme)]))

# Main Word Cloud page
main_cloud_tab <- tabPanel(
<<<<<<< Updated upstream
  title='Explore by Category',
  div(class='page-wrap',
      h2('Explore Melbourne by Category'),
      p(style='color:#666; font-size:14px; margin-bottom:16px; line-height:1.6;',
        'Click on any category below to discover Melbourne\'s top-rated places. ',
        'Data source: ',
        tags$a('Melbourne Open Data Portal',
               href='https://data.melbourne.vic.gov.au/',
               target='_blank', style='color:#036B55;')
      ),
      div(class='main-cloud-container',
          tableauPublicViz(
            id='mainCloudViz',
            url='https://public.tableau.com/views/Theme_Cloud/PickaThemetoStartExploring?:toolbar=no&:showVizHome=no',
            height="80vh"
=======
  title = 'Explore by Category',
  icon = icon("cloud"),
  collapsible_css,
  collapsible_js,
  heading_spacing_css,
  div(
    class = 'page-wrap',
    h2(class = 'section-lead', 'Explore Melbourne by Category'),
    p(
      class = 'section-desc',
      style = 'color:#666; font-size:14px; margin-bottom:16px; line-height:1.6;',
      'Click on any category below to discover Melbourne\'s top-rated places.'
    ),
    div(
      class = 'main-cloud-container wordcloud-container-wrapper',
      tableauPublicViz(id = 'mainCloudViz', url = 'https://public.tableau.com/views/Theme_Cloud/PickaThemetoStartExploring?:toolbar=no&:showVizHome=no', height =
                         "80vh"),
      # Info button - bottom left corner
      tags$button(
        id = 'dataSourceToggleMain',
        class = 'data-source-toggle',
        title = 'About this data',
        tags$i(class = 'fa fa-info', style = 'font-style: normal;')
      ),
      # Collapsible content
      div(
        id = 'dataSourceContentMain',
        class = 'data-source-content',
        tags$p(
          'Data source: ',
          tags$a(
            'Melbourne Open Data Portal',
            href = 'https://data.melbourne.vic.gov.au/',
            target = '_blank'
>>>>>>> Stashed changes
          )
        )
      )
    )
  )
)

# Sub Word Cloud + Ranking page
sub_cloud_tab <- tabPanel(
<<<<<<< Updated upstream
  title='Popular Attractions',
  div(class='page-wrap',
      fluidRow(
        column(width = 9,
               h2(class='sub-cloud-title', 'Highlights in This Category'),
               p(class='sub-cloud-desc', style='color:#666; font-size:14px; line-height:1.6;',
                 'Click on any attraction type to view the highest-rated places. ',
                 'Data source: ',
                 tags$a('Melbourne Open Data Portal',
                        href='https://data.melbourne.vic.gov.au/',
                        target='_blank', style='color:#036B55;')
               ),
               div(class='full-bleed',
                   tableauPublicViz(
                     id='subCloudViz',
                     url='https://public.tableau.com/views/Sub_Theme_Cloud/TopHighlightsinThisTheme?:toolbar=no&:showVizHome=no',
                     height="60vh"
                   )
               )
        ),
        column(width = 3,
               div(class='card',
                   h4('Theme'),
                   div(class = "radio-scroll",
                       radioButtons('themeSingle', NULL,
                                    choices = themes_available,
                                    selected = ifelse("Leisure" %in% themes_available,
                                                      "Leisure", themes_available[1]),
                                    inline = FALSE)
                   ),
                   span(class='help-note', 'Choose one theme to update the word cloud and the rankings.')
               )
        )
      ),
      hr(style='border:0; border-top:3px solid #036B55; margin:20px 0 15px 0;'),
      fluidRow(
        column(width = 9,
               h2('Top Rated Places by Google Reviews'),
               girafeOutput('plot_ranking', height='95vh')
=======
  title = 'Popular Attractions',
  icon = icon("fire"),
  div(
    class = 'page-wrap',
    map_button_css,
    fluidRow(
      column(
        width = 9,
        uiOutput("dynamic_subcloud_title"),
        uiOutput("dynamic_subcloud_desc"),
        div(
          class = 'wordcloud-container-wrapper',
          div(
            class = 'full-bleed',
            tableauPublicViz(id = 'subCloudViz', url = 'https://public.tableau.com/views/Sub_Theme_Cloud/TopHighlightsinThisTheme?:toolbar=no&:showVizHome=no', height =
                               "60vh")
          ),
          # Info button - bottom left corner
          tags$button(
            id = 'dataSourceToggleSub',
            class = 'data-source-toggle',
            title = 'About this data',
            tags$i(class = 'fa fa-info', style = 'font-style: normal;')
          ),
          # Collapsible content
          div(
            id = 'dataSourceContentSub',
            class = 'data-source-content',
            tags$p(
              'Data source: ',
              tags$a(
                'Melbourne Open Data Portal',
                href = 'https://data.melbourne.vic.gov.au/',
                target = '_blank'
              )
            )
          )
        )
      ),
      column(width = 3, div(
        class = 'card',
        h4('Theme'),
        div(
          class = "radio-scroll",
          radioButtons(
            'themeSingle',
            NULL,
            choices = themes_available,
            selected = ifelse("Leisure" %in% themes_available, "Leisure", themes_available[1]),
            inline = FALSE
          )
>>>>>>> Stashed changes
        ),
        span(class = 'help-note', 'Choose one theme to update the word cloud and the rankings.')
      ))
    ),
    hr(style = 'border:0; border-top:3px solid #036B55; margin:20px 0 15px 0;'),
    fluidRow(column(
      width = 9,
      div(
        style = 'margin-bottom: 15px;',
        uiOutput("dynamic_ranking_title"),
        actionButton(
          'showMapBtn',
          'View on Map',
          icon = icon('map-marker-alt'),
          style = 'background: linear-gradient(to bottom, #048d6f 0%, #036B55 50%, #025246 100%); color:white; padding:10px 24px; border:none; border-radius:8px; font-size:14px; font-weight:600; cursor:pointer; vertical-align:middle; margin-left:10px; box-shadow: 0 4px 12px rgba(3, 107, 85, 0.35), inset 0 1px 0 rgba(255,255,255,0.2); transition: all 0.3s ease; position: relative; overflow: hidden;'
        )
      ),
      girafeOutput('plot_ranking', height = '95vh')
    ), column(
      width = 3, div(
        class = 'card',
        h4('Show top'),
        selectInput(
          'topN',
          NULL,
          choices = c(
            '5' = 5,
            '10' = 10,
            '15' = 15,
            '20' = 20
          ),
          selected = 10,
          width = '100%'
        ),
        hr(style = 'border-color:#036B55; margin:15px 0;'),
        p('Number of top-rated places to display', style = 'color:#666; font-size:11px; line-height:1.3;')
      )
    ))
  )
)

<<<<<<< Updated upstream

list(
  main_cloud_tab,
  sub_cloud_tab
)
=======
# Return both tabs as a list
list(main_cloud_tab, sub_cloud_tab)
>>>>>>> Stashed changes
