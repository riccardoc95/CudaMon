source(system.file("future", "viz.R", package = "CudaMon"))

if (!requireNamespace("Rcollectl", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
  }
  remotes::install_github("vjcitn/Rcollectl")
}

library(CudaMon)
library(Rcollectl)

cl_sampler <- cl_start()
cm_sampler <- cm_start()
Sys.sleep(10)
cm_stop(cm_sampler)
cl_stop(cl_sampler)

cm_session <- cm_parser(cm_sampler)
cl_session <- cl_parse(cl_result_path(cl_sampler))

pdf("session.pdf", width = 8, height = 6)
plot_usage(cm_session, cl_session)
dev.off()
