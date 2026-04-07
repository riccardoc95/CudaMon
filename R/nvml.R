# Copyright (c) 2025 Mohammad Amin Zadenoori
# Copyright (c) 2025 Gabriele Sales
#

#' Number of NVML-visible devices
#' @export
nvml_device_count <- function() {
  cnt <- .Call("nvml_device_count_c", PACKAGE = "CudaMon")
  if (cnt < 0L) {
    nvml_check_status(cnt)
  }
  as.integer(cnt)
}

#' Check whether NVML is available
#'
#' @return `TRUE` if NVML can be initialised and queried, otherwise `FALSE`
#' @export
nvml_is_available <- function() {
  isTRUE(.Call("nvml_is_available_c", PACKAGE = "CudaMon"))
}

#' List NVML-visible devices
#'
#' @return A data frame with one row per GPU and stable device metadata
#' @export
nvml_list_devices <- function() {
  count <- nvml_device_count()

  if (count == 0L) {
    return(data.frame(
      device_index = integer(),
      name = character(),
      uuid = character(),
      memory_total_bytes = double(),
      stringsAsFactors = FALSE
    ))
  }

  devices <- lapply(seq_len(count) - 1L, function(idx) {
    nvml_as_device_df(.Call("nvml_device_info_c", idx, PACKAGE = "CudaMon"))
  })

  do.call(rbind, devices)
}

#' Get metrics for a device
#'
#' @param device_index Integer, 0-based GPU index
#' @return A named list with utilization percentages, temperature in Celsius,
#'   power draw in milliwatts, and memory usage in bytes
#' @export
nvml_get_metrics <- function(device_index) {
  if (!is.numeric(device_index) || length(device_index) != 1L) {
    stop("device_index must be a single numeric value", call. = FALSE)
  }
  idx <- as.integer(device_index)

  nvml_as_metrics(.Call("nvml_get_metrics_c", idx, PACKAGE = "CudaMon"))
}

#' Demo function showing typical usage
#' @export
nvml_demo <- function() {
  nvml_get_metrics(0)
}
