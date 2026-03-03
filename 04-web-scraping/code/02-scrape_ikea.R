###
# 02 - Scrape IKEA Billy Bookcase Prices
# 260226
###

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(rvest)
p_load(stringr)
p_load(jsonlite)
p_load(ggplot2)

# 0 - settings ----

dir.create("output", showWarnings = FALSE, recursive = TRUE)
dir.create("temp", showWarnings = FALSE, recursive = TRUE)

# 1 - scrape a single country page ----

# Germany
country = "de/de"
url = str_c("https://www.ikea.com/", country, "/p/billy-buecherregal-weiss-00263850/")

page = tryCatch(
  read_html(url),
  error = function(e) {
    message("Failed to read: ", url, "\n", e$message)
    NULL
  }
)

if (!is.null(page)) {
  # extract the price using CSS selectors
  price_node = page %>%
    html_node("#pip-buy-module-content >
       div.js-price-package.pip-price-package >
        div.pip-price-module.pip-price-module--small.pip-price-module--none >
         div.pip-price-module__price")

  price_int = price_node %>%
    html_node(".pip-price__integer") %>%
    html_text()
  price_dec = price_node %>%
    html_node(".pip-price__decimal") %>%
    html_text() %>%
    str_remove_all("\\,") %>%
    str_remove_all("\\.")
  price_currency = price_node %>%
    html_node(".pip-price__currency") %>%
    html_text()

  price_combined = as.numeric(str_c(price_int, ".", price_dec))
}

# 2 - scrape multiple countries ----

countries = c(
  "de/de", "fr/fr", "it/it", "es/es", "pl/pl", "nl/nl", "cz/cs",
  "dk/da", "fi/fi", "no/no", "se/sv", "hu/hu", "ro/ro",
  "us/en", "gb/en", "ie/en", "at/de", "ch/fr",
  "au/en", "ca/en", "sg/en", "jp/ja", "kr/ko", "in/en"
)

# some countries use a different product ID
alt_product_countries = c("in/en", "sg/en", "jp/ja", "kr/ko")

dt = data.table(
  country = character(),
  price = numeric(),
  currency = character()
)

for (cc in countries) {

  # build URL
  url = if (cc %in% alt_product_countries) {
    str_c("https://www.ikea.com/", cc, "/p/billy-bookcase-white-00522047/")
  } else {
    str_c("https://www.ikea.com/", cc, "/p/billy-buecherregal-weiss-00263850/")
  }
  cat("Scraping:", url, "\n")

  # read page with error handling
  page = tryCatch(
    read_html(url),
    error = function(e) {
      message("  Failed: ", e$message)
      NULL
    }
  )

  if (is.null(page)) next

  # extract price
  tryCatch({
    price_node = page %>%
      html_node("#pip-buy-module-content >
         div.js-price-package.pip-price-package >
          div.pip-price-module.pip-price-module--small.pip-price-module--none >
           div.pip-price-module__price")

    price_int = price_node %>%
      html_node(".pip-price__integer") %>%
      html_text() %>%
      str_remove_all(" ") %>%
      str_remove_all("\\,") %>%
      str_remove_all("\\.")
    price_dec = price_node %>%
      html_node(".pip-price__decimal") %>%
      html_text() %>%
      str_remove_all("\\,") %>%
      str_remove_all("\\.")
    price_currency = price_node %>%
      html_node(".pip-price__currency") %>%
      html_text()

    if (is.na(price_dec)) price_dec = "00"
    price_combined = as.numeric(str_c(price_int, ".", price_dec))

    dt = rbind(dt, data.table(
      country = cc,
      price = price_combined,
      currency = price_currency
    ))
  }, error = function(e) {
    message("  Parse error for ", cc, ": ", e$message)
  })

  # rate limiting: random delay between 1 and 3 seconds
  Sys.sleep(1 + runif(1, 0, 2))
}

print(dt)

# 3 - get exchange rates ----

rate_api = "https://open.er-api.com/v6/latest/USD"
rates = fromJSON(rate_api)
rates_dt = data.table(
  currency_code = names(rates$rates),
  rate = unlist(rates$rates)
)

# 4 - save results ----

fwrite(dt, "temp/ikea_billy_prices.csv")

# 5 - cleanup ----

rm(page, price_node)
gc()
