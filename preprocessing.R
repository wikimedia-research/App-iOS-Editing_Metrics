library(tidyverse)
library(magrittr)
library(lubridate)

all_ios_edits <- read_tsv("data/all_ios_edits_mediawiki_history.tsv", col_types = "ccccdccdiiilcl")

all_ios_edits %<>%
  mutate(date = ymd(date),
         local_user_registration = ymd_hms(local_user_registration),
         first_app_edit_ts = ymd_hms(first_app_edit_ts),
         local_user_id = ifelse(is.na(local_user_id), 0, local_user_id)
         ) %>%
  filter(date < as.Date("2019-07-01"))

wikitext_release <- as.Date("2019-02-21")
wikidata_release <- as.Date("2018-10-31")
