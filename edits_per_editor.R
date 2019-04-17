source("preprocessing.R")


edits_per_editor <-  all_ios_edits %>%
  filter(local_user_id != 0) %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n(),
            content_edits = sum(namespace == 0))
quantile(edits_per_editor$edit_counts, probs = 0.90)

# By project
anchor <- seq(from =wikitext_release-30*7, to=wikitext_release+30, by=30)
edits_per_editor_by_project <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  mutate(month = findInterval(date, anchor),
         project = ifelse(wiki_group=="wikidata", "Wikidata description", "Wikipedia")) %>%
  group_by(month, project, username) %>%
  summarize(edits = n())

p <- edits_per_editor_by_project %>%
  filter(month == 8) %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edits < 6 ~ paste(edits, "edits"),
      edits >= 6 & edits < 11 ~ "6 - 10 edits",
      edits >= 11 & edits < 16 ~ "11 - 15 edits",
      edits >= 16 & edits < 21 ~ "16 - 20 edits",
      edits >= 21 & edits < 31 ~ "21 - 30 edits",
      edits >= 31 & edits < 51 ~ "31 - 50 edits",
      edits >= 51 & edits < 101 ~ "51 - 100 edits",
      edits >= 101 ~ "101+ edits"
    ),
    levels = c(paste(1:5, "edits"), "6 - 10 edits", "11 - 15 edits", "16 - 20 edits", "21 - 30 edits",
               "31 - 50 edits", "51 - 100 edits", "101+ edits"))
  ) %>%
  dplyr::group_by(project, edits) %>%
  dplyr::summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot2::ggplot(aes(x = edits, y = prop, fill = project)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge") +
  ggplot2::scale_fill_brewer("Project", palette = "Paired") +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  ggplot2::geom_text(aes(label = scales::percent(prop), vjust = -0.1), position = position_dodge(width = 1), size = 3) +
  ggplot2::labs(x = 'Number of edits in 30 days',
                title = 'Distribution of edits per editor on the iOS app from Feb 21 to Mar 22, by project',
                subtitle = "Non-anonymous editors only.") +
  wmf::theme_min()
ggsave("edits_per_editor_distr_30after.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 11)

p <- edits_per_editor_by_project %>%
  filter(month == 7) %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edits < 6 ~ paste(edits, "edits"),
      edits >= 6 & edits < 11 ~ "6 - 10 edits",
      edits >= 11 & edits < 16 ~ "11 - 15 edits",
      edits >= 16 & edits < 21 ~ "16 - 20 edits",
      edits >= 21 & edits < 31 ~ "21 - 30 edits",
      edits >= 31 & edits < 51 ~ "31 - 50 edits",
      edits >= 51 & edits < 101 ~ "51 - 100 edits",
      edits >= 101 ~ "101+ edits"
    ),
    levels = c(paste(1:5, "edits"), "6 - 10 edits", "11 - 15 edits", "16 - 20 edits", "21 - 30 edits",
               "31 - 50 edits", "51 - 100 edits", "101+ edits"))
  ) %>%
  dplyr::group_by(project, edits) %>%
  dplyr::summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot2::ggplot(aes(x = edits, y = prop, fill = project)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge") +
  ggplot2::scale_fill_brewer("Project", palette = "Paired") +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  ggplot2::geom_text(aes(label = scales::percent(prop), vjust = -0.1), position = position_dodge(width = 1), size = 3) +
  ggplot2::labs(x = 'Number of edits in 30 days',
                title = 'Distribution of edits per editor on the iOS app from Jan 22 to Feb 20, by project',
                subtitle = "Non-anonymous editors only.") +
  wmf::theme_min()
ggsave("edits_per_editor_distr_30before.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 11)

# Trend across projects
p <- edits_per_editor %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edit_counts == 1 ~ "1 edit",
      edit_counts >= 2 & edit_counts < 5 ~ "2 - 4 edits",
      edit_counts >= 5 & edit_counts < 11 ~ "5 - 10 edits",
      edit_counts >= 11 ~ "11+ edits"
    ),
    levels = c( "1 edit", "2 - 4 edits", "5 - 10 edits", "11+ edits" ))
  ) %>%
  group_by(month, edits) %>%
  summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot(aes(x=month, y=prop, group = edits, color = edits)) +
  geom_line(size = 1.2) +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  scale_x_date("Month") +
  scale_color_brewer("Edits per Editor per month", palette = "Dark2") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.2, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.2, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Proportion of editors, by their edits in a month',
       subtitle = 'Non-anonymous editors only. ')
