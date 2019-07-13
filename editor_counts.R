source("preprocessing.R")


# All editors

daily_editor_counts <- all_ios_edits %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, username) %>%
  summarize(project = case_when(
    all(project == "Wikipedia") ~ "Wikipedia",
    all(project == "Wikidata description") ~ "Wikidata description",
    TRUE ~ "Wikipedia & Wikidata"
  )) %>%
  group_by(date, project) %>%
  summarize(n_editors = length(unique(username)))
p <- daily_editor_counts %>%
  ggplot(aes(x=date, y=n_editors, fill=project)) +
  geom_area() +
  scale_x_date(name = "Date", date_breaks = "month") +
  scale_y_continuous(name = "Number of editors") +
  scale_fill_brewer("Project", palette = "Paired") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 200, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 200, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of editors on the iOS app, by project",
       subtitle = "Including both anonymous and non-anonymous editors. Anonymous editors are identified by their IP addresses.")
ggsave("all_ios_editors_byproj.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 12)
p <- daily_editor_counts %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, project) %>%
  summarize(n_editors = sum(n_editors)) %>%
  ggplot(aes(x=month, y=n_editors, fill=project)) +
  geom_bar(stat="identity") +
  scale_x_date(name = "Month", date_labels = "%Y-%m") +
  scale_y_continuous(name = "Number of editors") +
  scale_fill_brewer("Project", palette = "Paired") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 5000, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 5000, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of editors on the iOS app, by project",
       subtitle = "Including both anonymous and non-anonymous editors. Anonymous editors are identified by their IP addresses.")
