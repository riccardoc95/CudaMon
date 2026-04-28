# Read CSV output produced by the NVML sampler

Read CSV output produced by the NVML sampler

## Usage

``` r
cm_parser(sampler)
```

## Arguments

- sampler:

  A sampler object returned by
  [`cm_start()`](https://riccardoc95.github.io/CudaMon/reference/cm_start.md),
  or a character path prefix used to build the sampler output paths.

## Value

A `CudaMonSession` object.
