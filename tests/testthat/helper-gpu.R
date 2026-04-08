has_cudamon_native_symbol <- function(name) {
  tryCatch(
    {
      getNativeSymbolInfo(name, PACKAGE = "CudaMon")
      TRUE
    },
    error = function(...) FALSE
  )
}

skip_if_no_nvidia_gpu <- function() {
  testthat::skip_if_not(
    has_cudamon_native_symbol("nvml_is_available_c"),
    message = "CudaMon native NVML symbols are not available"
  )

  testthat::skip_if_not(
    has_cudamon_native_symbol("nvml_device_count_c"),
    message = "CudaMon native NVML symbols are not available"
  )

  testthat::skip_if_not(
    CudaMon:::nvml_is_available(),
    message = "NVML is not available on this machine"
  )

  testthat::skip_if_not(
    CudaMon:::nvml_device_count() > 0L,
    message = "No NVIDIA GPU detected"
  )
}

compile_manual_cuda_library <- function() {
  src_dir <- normalizePath(file.path("inst", "scripts", "test-cuda"), mustWork = TRUE)

  testthat::skip_if_not(dir.exists(src_dir), message = "CUDA test sources not found")
  testthat::skip_if_not(nzchar(Sys.which("nvcc")), message = "nvcc is not available")

  old_wd <- setwd(src_dir)
  on.exit(setwd(old_wd), add = TRUE)

  compile_output <- tryCatch(
    system2("sh", "compile.sh", stdout = TRUE, stderr = TRUE),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )

  so_path <- file.path(src_dir, "cudamatrix.so")
  status <- attr(compile_output, "status")

  if (!is.null(status) || !file.exists(so_path)) {
    detail <- paste(utils::tail(as.character(compile_output), 10L), collapse = "\n")
    if (!nzchar(detail)) {
      detail <- "No compiler output captured"
    }
    testthat::skip(paste("CUDA manual test library did not compile\n", detail))
  }

  list(
    build_dir = src_dir,
    so_path = so_path,
    compile_output = compile_output
  )
}

import_torch_with_cuda <- function() {
  testthat::skip_if_not_installed("reticulate")

  python_bin <- Sys.getenv("RETICULATE_PYTHON", unset = "")
  if (!nzchar(python_bin)) {
    python_bin <- Sys.which("python")
  }
  if (nzchar(python_bin)) {
    reticulate::use_python(python_bin, required = FALSE)
  }

  torch <- tryCatch(
    reticulate::import("torch"),
    error = function(...) NULL
  )

  testthat::skip_if_not(
    !is.null(torch),
    message = "Python package 'torch' is not importable"
  )

  testthat::skip_if_not(
    isTRUE(torch$cuda$is_available()),
    message = "Torch CUDA is not available"
  )

  torch
}