ggsave("prop_editor_by_edits_login.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)
p <- all_ios_edits %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n()) %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edit_counts == 1 ~ "1 edit",
      edit_counts >= 2 & edit_counts < 5 ~ "2 - 4 edits",
      edit_counts >= 5 & edit_counts < 11 ~ "5 - 10 edits",
      edit_counts >= 11 ~ "11+ edits"
    ),
    levels = c( "1 edit", "2 - 4 edits", "5 - 10 edits", "11+ edits" ))
  ) %>%
  group_by(month, edits) %>%
  summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot(aes(x=month, y=prop, group = edits, color = edits)) +
  geom_line(size = 1.2) +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  scale_x_date("Month") +
  scale_color_brewer("Edits per Editor per month", palette = "Dark2") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.2, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.2, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Proportion of editors, by their edits in a month',
       subtitle = 'Including both anonymous and non-anonymous editors.')
ggsave("prop_editor_by_edits_all.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)


# Trend by project

p <- all_ios_edits %>%
  filter(wiki_group=="wikidata") %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n()) %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edit_counts == 1 ~ "1 edit",
      edit_counts >= 2 & edit_counts < 5 ~ "2 - 4 edits",
      edit_counts >= 5 & edit_counts < 11 ~ "5 - 10 edits",
      edit_counts >= 11 ~ "11+ edits"
    ),
    levels = c( "1 edit", "2 - 4 edits", "5 - 10 edits", "11+ edits" ))
  ) %>%
  group_by(month, edits) %>%
  summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot(aes(x=month, y=prop, group = edits, color = edits)) +
  geom_line(size = 1.2) +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  scale_x_date("Month") +
  scale_color_brewer("Edits per Editor per month", palette = "Dark2") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.2, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.2, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Proportion of Wikidata short description editors, by their Wikidata edits in a month',
       subtitle = 'Including both anonymous and non-anonymous editors.')
ggsave("prop_editor_by_edits_wikidata.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)
p <- all_ios_edits %>%
  filter(wiki_group=="wikipedia") %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month, username) %>%
  summarize(edit_counts = n()) %>%
  dplyr::mutate(
    edits = factor(dplyr::case_when(
      edit_counts == 1 ~ "1 edit",
      edit_counts >= 2 & edit_counts < 5 ~ "2 - 4 edits",
      edit_counts >= 5 & edit_counts < 11 ~ "5 - 10 edits",
      edit_counts >= 11 ~ "11+ edits"
    ),
    levels = c( "1 edit", "2 - 4 edits", "5 - 10 edits", "11+ edits" ))
  ) %>%
  group_by(month, edits) %>%
  summarize(n_editor = n()) %>%
  dplyr::mutate(prop = n_editor/sum(n_editor)) %>%
  ggplot(aes(x=month, y=prop, group = edits, color = edits)) +
  geom_line(size = 1.2) +
  ggplot2::scale_y_continuous("Proportion of editors", labels = scales::percent_format()) +
  scale_x_date("Month") +
  scale_color_brewer("Edits per Editor per month", palette = "Dark2") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.2, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.2, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'Proportion of Wikipedia editors, by their Wikipedia edits in a month',
       subtitle = 'Including both anonymous and non-anonymous editors.')
ggsave("prop_editor_by_edits_wikipedia.png", p, path = 'figures', units = "in", dpi = 300, height = 6, width = 10)
