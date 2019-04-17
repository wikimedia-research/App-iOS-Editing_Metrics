library(tidyverse)
library(magrittr)
library(lubridate)

all_ios_edits <- read_tsv("data/all_ios_edits_production_replica.tsv")

all_ios_edits %<>%
  mutate(date = ymd(date),
         first_app_edit_ts = ymd_hms(first_app_edit_ts),
         user_registration = ymd_hms(user_registration),
         is_deleted = ifelse(is_deleted=="True", TRUE, FALSE),
         is_reverted = ifelse(is_reverted=="True", TRUE, FALSE),
         wiki_group = ifelse(wiki == "wikidatawiki", "wikidata", wiki_group)
         )

wikitext_release <- as.Date("2019-02-21")
wikidata_release <- as.Date("2018-10-31")
