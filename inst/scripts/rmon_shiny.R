#!/usr/bin/env Rscript
# Command-line wrapper for rmon::runShinyWithMonitor

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  cat("Usage: Rscript rmon_shiny.R <app_folder> [port]\n")
  quit(status = 1)
}

app_dir <- args[1]
port <- if (length(args) >= 2) as.integer(args[2]) else 1234

# Load the rmon package
if (!requireNamespace("rmon", quietly = TRUE)) {
  stop("rmon package is not installed. Please install it first.")
}

# Run the monitor
rmon::runShinyWithMonitor(app_dir = app_dir, port = port)

