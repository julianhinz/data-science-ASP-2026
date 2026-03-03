###
# 01 - APIs and httr2
# 260226
###

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(httr2)
p_load(jsonlite)
p_load(ggplot2)

# 0 - settings ----

dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("temp", showWarnings = FALSE, recursive = TRUE)

# 1 - API basics: World Bank ----

# the World Bank API is free and requires no key
# fetch GDP data for Germany
resp = request("https://api.worldbank.org/v2") %>%
  req_url_path_append("country", "DEU", "indicator", "NY.GDP.MKTP.CD") %>%
  req_url_query(format = "json", per_page = 50, date = "2000:2023") %>%
  req_perform()

# parse the JSON response
body = resp %>% resp_body_json()

# the World Bank API returns a list: [[1]] is metadata, [[2]] is data
gdp_raw = body[[2]]

# extract into a data.table
gdp = rbindlist(lapply(gdp_raw, function(x) {
  data.table(
    country = x$country$value,
    year = as.integer(x$date),
    gdp = as.numeric(x$value)
  )
}))

print(gdp[order(year)])

# quick plot
ggplot(gdp[!is.na(gdp)], aes(x = year, y = gdp / 1e12)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(color = "steelblue") +
  labs(title = "Germany: GDP (current USD)",
       x = "Year", y = "GDP (trillions USD)",
       caption = "Source: World Bank API") +
  theme_minimal()

# 2 - API key management ----

# never hardcode API keys in scripts!
# store them in .Renviron (loaded automatically at R startup)

# edit your .Renviron file:
# usethis::edit_r_environ()
#
# add a line like:
# OPENROUTER_API_KEY=sk-or-v1-abc123...
#
# then access it in R:
# api_key = Sys.getenv("OPENROUTER_API_KEY")
# if (api_key == "") stop("Set OPENROUTER_API_KEY in .Renviron")

# 3 - httr2: retry and rate limiting ----

# httr2 has built-in retry logic and rate limiting
resp = request("https://api.worldbank.org/v2") %>%
  req_url_path_append("country", "all", "indicator", "NY.GDP.MKTP.CD") %>%
  req_url_query(format = "json", per_page = 100, date = "2022") %>%
  req_retry(max_tries = 3, backoff = ~ 2) %>%   # retry up to 3 times with exponential backoff
  req_throttle(rate = 10 / 60) %>%               # max 10 requests per minute
  req_perform()

resp_status(resp)

# 4 - httr2: error handling ----

# suppress automatic errors to handle them manually
resp = request("https://api.worldbank.org/v2") %>%
  req_url_path_append("country", "INVALID", "indicator", "NY.GDP.MKTP.CD") %>%
  req_url_query(format = "json") %>%
  req_error(is_error = \(resp) FALSE) %>%  # don't throw on HTTP errors
  req_perform()

if (resp_status(resp) >= 400) {
  message("HTTP error: ", resp_status(resp), " ", resp_status_desc(resp))
} else {
  resp_status(resp)
}

# 5 - fetching multiple countries in a loop ----

countries = c("DEU", "FRA", "USA", "CHN", "BRA", "IND", "JPN", "GBR")

results = list()
for (cc in countries) {
  cat("Fetching:", cc, "\n")

  tryCatch({
    resp = request("https://api.worldbank.org/v2") %>%
      req_url_path_append("country", cc, "indicator", "NY.GDP.MKTP.CD") %>%
      req_url_query(format = "json", per_page = 30, date = "2000:2023") %>%
      req_retry(max_tries = 3) %>%
      req_throttle(rate = 10 / 60) %>%
      req_perform()

    body = resp %>% resp_body_json()

    if (length(body) >= 2 && !is.null(body[[2]])) {
      results[[cc]] = rbindlist(lapply(body[[2]], function(x) {
        data.table(
          country = x$country$id,
          country_name = x$country$value,
          year = as.integer(x$date),
          gdp = as.numeric(x$value)
        )
      }))
    }
  }, error = function(e) {
    message("Failed for ", cc, ": ", e$message)
  })

  Sys.sleep(runif(1, 0.5, 1.5))  # polite delay
}

all_gdp = rbindlist(results)
print(all_gdp[order(country, year)])

# 6 - the polite package ----

# polite automatically reads robots.txt, respects crawl delays,
# and identifies your scraper via user-agent

# p_load(polite)
#
# session = bow(
#   url = "https://www.ikea.com",
#   user_agent = "DSfE course bot (academic use)",
#   delay = 5  # seconds between requests
# )
# print(session)  # shows robots.txt rules
#
# page = nod(session, path = "/de/de/p/billy-buecherregal-weiss-00263850/")
# result = scrape(page)

# 7 - exchange rates API (JSON) ----

# free exchange rate API, no key required
rates_resp = request("https://open.er-api.com/v6/latest/USD") %>%
  req_perform()

rates_json = rates_resp %>% resp_body_json()
rates_dt = data.table(
  currency = names(rates_json$rates),
  rate = unlist(rates_json$rates)
)
print(rates_dt[currency %in% c("EUR", "GBP", "JPY", "CNY", "BRL")])

# 8 - cleanup ----

rm(gdp, all_gdp, rates_dt)
gc()
