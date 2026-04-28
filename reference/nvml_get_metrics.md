# Get metrics for a device

Get metrics for a device

## Usage

``` r
nvml_get_metrics(device_index)
```

## Arguments

- device_index:

  Integer, 0‑based GPU index

## Value

A named list with utilization percentages, temperature in Celsius, power
draw in milliwatts, and memory usage in bytes
