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
