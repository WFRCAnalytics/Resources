library(shinydashboard)
library(shinyalert)  # Include shinyalert library
library(tidyverse)  # Not actually used in this script, could be removed if not used elsewhere
library(bslib)  # For theming, ensure its use or remove if unnecessary
library(ggplot2)
library(dplyr)

# It's assumed that functions.R, if needed, loads necessary data and functions
source("functions.R")  # Make sure this file is necessary and contains needed components

ui <- dashboardPage(
  dashboardHeader(title = "Trip Length Distributions from the 2023 Household Travel Survey", titleWidth = 700,
                  tags$li(class = "dropdown", style = "float:right; padding: 10px;", textOutput("date"))
  ),
  dashboardSidebar(
    # Sidebar panel for inputs
    selectInput("countyGroup",
                "Select Origin County Group:",
                choices = setNames(labelsCountyGroups$value, labelsCountyGroups$label)),
    selectInput("binSize",
                "Select Bin Size:",
                choices = setNames(labelsBinSizes$value, labelsBinSizes$label)),
    selectInput("modeTypeBroad",
                "Select Broad Mode:",
                choices = setNames(labelsModeTypeBroad$value, labelsModeTypeBroad$label)),
    selectInput("tripType",
                "Select Trip Type:",
                choices = setNames(labelsTripType$value, labelsTripType$label)),
    selectInput("numVehicles",
                "Select HH Number of Vehicles:",
                choices = setNames(labelsNumVehicles$value, labelsNumVehicles$label)),
    selectInput("numWorkers",
                "Select HH Number of Workers:",
                choices = setNames(labelsNumWorkers$value, labelsNumWorkers$label)),
    selectInput("typeChart",
                "Select Type of Plot:",
                choices = c("Histogram" = "histogram",
                            "Cumulative Distribution" = "cumulative",
                            "Number of Records" = "records")),
    selectInput("maxX",
                "Select Max X-axis Value:",
                choices = seq(5, 100, by = 5),
                selected = 30)
  ),
  dashboardBody(
    plotOutput("dataPlot"),
    tableOutput("dataTable")
  )
)

server <- function(input, output) {
  
  useShinyalert()  # Initialize shinyalert
  
  # Display the alert when the app is opened
  shinyalert(
    text = "The 2023 Utah Moves household travel survey was designed and conducted for use in regional and statewide travel demand modeling.  The sample size and frame is suitable for that purpose.
    \n Proper application of the dataset and use of this application is the responsibility of the user. In using the information or data herein, users assume the risk for relying on such data or information, and further agree to hold Utah's transportation agencies harmless for all liability of any nature resulting from the lack of accuracy or correctness of the information or data, or uses of the information or data. The user acknowledges that the use of this information or data may be subject to error and omission, and the accuracy of the information provided is not guaranteed or represented to be true, complete, nor correct. 
    \n Users are encouraged to contact analytics@wfrc.org with questions or to discuss proper uses and application of this data.",
    closeOnClickOutside = FALSE,
    closeOnEsc = FALSE,
    confirmButtonText = "I acknowledge and agree",
    size="m"
  )
  
  observe({
    # Convert inputs to numeric to avoid non-numeric errors
    numeric_binSize <- as.numeric(input$binSize)
    numeric_maxX <- as.numeric(input$maxX)
    
    output$dataPlot <- renderPlot({
      filtered_data <- data %>%
        filter(countyGroup == input$countyGroup,
               num_workers == input$numWorkers,
               num_vehicles == input$numVehicles,
               trip_type == input$tripType,
               mode_type_broad == input$modeTypeBroad,
               binSize == numeric_binSize)
      
      lowerlimit <- -0.5 * numeric_binSize
      
      if (input$typeChart == "histogram") {
        ggplot(filtered_data, aes(x = binStart + numeric_binSize / 2, y = percentage)) +
          geom_bar(stat = "identity", position = "dodge", fill = "steelblue", width = numeric_binSize) +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX + numeric_binSize / 2),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Trip Length Histogram",
               x = "Distance (miles)",
               y = "Percentage")
      } else if (input$typeChart == "records") {
        ggplot(filtered_data, aes(x = binStart + numeric_binSize / 2, y = numRecords)) +
          geom_bar(stat = "identity", position = "dodge", fill = "steelblue", width = numeric_binSize) +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX + numeric_binSize / 2),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Number of Records by Bin",
               x = "Distance (miles)",
               y = "Records")
      } else {
        ggplot(filtered_data, aes(x = binStart, y = cumulative_percentage)) +
          geom_line() +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Trip Length Cumulative Distribution",
               x = "Distance (miles)",
               y = "Cumulative Percentage")
      }
    })
    
    output$dataTable <- renderTable({
      filtered_data <- data %>%
        filter(countyGroup == input$countyGroup,
               num_workers == input$numWorkers,
               num_vehicles == input$numVehicles,
               trip_type == input$tripType,
               mode_type_broad == input$modeTypeBroad,
               binSize == numeric_binSize)
      
      filtered_data
    })
  })
}

shinyApp(ui = ui, server = server)
