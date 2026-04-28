# Reshape sampled GPU metrics for visualization

Reshape sampled GPU metrics for visualization

## Usage

``` r
cm_vizdf(x, tz = "UTC", device_index = NULL)
```

## Arguments

- x:

  A `CudaMonSession` object returned by
  [`cm_parser()`](https://riccardoc95.github.io/CudaMon/reference/cm_parser.md).

- tz:

  Time zone used to parse timestamps.

- device_index:

  Optional integer GPU index. If `NULL`, include all sampled devices.

## Value

A long-format data frame suitable for plotting.
