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

  Data frame with GPU device-level samples. Expected columns include:

  timestamp

  :   Sample timestamp in UTC.

  sampler_pid

  :   Root process identifier tracked by the sampler.

  device_index

  :   Zero-based GPU device index.

  gpu_utilization_pct

  :   Percent of the sampling interval during which at least one kernel
      was executing on the GPU. This is an activity ratio, not a measure
      of how saturated the GPU cores were.

  memory_utilization_pct

  :   Percent of the sampling interval during which global device memory
      was being read from or written to. This is memory-controller
      activity, not the fraction of GPU memory allocated.

  temperature_c

  :   GPU temperature in degrees Celsius.

  power_usage_mw

  :   Instantaneous board power draw in milliwatts.

  memory_used_bytes

  :   Bytes of device memory currently allocated.

  memory_total_bytes

  :   Total bytes of device memory available.

- compute_processes:

  Data frame with GPU process-level samples. Expected columns include:

  timestamp

  :   Sample timestamp in UTC.

  sampler_pid

  :   Root process identifier tracked by the sampler.

  device_index

  :   Zero-based GPU device index.

  pid

  :   Process identifier reported by NVML as using the GPU.

  tracked_pid

  :   Tracked process identifier after filtering to the requested root
      process and, optionally, its descendants.

  is_root_pid

  :   Whether `tracked_pid` is the root process passed to the sampler.

  used_gpu_memory_bytes

  :   Bytes of GPU memory allocated by the process on the sampled
      device, when reported by NVML.

  gpu_instance_id

  :   MIG GPU instance identifier, or `NA` when it does not apply or is
      not reported.

  compute_instance_id

  :   MIG compute instance identifier, or `NA` when it does not apply or
      is not reported.

- events:

  Data frame with event markers recorded during sampling.

- paths:

  Named list of output paths.

- metadata:

  Named list with session metadata.

## Value

An object of class `CudaMonSession`.
