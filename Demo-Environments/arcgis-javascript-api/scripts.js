let legend;

require([
    "esri/Map",
    "esri/views/MapView",
    "esri/layers/GeoJSONLayer",
    "esri/layers/CSVLayer",
    "esri/symbols/SimpleLineSymbol",
    "esri/symbols/SimpleMarkerSymbol",
    "esri/Color",
    "esri/renderers/ClassBreaksRenderer",
    "esri/widgets/Legend"
], function(Map, MapView, GeoJSONLayer, CSVLayer, SimpleLineSymbol, SimpleMarkerSymbol, Color, ClassBreaksRenderer, Legend) {


    // CREATE MAP
    const map = new Map({
        basemap: "gray-vector" // Basemap service
    });


    // ADD NEW VIEW OF MAP
    const view = new MapView({
        container: "viewDiv",
        map: map,
        center: [-111.8910, 40.7608], // center on Salt Lake County
        zoom: 10, // Zoom level
    });

    
    // ADD SEGMENTS LAYER

    // connect to Segments GeoJSON layer
    const geojsonSegments = new GeoJSONLayer({
        url: "data/segments.geojson",
        title: "Segments",
        renderer: new ClassBreaksRenderer({
            field: "AADT2021",
            classBreakInfos: [
                { minValue:   0.01, maxValue:     5999, symbol: new SimpleLineSymbol({ color: new Color("#31398a"), width: 0.5000 }), label: "Less than 6,000"   },
                { minValue:   6000, maxValue:    17999, symbol: new SimpleLineSymbol({ color: new Color("#1ba9e6"), width: 1.1000 }), label: "6,000 to 18,000"   },
                { minValue:  18000, maxValue:    35999, symbol: new SimpleLineSymbol({ color: new Color("#00a74e"), width: 1.7000 }), label: "18,000 to 36,000"  },
                { minValue:  36000, maxValue:    71999, symbol: new SimpleLineSymbol({ color: new Color("#6cb74a"), width: 2.3000 }), label: "36,000 to 72,000"  },
                { minValue:  72000, maxValue:   119999, symbol: new SimpleLineSymbol({ color: new Color("#8dc348"), width: 3.9000 }), label: "72,000 to 120,000" },
                { minValue: 120000, maxValue:   159999, symbol: new SimpleLineSymbol({ color: new Color("#E09d2e"), width: 3.5000 }), label: "120,000 to 160,000"},
                { minValue: 160000, maxValue:   199999, symbol: new SimpleLineSymbol({ color: new Color("#Eb672d"), width: 4.1000 }), label: "160,000 to 200,000"},
                { minValue: 200000, maxValue:   239999, symbol: new SimpleLineSymbol({ color: new Color("#E5272d"), width: 4.7000 }), label: "200,000 to 240,000"},
                { minValue: 240000, maxValue: Infinity, symbol: new SimpleLineSymbol({ color: new Color("#Af2944"), width: 5.3000 }), label: "More than 240,000" }
            ]
        })
    });

    // add Segments layer to map
    map.add(geojsonSegments);


    // LISTENERS FOR USING WIDGETS

    // add listener to update renderer based on selection change
    document.getElementById("selectAadtYear").addEventListener("calciteSelectChange", function(event) {
        const selectedValue = event.target.selectedOption.value;
        console.log("Selected value:", selectedValue);

        geojsonSegments.renderer.field = selectedValue;
        geojsonSegments.refresh();

    });

    // add listenter for check box to update display of Segments layer
    document.getElementById("checkboxSegments").addEventListener("calciteCheckboxChange", function(event) {
        let isChecked = event.target.checked;
        console.log("Segments Checkbox is:", isChecked ? "Checked" : "Unchecked");

        if (isChecked) {
            geojsonSegments.visible = false;  // Hide the segmentsLayer when checked
        } else {
            geojsonSegments.visible = true;   // Show the segmentsLayer when unchecked
        }
    });
    
    
    // ADD CSV LAYER

    // URL of the CSV file (change this to your CSV file's location)
    const url = "data/random-spots.csv";

    // Create the CSVLayer and specify its properties
    const csvRandomSpots = new CSVLayer({
        url: url,
        title: "Random Spots",
        latitudeField: "lat",  // Change these based on your CSV column names
        longitudeField: "lon",
        renderer: new ClassBreaksRenderer({
            field: "customers",
            classBreakInfos: [{
                minValue: 0,
                maxValue: 999,
                symbol: new SimpleMarkerSymbol({
                    color: "blue",
                    size: "10px"
                }),
                label: "Low (0-999)"
            }, {
                minValue: 1000,
                maxValue: 1499,
                symbol: new SimpleMarkerSymbol({
                    color: "yellow",
                    size: "20px"
                }),
                label: "Medium (1000-1499)"
            }, {
                minValue: 1500,
                maxValue: 3000,  // Assuming 3000 is the max value you expect
                symbol: new SimpleMarkerSymbol({
                    color: "red",
                    size: "30px"
                }),
                label: "High (1500-3000)"
            }]
        })
    });

    // Add the CSVLayer to the map
    map.add(csvRandomSpots);


    // CREATE LEGEND WIDGET
    legend = new Legend({
        view: view,
        layerInfos: [
                      { layer: csvRandomSpots , title: 'Random Spots' },
                      { layer: geojsonSegments, title: 'Segments'     }
                    ]
    });
    view.ui.add(legend, "top-right");

});
