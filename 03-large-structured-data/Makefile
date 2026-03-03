###
# Makefile for 03-large-structured-data
# 260303
# produce two nice plots from Colombian firm-level data
###

all: output/figures/size_distribution.png output/figures/imports_over_time.png

temp/Impo_2018/Diciembre.csv: code/00-download_data.sh
	./code/00-download_data.sh

output/figures/size_distribution.png output/figures/imports_over_time.png: code/01-load_and_explore.R temp/Impo_2018/Diciembre.csv
	./code/01-load_and_explore.R
