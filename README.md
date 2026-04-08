# CudaMon

CudaMon is an R package for monitoring NVIDIA GPU activity through NVML and collecting simple resource traces that can be plotted from R.

## Install

```sh
R CMD INSTALL .
```

## Example

```r
library(CudaMon)

sampler <- nvml_sample_start(period = 0.5)
Sys.sleep(2)
nvml_sample_stop(sampler)

session <- nvml_sample_read(sampler)
plot_usage(session)
```

## Tests

```sh
R -q -e "library(CudaMon); library(testthat); testthat::test_dir('tests/testthat')"
```
