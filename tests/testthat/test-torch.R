run_torch_cuda_matmul <- function(torch, size = 1000L, iterations = 2L) {
  shape <- reticulate::tuple(as.integer(size), as.integer(size))

  a <- torch$randint(
    low = as.integer(-128L),
    high = as.integer(128L),
    size = shape,
    device = "cuda"
  )$to(dtype = torch$float32)
  b <- torch$randint(
    low = as.integer(-128L),
    high = as.integer(128L),
    size = shape,
    device = "cuda"
  )$to(dtype = torch$float32)

  start <- proc.time()[["elapsed"]]
  out <- NULL

  for (iter in seq_len(as.integer(iterations))) {
    out <- torch$matmul(b, a$transpose(0L, 1L))
  }

  torch$cuda$synchronize()
  elapsed_ms <- (proc.time()[["elapsed"]] - start) * 1000

  list(
    total_time_ms = as.double(elapsed_ms),
    ndim = as.integer(reticulate::py_to_r(out$dim())),
    nrow = as.integer(reticulate::py_to_r(out$size(as.integer(0L)))),
    ncol = as.integer(reticulate::py_to_r(out$size(as.integer(1L))))
  )
}

test_that("CudaMon monitors GPU activity during Torch CUDA matrix multiplication", {
  skip_if_no_nvidia_gpu()
  torch <- import_torch_with_cuda()

  prefix <- tempfile("cudamon-torch-")
  plot_path <- paste0(prefix, "_usage.png")
  stopped <- FALSE

  sampler <- CudaMon:::cm_start(
    path_prefix = prefix,
    period = 0.2,
    pid = Sys.getpid(),
    include_descendants = TRUE
  )

  CudaMon:::cm_timestamp(sampler, "torch_matmul_start")
  result <- run_torch_cuda_matmul(torch, size = 1000L, iterations = 2L)
  CudaMon:::cm_timestamp(sampler, "torch_matmul_end")
  CudaMon:::cm_stop(sampler)
  stopped <- TRUE

  session <- CudaMon:::cm_parser(sampler)
  plot_obj <- CudaMon:::plot_usage(session)
  ggplot2::ggsave(plot_path, plot_obj, width = 8, height = 5, dpi = 120)

  expect_true(is.finite(result$total_time_ms))
  expect_gt(result$total_time_ms, 0)
  expect_identical(result$ndim, 2L)
  expect_identical(result$nrow, 1000L)
  expect_identical(result$ncol, 1000L)
  expect_gt(nrow(session$device_metrics), 0)
  expect_s3_class(plot_obj, "ggplot")
  expect_true(file.exists(plot_path))
})
