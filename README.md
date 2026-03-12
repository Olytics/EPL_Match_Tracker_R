
# EPL Match Tracker (Shiny for R)

## About

This is the individual assignment version of the EPL Match Tracker implemented in Shiny for R. The app allows a user to select a `team` and `season` and then displays:

- Reactive KPI cards (Total Matches, Win Rate, Average Goals).
- A ggplot comparing average goals by venue (Home vs Away).
- A data table of filtered matches.

Built with: R · Shiny · ggplot 

### Live Dashboard

https://019ce440-2ac5-1247-22c5-5cb478b5f8cf.share.connect.posit.cloud/

---

## What this app solves

This interactive dashboard helps coaches and analysts compare home vs away performance, track win rate by venue, and inspect match-by-match details for a selected team and season.

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/Olytics/EPL_Match_Tracker_R.git
cd EPL_Match_Tracker_R
```

### 2. Install R packages

```bash
Rscript -e 'install.packages(c("shiny", "DT", "ggplot2", "dplyr", "lubridate", "tidyr"), repos="https://cran.rstudio.com")'
```

For reproducible environments, consider `renv::init()` and `renv::snapshot()`.

### 3. Run the app locally

From the repository root run:

```bash
Rscript -e "shiny::runApp('.', port = 8000, launch.browser = TRUE)"
```

Or open `EPL_Match_Tracker_R/app.R` in RStudio and click "Run App".

Visit http://127.0.0.1:8000 in your browser if the app does not open automatically.

