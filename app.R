library(shiny)
library(DT)
library(ggplot2)
library(dplyr)
library(lubridate)
library(tidyr)

# Load dataset
df_all <- read.csv(file.path("data", "raw", "epl_final.csv"), stringsAsFactors = FALSE)
df_all <- df_all %>%
  mutate(
    Season = trimws(as.character(Season)),
    HomeTeam = trimws(as.character(HomeTeam)),
    AwayTeam = trimws(as.character(AwayTeam)),
    FullTimeResult = trimws(as.character(FullTimeResult)),
    MatchDate = as.Date(MatchDate),
    FullTimeHomeGoals = as.numeric(FullTimeHomeGoals),
    FullTimeAwayGoals = as.numeric(FullTimeAwayGoals),
    Result = dplyr::recode(FullTimeResult, `H` = "Home team win", `A` = "Away team win", `D` = "Draw")
  )

ALL_TEAMS <- sort(unique(c(df_all$HomeTeam, df_all$AwayTeam)))
ALL_SEASONS <- sort(unique(df_all$Season))
DEFAULT_SEASON <- tail(ALL_SEASONS, 1)

get_team_matches <- function(df, team) {
  home <- df %>% filter(HomeTeam == team)
  away <- df %>% filter(AwayTeam == team)

  if (nrow(home) > 0) {
    home <- home %>%
      mutate(
        venue = "Home",
        goals_for = FullTimeHomeGoals,
        goals_against = FullTimeAwayGoals,
        win = as.integer(FullTimeResult == "H")
      )
  }

  if (nrow(away) > 0) {
    away <- away %>%
      mutate(
        venue = "Away",
        goals_for = FullTimeAwayGoals,
        goals_against = FullTimeHomeGoals,
        win = as.integer(FullTimeResult == "A")
      )
  }

  res <- bind_rows(home, away) %>% arrange(MatchDate)
  res
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML("\
      .full-width { max-width: 100% !important; padding-left:16px; padding-right:16px; }\
      .top-equal { display:flex; gap:16px; align-items:stretch; }\
      .filter-panel { background:#fff; padding:12px; border-radius:8px; box-shadow:0 2px 6px rgba(0,0,0,0.06); }\
      .cards-panel { display:flex; gap:12px; align-items:stretch; }\
      .kpi-card { flex:1; padding:12px; background:#fff; border-radius:8px; box-shadow:0 2px 6px rgba(0,0,0,0.06); text-align:left; }\
      .chart-card { background:#fff; padding:12px; border-radius:8px; box-shadow:0 2px 8px rgba(0,0,0,0.06); min-height:380px; margin-top:8px; }\
      .table-card { background:#fff; padding:12px; border-radius:8px; box-shadow:0 2px 8px rgba(0,0,0,0.06); min-height:380px; overflow:auto; margin-top:8px; }\
      .top-equal { display:flex; gap:16px; align-items:stretch; margin-bottom:6px; }\
      @media (max-width: 768px) { .top-equal { flex-direction:column; } .cards-panel { flex-direction:row; } }\
    "))
  ),
  tags$head(
    tags$style(HTML(".kpi-card{display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%; text-align:center;}"))
  ),

  div(class = "container-fluid full-width",
  titlePanel("English Premier League Match Tracker"),

    # Top row: filter and KPI cards 
      div(class = "top-equal",
        div(class = "filter-panel", style = "flex: 0 0 20%; display:flex; flex-direction:column; justify-content:center;",
          div(style = "display:flex; gap:8px; flex-direction:row; align-items:center;",
            div(style = "flex:1;", selectInput("team", "Team", choices = ALL_TEAMS, selected = "Arsenal")),
            div(style = "flex:1;", selectInput("season", "Season", choices = ALL_SEASONS, selected = DEFAULT_SEASON))
          )
        ),

        div(style = "flex: 1 1 80%; display:flex;",
          div(class = "cards-panel", style = "flex:1;",
            div(class = "kpi-card",
              tags$div(style="font-size:12px; font-weight:700; color:#6b7280;", "Total Matches"),
              tags$div(textOutput("kpi_total", inline = TRUE), style="font-size:18px; font-weight:700; color:#111827; margin-top:6px;")
            ),
            div(class = "kpi-card",
              tags$div(style="font-size:12px; font-weight:700; color:#6b7280;", "Win Rate (%)"),
              tags$div(textOutput("kpi_winrate", inline = TRUE), style="font-size:18px; font-weight:700; color:#111827; margin-top:6px;")
            ),
            div(class = "kpi-card",
              tags$div(style="font-size:12px; font-weight:700; color:#6b7280;", "Average Goals"),
              tags$div(textOutput("kpi_goals_for", inline = TRUE), style="font-size:18px; font-weight:700; color:#111827; margin-top:6px;")
            )
          )
        )
      ),

    # Chart and table 
    fluidRow(
      column(6,
        div(class = "chart-card",
          tags$h3("Average Goals by Venue"),
          plotOutput("plot_goals")
        )
      ),
      column(6,
        div(class = "table-card",
          tags$h3("Matches"),
          DTOutput("matches_table")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Reactive calc
  matches_filtered <- reactive({
    req(input$team, input$season)
    df <- df_all %>% filter(Season == input$season)
    get_team_matches(df, input$team)
  })

  # KPIs
  output$kpi_total <- renderText({
    nrow(matches_filtered())
  })

  output$kpi_winrate <- renderText({
    df <- matches_filtered()
    if (nrow(df) == 0) return("0.0")
    sprintf("%.1f", mean(df$win, na.rm = TRUE) * 100)
  })

  output$kpi_goals_for <- renderText({
    df <- matches_filtered()
    if (nrow(df) == 0) return("0.00")
    sprintf("%.2f", mean(df$goals_for, na.rm = TRUE))
  })

  # Plot: avg goals by venue
  output$plot_goals <- renderPlot({
    df <- matches_filtered()
    if (nrow(df) == 0) {
      ggplot() + theme_minimal() + ggtitle("No matches for selection")
    } else {
      s <- df %>% group_by(venue) %>%
        summarise(avg_for = mean(goals_for, na.rm = TRUE), avg_against = mean(goals_against, na.rm = TRUE), n = n())

      s_long <- tidyr::pivot_longer(s, cols = c("avg_for", "avg_against"), names_to = "metric", values_to = "value")

      ggplot(s_long, aes(x = venue, y = value, fill = metric)) +
        geom_col(position = position_dodge(width = 0.7), width = 0.6) +
        scale_fill_manual(values = c("avg_for" = "#472A4B", "avg_against" = "#e15759"), labels = c("Avg Goals For", "Avg Goals Against")) +
        labs(x = "Venue", y = "Average Goals", fill = "Metric") +
        theme_minimal() + theme(text = element_text(size = 12))
    }
  })

  # Table: show matches
  output$matches_table <- renderDT({
    df <- matches_filtered()
    if (nrow(df) == 0) return(datatable(df, options = list(pageLength = 5, scrollX = TRUE)))
    df2 <- df %>% mutate(MatchDate = as.character(MatchDate)) %>%
      select(MatchDate, Season, venue, HomeTeam, AwayTeam, FullTimeHomeGoals, FullTimeAwayGoals, Result)
    datatable(df2, options = list(pageLength = 5, scrollX = TRUE))
  })
}

shinyApp(ui, server)
