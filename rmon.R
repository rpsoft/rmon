# rmon.R
library(fs)
library(processx)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage: Rscript rmon.R <folder_to_watch> <command_to_run>\n")
  quit(status = 1)
}

watch_dir <- args[1]
command <- args[-1]
poll_delay <- 1

cat("📡 Watching", watch_dir, "for changes...\n")
cat("▶️  Command to run on change:", paste(command, collapse = " "), "\n")

get_mod_time <- function() {
  files <- dir_info(watch_dir, recurse = TRUE, type = "file", regexp = "\\.R$")
  if (nrow(files) == 0) return(Sys.time())
  max(files$modification_time, na.rm = TRUE)
}

last_mod_time <- get_mod_time()
proc <- NULL

repeat {
  Sys.sleep(poll_delay)
  current_mod_time <- tryCatch(get_mod_time(), error = function(e) last_mod_time)
  
  if (!is.na(current_mod_time) && current_mod_time > last_mod_time) {
    last_mod_time <- current_mod_time
    
    if (!is.null(proc) && proc$is_alive()) {
      proc$kill()
    }
    
    cat("\n🔁 Change detected in", watch_dir, "\n")
    proc <- process$new(command[1], command[-1], stdout = "|", stderr = "|")
    
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
