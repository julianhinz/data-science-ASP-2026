###
# 01 - Text Mining WTO Treaties
# 260226
###

# This script covers:
# 1. Regular expressions basics
# 2. Cosine similarity
# 3. WTO treaty data: XML parsing, word frequencies, wordclouds
# 4. Chi-square comparison of treaty content
# 5. Treaty depth over time
#
# Based on WTO treaty data from the TOTA project:
# https://github.com/mappingtreaties/tota

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(xml2)
p_load(tidytext)
p_load(textstem)
p_load(wordcloud2)
p_load(tidyverse)  # for unnest, spread, map_df (tidytext integration)
p_load(ggplot2)

# 0 - settings ----

dir.create("input", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# 1 - regular expressions basics ----

# detect patterns
grepl("class", "Today class it's very fun\n\n\t\t")

# replace patterns
gsub("\t|\n", "", "Today class it's very fun\n\n\t\t")

# filter by pattern
some_text = c("This", "topic", "is", "so", "much", "fun")
some_text[grep("^[T]", some_text)]

# remove brackets
text_chunk = "[This topic is not so fun]"
gsub("\\[|\\]", "", text_chunk)

# exercise: extract all words starting with "p"
words = c("Policy", "trade", "production", "data")
words[grepl("^[Pp]", words)]

# 2 - cosine similarity ----

# how similar are two texts? cosine similarity quantifies it
s1 = "The book is on the table"
s2 = "The pen is on the table"
s3 = "Put the pen on the book"

sv = c(s1 = s1, s2 = s2, s3 = s3)
svs = strsplit(tolower(sv), "\\s+")
termf = table(stack(svs))

# TF-IDF weighting
idf = log(1 / rowMeans(termf != 0))
tfidf = termf * idf

# cosine similarity between s3 and each of s1, s2
dp = t(tfidf[, 3]) %*% tfidf[, -3]
cosim = dp / (sqrt(colSums(tfidf[, -3]^2)) * sqrt(sum(tfidf[, 3]^2)))
print(cosim)

# question: how does similarity change if you swap just one word?

# 3 - download WTO treaty data ----

if (!dir.exists("input/tota-master")) {
  url = "https://github.com/mappingtreaties/tota/archive/refs/heads/master.zip"
  download.file(url, "input/tota.zip")
  unzip("input/tota.zip", exdir = "input/")
}

# 4 - read and parse a sample XML treaty ----

treaty_data = read_xml("input/tota-master/xml/pta_1.xml")

# extract metadata
info = as_list(treaty_data) %>%
  tibble::as_tibble() %>%
  unnest_longer(treaty) %>%
  filter(treaty_id %in% c("date_signed", "parties_original"))

# extract articles
articles = treaty_data %>% xml_find_all("//article")
id = articles %>% xml_attr("article_identifier") %>% as.character()
content = articles %>% xml_text() %>% trimws()

# build treaty text data frame
treaty_text = content %>%
  as.data.frame() %>%
  rename(content = ".") %>%
  mutate(
    year = unlist(filter(info, treaty_id == "date_signed")$treaty),
    parties = filter(info, treaty_id == "parties_original")$treaty
  ) %>%
  ungroup() %>%
  select(content, year, parties) %>%
  group_by(year, parties) %>%
  summarise(treaty = paste(content, collapse = " // "), .groups = "keep")

# 5 - most frequent words ----

# raw frequency
treaty_text[1, 3] %>%
  as.data.frame() %>%
  unnest_tokens(word, treaty) %>%
  count(word, sort = TRUE) %>%
  head(10)

# with stopword removal and lemmatization
word_freq = treaty_text[1, 3] %>%
  as.data.frame() %>%
  unnest_tokens(word, treaty) %>%
  anti_join(stop_words, by = "word") %>%
  filter(!grepl("[0-9]", word)) %>%
  mutate(word = lemmatize_words(word)) %>%
  count(word, sort = TRUE)
head(word_freq, 15)

# 6 - wordcloud ----

wordcloud2(word_freq, color = "random-light", backgroundColor = "#152238")

# question: which keywords dominate? are they surprising?

# 7 - helper function for batch XML processing ----

read_my_xml = function(x) {
  cat("Processing:", basename(x), "\n")

  treaty_data = read_xml(x)

  info = as_list(treaty_data) %>%
    tibble::as_tibble() %>%
    unnest_longer(treaty) %>%
    filter(treaty_id %in% c("date_signed", "parties_original"))

  articles = treaty_data %>% xml_find_all("//article")
  content = articles %>% xml_text() %>% trimws()

  data = content %>%
    as.data.frame() %>%
    rename(content = ".") %>%
    mutate(
      year = unlist(filter(info, treaty_id == "date_signed")$treaty),
      parties = filter(info, treaty_id == "parties_original")$treaty
    ) %>%
    ungroup() %>%
    select(content, year, parties) %>%
    group_by(year, parties) %>%
    summarise(treaty = paste(content, collapse = " // "), .groups = "keep")

  # count services and agriculture terms
  temp = data[1, 3] %>%
    as.data.frame() %>%
    unnest_tokens(word, treaty) %>%
    anti_join(stop_words, by = "word") %>%
    count(word, sort = TRUE) %>%
    ungroup() %>%
    mutate(tot_words = sum(n)) %>%
    filter(grepl("^servic", word) | grepl("^agric", word)) %>%
    mutate(year = data$year, parties = data$parties)

  if (nrow(temp) == 0) {
    temp = data.frame(n = 0, tot_words = 0, word = "NA",
                      year = data$year, parties = data$parties)
  }

  return(temp)
}

# 8 - chi-square comparison of two treaties ----

file_directory = "input/tota-master/xml"
my_files = list.files(file_directory, full.names = TRUE)

set.seed(123)
draw2 = sample(my_files, 2)

dat = map_df(draw2, read_my_xml)

# reshape to wide format
table_wide = dat %>% spread(key = word, value = n)
print(table_wide)

# combine service/agriculture columns
table_wide = table_wide %>%
  mutate(
    agriculture_combined = rowSums(select(., starts_with("agric")), na.rm = TRUE),
    services_combined = rowSums(select(., starts_with("servic")), na.rm = TRUE)
  ) %>%
  select(year, parties, tot_words, agriculture_combined, services_combined)

# chi-square test
chi_sq_result = chisq.test(table_wide$agriculture_combined,
                           table_wide$services_combined,
                           correct = FALSE)
print(chi_sq_result)

# question: if significant, what does that tell you about the two documents?

# 9 - depth of trade agreements over time ----

read_treaty_depth = function(x) {
  treaty_data = read_xml(x)
  info = as_list(treaty_data) %>%
    tibble::as_tibble() %>%
    unnest_longer(treaty) %>%
    filter(treaty_id %in% c("date_signed", "parties_original"))
  content = treaty_data %>%
    xml_find_all("//article") %>%
    xml_text() %>%
    trimws()
  data.frame(
    year = unlist(filter(info, treaty_id == "date_signed")$treaty),
    words = length(unlist(strsplit(content, " ")))
  )
}

dat_depth = map_df(my_files, read_treaty_depth)

p_depth = dat_depth %>%
  mutate(year = as.numeric(format(as.Date(year), "%Y"))) %>%
  group_by(year) %>%
  summarise(avg_words = mean(words, na.rm = TRUE)) %>%
  ggplot(aes(x = year, y = avg_words)) +
  geom_line(color = "steelblue") +
  geom_point(color = "red") +
  scale_x_continuous(breaks = seq(1950, 2020, 10)) +
  labs(title = "Depth of WTO Trade Agreements Over Time",
       x = "Year",
       y = "Average Word Count") +
  theme_minimal()
ggsave("output/figures/260226_treaty_depth.png", p_depth,
       width = 8, height = 5, dpi = 300)
rm(p_depth)

# question: does the trend match what you expected?

# 10 - cleanup ----

rm(treaty_data, treaty_text, word_freq, dat, dat_depth, table_wide)
gc()
