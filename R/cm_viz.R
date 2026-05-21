#' Reshape sampled GPU metrics for visualization
#'
#' @param x A `CudaMonSession` object returned by `cm_parser()`.
#' @param tz Time zone used to parse timestamps.
#' @param device_index Optional integer GPU index. If `NULL`, include all
#'   sampled devices.
#' @return A long-format data frame suitable for plotting.
#' @examples
#' device_metrics <- data.frame(
#'   timestamp = format(Sys.time() + 0:1, tz = "UTC", usetz = TRUE),
#'   sampler_pid = Sys.getpid(),
#'   device_index = 0L,
#'   gpu_utilization_pct = c(10L, 25L),
#'   memory_utilization_pct = c(5L, 12L),
#'   temperature_c = c(40L, 42L),
#'   power_usage_mw = c(50000L, 53000L),
#'   memory_used_bytes = c(1e9, 1.2e9),
#'   memory_total_device_bytes = 8e9
#' )
#' session <- CudaMonSession(device_metrics = device_metrics)
#' cm_vizdf(session)
#' @export
cm_vizdf <- function(x, tz = "UTC", device_index = NULL) {
  if (!inherits(x, "CudaMonSession")) {
    stop("x must inherit from 'CudaMonSession'", call. = FALSE)
  }

  df <- x$device_metrics
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(data.frame(
      tm = as.POSIXct(character(), tz = tz),
      xtype = character(),
      pos = character(),
      value = double(),
      type = character(),
      device_index = integer(),
      stringsAsFactors = FALSE
    ))
  }

  if (!is.null(device_index)) {
    df <- df[df$device_index %in% as.integer(device_index), , drop = FALSE]
  }

  if (nrow(df) == 0L) {
    return(data.frame(
      tm = as.POSIXct(character(), tz = tz),
      xtype = character(),
      pos = character(),
      value = double(),
      type = character(),
      device_index = integer(),
      stringsAsFactors = FALSE
    ))
  }

  tm <- as.POSIXct(df$timestamp, tz = "UTC")

  plot_df <- rbind(
    data.frame(
      tm = tm,
      xtype = "GPU_MEM",
      pos = "top",
      value = as.double(df$gpu_utilization_pct),
      type = "GPU memory activity (%)",
      device_index = as.integer(df$device_index),
      stringsAsFactors = FALSE
    ),
    data.frame(
      tm = tm,
      xtype = "GPU_MEM",
      pos = "bot",
      value = as.double(df$memory_used_bytes * 1e-9),
      type = "GPU memory used (Gb)",
      device_index = as.integer(df$device_index),
      stringsAsFactors = FALSE
    ),
    data.frame(
      tm = tm,
      xtype = "THERM_PWR",
      pos = "top",
      value = as.double(df$temperature_c),
      type = "Temperature (C)",
      device_index = as.integer(df$device_index),
      stringsAsFactors = FALSE
    ),
    data.frame(
      tm = tm,
      xtype = "THERM_PWR",
      pos = "bot",
      value = as.double(df$power_usage_mw * 1e-3),
      type = "Power (W)",
      device_index = as.integer(df$device_index),
      stringsAsFactors = FALSE
    )
  )
  has_value <- stats::ave(
    !is.na(plot_df$value),
    plot_df$type,
    FUN = any
  )
  plot_df[has_value, , drop = FALSE]
}

#' Plot sampled GPU usage over time
#'
#' @param x A `CudaMonSession` object returned by `cm_parser()`.
#' @param tz Time zone used to parse timestamps.
#' @param device_index Optional integer GPU index. If `NULL`, include all
#'   sampled devices.
#' @return A ggplot object with one facet per metric.
#' @examples
#' device_metrics <- data.frame(
#'   timestamp = format(Sys.time() + 0:1, tz = "UTC", usetz = TRUE),
#'   sampler_pid = Sys.getpid(),
#'   device_index = 0L,
#'   gpu_utilization_pct = c(10L, 25L),
#'   memory_utilization_pct = c(5L, 12L),
#'   temperature_c = c(40L, 42L),
#'   power_usage_mw = c(50000L, 53000L),
#'   memory_used_bytes = c(1e9, 1.2e9),
#'   memory_total_device_bytes = 8e9
#' )
#' session <- CudaMonSession(device_metrics = device_metrics)
#' cm_plot_usage(session)
#' @export
cm_plot_usage <- function(x, tz = "UTC", device_index = NULL) {
  plot_df <- cm_vizdf(x, tz = tz, device_index = device_index)

  # Check: I don't know if it is the best way to avoid R CMD check warnings
  tm <- value <- type <- label_y <- step <- NULL

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = tm, y = value)
  ) +
    ggplot2::geom_point(na.rm = TRUE) +
    ggplot2::facet_grid(ggplot2::vars(type), scales = "free") +
    ggplot2::scale_x_datetime(
      timezone = tz,
      date_labels = "%H:%M:%S"
    )

  events_df <- x$events
  if (is.data.frame(events_df) && nrow(events_df) > 0L &&
    "timestamp" %in% names(events_df) && "step" %in% names(events_df)) {
    events_df <- events_df[, c("timestamp", "step"), drop = FALSE]
    events_df$tm <- as.POSIXct(events_df$timestamp, tz = "UTC")
    events_df$label_y <- Inf

    p <- p +
      ggplot2::geom_vline(
        data = events_df,
        ggplot2::aes(xintercept = tm),
        inherit.aes = FALSE,
        linetype = "dashed",
        color = "firebrick"
      ) +
      ggplot2::geom_text(
        data = events_df,
        ggplot2::aes(
          x = tm,
          y = label_y,
          label = step
        ),
        inherit.aes = FALSE,
        angle = 90,
        vjust = 1.2,
        hjust = 1,
        color = "firebrick",
        size = 3
      )
  }

  p
}
