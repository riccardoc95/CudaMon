#' Plot sampled CPU and GPU usage over time
#'
#' This function plots time-series metrics from a `CudaMonSession` object,
#' optionally combining them with precomputed CPU metrics. GPU metrics are
#' obtained via [cm_vizdf()], while CPU metrics must already be in the
#' long/tidy format returned by `vizdf()`.
#'
#' If `x_rcollectl` is provided, CPU metrics are plotted first, followed by GPU
#' metrics, using faceting by metric type.
#'
#' @param x A `CudaMonSession` object returned by `cm_parser()`.
#' @param x_rcollectl Optional data frame of CPU metrics in long format (as returned
#'   by `vizdf()`). Must contain columns: `tm`, `xtype`, `pos`, `value`, `type`.
#' @param tz Time zone used to parse timestamps.
#' @param device_index Optional integer GPU index. If `NULL`, include all
#'   sampled devices.
#'
#' @return A `ggplot2` object with one facet per metric
#'   CPU and GPU data.
#' @export
plot_usage <- function(x, x_rcollectl = NULL, tz = "UTC", device_index = NULL) {
  gpu_df <- cm_vizdf(x, tz = tz, device_index = device_index)

  # If x_rcollectl is provided, normalize it and merge with gpu_df
  if (!is.null(x_rcollectl)) {
    cpu_df <- Rcollectl:::vizdf(xrcollectl)
    if (!is.data.frame(cpu_df)) {
      stop("x_rcollectl must be a data.frame", call. = FALSE)
    }

    required_cols <- c("tm", "xtype", "pos", "value", "type")
    missing_cols <- setdiff(required_cols, names(cpu_df))
    if (length(missing_cols) > 0L) {
      stop(
        sprintf(
          "x_rcollectl is missing required columns: %s",
          paste(missing_cols, collapse = ", ")
        ),
        call. = FALSE
      )
    }

    cpu_df <- cpu_df[, required_cols, drop = FALSE]
    cpu_df$tm <- as.POSIXct(cpu_df$tm, tz = tz)
    cpu_df$value <- as.double(cpu_df$value)
    cpu_df$device_index <- NA_integer_

    plot_df <- rbind(
      cpu_df[, c("tm", "xtype", "pos", "value", "type", "device_index")],
      gpu_df[, c("tm", "xtype", "pos", "value", "type", "device_index")]
    )
  } else {
    plot_df <- gpu_df
  }

  # CPU and GPU facet order
  facet_order <- c(
    "%CPU active",
    "MEM used",
    "KB NET",
    "Cumul KB disk",
    "GPU active (%)",
    "GPU memory used (Gb)",
    "Temperature (C)",
    "Power (W)"
  )

  plot_df$type <- factor(
    plot_df$type,
    levels = intersect(facet_order, unique(as.character(plot_df$type)))
  )

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
