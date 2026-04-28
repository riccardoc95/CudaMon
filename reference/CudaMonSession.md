# Construct a CudaMon session object

Construct a CudaMon session object

## Usage

``` r
CudaMonSession(
  device_metrics = data.frame(),
  compute_processes = data.frame(),
  events = data.frame(),
  paths = list(),
  metadata = list()
)
```

## Arguments

- device_metrics:

  Data frame with GPU device-level samples.

- compute_processes:

  Data frame with GPU process-level samples.

- paths:

  Named list of output paths.

- metadata:

  Named list with session metadata.

## Value

An object of class `CudaMonSession`.
