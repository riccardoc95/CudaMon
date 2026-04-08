## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>",
    crop = NULL ## Related to https://stat.ethz.ch/pipermail/bioc-devel/2020-April/016656.html
)

## ----vignetteSetup, echo=FALSE, message=FALSE, warning = FALSE----------------
## Track time spent on making the vignette
startTime <- Sys.time()

## Bib setup
library("knitcitations")

## Load knitcitations with a clean bibliography
cleanbib()
cite_options(hyperlink = "to.doc", citation_format = "text", style = "html")

## Write bibliography information
bib <- c(
    R = citation(),
    BiocStyle = citation("BiocStyle")[1],
    knitcitations = citation("knitcitations")[1],
    knitr = citation("knitr")[1],
    rmarkdown = citation("rmarkdown")[1],
    sessioninfo = citation("sessioninfo")[1],
    testthat = citation("testthat")[1],
    Rcollectl = citation("Rcollectl")[1]
)

write.bibtex(bib, file = "Rcollectl.bib")

## ----"start", message=FALSE---------------------------------------------------
library("Rcollectl")

## ----lkdemo-------------------------------------------------------------------
lk = cl_parse(system.file("demotab/demo_1123.tab.gz", package="Rcollectl"))
dim(lk)
attr(lk, "meta")
lk[1:5,1:5]

## ----lkviz--------------------------------------------------------------------
plot_usage(lk)

## ----lklk,eval=FALSE----------------------------------------------------------
# id = cl_start([target file prefix])
# [use R until task to be measured is complete]
# cl_stop(id)
# usage_df = cl_parse(dir(patt=[target file prefix]))
# # analyze or filter the usage_df (for example, to trim away
# # time related to task delay or delay of `cl_stop`
# plot_usage(usage_df)

## ----lkts, eval=TRUE----------------------------------------------------------
     id <- cl_start() 
     Sys.sleep(2)
     #code
     cl_timestamp(id, "step1")
     Sys.sleep(2)
     # code
     Sys.sleep(2)
     cl_timestamp(id, "step2")
     Sys.sleep(2)
     # code
     Sys.sleep(2)
     cl_timestamp(id, "step3")
     Sys.sleep(2)
     # code
     cl_stop(id)
     path <- cl_result_path(id)
     
     plot_usage(cl_parse(path)) +
       cl_timestamp_layer(path) +
       cl_timestamp_label(path) +
       ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust=1))

## ----createVignette, eval=FALSE-----------------------------------------------
# ## Create the vignette
# library("rmarkdown")
# system.time(render("Rcollectl.Rmd", "BiocStyle::html_document"))
# 
# ## Extract the R code
# library("knitr")
# knit("Rcollectl.Rmd", tangle = TRUE)

## ----createVignette2----------------------------------------------------------
## Clean up
file.remove("Rcollectl.bib")

## ----reproduce1, echo=FALSE---------------------------------------------------
## Date the vignette was generated
Sys.time()

## ----reproduce2, echo=FALSE---------------------------------------------------
## Processing time in seconds
totalTime <- diff(c(startTime, Sys.time()))
round(totalTime, digits = 3)

## ----reproduce3, echo=FALSE-------------------------------------------------------------------------------------------
## Session info
library("sessioninfo")
options(width = 120)
session_info()

## ----vignetteBiblio, results = "asis", echo = FALSE, warning = FALSE, message = FALSE---------------------------------
## Print bibliography
bibliography()

