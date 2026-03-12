# dependencies.R
# Installs required packages for the Shiny app if they are missing
packages <- c(
  "shiny",
  "DT",
  "ggplot2",
  "dplyr",
  "lubridate",
  "tidyr"
)

install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cran.rstudio.com")
  }
}

invisible(lapply(packages, install_if_missing))
cat("Checked/installed packages:", paste(packages, collapse = ", "), "\n")
