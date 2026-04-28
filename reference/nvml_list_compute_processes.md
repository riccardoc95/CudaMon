# List compute processes active on NVML-visible GPUs

List compute processes active on NVML-visible GPUs

## Usage

``` r
nvml_list_compute_processes(device_index = NULL, pid = NULL)
```

## Arguments

- device_index:

  Optional integer GPU index. If `NULL`, query all devices.

- pid:

  Optional integer vector used to filter the returned processes.

## Value

A data frame with one row per GPU process observation
