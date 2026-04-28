# Record a workflow step during an active NVML sampling session

Record a workflow step during an active NVML sampling session

## Usage

``` r
cm_timestamp(sampler, step)
```

## Arguments

- sampler:

  A sampler object returned by
  [`cm_start()`](https://riccardoc95.github.io/CudaMon/reference/cm_start.md).

- step:

  A short label identifying the current workflow step.

## Value

Invisibly returns the sampler.
