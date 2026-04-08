#' Start sampling NVML metrics to CSV files
#'
#' @param path_prefix Optional output path prefix. If `NULL`, a unique prefix is
#'   generated automatically. Two files will be created:
#'   `*_device_metrics.csv`, `*_compute_processes.csv`, and `*_events.csv`.
#' @param period Sampling interval in seconds.
#' @param pid Root process identifier, defaults to the current R session PID.
#' @param include_descendants Whether to include child processes of `pid`.
#' @param device_index Optional integer GPU index. If `NULL`, query all devices.
#' @param log Optional log file written by the background sampler process.
#' @param startup_timeout Maximum startup wait in seconds.
#' @return A list with sampler metadata and class `nvml_sampler`.
#' @export
nvml_sample_start <- function(
    path_prefix = NULL,
    period = 1,
    pid = Sys.getpid(),
    include_descendants = TRUE,
    device_index = NULL,
    log = NULL,
    startup_timeout = 2) {
  if (is.null(path_prefix)) {
    path_prefix <- default_sampler_prefix(pid)
  }

  if (!is.character(path_prefix) || length(path_prefix) != 1L || !nzchar(path_prefix)) {
    stop("path_prefix must be NULL or a single non-empty string", call. = FALSE)
  }

  if (!is.numeric(period) || length(period) != 1L || is.na(period) || period <= 0) {
    stop("period must be a single positive numeric value", call. = FALSE)
  }

  if (!is.numeric(startup_timeout) || length(startup_timeout) != 1L ||
      is.na(startup_timeout) || startup_timeout <= 0) {
    stop("startup_timeout must be a single positive numeric value", call. = FALSE)
  }

  root_pid <- as.integer(pid)
  device_index <- if (is.null(device_index)) NULL else as.integer(device_index)
  device_metrics_path <- paste0(path_prefix, "_device_metrics.csv")
  compute_processes_path <- paste0(path_prefix, "_compute_processes.csv")
  events_path <- paste0(path_prefix, "_events.csv")
  witness_path <- paste0(path_prefix, "_startup.signal")
  log_path <- if (is.null(log)) paste0(path_prefix, "_sampler.log") else log
  script_path <- nvml_sampler_script_path()
  rscript_path <- file.path(R.home("bin"), "Rscript")
  if (!file.exists(rscript_path)) {
    rscript_path <- file.path(R.home("bin"), "R")
  }
  lib_paths <- .libPaths()
  env <- sampler_env(lib_paths)

  job <- processx::process$new(
    command = rscript_path,
    args = nvml_sampler_args(
      command = rscript_path,
      script_path = script_path,
      device_metrics_path = device_metrics_path,
      compute_processes_path = compute_processes_path,
      witness_path = witness_path,
      period = period,
      pid = root_pid,
      include_descendants = include_descendants,
      device_index = device_index
    ),
    stdout = log_path,
    stderr = log_path,
    env = env,
    cleanup_tree = TRUE
  )

  deadline <- Sys.time() + startup_timeout
  started <- FALSE

  while (Sys.time() < deadline) {
    job$wait(timeout = 100L)

    if (file.exists(witness_path)) {
      unlink(witness_path)
      started <- TRUE
      break
    }

    status <- job$get_exit_status()
    if (!is.null(status)) {
      stop(
        sprintf(
          "NVML sampler failed to start (exit status %d). Check log: %s",
          status,
          log_path
        ),
        call. = FALSE
      )
    }
  }

  if (!started) {
    kill_process(job)
    stop(
      sprintf(
        "NVML sampler did not start before the timeout elapsed. Check log: %s",
        log_path
      ),
      call. = FALSE
    )
  }

  structure(
    list(
      process = job,
      pid = job$pid,
      root_pid = root_pid,
      period = period,
      include_descendants = include_descendants,
      device_index = device_index,
      script_path = script_path,
      log_path = log_path,
      paths = list(
        device_metrics = device_metrics_path,
        compute_processes = compute_processes_path,
        events = events_path,
        log = log_path
      )
    ),
    class = "nvml_sampler"
  )
}

#' Record a workflow step during an active NVML sampling session
#'
#' @param sampler A sampler object returned by `nvml_sample_start()`.
#' @param step A short label identifying the current workflow step.
#' @return Invisibly returns the sampler.
#' @export
nvml_mark_step <- function(sampler, step) {
  if (!inherits(sampler, "nvml_sampler")) {
    stop("sampler must inherit from 'nvml_sampler'", call. = FALSE)
  }

  if (!is.character(step) || length(step) != 1L || !nzchar(step)) {
    stop("step must be a single non-empty string", call. = FALSE)
  }

  event_row <- data.frame(
    timestamp = format(Sys.time(), tz = "UTC", usetz = TRUE),
    root_pid = as.integer(sampler$root_pid),
    step = step,
    stringsAsFactors = FALSE
  )

  append_csv(event_row, sampler$paths$events)
  invisible(sampler)
}

