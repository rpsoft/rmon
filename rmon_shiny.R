# rmon_shiny.R
library(fs)
library(processx)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript rmon_shiny.R <app_folder> [port]\n")
  quit(status = 1)
}

app_dir <- args[1]
port <- if (length(args) >= 2) as.integer(args[2]) else 1234
poll_delay <- 1

cat("📡 Watching Shiny app at:", app_dir, "\n")
cat("▶️  Will launch on port", port, "\n")

# Function to get max mod time of all relevant files
get_mod_time <- function() {
  files <- dir_info(app_dir, recurse = TRUE, type = "file", regexp = "\\.R$")
  if (nrow(files) == 0) return(Sys.time())
  max(files$modification_time, na.rm = TRUE)
}

last_mod_time <- get_mod_time()
proc <- NULL
first_launch <- TRUE

repeat {
  Sys.sleep(poll_delay)
  current_mod_time <- tryCatch(get_mod_time(), error = function(e) last_mod_time)
  
  if (!is.na(current_mod_time) && current_mod_time > last_mod_time) {
    last_mod_time <- current_mod_time
    
    if (!is.null(proc) && proc$is_alive()) {
      proc$kill()
    }
    
    cat("\n🔁 Change detected. Restarting Shiny app...\n")
    
    browser_flag <- if (first_launch) "TRUE" else "FALSE"
    cmd <- sprintf("shiny::runApp('%s', port=%d, launch.browser=%s)", app_dir, port, browser_flag)
    
    proc <- process$new("Rscript", c("-e", cmd), stdout = "|", stderr = "|")
    first_launch <- FALSE
    
    repeat {
      is_alive <- tryCatch(proc$is_alive(), error = function(e) FALSE)
      out <- tryCatch(proc$read_output_lines(), error = function(e) character(0))
      err <- tryCatch(proc$read_error_lines(), error = function(e) character(0))
      
      if (length(out)) cat(out, sep = "\n")
      if (length(err)) cat(err, sep = "\n")
      if (!is_alive && length(out) == 0 && length(err) == 0) break
      
      Sys.sleep(0.2)
    }
  }
}