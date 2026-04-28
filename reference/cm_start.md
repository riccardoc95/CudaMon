# Start sampling NVML metrics to CSV files

Start sampling NVML metrics to CSV files

## Usage

``` r
cm_start(
  period = 1,
  pid = Sys.getpid(),
  include_descendants = TRUE,
  device_index = NULL,
  log = NULL,
  path_prefix = NULL
)
```

## Arguments

- period:

  Sampling interval in seconds.

- pid:

  Root process identifier, defaults to the current R session PID.

- include_descendants:

  Whether to include child processes of `pid`.

- device_index:

  Optional integer GPU index. If `NULL`, query all devices.

- log:

  Optional log file written by the background sampler process.

- path_prefix:

  Optional output path prefix. If `NULL`, a unique prefix is generated
  automatically. Three files will be created: `*_device_metrics.csv`,
  `*_compute_processes.csv`, and `*_events.csv`.

## Value

A list with sampler metadata and class `nvml_sampler`.
