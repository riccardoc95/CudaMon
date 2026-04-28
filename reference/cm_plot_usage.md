# Plot sampled GPU usage over time

Plot sampled GPU usage over time

## Usage

``` r
cm_plot_usage(x, tz = "UTC", device_index = NULL)
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

A ggplot object with one facet per metric.
