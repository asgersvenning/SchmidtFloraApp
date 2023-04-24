# addResourcePath("www", "./www")

server <- function(input, output, session) {
  library(tidyverse)
  library(leaflet)
  library(pdfWheel)
  library(DT)
  source("helpers.r")
  
  ## pdfWheel setup
  ### My custom htmlwidget for arbitrarily large Shiny pdf's with reactivity 
  Schmidt <- pdfWheel("Schmidt", "www/pages", F)
  
  output$Schmidt <- renderPdfWheel({
    Schmidt$widget
  })
  
  ## DT setup
  DTData <- read_csv2("www/DTData.csv",
                      show_col_types = F,
                      locale = locale(decimal_mark = ",", grouping_mark = "."),
                      col_types = paste0("cccc", "nncD", paste0(rep("c",12), collapse = ""), "nncci"))
  
  ### Exposing the raw data to the user
  output$observationDataTable <- renderDT(
    DTData %>% 
      select(!c(Page, popup, rid, contains("Longitude"), contains("Latitude"))) %>% 
      datatable(
        options = list(
          columnDefs = map2(c(2, 3, 2, 2, 1, 2, 10, 10, 1, 3, 2, 2, 2, 2, 2, 2, 1, 2), 1:18, 
                            function(x, y) list(width = paste0(x*20, "px"), targets = y)),
          # columnDefs = list(list(
          #   targets = 7:8,
          #   render = JS("$.fn.dataTable.render.ellipsis( 17, false )")
          # )),
          # lengthChange = TRUE,
          autoWidth    = TRUE,
          pageLength   = 10,
          lengthMenu   = list(c(5, 10, 25, 100, -1), c("5", "10", "25", "100", "All")),
          paging       = TRUE,
          deferRender = TRUE,
          scrollX      = TRUE,
          buttons      = list(
            list(
              extend = "",
              text = "Apply filter to map",
              action = JS("function (e, dt, node, config) { Shiny.setInputValue('applyFilter', Shiny.shinyapp.$inputValues.applyFilter + 1, {priority: 'event'}); }")
            ),
            list(
              extend = "collection",
              buttons = list(
                list(
                  extend = "csv", 
                  text = "CSV",
                  exportOptions = list(modifier = list(page = "all"))
                ),
                list(extend = "excel",
                     text = "Excel",
                     exportOptions = list(modifier = list(page = "all"))
                ),
                list(extend = "pdf",
                     text = "PDF",
                     exportOptions = list(modifier = list(page = "all"))
                )),
              text = "Download (visible rows only)"
            )
          ),
          dom = "B<clear>rftip",
          server = FALSE),
        # plugins = "ellipsis",
        extensions = c(
          # "FixedColumns",
          
          "Buttons"),
        escape = FALSE
      )
  )
  
  ## Leaflet setup
  leafletData <- reactiveVal(
    DTData %>%
      select(c(contains("Longitude"), contains("Latitude"), popup, Herbarium, Page, rid)) %>% 
      mutate(Herbarium = c("Copenhagen" = "Copenhagen (Johannes Schmidt)", 
                           "Bangkok" = "Bangkok Forest Herbarium (BKF)", 
                           "Leiden" = "Leiden", 
                           "Aarhus" = "Aarhus (AAU)")[Herbarium] %>% 
               unname) %>% 
      rename_with(~str_remove(., "^centroid_"))
  )
  
  ### Apply DT search filter to Leaflet map data
  observeEvent({
    list(input$applyFilter, input$coordinateType)
  }, {
    selectRows <- if (is.null(input$observationDataTable_rows_all) || length(input$observationDataTable_rows_all) == 0) {
      1:nrow(DTData)
    } else {
      input$observationDataTable_rows_all
    }
    
    leafletData(
      DTData %>% 
        select(c(contains("Longitude"), contains("Latitude"), popup, Herbarium, Page, rid)) %>% 
        slice(selectRows) %>% 
        mutate(Herbarium = c("Copenhagen" = "Copenhagen (Johannes Schmidt)", 
                             "Bangkok" = "Bangkok Forest Herbarium (BKF)", 
                             "Leiden" = "Leiden", 
                             "Aarhus" = "Aarhus (AAU)")[Herbarium] %>% 
                 unname) %>% 
        rename_with(~str_remove(., if (!is.null(input$coordinateType)) input$coordinateType else "^centroid_"))
    )
  })
  
  sharedOptions <- tileOptions(
    minZoom = 8,
    maxZoom = 15,
    tms = F,
    errorTileUrl = "www/tiles/emptyTile.jpg"
  )
  
  markerColors <- colorFactor("Dark2", c("Copenhagen (Johannes Schmidt)", "Bangkok Forest Herbarium (BKF)", "Leiden", "Aarhus (AAU)"))
  
  output$KohChangMap <- renderLeaflet({
    DTData %>% 
      rename_with(~str_remove(., "^centroid_")) %>%
      leaflet() %>% 
      setMaxBounds(100, 10, 105, 15) %>% 
      setView(102.3516, 12.0263, 11) %>% 
      addTiles(
        urlTemplate = "www/tiles/{z}/{x}/{y}.jpg",
        group = "Schmidt Map",
        layerId = 1,
        attribution = "Digitized by Asger Svenning",
        options = sharedOptions) %>% 
      addProviderTiles(
        provider = providers$OpenStreetMap,
        group = "OpenStreetMap",
        layerId = 2,
        options = sharedOptions
      ) %>% 
      addProviderTiles(
        provider = providers$Esri.WorldImagery,
        group = "EsriImagery",
        layerId = 3,
        options = sharedOptions
      ) %>% 
      hideGroup("EsriImagery") %>% 
      addCircleMarkers(
        group = "Observations",
        radius = 5,
        stroke = F,
        fillOpacity = 0.75,
        fillColor = ~markerColors(Herbarium),
        popup = ~popup,
        layerId = ~paste0(Herbarium, rid),
        clusterOptions = markerClusterOptions()
      ) %>% 
      addLegend(
        position = "bottomleft", 
        pal = markerColors,
        values = c("Copenhagen (Johannes Schmidt)", "Bangkok Forest Herbarium (BKF)", "Leiden", "Aarhus (AAU)")
      ) %>% 
      addLayersControl(
        baseGroups = c("Schmidt Map"),
        overlayGroups = c(
          "OpenStreetMap",
          "EsriImagery",
          "Observations"
          # "Johannes Schmidt",
          # "Herbarium"
        ),
        options = layersControlOptions(F)
      ) %>% 
      addControl(html = '<input id="OpacitySlider" type="range" min="0" max="1" step="0.01" value="0.25">') %>%
      addControl(html = '<button id="clusterToggle" onclick="toggleClustering();"><center>Show/Hide<br>all observations</center></button>') %>% 
      addControl(html = '<button id="coordinateToggle" onclick="toggleCoordinates();"><center>Show coordinates as<br>centroid or spaced in polygon</center></button>') %>% 
      htmlwidgets::onRender(opacity_js_script) %>% 
      suppressWarnings() %>% 
      suppressMessages()
  })
  
  ## Custom leaflet-Shiny interactions
  ### Interaction between leaflet-circleMarkers and pdfWheel
  observeEvent(input$KohChangMap_marker_click, {
    observationId <- input$KohChangMap_marker_click
    if ("id" %in% names(observationId) && !is.null(observationId$id)) {
      rowNumber <- str_extract(observationId$id, "[:digit:]+") %>% 
        as.integer
      rowSource <- str_extract(observationId$id, "^[:alpha:]+")
      
      if (rowSource %in% c("Aarhus", "Leiden", "Bangkok")) {
        print(paste0("No shiny reactions to clicking on observation from \"", rowSource, "\" implemented yet."))
      }
      else if (rowSource == "Copenhagen") {
        pageNumber <- leafletData()$Page[rowNumber] %>% 
          str_extract("^[[:digit:]\\.]+") %>% 
          str_split_fixed("\\.", 2) %>% 
          as.vector %>% 
          str_extract("[:digit:]+") %>% 
          as.integer
        
        adjustedPageNumber <- adjust_page(pageNumber)
        
        Schmidt$changePage(adjustedPageNumber)
      }
      else {
        warning(paste0("Unknown source: \"", rowSource,"\"!"))
      }
    }
  })
  
  ### Toggle leaflet marker clustering
  observe({
    leafletData() %>% 
      {leafletProxy("KohChangMap", data = .)} %>%
      clearMarkerClusters() %>%
      clearMarkers() %>%
      addCircleMarkers(
        group = "Observations",
        radius = 5,
        stroke = F,
        fillOpacity = 0.75,
        fillColor = ~markerColors(Herbarium),
        popup = ~popup,
        layerId = ~paste0(Herbarium, rid),
        clusterOptions = if (!is.logical(input$clusterToggle) || input$clusterToggle) markerClusterOptions() else markerClusterOptions(disableClusteringAtZoom = 8)
      ) %>% 
      suppressWarnings() %>% 
      suppressMessages()
  })
}