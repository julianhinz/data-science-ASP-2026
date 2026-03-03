#!/opt/homebrew/bin/Rscript

print("Hello world")


# loop
for (i in 1:5) {
  print(paste("Iteration", i))
}

i <- 1
while (i <= 5) {
  print(paste("Iteration", i))
  i <- i + 1
}


# pipes
library(magrittr)

d = data.frame(x = 1:50, y = 6:55)
d %>% head() %>% summary()
summary(head(d))

install.packages("ggplot2")
library(ggplot2)

install.packages("pacman")
library(pacman)

p_load(data.table)


# heading 1
## heading 2

- item 1
- item 2

*bold* and _italic_ text

- [ ] task 1
- [x] task 2
