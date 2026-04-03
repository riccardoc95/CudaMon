#' Convert an NVML error code to an R error
#'
#' @param code Integer NVML return code (0 == success)
#' @return Invisible TRUE on success; otherwise stops with an error
nvml_check_status <- function(code) {
  if (!is.numeric(code) && !is.integer(code)) {
    stop("Internal error: NVML status code is not numeric", call. = FALSE)
  }

  code <- as.integer(code)

  if (code == 0L) {
    return(invisible(TRUE))
  }

  msg <- .Call("nvml_error_string_c", code, PACKAGE = "CudaMon")
  stop(sprintf("NVML error: %s (code: %d)", msg, code), call. = FALSE)
}
