source("preprocessing.R")

# Monthly
all_ios_edits %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))
all_ios_edits %>%
  filter(language != "English") %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))

# Quarterly
all_ios_edits %>%
  mutate(quarter = floor_date(date, "quarter")) %>%
  group_by(quarter) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))
all_ios_edits %>%
  filter(language != "English") %>%
  mutate(quarter = floor_date(date, "quarter")) %>%
  group_by(quarter) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))

# 30 days cohorts
anchor <- seq(from =wikitext_release-30*7, to=wikitext_release+30, by=30)
all_ios_edits %>%
  mutate(month = findInterval(date, anchor)) %>%
  group_by(month) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))
all_ios_edits %>%
  filter(language != "English") %>%
  mutate(month = findInterval(date, anchor)) %>%
  group_by(month) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))

# Revert rate by project
p <- all_ios_edits %>%
  filter(!(wiki_group=="wikidata" & date < wikidata_release)) %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, project) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted))) %>%
  ggplot(aes(x=date, y=revert_rate, color = project)) +
  geom_line(size = 1.2) +
  scale_y_continuous("Revert Rate", labels = scales::percent_format()) +
  scale_x_date("Date") +
  scale_color_brewer("Project", palette = "Paired") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.1, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.1, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Daily iOS app edits revert rate, by project')
ggsave("daily_revert_rate_by_proj.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)
p <- all_ios_edits %>%
  filter(!(wiki_group=="wikidata" & date < wikidata_release)) %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia"),
         month = floor_date(date, "month")) %>%
  group_by(month, project) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted))) %>%
  ggplot(aes(x=month, y=revert_rate, color = project)) +
  geom_line(size = 1.2) +
  scale_y_continuous("Revert Rate", labels = scales::percent_format()) +
  scale_x_date(name = "Month", date_labels = "%Y-%m") +
  scale_color_brewer("Project", palette = "Paired") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.1, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.1, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Monthly iOS app edits revert rate, by project')
ggsave("monthly_revert_rate_by_proj.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)

all_ios_edits %>%
  filter(!(wiki_group=="wikidata" & date < wikidata_release)) %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(project) %>%
  summarize(revert_rate = sum(is_reverted, na.rm = TRUE)/sum(!is.na(is_reverted)))
