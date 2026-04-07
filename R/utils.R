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

# Convert the C return payload for a single device into a one-row data frame.
nvml_as_device_df <- function(res) {
  if (is.integer(res) && length(res) == 1L && res < 0L) {
    nvml_check_status(res)
  }

  data.frame(
    device_index = as.integer(res[[1L]]),
    name = as.character(res[[2L]]),
    uuid = as.character(res[[3L]]),
    memory_total_bytes = as.double(res[[4L]]),
    stringsAsFactors = FALSE
  )
}

# Convert the C return payload for GPU compute processes into tabular form.
nvml_as_process_df <- function(res) {
  if (is.integer(res) && length(res) == 1L && res < 0L) {
    nvml_check_status(res)
  }

  data.frame(
    device_index = as.integer(res[[1L]]),
    pid = as.integer(res[[2L]]),
    used_gpu_memory_bytes = as.double(res[[3L]]),
    gpu_instance_id = as.integer(res[[4L]]),
    compute_instance_id = as.integer(res[[5L]]),
    stringsAsFactors = FALSE
  )
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
