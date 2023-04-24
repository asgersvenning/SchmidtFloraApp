library(shiny)
library(leaflet)
library(pdfWheel)
library(DT)

ui <- fluidPage(
  navbarPage(
    bslib:::navbarMenu_(
      title = "Flora of Koh Chang",
      icon = tags$img(src = "www/icon.png",
                      style = "height: calc(100% + 20px); float: left; margin: -10px 10px 0px 0px;"),
      align = NULL
    ),
    tabPanel(
      title = "Map",
      leafletOutput("KohChangMap", height = "90vh")
    ),
    tabPanel(
      title = "Observations",
      DTOutput("observationDataTable")
    ),
    tabPanel(
      title = "Original Reference",
      pdfWheelOutput("Schmidt", 400, 400 / 0.57)
    )
  ),
  tags$head(
    tags$style(HTML("
      #KohChangMap {
          margin: auto;
      }
      div.navbar-header {
          margin-left: 10px !important;
      }
      ")),
    tags$script(HTML('
      $(document).on("shiny:sessioninitialized", function(event) {
        // Initialize shiny input "applyFilter"
        Shiny.setInputValue("applyFilter", 1, {priority: "event"});
      
        // Initialize shiny input "clusterToggle"
        Shiny.setInputValue("clusterToggle", true, {priority: "event"});
        
        $("#clusterToggle").mousedown(function() {
                   map.dragging.disable();
                   });
        $("#clusterToggle").mouseup(function() {
          map.dragging.enable();
        });
        
        // Initialize shiny input coordinateToggle
        Shiny.setInputValue("coordinateType", "^centroid_", {priority: "event"});
        $("#coordinateToggle").mousedown(function() {
          map.dragging.disable();
        });
        $("#coordinateToggle").mouseup(function() {
          map.dragging.enable();
        });
      });
      
      function toggleClustering() {
        Shiny.setInputValue("clusterToggle", !Shiny.shinyapp.$inputValues.clusterToggle, {priority: "event"});
      };
      
      function toggleCoordinates() {
        Shiny.setInputValue("coordinateType", (Shiny.shinyapp.$inputValues.coordinateType == "^centroid_") ? "^spaced_" : "^centroid_", {priority: "event"});
      };
                     '))
  )
)