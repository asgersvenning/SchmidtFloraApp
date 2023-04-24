adjust_page <- function(page) {
  adjustedPage <- page[2]
  
  if (page[1] == 1) {
    if (page[2] <= 22) {
      adjustedPage <- adjustedPage + 4
    }
    else if (page[2] > 22) {
      adjustedPage <- adjustedPage - 52
    }
  }
  else if (page[1] == 2) {
    if (page[2] < 180) {
      adjustedPage <- adjustedPage + 14
    }
    else if (page[2] >= 180 & page[2] < 267) {
      adjustedPage <- adjustedPage + 18
    } 
    else if (page[2] >= 267 & page[2] < 329) {
      adjustedPage <- adjustedPage + 30
    }
    else if (page[2] >= 329 & page[2] < 385) {
      adjustedPage <- adjustedPage + 42
    }
    else if (page[2] >= 385) {
      adjustedPage <- adjustedPage + 48
    }
  }
  
  adjustedPage
}

opacity_js_script <- "function(el, x, data) {
          var map = this;
          
          var updateBackgroundMapOpacity = function(e) {
            
            // Loop over all the active layers
            map.eachLayer(function(layerOrGroup) {
              
              // If the layer is a group and is not the 'Schmidt Map' group
              // (The 'eachLayer' function of the leaflet map object gets the layers both individually, but also grouped. AFAIK it is not possible to name individual layers (at least without discarding R-leaflet), so I just wrap each layer in a named group, and filter based on the name of the group, then get the layer(s) from the group. In principle I don't think it is possible to add more than one layer to the group using this approach, but the code here doesn't assume that the group contains only 1 layer, it would also work with multiple layers). 
              if (layerOrGroup.groupname != 'Schmidt Map' & Object.hasOwn(layerOrGroup, 'groupname')) {
                
                // Loop over all the values (layers) of the '_layers' attribute of the group
                // (There might be a more Leaflety way to do this)
                Object.values(layerOrGroup._layers).forEach(function(layer) {
                  
                  // Set the opacity based on the value attribute of the 'OpacitySlider' DOM element
                  // (The value is taken from the DOM directly to ensure that the 'updateBackgroundMapOpacity' function can be called by any event, and still apply the opacity correctly.)
                  if (typeof layer.setOpacity === 'function') {
                    layer.setOpacity(document.getElementById('OpacitySlider').value);
                  }
                });
              }
            });
          }
          
          // Disable map dragging while changing the opacity
          $('#OpacitySlider').mousedown(function() {
            map.dragging.disable();
          });
          $('#OpacitySlider').mouseup(function() {
            map.dragging.enable();
          });
          
          // Apply the opacity selection when the value attribute of the 'OpacitySlider' DOM element changes
          $('#OpacitySlider').on('input', updateBackgroundMapOpacity);
          
          // Ensure that the opacity selection is applied when switching the secondary layer
          $('.leaflet-control-layers-selector').on('input', updateBackgroundMapOpacity);
          
          // Ensure that the opacity selection is applied on load 
          map.whenReady(updateBackgroundMapOpacity);
        }"