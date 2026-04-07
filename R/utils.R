#' Construct a CudaMon session object
#'
#' @param device_metrics Data frame with GPU device-level samples.
#' @param compute_processes Data frame with GPU process-level samples.
#' @param paths Named list of output paths.
#' @param metadata Named list with session metadata.
#' @return An object of class `CudaMonSession`.
#' @export
CudaMonSession <- function(
    device_metrics = data.frame(),
    compute_processes = data.frame(),
    events = data.frame(),
    paths = list(),
    metadata = list()) {
  structure(
    list(
      device_metrics = device_metrics,
      compute_processes = compute_processes,
      events = events,
      paths = paths,
      metadata = metadata
    ),
    class = "CudaMonSession"
  )
}

#' @export
print.CudaMonSession <- function(x, ...) {
  cat("CudaMonSession\n")
  cat("  Device samples: ", nrow(x$device_metrics), "\n", sep = "")
  cat("  GPU process samples: ", nrow(x$compute_processes), "\n", sep = "")
  cat("  Event markers: ", nrow(x$events), "\n", sep = "")

  if (length(x$paths) > 0L) {
    if (!is.null(x$paths$device_metrics)) {
      cat("  Device metrics path: ", x$paths$device_metrics, "\n", sep = "")
    }
    if (!is.null(x$paths$compute_processes)) {
      cat("  Compute processes path: ", x$paths$compute_processes, "\n", sep = "")
    }
    if (!is.null(x$paths$events)) {
      cat("  Events path: ", x$paths$events, "\n", sep = "")
    }
    if (!is.null(x$paths$log)) {
      cat("  Sampler log path: ", x$paths$log, "\n", sep = "")
    }
  }

  if (length(x$metadata) > 0L) {
    if (!is.null(x$metadata$root_pid)) {
      cat("  Root PID: ", x$metadata$root_pid, "\n", sep = "")
    }
    if (!is.null(x$metadata$include_descendants)) {
      cat(
        "  Include descendants: ",
        x$metadata$include_descendants,
        "\n",
        sep = ""
      )
    }
  }

  invisible(x)
}

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

# Resolve the full PID set for a root process, optionally including descendants.
process_tree_pids <- function(pid, include_descendants = TRUE) {
  pid <- as.integer(pid)
  if (!include_descendants) {
    return(pid)
  }

  ps_output <- tryCatch(
    system2("ps", c("-e", "-o", "pid=", "-o", "ppid="), stdout = TRUE, stderr = FALSE),
    warning = function(...) character(),
    error = function(...) character()
  )

  if (length(ps_output) == 0L) {
    return(pid)
  }

  proc_table <- tryCatch(
    utils::read.table(
      text = ps_output,
      col.names = c("pid", "ppid"),
      stringsAsFactors = FALSE
    ),
    error = function(...) NULL
  )

  if (is.null(proc_table) || nrow(proc_table) == 0L) {
    return(pid)
  }

  seen <- pid
  frontier <- pid

  # Walk the process tree breadth-first so child processes can be monitored too.
  while (length(frontier) > 0L) {
    children <- proc_table$pid[proc_table$ppid %in% frontier]
    children <- setdiff(unique(as.integer(children)), seen)
    if (length(children) == 0L) {
      break
    }

    seen <- c(seen, children)
    frontier <- children
  }

  as.integer(seen)
}

# Filter NVML compute processes down to a root PID and its descendants.
nvml_list_r_compute_processes <- function(pid, include_descendants = TRUE, device_index = NULL) {
  if (!is.numeric(pid) || length(pid) != 1L || is.na(pid)) {
    stop("pid must be a single numeric value", call. = FALSE)
  }

  root_pid <- as.integer(pid)
  tracked_pids <- process_tree_pids(root_pid, include_descendants = include_descendants)
  process_df <- nvml_list_compute_processes(device_index = device_index, pid = tracked_pids)

  if (nrow(process_df) == 0L) {
    return(data.frame(
      device_index = integer(),
      pid = integer(),
      tracked_pid = integer(),
      is_root_pid = logical(),
      used_gpu_memory_bytes = double(),
      gpu_instance_id = integer(),
      compute_instance_id = integer(),
      stringsAsFactors = FALSE
    ))
  }

  process_df$tracked_pid <- as.integer(process_df$pid)
  process_df$is_root_pid <- process_df$tracked_pid == root_pid
  process_df <- process_df[, c(
    "device_index",
    "pid",
    "tracked_pid",
    "is_root_pid",
    "used_gpu_memory_bytes",
    "gpu_instance_id",
    "compute_instance_id"
  )]
  rownames(process_df) <- NULL

  process_df
}