#' Stop an NVML background sampler
#'
#' @param sampler A sampler object returned by `nvml_sample_start()`.
#' @return Invisibly returns the sampler.
#' @export
nvml_sample_stop <- function(sampler) {
  if (!inherits(sampler, "nvml_sampler")) {
    stop("sampler must inherit from 'nvml_sampler'", call. = FALSE)
  }

  if (!is.null(sampler$process)) {
    wait_seconds <- if (!is.null(sampler$period) && is.finite(sampler$period)) {
      max(0, as.numeric(sampler$period))
    } else {
      1
    }
    Sys.sleep(wait_seconds)
    kill_process(sampler$process)
  }
  invisible(sampler)
}

#' Read CSV output produced by the NVML sampler
#'
#' @param sampler A sampler object returned by `nvml_sample_start()`, or a
#'   character path prefix used to build the sampler output paths.
#' @return A `CudaMonSession` object.
#' @export
nvml_sample_read <- function(sampler) {
  if (inherits(sampler, "nvml_sampler")) {
    device_metrics_path <- sampler$paths$device_metrics
    compute_processes_path <- sampler$paths$compute_processes
    events_path <- sampler$paths$events
    log_path <- sampler$paths$log
    metadata <- list(
      root_pid = sampler$root_pid,
      include_descendants = sampler$include_descendants,
      device_index = sampler$device_index
    )
  } else if (is.character(sampler) && length(sampler) == 1L && nzchar(sampler)) {
    device_metrics_path <- paste0(sampler, "_device_metrics.csv")
    compute_processes_path <- paste0(sampler, "_compute_processes.csv")
    events_path <- paste0(sampler, "_events.csv")
    log_path <- paste0(sampler, "_sampler.log")
    metadata <- list()
  } else {
    stop("sampler must be an 'nvml_sampler' object or a path prefix", call. = FALSE)
  }

  CudaMonSession(
    device_metrics = read_sampler_csv(device_metrics_path),
    compute_processes = read_sampler_csv(compute_processes_path),
    events = read_sampler_csv(events_path),
    paths = list(
      device_metrics = device_metrics_path,
      compute_processes = compute_processes_path,
      events = events_path,
      log = log_path
    ),
    metadata = metadata
  )
}

kill_process <- function(proc) {
  proc$interrupt()
  proc$wait(timeout = 1000L)

  if (proc$is_alive()) {
    proc$kill()
  }
}

sampler_env <- function(lib_paths) {
  env <- character()

  r_libs <- paste(lib_paths, collapse = .Platform$path.sep)
  env["R_LIBS"] <- r_libs
  env["R_LIBS_USER"] <- r_libs
  env["R_LIBS_SITE"] <- Sys.getenv("R_LIBS_SITE", unset = "")

  env
}

default_sampler_prefix <- function(pid) {
  tempfile(pattern = sprintf("cudamon-%d-", as.integer(pid)))
}

append_csv <- function(x, path) {
  utils::write.table(
    x,
    file = path,
    sep = ",",
    row.names = FALSE,
    col.names = !file.exists(path),
    append = file.exists(path),
    qmethod = "double"
  )
}

nvml_sampler_args <- function(
    command,
    script_path,
    device_metrics_path,
    compute_processes_path,
    witness_path,
    period,
    pid,
    include_descendants,
    device_index) {
  device_index_arg <- if (is.null(device_index)) "" else paste(device_index, collapse = ",")

  if (grepl("^Rscript", basename(command))) {
    return(c(
      "--vanilla",
      script_path,
      device_metrics_path,
      compute_processes_path,
      witness_path,
      as.character(period),
      as.character(pid),
      if (isTRUE(include_descendants)) "true" else "false",
      device_index_arg
    ))
  }

  c(
    script_path,
    device_metrics_path,
    compute_processes_path,
    witness_path,
    as.character(period),
    as.character(pid),
    if (isTRUE(include_descendants)) "true" else "false",
    device_index_arg
  )
}

write_nvml_sampler_script <- function() {
  .Deprecated("nvml_sampler_script_path")
  nvml_sampler_script_path()
}

nvml_sampler_script_path <- function() {
  script_path <- system.file("scripts", "nvml_sampler.R", package = "CudaMon")
  if (!nzchar(script_path)) {
    stop("Cannot find bundled NVML sampler script", call. = FALSE)
  }
  script_path
}

read_sampler_csv <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$size == 0)) {
    return(data.frame())
  }

  utils::read.csv(path, stringsAsFactors = FALSE)
}