ggsave("all_ios_editors_byproj_bar.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 12)

all_ios_edits %>%
  mutate(month = month(date)) %>%
  group_by(month) %>%
  summarize(n_editors = length(unique(username)))
all_ios_edits %>%
  mutate(project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  filter(date >= wikitext_release) %>%
  group_by(username) %>%
  summarize(project = case_when(
    all(project == "Wikipedia") ~ "Wikipedia",
    all(project == "Wikidata description") ~ "Wikidata description",
    TRUE ~ "Wikipedia & Wikidata"
  )) %>%
  group_by(project) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(proportion = n_editors/sum(n_editors))

# by anonymous
p <- all_ios_edits %>%
  mutate(is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(date, is_anon) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  ggplot(aes(x=date, y=n_editors, fill=is_anon)) +
  geom_area() +
  scale_x_date(name = "Date", date_breaks = "1 month") +
  scale_y_continuous(name = "Number of editors") +
  scale_fill_brewer("Editor Type", palette = "Pastel1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 200, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 200, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of editors on the iOS app, by login status",
       subtitle = "Anonymous editors are identified by their IP addresses.")
ggsave("all_ios_editors_bylogin.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 12)
p <- all_ios_edits %>%
  mutate(month = floor_date(date, "month"),
         is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(month, is_anon) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  ggplot(aes(x=month, y=n_editors, fill=is_anon)) +
  geom_bar(stat="identity") +
  scale_x_date(name = "Month", date_labels = "%Y-%m") +
  scale_y_continuous(name = "Number of editors") +
  scale_fill_brewer("Editor Type", palette = "Pastel1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 3000, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 3000, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of editors on the iOS app, by login status",
       subtitle = "Anonymous editors are identified by their IP addresses.")
ggsave("all_ios_editors_bylogin_bar.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 12)

p <- all_ios_edits %>%
  mutate(is_anon = local_user_id == 0) %>%
  filter(wiki_group=="wikipedia") %>%
  group_by(date, is_anon) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(is_anon = ifelse(is_anon, "Anonymous", "Non-anonymous")) %>%
  ggplot(aes(x=date, y=n_editors, fill=is_anon)) +
  geom_area() +
  scale_x_date(name = "Date", date_breaks = "1 month") +
  scale_y_continuous(name = "Number of editors") +
  scale_fill_brewer("Editor Type", palette = "Pastel1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 200, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 200, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of Wikipedia editors on the iOS app, by login status",
       subtitle = "Anonymous editors are identified by their IP addresses.")
ggsave("wikipedia_editors_bylogin.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 12)



all_ios_edits %>%
  mutate(is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  mutate(month = month(date)) %>%
  group_by(month, is_anon) %>%
  summarize(n_editors = length(unique(username)))

all_ios_edits %>%
  mutate(is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  filter(date >= wikitext_release) %>%
  group_by(is_anon) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(proportion = n_editors/sum(n_editors))

all_ios_edits %>%
  mutate(is_anon = local_user_id == 0,
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(project, is_anon) %>%
  summarize(n_editors = length(unique(username))) %>%
  mutate(proportion = n_editors/sum(n_editors))


# Active editors


editor_month <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  group_by(username) %>%
  mutate(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE) ) %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n(),
            content_edits = sum(namespace == 0),
            first_ios_edit_date = min(first_ios_edit_date, na.rm = TRUE))
            # user_registration = min(user_registration, na.rm = TRUE)
active_editors <- editor_month %>%
  filter(content_edits >= 5) %>%
  group_by(month) %>%
  summarize(all_active_editors = n()) %>%
  inner_join({
    editor_month %>%
      filter(content_edits >= 5, month == floor_date(first_ios_edit_date, "month")) %>%
      group_by(month) %>%
      summarize(new_active_editors = n())
  }, by = 'month') %>%
 inner_join({
   editor_month %>%
     filter(content_edits >= 5, month != floor_date(first_ios_edit_date, "month")) %>%
     group_by(month) %>%
     summarize(returning_active_editors = n())
 }, by = 'month')

p <- active_editors %>%
  select(-all_active_editors) %>%
  gather(key="User type", value=counts, -month) %>%
  mutate(`User type` = factor(gsub("_", " ", `User type`),
                              levels = c("new active editors", "returning active editors"))) %>%
  ggplot(aes(x=month, y=counts, fill=`User type`)) +
  geom_bar(stat="identity") +
  scale_x_date(name = "Month", date_labels = "%Y-%m") +
  scale_y_continuous(name = "Number of active iOS editors") +
  scale_fill_brewer("User Type", palette = "Set2") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 200, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 200, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = "Number of non-anonymous active iOS app editors, by user type",
       subtitle = "Active iOS editors are users who made at least 5 Wikipedia/Wikidata content edits through the iOS app in the given calendar month",
       caption = "New active iOS editors are users who made their first ever iOS app edit AND at least 5 wikipedia/wikidata content edits through the iOS app in the given calendar month.")
ggsave("active_editor_bynew_bar.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 11)

# without English
editor_month_no_en <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  group_by(username) %>%
  mutate(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE) ) %>%
  mutate(month = floor_date(date, "month")) %>%
  filter(language != "English") %>%
  group_by(month, username) %>%
  summarize(edit_counts = n(),
            content_edits = sum(namespace == 0),
            first_ios_edit_date = min(first_ios_edit_date, na.rm = TRUE))
            # user_registration = min(user_registration, na.rm = TRUE)
active_editors_no_en <- editor_month_no_en %>%
  filter(content_edits >= 5) %>%
  group_by(month) %>%
  summarize(all_active_editors = n()) %>%
  inner_join({
    editor_month_no_en %>%
      filter(content_edits >= 5, month == floor_date(first_ios_edit_date, "month")) %>%
      group_by(month) %>%
      summarize(new_active_editors = n())
  }, by = 'month') %>%
 inner_join({
   editor_month_no_en %>%
     filter(content_edits >= 5, month != floor_date(first_ios_edit_date, "month")) %>%
     group_by(month) %>%
     summarize(returning_active_editors = n())
 }, by = 'month')


# By quarter
active_editors %>%
  group_by(quarter = floor_date(month, "quarter")) %>%
  select(-month) %>%
  summarise_all(sum)
active_editors_no_en %>%
  group_by(quarter = floor_date(month, "quarter")) %>%
  select(-month) %>%
  summarise_all(sum)


# 30 days before and after
anchor <- seq(from =wikitext_release-30*7, to=wikitext_release+30, by=30)
editor_month_cohort <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  group_by(username) %>%
  mutate(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE) ) %>%
  mutate(month = findInterval(date, anchor)) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n(),
            content_edits = sum(namespace == 0),
            first_ios_edit_date = min(first_ios_edit_date, na.rm = TRUE))
            # user_registration = min(user_registration, na.rm = TRUE)
active_editors_cohort <- editor_month_cohort %>%
  filter(content_edits >= 5) %>%
  group_by(month) %>%
  summarize(all_active_editors = n()) %>%
  inner_join({
    editor_month_cohort %>%
      filter(content_edits >= 5, month == findInterval(first_ios_edit_date, anchor)) %>%
      group_by(month) %>%
      summarize(first_month_active_editors = n())
  }, by = 'month') %>%
  inner_join({
    editor_month_cohort %>%
      filter(content_edits >= 5, month == findInterval(first_ios_edit_date, anchor)+1) %>%
      group_by(month) %>%
      summarize(second_month_active_editors = n())
  }, by = 'month') %>%
 inner_join({
   editor_month_cohort %>%
     filter(content_edits >= 5, month != findInterval(first_ios_edit_date, anchor)+1, month != findInterval(first_ios_edit_date, anchor)) %>%
     group_by(month) %>%
     summarize(existing_active_editors = n())
 }, by = 'month')

# without English
editor_month_cohort_no_en <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  group_by(username) %>%
  mutate(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE) ) %>%
  mutate(month = findInterval(date, anchor)) %>%
  filter(language != "English") %>%
  group_by(month, username) %>%
  summarize(edit_counts = n(),
            content_edits = sum(namespace == 0),
            first_ios_edit_date = min(first_ios_edit_date, na.rm = TRUE))
            # user_registration = min(user_registration, na.rm = TRUE)
active_editors_cohort_no_en <- editor_month_cohort_no_en %>%
  filter(content_edits >= 5) %>%
  group_by(month) %>%
  summarize(all_active_editors = n()) %>%
  inner_join({
    editor_month_cohort_no_en %>%
      filter(content_edits >= 5, month == findInterval(first_ios_edit_date, anchor)) %>%
      group_by(month) %>%
      summarize(first_month_active_editors = n())
  }, by = 'month') %>%
  inner_join({
    editor_month_cohort_no_en %>%
      filter(content_edits >= 5, month == findInterval(first_ios_edit_date, anchor)+1) %>%
      group_by(month) %>%
      summarize(second_month_active_editors = n())
  }, by = 'month') %>%
 inner_join({
   editor_month_cohort_no_en %>%
     filter(content_edits >= 5, month != findInterval(first_ios_edit_date, anchor)+1, month != findInterval(first_ios_edit_date, anchor)) %>%
     group_by(month) %>%
     summarize(existing_active_editors = n())
 }, by = 'month')
