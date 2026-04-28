# Package index

## Main functions

- [`cm_start()`](https://riccardoc95.github.io/CudaMon/reference/cm_start.md)
  : Start sampling NVML metrics to CSV files
- [`cm_timestamp()`](https://riccardoc95.github.io/CudaMon/reference/cm_timestamp.md)
  : Record a workflow step during an active NVML sampling session
- [`cm_stop()`](https://riccardoc95.github.io/CudaMon/reference/cm_stop.md)
  : Stop an NVML background sampler
- [`cm_parser()`](https://riccardoc95.github.io/CudaMon/reference/cm_parser.md)
  : Read CSV output produced by the NVML sampler
- [`cm_vizdf()`](https://riccardoc95.github.io/CudaMon/reference/cm_vizdf.md)
  : Reshape sampled GPU metrics for visualization
- [`cm_plot_usage()`](https://riccardoc95.github.io/CudaMon/reference/cm_plot_usage.md)
  : Plot sampled GPU usage over time

## Session

- [`CudaMonSession()`](https://riccardoc95.github.io/CudaMon/reference/CudaMonSession.md)
  : Construct a CudaMon session object

## NVML bindings

- [`nvml_is_available()`](https://riccardoc95.github.io/CudaMon/reference/nvml_is_available.md)
  : Check whether NVML is available
- [`nvml_device_count()`](https://riccardoc95.github.io/CudaMon/reference/nvml_device_count.md)
  : Number of NVML‑visible devices
- [`nvml_list_devices()`](https://riccardoc95.github.io/CudaMon/reference/nvml_list_devices.md)
  : List NVML-visible devices
- [`nvml_list_compute_processes()`](https://riccardoc95.github.io/CudaMon/reference/nvml_list_compute_processes.md)
  : List compute processes active on NVML-visible GPUs
- [`nvml_get_metrics()`](https://riccardoc95.github.io/CudaMon/reference/nvml_get_metrics.md)
  : Get metrics for a device

## Internal

- [`nvml_check_status()`](https://riccardoc95.github.io/CudaMon/reference/nvml_check_status.md)
  : Convert an NVML error code to an R error
