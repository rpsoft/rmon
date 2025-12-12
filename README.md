# rmon: Shiny App File Monitor and Hot Reloader

A file monitoring tool for R Shiny applications that automatically restarts the app when R source files are modified. Provides an alternative launcher for Shiny apps with hot-reload functionality.

## Installation

Install the package from source:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install rmon
devtools::install(".")
```

Or if you're in the package directory:

```r
install.packages(".", repos = NULL, type = "source")
```

## Usage

### From R

The main function is `runShinyWithMonitor()`:

```r
library(rmon)

# Monitor a Shiny app in the current directory
runShinyWithMonitor(".", port = 3838)

# Monitor a specific app directory
runShinyWithMonitor("~/my-shiny-app", port = 8080)

# Without launching browser on first start
runShinyWithMonitor(".", port = 3838, launch_browser = FALSE)
```

### From Command Line

A command-line wrapper script is available at `inst/scripts/rmon_shiny.R`:

```bash
Rscript inst/scripts/rmon_shiny.R <app_folder> [port]
```

Example:
```bash
Rscript inst/scripts/rmon_shiny.R ./my-app 3838
```

## Features

- **Automatic file monitoring**: Watches all `.R` and `.r` files in the app directory and subdirectories
- **Hot reload**: Automatically restarts the Shiny app when changes are detected
- **Output streaming**: Displays app output and errors in real-time
- **Configurable**: Adjustable port, poll delay, and browser launch behavior

## How It Works

1. Monitors modification times of all R source files in the specified directory
2. When a change is detected, stops the current Shiny app process
3. Restarts the app with the updated code
4. Streams output and errors to the console

The function runs indefinitely until interrupted (Ctrl+C), making it perfect for development workflows.

## Requirements

- R (>= 3.5.0)
- `fs` package
- `processx` package
- `shiny` package (for running the apps)

## License

MIT
