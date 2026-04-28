# CudaMon with Rcollectl

This vignette shows how to combine GPU monitoring from `CudaMon` with
CPU and system metrics collected through `Rcollectl`.

At the moment the combined plotting helper lives in the package’s
experimental area, so it must be loaded explicitly.

## Load packages and helper code

``` r
source(system.file("future", "viz.R", package = "CudaMon"))

if (!requireNamespace("Rcollectl", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
  }
  remotes::install_github("vjcitn/Rcollectl")
}

library(CudaMon)
library(Rcollectl)
```

## Start CPU and GPU samplers together

`cl_start()` starts the `collectl`-based sampler, while
[`cm_start()`](https://riccardoc95.github.io/CudaMon/reference/cm_start.md)
starts the NVML sampler for GPU metrics.

``` r
cl_sampler <- cl_start()
cm_sampler <- cm_start()
```

## Run a workload and record event markers

The example below records three simple workflow steps while both
samplers are active.

``` r
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 1")
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 2")
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 3")
Sys.sleep(2)
```

## Stop both samplers

Stop the GPU sampler first, then stop the `collectl` sampler and parse
both outputs.

``` r
cm_stop(cm_sampler)
cl_stop(cl_sampler)

cm_session <- cm_parser(cm_sampler)
cl_session <- cl_parse(cl_result_path(cl_sampler))
```

## Plot CPU and GPU metrics together

`plot_usage()` combines:

- CPU and system metrics coming from `Rcollectl`
- GPU metrics coming from `CudaMon`
- event markers recorded with
  [`cm_timestamp()`](https://riccardoc95.github.io/CudaMon/reference/cm_timestamp.md)

The example below renders the combined plot in the Rome time zone.

``` r
p <- plot_usage(cm_session, cl_session, tz = "Europe/Rome")
p
```

## Complete example

``` r
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
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 1")
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 2")
Sys.sleep(2)
cm_timestamp(cm_sampler, "step 3")
Sys.sleep(2)
cm_stop(cm_sampler)
cl_stop(cl_sampler)

cm_session <- cm_parser(cm_sampler)
cl_session <- cl_parse(cl_result_path(cl_sampler))

pdf("session.pdf", width = 8, height = 6)
plot_usage(cm_session, cl_session, tz = "Europe/Rome")
dev.off()
```
