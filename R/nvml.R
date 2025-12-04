# Copyright (c) 2025 Mohammad Amin Zadenoori
# Copyright (c) 2025 Gabriele Sales
#
# This software is licensed under the Artistic License 2.0.

#' Initialise NVML
#' @export
nvml_init <- function() {
  status <- .Call(nvml_init_c)
  nvml_check_status(status, call = rlang::caller_env())
  invisible(TRUE)
}

#' Shut down NVML
#' @export
nvml_shutdown <- function() {
  status <- .Call(nvml_shutdown_c)
  nvml_check_status(status, call = rlang::caller_env())
  invisible(TRUE)
}

#' Number of NVML‑visible devices
#' @export
nvml_device_count <- function() {
  cnt <- .Call(nvml_device_count_c)
  if (cnt < 0L) {
    nvml_check_status(cnt, call = rlang::caller_env())
  }
  as.integer(cnt)
}

#' Get metrics for a device
#'
#' @param device_index Integer, 0‑based GPU index
#' @export
nvml_get_metrics <- function(device_index) {
  if (!is.numeric(device_index) || length(device_index) != 1L) {
    rlang::abort(
      "device_index must be a single numeric value",
      class = "nvml_error",
      .call = rlang::caller_env()
    )
  }
  idx <- as.integer(device_index)

  res <- .Call(nvml_get_metrics_c, idx)
  if (is.integer(res) && length(res) == 1L && res < 0L) {
    nvml_check_status(res, call = rlang::caller_env())
  }
  res
}

#' Demo function showing typical usage
#' @export
demo <- function() {
  nvml_init()
  on.exit(nvml_shutdown(), add = TRUE)
  nvml_get_metrics(0)
}
