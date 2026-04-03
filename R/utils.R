#' Convert an NVML error code to an R error
#'
#' @param code Integer NVML return code (0 == success)
#' @return Invisible TRUE on success; otherwise stops with an error
nvml_check_status <- function(code) {
  if (!is.numeric(code) && !is.integer(code)) {
    stop("Internal error: NVML status code is not numeric", call. = FALSE)
  }

  code <- as.integer(code)
  nvml_code <- if (code < 0L) abs(code) else code

  if (nvml_code == 0L) {
    return(invisible(TRUE))
  }

  msg <- .Call("nvml_error_string_c", nvml_code, PACKAGE = "CudaMon")
  stop(sprintf("NVML error: %s (code: %d)", msg, nvml_code), call. = FALSE)
}

# Normalize the metrics payload returned by C into a named R list.
nvml_as_metrics <- function(res) {
  if (is.integer(res) && length(res) == 1L && res < 0L) {
    nvml_check_status(res)
  }

  stats::setNames(
    list(
      as.integer(res[[1L]]),
      as.integer(res[[2L]]),
      as.integer(res[[3L]]),
      as.integer(res[[4L]]),
      as.double(res[[5L]]),
      as.double(res[[6L]])
    ),
    c(
      "gpu_utilization_pct",
      "memory_utilization_pct",
      "temperature_c",
      "power_usage_mw",
      "memory_used_bytes",
      "memory_total_bytes"
    )
  )
}
