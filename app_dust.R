# using plotly and magick to provide some dust-cleaning functions
# library(magrittr)
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
             p("Reset: returns to default values.")
    )
    ))
)

img_list <- function(img){
  # return a list structure containing the image magick image
  w <- image_info(img)$width
  h <- image_info(img)$height
  list(
    img = img,
    w = w,
    h = h
  )
}

## server.R
server <- function(input, output, session){
  
  observeEvent(input$reset, {
    shinyjs::reset("zoom")
    shinyjs::reset("md_radius")
    shinyjs::reset("k_radius")
    shinyjs::reset("threshold")
    shinyjs::reset("trim")
  })
  
  #get image and its metadata
  i_raw <- reactive({
    i_file <- "data/Dust1_323x302.jpg" #default during development
    if (is.data.frame(input$file1)) i_file <- req(input$file1$datapath)
    # i_file <-  "data/Dust1_323x302.jpg"
    img <- image_read(i_file) |> 
      image_convert("png")
    
    # cat(file=stderr(), input$file1$datapath, input$file1$name)
    img_list(img) #result
  })

  # first remove any unwanted border
  i_trim <- reactive({
    req(i_raw(), input$trim)
    img <- i_raw()$img |> 
      # trim black edges (not just black due to jpeg)
      image_trim(fuzz = input$trim) 
    img_list(img)
  })
  
  # smoothed image, for filling in with
  i_md <- reactive({
    req(i_trim(), input$md_radius)
    img <- i_trim()$img |> 
      # smoothing
      image_median(radius = input$md_radius)  
    img_list(img)
  })
  
  # a function factory to conveniently get out an images dimension
  img_dim_f <- function(parm, min_pix = 40) {
    function() {
      p <- 0
      i <- req(i_trim())
      if (isTruthy(i)) {
        if (isTruthy(i[[parm]])) {
          p <- i[[parm]]
        }
      }
      # scale is fit image to window height
      sc <- 400/i$h #400 pix is height defined above
      # zoom is user-selected magnification
      z <- req(input$zoom)
      # zoom, keep integer and not smaller than min_pix (some distortion possible)
      max(ceiling(p * sc * z/100), min_pix)
    }
  }
  
  # create the dust mask
  i_mask <- reactive({
    req(i_trim(), input$k_radius, input$threshold)
    # find peaks
    img <- i_trim()$img |> 
      image_morphology("bottomhat", stringr::str_c("disk:", 
                                                   round(as.numeric(input$k_radius), 1))) |> 
      image_threshold(threshold = stringr::str_c(input$threshold, "%"),
                      type = "white") |> 
      # dilate by a pixel. default rectangle is a 3x3-pixel square
      image_morphology("dilate", "rectangle")
    
    img_list(img) #result
  })
  
  i_final <- reactive({
    req(i_trim(), i_md(), i_mask())
    img1 <- i_md()$img |> 
      # just the mask bit of this
      image_composite(i_mask()$img, operator = "CopyOpacity")
   # combine
    img <- i_trim()$img |>
      image_composite(img1, operator = "atop") 

    img_list(img) #result
  })

  # default params
  i_renderPlot <- function(...){renderPlot(..., width = img_dim_f("w"),
                                      height = img_dim_f("h"))}
    
  # graphical outputs
  output$p0 <- i_renderPlot({plot(i_raw()$img)})
  
  output$pd <- i_renderPlot({
    plot(i_mask()$img)
  })
  
  output$p1 <- i_renderPlot({
      plot(i_final()$img)
    })
  
  output$download <- downloadHandler(
    filename = function() {
      paste0(stringr::str_remove(input$file1$name, ".jpg"), "_dusted.jpg")
    },
    content = function(file) {
      image_write(i_final()$img, file, format = "jpg")
    }
  )
  
  return(output)
}


### Run Application
shinyApp(ui, server, options = list("launch.browser" = TRUE))