#' Reshape sampled GPU metrics for visualization
#'
#' @param x A `CudaMonSession` object returned by `cm_parser()`.
#' @param tz Time zone used to parse timestamps.
#' @param device_index Optional integer GPU index. If `NULL`, include all
#'   sampled devices.
#' @return A long-format data frame suitable for plotting.
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

  tm <- as.POSIXct(df$timestamp, tz = tz)

  rbind(
    data.frame(
      tm = tm,
      xtype = "GPU_MEM",
      pos = "top",
      value = as.double(df$gpu_utilization_pct),
      type = "GPU active (%)",
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
}

#' Plot sampled GPU usage over time
#'
#' @param x A `CudaMonSession` object returned by `cm_parser()`.
#' @param tz Time zone used to parse timestamps.
#' @param device_index Optional integer GPU index. If `NULL`, include all
#'   sampled devices.
#' @return A ggplot object with one facet per metric.
#' @export
cm_plot_usage <- function(x, tz = "UTC", device_index = NULL) {
  plot_df <- cm_vizdf(x, tz = tz, device_index = device_index)
  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = tm, y = value)
  ) +
    ggplot2::geom_point() +
    ggplot2::facet_grid(ggplot2::vars(type), scales = "free")

  events_df <- x$events
  if (is.data.frame(events_df) && nrow(events_df) > 0L &&
      "timestamp" %in% names(events_df) && "step" %in% names(events_df)) {
    events_df <- events_df[, c("timestamp", "step"), drop = FALSE]
    events_df$tm <- as.POSIXct(events_df$timestamp, tz = tz)
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
        ggplot2::aes(x = tm, y = label_y, label = step),
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
