# using plotly and magick to provide some dust-cleaning functions
# library(magrittr)
library(shiny)
library(magick)

## ui.R
ui <- fluidPage(
  titlePanel("Duster", windowTitle = "Photo Duster"),
  verticalLayout(
    inputPanel(
      fileInput("file1", "Choose .jpg file", accept = ".jpg"),
      checkboxInput("showOriginal", "Show original", FALSE)
    ),
    plotOutput("p1"),
    conditionalPanel(
      condition = "input.showOriginal",
      titlePanel("Original:"),
      plotOutput("p0")
    )
  )
)

## server.R
server <- function(input, output, session){
  
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
  img_dim_f <- function(parm) {
    function() {
      p <- 0
      i <- req(i_final())
      if (isTruthy(i)) {
        if (isTruthy(i[[parm]])) {
          p <- i[[parm]]
        }
      }
      p
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