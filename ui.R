# using plotly and magick to provide some dust-cleaning functions
library(shiny)
library(magick)

## ui.R
ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("Photo Duster", windowTitle = "Photo Duster"),
  verticalLayout(
    inputPanel(
      sliderInput("trim", "Edge crop strength", min = 0, max = 50,
                  value = 25),
      # for radius, there are really only discrete options, 
      # see https://imagemagick.org/Usage/morphology/#disk
      selectInput("k_radius", "Detection Radius", 
                  choices = c(1, 1.5, 2.0, 2.5, 2.9, 3.5, 3.9, 4.3, 4.5, 5.3),
                  selected = 2.9, width = "50%"),
      sliderInput("threshold", "Detection Threshold", min = 1, max = 25,
                  value = 19, post = "%", step = 1.0),
      sliderInput("md_radius", "Replacement Radius", min = 2, max = 15,
                  value = 8, post = "px"),
      actionButton("reset", "Reset")
    ),
    tabsetPanel(type = "tabs",
                tabPanel("Single",
                         inputPanel(
                                  fileInput("file1", "Upload .jpg file", accept = ".jpg"),
                                  # checkboxInput("showDust", "Show dust", TRUE),
                                  checkboxInput("showOriginal", "Show original", FALSE),
                                  sliderInput("zoom", "Image Zoom", min = 1, max = 400, 
                                              value = 100, post = "%"),
                                  downloadButton("download", "Download dusted image")
                                ),
                         fluidRow(
                           shinydashboard::box(width = 6, 
                                               style='overflow-x: scroll;height:400px;overflow-y: scroll;',
                                               plotOutput("p1")
                           ),
                           shinydashboard::box(width = 6, 
                                                 style='overflow-x: scroll;height:400px;overflow-y: scroll;',
                                                 plotOutput("pd")
                           )),
                         conditionalPanel(
                             condition = "input.showOriginal",
                             titlePanel("Original:"),
                             shinydashboard::box(width = 12, 
                                                 style='overflow-x: scroll;height:400px;overflow-y: scroll;',
                                                 plotOutput("p0"))
                           )
                ),
    tabPanel("Instructions",
             strong("How to use the single-image tool."),
             p("1. Upload a jpeg. It will be shown, together with the dust detected using the default settings."),
             p("2. If there is a 'black' border, it will be mostly removed. If too much is being removed, reduce the edge crop strength."),
             p("3. Check the dust. If not enough is being found, increase the detection radius or reduce the detection threshold. It's likely that some larger pieces will escape"),
             p("4. Check the dust again. If it is showing real structure from the image (eg mouth, fabric texture), increase the detection threshold."),
             p("5. When you're happy, download the image to your browser's default download folder."),
             p("Reset: returns to default values."),
             div(),
             p("For more details and licensing, see ", a(href = "https://github.com/david6marsh/duster", "the github page."))
    )
    ))
)
