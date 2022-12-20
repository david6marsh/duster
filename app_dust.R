# using plotly and magick to provide some dust-cleaning functions
# library(magrittr)
library(shiny)
library(magick)

## ui.R
ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("Duster", windowTitle = "Photo Duster"),
  verticalLayout(
    inputPanel(
      fileInput("file1", "Choose .jpg file", accept = ".jpg"),
      checkboxInput("showOriginal", "Show original", FALSE),
      sliderInput("zoom", "Zoom", min = 1, max = 400, 
                  value = 100, post = "%"),
      actionButton("reset", "Reset")
    ),
    fluidRow(
      shinydashboard::box(width = 12, 
                          style='width:800px;overflow-x: scroll;height:500px;overflow-y: scroll;',
                          plotOutput("p1", width = "100%")
      )),
    fluidRow(
      conditionalPanel(
        condition = "input.showOriginal",
        titlePanel("Original:"),
        shinydashboard::box(width = 12, 
                            style='width:800px;overflow-x: scroll;height:500px;overflow-y: scroll;',
                            plotOutput("p0", width = "100%")
        )
      )
    )
  )
)

## server.R
server <- function(input, output, session){
  
  observeEvent(input$reset, {
    shinyjs::reset("zoom")
  })
  
  #get image and its metadata
  i_raw <- reactive({
    i_file <- "data/Dust1_323x302.jpg" #default during development
    if (is.data.frame(input$file1)) i_file <- req(input$file1$datapath)
    # i_file <-  "data/Dust1_323x302.jpg"
    img <- magick::image_read(i_file) 
    
    w <- image_info(img)$width
    h <- image_info(img)$height
    list(
      raster = as.raster(img),
      w = w,
      h = h
    )
  })

  # a function factory to conveniently get out an images dimension
  img_dim_f <- function(parm, min_pix = 40) {
    function() {
      p <- 0
      i <- req(i_final())
      if (isTruthy(i)) {
        if (isTruthy(i[[parm]])) {
          p <- i[[parm]]
        }
      }
      z <- req(input$zoom)
      # zoom, keep integer and not smaller than min_pix (some distortion possible)
      max(ceiling(p * z/100), min_pix)
    }
  }
  
  i_final <- i_raw
  
  output$p0 <- renderPlot(
    expr = {
      i <- req(i_raw())
      r <- req(i$raster)
      plot(r)
    },
    # use final width, not raw
    width = img_dim_f("w"),
    height = img_dim_f("h")
  )
  
  output$p1 <- renderPlot(
    expr = {
      i <- req(i_final())
      r <- req(i$raster)
      plot(r)
    },
    width = img_dim_f("w"),
    height = img_dim_f("h")
  )
  
  return(output)
}




### Run Application
shinyApp(ui, server, options = list("launch.browser" = TRUE))