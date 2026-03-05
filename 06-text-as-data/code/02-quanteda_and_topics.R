###
# 02 - Quanteda Pipeline and LDA Topic Modeling
# 260226
###

# This script covers:
# 1. quanteda pipeline: corpus → tokens → dfm → tfidf
# 2. Document similarity with quanteda
# 3. Dictionary-based methods
# 4. LDA topic modeling with the topicmodels package
#
# Uses the same WTO treaty data as 01-text_mining_treaties.R

if (!require("pacman")) install.packages("pacman"); library(pacman)
p_load(data.table)
p_load(magrittr)
p_load(quanteda)
p_load(quanteda.textstats)
p_load(quanteda.textplots)
p_load(topicmodels)
p_load(xml2)
p_load(tidytext)   # for convert()
p_load(ggplot2)

# 0 - settings ----

dir.create("input", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

# 1 - load treaty texts ----

# download if needed
if (!dir.exists("input/tota-master")) {
  url = "https://github.com/mappingtreaties/tota/archive/refs/heads/master.zip"
  download.file(url, "input/tota.zip")
  unzip("input/tota.zip", exdir = "input/")
}

file_directory = "input/tota-master/xml"
my_files = list.files(file_directory, full.names = TRUE)

# read all treaties into a data.table
read_treaty = function(x) {
  tryCatch({
    treaty_data = read_xml(x)
    info = as_list(treaty_data)$treaty
    date_signed = tryCatch(
      unlist(info[names(info) == "date_signed"]),
      error = function(e) NA_character_
    )
    content = treaty_data %>%
      xml_find_all("//article") %>%
      xml_text() %>%
      trimws() %>%
      paste(collapse = " ")
    data.table(
      file = basename(x),
      date = date_signed[1],
      text = content
    )
  }, error = function(e) {
    data.table(file = basename(x), date = NA_character_, text = NA_character_)
  })
}

cat("Reading", length(my_files), "treaty files...\n")
treaties = rbindlist(lapply(my_files, read_treaty))

# remove empty or very short treaties
treaties = treaties[!is.na(text) & nchar(text) > 100]
cat("Treaties with text:", nrow(treaties), "\n")

# 2 - quanteda pipeline: corpus → tokens → dfm ----

# create a corpus
corp = corpus(treaties, text_field = "text", docid_field = "file")
cat("Corpus summary:\n")
print(summary(corp, n = 5))

# tokenize: split into words, remove punctuation and numbers
toks = tokens(corp, remove_punct = TRUE, remove_numbers = TRUE) %>%
  tokens_remove(stopwords("en")) %>%
  tokens_tolower()

# create document-feature matrix (DFM)
dfmat = dfm(toks)
cat("\nDFM dimensions:", dim(dfmat), "(documents x features)\n")

# top features across all documents
topfeatures(dfmat, 20)

# 3 - TF-IDF weighting ----

dfmat_tfidf = dfm_tfidf(dfmat)

# compare: raw counts vs tfidf for the first document
cat("\nTop features in document 1 (raw counts):\n")
print(topfeatures(dfmat[1, ], 10))

cat("\nTop features in document 1 (tf-idf):\n")
print(topfeatures(dfmat_tfidf[1, ], 10))

# 4 - trimming rare/common features ----

# remove features that appear in fewer than 5 documents
# or in more than 80% of documents
dfmat_trimmed = dfm_trim(dfmat, min_docfreq = 5, max_docfreq = 0.8,
                         docfreq_type = "prop")
cat("\nTrimmed DFM dimensions:", dim(dfmat_trimmed), "\n")

# 5 - document similarity ----

# cosine similarity between first 10 treaties
sim_matrix = textstat_simil(dfmat_tfidf[1:10, ], method = "cosine")
cat("\nCosine similarity (first 10 treaties):\n")
print(round(as.matrix(sim_matrix), 3))

# Jaccard similarity (binary: word present or not)
sim_jaccard = textstat_simil(dfm_weight(dfmat[1:10, ], scheme = "boolean"),
                             method = "jaccard")

# 6 - wordcloud visualization ----

# wordcloud of top features
set.seed(42)
textplot_wordcloud(dfmat_trimmed, max_words = 100, color = "steelblue")

# 7 - dictionary-based methods ----

# create a custom trade-policy dictionary
trade_dict = dictionary(list(
  liberalization = c("liberali*", "free trade", "tariff reduction",
                     "market access", "most favoured nation", "mfn"),
  protection = c("safeguard*", "anti-dumping", "countervailing",
                 "quota*", "restriction*", "prohibit*"),
  services = c("servic*", "financial", "telecommunicat*",
               "transport*", "professional"),
  agriculture = c("agric*", "farm*", "rural", "crop*",
                  "livestock", "fisheri*", "sanitary")
))

# apply dictionary to the DFM
dfmat_dict = dfm_lookup(dfmat, dictionary = trade_dict)
cat("\nDictionary-based counts (first 5 treaties):\n")
print(as.matrix(dfmat_dict[1:5, ]))

# proportion of each category
dict_props = as.data.table(convert(dfmat_dict, to = "data.frame"))
dict_props[, total := liberalization + protection + services + agriculture]
dict_props[total > 0, .(
  lib_share = mean(liberalization / total),
  prot_share = mean(protection / total),
  serv_share = mean(services / total),
  agri_share = mean(agriculture / total)
)]

# 8 - LDA topic modeling ----

# prepare a trimmed DFM for topic modeling
dfmat_lda = dfm_trim(dfmat, min_termfreq = 5, min_docfreq = 3)
cat("\nDFM for LDA:", dim(dfmat_lda), "\n")

# convert to topicmodels format
dtm = convert(dfmat_lda, to = "topicmodels")

# fit LDA with k = 5 topics
set.seed(42)
cat("Fitting LDA model (k = 5)...\n")
lda_model = LDA(dtm, k = 5, control = list(seed = 42))

# top 10 words per topic
cat("\nTop 10 words per topic:\n")
print(terms(lda_model, 10))

# topic proportions for first 5 documents
cat("\nTopic proportions (first 5 documents):\n")
print(round(posterior(lda_model)$topics[1:5, ], 3))

# 9 - visualize topic proportions ----

topic_props = as.data.table(posterior(lda_model)$topics)
topic_props[, doc_id := 1:.N]
topic_long = melt(topic_props, id.vars = "doc_id",
                  variable.name = "topic", value.name = "proportion")

# average topic proportions
avg_topics = topic_long[, .(mean_prop = mean(proportion)), by = topic]

p_topics = ggplot(avg_topics, aes(x = topic, y = mean_prop, fill = topic)) +
  geom_col() +
  labs(title = "Average Topic Proportions Across Treaties",
       x = "Topic", y = "Mean Proportion") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave("output/figures/260226_lda_topics.png", p_topics,
       width = 8, height = 5, dpi = 300)
rm(p_topics)

# 10 - choosing k: perplexity ----

# try different values of k and compare perplexity
# (lower perplexity = better fit, but beware overfitting)

if (FALSE) {  # slow; uncomment to run
  ks = c(3, 5, 7, 10, 15)
  perplexities = sapply(ks, function(k) {
    cat("Fitting k =", k, "\n")
    m = LDA(dtm, k = k, control = list(seed = 42))
    perplexity(m)
  })

  perp_dt = data.table(k = ks, perplexity = perplexities)

  ggplot(perp_dt, aes(x = k, y = perplexity)) +
    geom_line(color = "steelblue") +
    geom_point(color = "steelblue", size = 3) +
    labs(title = "LDA Perplexity by Number of Topics",
         x = "k (number of topics)", y = "Perplexity") +
    theme_minimal()
}

# 11 - cleanup ----

rm(corp, toks, dfmat, dfmat_tfidf, dfmat_trimmed, dfmat_lda, dfmat_dict)
rm(treaties, lda_model, dtm, topic_props, topic_long)
gc()
