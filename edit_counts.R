source("preprocessing.R")

daily_edit_counts <- all_ios_edits %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, project) %>%
  summarize(edit_counts = n())
p <- daily_edit_counts %>%
  ggplot(aes(x=date, y=edit_counts, fill=project)) +
  geom_area() +
  scale_x_date(name = "Date", date_breaks = "month") +
  scale_y_continuous(name = "Number of edits") +
  scale_fill_brewer("Project", palette = "Paired") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 500, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 500, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of edits on the iOS app, by project")
ggsave("all_ios_edits_byproj.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)

# 30 days before and after
daily_edit_counts %>%
  filter(date >= wikitext_release, date < wikitext_release+30) %>%
  group_by(project) %>%
  summarize(edit_counts = sum(edit_counts))
daily_edit_counts %>%
  filter(date < wikitext_release, date >= wikitext_release-30) %>%
  group_by(project) %>%
  summarize(edit_counts = sum(edit_counts))
# By month
daily_edit_counts %>%
  mutate(month = month(date)) %>%
  group_by(month) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(mom = edit_counts/lag(edit_counts)-1)
daily_edit_counts %>%
  mutate(month = month(date)) %>%
  group_by(project, month) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(mom = edit_counts/lag(edit_counts)-1)
# By quarter
daily_edit_counts %>%
  mutate(quarter = quarter(date)) %>%
  group_by(quarter) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(qoq = edit_counts/lag(edit_counts)-1)
daily_edit_counts %>%
  mutate(quarter = quarter(date)) %>%
  group_by(project, quarter) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(qoq = edit_counts/lag(edit_counts)-1)


# Without English
daily_edit_counts_other <- all_ios_edits %>%
  filter(language != "English") %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, project) %>%
  summarize(edit_counts = n())
# 30 days before and after
daily_edit_counts_other %>%
  filter(date >= wikitext_release, date < wikitext_release+30) %>%
  group_by(project) %>%
  summarize(edit_counts = sum(edit_counts))
daily_edit_counts_other %>%
  filter(date < wikitext_release, date >= wikitext_release-30) %>%
  group_by(project) %>%
  summarize(edit_counts = sum(edit_counts))
# By month
daily_edit_counts_other %>%
  mutate(month = month(date)) %>%
  group_by(month) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(mom = edit_counts/lag(edit_counts)-1)
daily_edit_counts_other %>%
  mutate(month = month(date)) %>%
  group_by(project, month) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(mom = edit_counts/lag(edit_counts)-1)
# By quarter
daily_edit_counts_other %>%
  mutate(quarter = quarter(date)) %>%
  group_by(quarter) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(qoq = edit_counts/lag(edit_counts)-1)
daily_edit_counts_other %>%
  mutate(quarter = quarter(date)) %>%
  group_by(project, quarter) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(qoq = edit_counts/lag(edit_counts)-1)


# By login status
edits_by_login <- all_ios_edits %>%
  filter(!is.na(local_user_id)) %>%
  mutate(is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, project, is_anon) %>%
  summarize(edit_counts = n())
p <- edits_by_login %>%
  mutate(is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  group_by(date, is_anon) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  ggplot(aes(x=date, y=edit_counts, fill=is_anon)) +
  geom_area() +
  scale_x_date(name = "Date") +
  scale_y_continuous(name = "Number of edits") +
  scale_fill_brewer("Edit Type", palette = "Pastel1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 500, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 500, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of edits on the iOS app, by login status")
ggsave("all_ios_edits_bylogin.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)

p <- edits_by_login %>%
  filter(project == "Wikipedia") %>%
  mutate(is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  ggplot(aes(x=date, y=edit_counts, fill=is_anon)) +
  geom_area() +
  scale_x_date(name = "Date") +
  scale_y_continuous(name = "Number of edits") +
  scale_fill_brewer("Edit Type", palette = "Pastel1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 500, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 500, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of Wikipedia edits on the iOS app, by login status")
ggsave("wikipedia_edits_bylogin.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)

anchor <- seq(from =wikitext_release-30*7, to=wikitext_release+30, by=30)
edits_by_login %>%
  filter(project == "Wikipedia") %>%
  mutate(month = findInterval(date, anchor),
         is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  group_by(month, is_anon) %>%
  summarize(edit_counts = sum(edit_counts))

# Number of edits by device

edits_by_device <- all_ios_edits %>%
  filter(date>=as.Date("2018-09-12")) %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, project, device) %>%
  summarize(edit_counts = n())
p <- edits_by_device %>%
  # mutate(device = ifelse(is.na(device), "Unknown", device)) %>%
  filter(!is.na(device)) %>%
  group_by(date, device) %>%
  summarize(edit_counts = sum(edit_counts, na.rm = TRUE)) %>%
  ggplot(aes(x=date, y=edit_counts, fill=device)) +
  geom_area() +
  scale_x_date(name = "Date") +
  scale_y_continuous(name = "Number of edits") +
  scale_fill_brewer("Device", palette = "Accent") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 500, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 500, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of edits on the iOS app, by device")
ggsave("all_ios_edits_bydevice.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)
p <- edits_by_device %>%
  filter(project == "Wikipedia", !is.na(device)) %>%
  # mutate(device = ifelse(is.na(device), "Unknown", device)) %>%
  ggplot(aes(x=date, y=edit_counts, fill=device)) +
  geom_area() +
  scale_x_date(name = "Date") +
  scale_y_continuous(name = "Number of edits") +
  scale_fill_brewer("Device", palette = "Accent") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 500, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 500, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of Wikipedia edits on the iOS app, by device")
ggsave("wikipedia_edits_bydevice.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)

edits_by_device %>%
  filter(project == "Wikipedia") %>%
  mutate(month = findInterval(date, anchor)) %>%
  group_by(month, device) %>%
  summarize(edit_counts = sum(edit_counts)) %>%
  mutate(proportion = edit_counts/sum(edit_counts))
