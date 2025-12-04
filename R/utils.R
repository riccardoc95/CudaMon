#' Convert an NVML error code to a tidy rlang condition
#'
#' @param code Integer NVML return code (0 == success)
#' @param call The call environment to attach (default caller_env())
#' @return Invisible TRUE on success; otherwise aborts with class "nvml_error"
nvml_check_status <- function(code, call = rlang::caller_env()) {
  if (!is.numeric(code) && !is.integer(code)) {
    rlang::abort(
      "Internal error: NVML status code is not numeric",
      class = "nvml_error",
      .call = call
    )
  }

  code <- as.integer(code)

  if (code == 0L) {
    return(invisible(TRUE))
  }

  msg <- .Call(nvml_error_string_c, code)
  rlang::abort(
    message = c(
      paste0("NVML error: ", msg),
      "i" = paste0("Error code: ", code)
    ),
    class   = "nvml_error",
    nvml_code = code,
    .call   = call
  )
}
