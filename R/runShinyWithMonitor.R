#' Run a Shiny app with file monitoring and hot reload
#'
#' Monitors R source files in a Shiny app directory and automatically restarts
#' the app when changes are detected. This provides a hot-reload development
#' experience similar to other modern web frameworks.
#'
#' @param app_dir Character string. Path to the Shiny app directory to monitor.
#' @param port Integer. Port number to run the Shiny app on (default: 1234).
#' @param poll_delay Numeric. Number of seconds between file system checks
#'   (default: 1).
#' @param launch_browser Logical. Whether to launch the browser on first start
#'   (default: TRUE). Subsequent restarts will not launch the browser.
#'
#' @details
#' This function continuously monitors R source files (files with .R or .r
#' extension) in the specified directory and its subdirectories. When a change
#' is detected, it:
#' \itemize{
#'   \item Stops the currently running Shiny app process
#'   \item Restarts the app with the updated code
#'   \item Streams output and error messages to the console
#' }
#'
#' The function runs indefinitely until interrupted (Ctrl+C). Use this for
#' development workflows where you want automatic restarts when code changes.
#'
#' @return Invisibly returns NULL. This function is intended to run indefinitely
#'   until interrupted.
#'
#' @examples
#' \dontrun{
#' # Monitor a Shiny app in the current directory
#' rmon::runShinyWithMonitor(".", port = 3838)
#'
#' # Monitor a specific app directory
#' rmon::runShinyWithMonitor("~/my-shiny-app", port = 8080)
#' }
#'
#' @export
runShinyWithMonitor <- function(app_dir, port = 1234, poll_delay = 1, launch_browser = TRUE) {
  # Normalize the folder path properly
  app_dir <- fs::path_abs(app_dir)
  app_dir <- fs::path_norm(app_dir)
  app_dir <- fs::path_real(app_dir)
  app_dir <- sub("/+$", "", app_dir)

  if (!fs::dir_exists(app_dir)) {
    stop("Error: directory does not exist: ", app_dir)
  }

  cat("📡 Watching Shiny app at:", app_dir, "\n")
  cat("▶️ Running on port:", port, "\n\n")

  get_mod_time <- function() {
    files <- fs::dir_info(app_dir, recurse = TRUE, type = "file", regexp = "\\.[rR]$")
    if (nrow(files) == 0) return(Sys.time())
    max(files$modification_time, na.rm = TRUE)
  }

  last_mod_time <- get_mod_time()
  proc <- NULL
  first_launch <- TRUE

  # Helper function to launch the app
  launch_app <- function() {
    if (!is.null(proc) && proc$is_alive()) {
      proc$kill()
    }

    if (first_launch) {
      cat("🚀 Launching Shiny app…\n")
    } else {
      cat("🔁 Change detected — restarting Shiny app…\n")
    }

    browser_flag <- if (first_launch && launch_browser) "TRUE" else "FALSE"
    cmd <- sprintf(
      "shiny::runApp('%s', port=%d, launch.browser=%s)",
      app_dir, port, browser_flag
    )

    proc <<- processx::process$new("Rscript", c("-e", cmd), stdout = "|", stderr = "|")
    first_launch <<- FALSE

    # Stream initial output to catch startup messages/errors
    for (i in 1:10) {
      is_alive <- tryCatch(proc$is_alive(), error = function(e) FALSE)
      out <- tryCatch(proc$read_output_lines(), error = function(e) character(0))
      err <- tryCatch(proc$read_error_lines(), error = function(e) character(0))

      if (length(out)) cat(out, sep = "\n")
      if (length(err)) cat(err, sep = "\n")
      
      if (!is_alive) break
      Sys.sleep(0.2)
    }
  }

  # Launch the app immediately on first run
  launch_app()

  # Then monitor for file changes
  repeat {
    Sys.sleep(poll_delay)
    
    # Check if process is still alive and stream any output
    if (!is.null(proc)) {
      is_alive <- tryCatch(proc$is_alive(), error = function(e) FALSE)
      if (is_alive) {
        out <- tryCatch(proc$read_output_lines(), error = function(e) character(0))
        err <- tryCatch(proc$read_error_lines(), error = function(e) character(0))
        if (length(out)) cat(out, sep = "\n")
        if (length(err)) cat(err, sep = "\n")
      }
    }
    
    # Check for file changes
    current_mod_time <- tryCatch(get_mod_time(), error = function(e) last_mod_time)

    if (!is.na(current_mod_time) && current_mod_time > last_mod_time) {
      last_mod_time <- current_mod_time
      launch_app()
    }
  }
}

