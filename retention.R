source("preprocessing.R")

check_retention <- function(birth_date, edit_dates, t1 = 1, t2 = 30, t3 = 30) {
  # t1 represents activation period,
  # t2 represents trial period,
  # t3 represents survival period.
  # See https://meta.wikimedia.org/wiki/Research:Surviving_new_editor
  edit_dates <- sort(edit_dates)
  # Check if user made an edit in the activation period.
  # If a user didn't have any edits in activation period, they are not considered as new editor
  first_milestone <- birth_date + t1
  if (!any(edit_dates >= birth_date & edit_dates < first_milestone)) return(NA)
  # Check if user made another edit in the survival period:
  second_milestone <- birth_date + t2
  third_milestone <- birth_date + t2 + t3
  is_survived <- any(edit_dates >= second_milestone & edit_dates < third_milestone)
  # if we haven't reach survival period
  # or survival period hasn't end and user hasn't make an edit
  # this users should not be counted
  if( (Sys.Date() < second_milestone) |
      (Sys.Date() >= second_milestone & Sys.Date() < third_milestone & !is_survived) ) {
    return(NA)
  } else {
    return(is_survived)
  }
}


# New editors retention


user_retention <- all_ios_edits %>%
  filter(local_user_id != 0) %>%
  group_by(username) %>%
  summarize(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE),
            retained_15 = check_retention(first_ios_edit_date, date, 1, 16, 15), # 16th-30th day following first_edit_date
            retained_30 = check_retention(first_ios_edit_date, date, 1, 31, 30) # 31st-60th day following first_edit_date
            ) %>%
  filter(first_ios_edit_date >= as.Date("2018-07-01"))
monthly_retention_rate <- user_retention %>%
  mutate(survival_end_month = floor_date(first_ios_edit_date + 60, "month")) %>%
  group_by(survival_end_month) %>%
  summarize(`Second 30 days Retention` = mean(retained_30, na.rm = TRUE)) %>%
  filter(survival_end_month >= as.Date("2018-09-01"), survival_end_month < as.Date("2019-04-01")) %>%
  right_join({
    user_retention %>%
      mutate(survival_end_month = floor_date(first_ios_edit_date + 30, "month")) %>%
      group_by(survival_end_month) %>%
      summarize(`Second 15 days Retention` = mean(retained_15, na.rm = TRUE)) %>%
      filter(survival_end_month >= as.Date("2018-08-01"), survival_end_month < as.Date("2019-04-01"))
  }, by = "survival_end_month")

p <- monthly_retention_rate %>%
  gather(key = retention_type, value = retention_rate, -survival_end_month) %>%
  ggplot(aes(x=survival_end_month, y=retention_rate, group = retention_type, color = retention_type)) +
  geom_line(size = 1.2) +
  scale_y_continuous("Retention Rate", labels = scales::percent_format()) +
  scale_x_date("Month") +
  scale_color_brewer("Type of Retention Rate", palette = "Set1") +
  geom_vline(xintercept = as.numeric(wikidata_release),
             linetype = "dashed", color = "black") +
  geom_vline(xintercept = as.numeric(wikitext_release),
             linetype = "dashed", color = "black") +
  annotate("text", x = wikidata_release-3, y = 0.1, label = "Wikidata description edit released", angle = 90) +
  annotate("text", x = wikitext_release-3, y = 0.1, label = "Wikitext editing tools released", angle = 90) +
  wmf::theme_min() +
  labs(title = 'New iOS app editor retention',
       subtitle = "Non-anonymous editors only.",
       caption = 'Second 15 days retention: Out of the non-anonymous users who have their 30 day iOS-app-edit birthday in the given calendar month, the percentage of them edited on the app during their second 15 days.
       Second 30 days retention: Out of the non-anonymous users who have their 60 day iOS-app-edit birthday in the given calendar month, the percentage of them edited on the app during their second 30 days.')
ggsave("new_editor_retention.png", p, path = 'figures', units = "in", dpi = 300, height = 7, width = 13)


# without English
user_retention_no_en <- all_ios_edits %>%
  filter(local_user_id != 0, language != "English") %>%
  group_by(username) %>%
  summarize(first_ios_edit_date = min(date(min(first_app_edit_ts, na.rm = TRUE)), min(date, na.rm = TRUE), na.rm = TRUE),
            retained_15 = check_retention(first_ios_edit_date, date, 1, 16, 15), # 16th-30th day following first_edit_date
            retained_30 = check_retention(first_ios_edit_date, date, 1, 31, 30) # 31st-60th day following first_edit_date
            ) %>%
  filter(first_ios_edit_date >= as.Date("2018-07-01"))

user_retention_no_en %>%
  mutate(birthday_60_month = floor_date(first_ios_edit_date + 60, "month")) %>%
  group_by(birthday_60_month) %>%
  summarize(retention_30 = mean(retained_30, na.rm = TRUE))
user_retention_no_en %>%
  mutate(birthday_30_month = floor_date(first_ios_edit_date + 30, "month")) %>%
  group_by(birthday_30_month) %>%
  summarize(retention_15 = mean(retained_15, na.rm = TRUE))


# By quarter

user_retention %>%
  mutate(survival_end_quarter = floor_date(first_ios_edit_date + 60, "quarter")) %>%
  group_by(survival_end_quarter) %>%
  summarize(`Second 30 days Retention` = mean(retained_30, na.rm = TRUE)) %>%
  filter(survival_end_quarter >= as.Date("2018-09-01"), survival_end_quarter < as.Date("2019-04-01")) %>%
  right_join({
    user_retention %>%
      mutate(survival_end_quarter = floor_date(first_ios_edit_date + 30, "quarter")) %>%
      group_by(survival_end_quarter) %>%
      summarize(`Second 15 days Retention` = mean(retained_15, na.rm = TRUE)) %>%
      filter(survival_end_quarter >= as.Date("2018-08-01"), survival_end_quarter < as.Date("2019-04-01"))
  }, by = "survival_end_quarter")
user_retention_no_en %>%
  mutate(survival_end_quarter = floor_date(first_ios_edit_date + 60, "quarter")) %>%
  group_by(survival_end_quarter) %>%
  summarize(`Second 30 days Retention` = mean(retained_30, na.rm = TRUE)) %>%
  filter(survival_end_quarter >= as.Date("2018-09-01"), survival_end_quarter < as.Date("2019-04-01")) %>%
  right_join({
    user_retention_no_en %>%
      mutate(survival_end_quarter = floor_date(first_ios_edit_date + 30, "quarter")) %>%
      group_by(survival_end_quarter) %>%
      summarize(`Second 15 days Retention` = mean(retained_15, na.rm = TRUE)) %>%
      filter(survival_end_quarter >= as.Date("2018-08-01"), survival_end_quarter < as.Date("2019-04-01"))
  }, by = "survival_end_quarter")


# By cohort

anchor <- seq(from =wikitext_release-30*7, to=wikitext_release+30, by=30)
user_retention %>%
  mutate(survival_end_month = findInterval(first_ios_edit_date + 60, anchor)) %>%
  group_by(survival_end_month) %>%
  summarize(`Second 30 days Retention` = mean(retained_30, na.rm = TRUE)) %>%
  right_join({
    user_retention %>%
      mutate(survival_end_month = findInterval(first_ios_edit_date + 30, anchor)) %>%
      group_by(survival_end_month) %>%
      summarize(`Second 15 days Retention` = mean(retained_15, na.rm = TRUE))
  }, by = "survival_end_month")
user_retention_no_en %>%
  mutate(survival_end_month = findInterval(first_ios_edit_date + 60, anchor)) %>%
  group_by(survival_end_month) %>%
  summarize(`Second 30 days Retention` = mean(retained_30, na.rm = TRUE)) %>%
  right_join({
    user_retention_no_en %>%
      mutate(survival_end_month = findInterval(first_ios_edit_date + 30, anchor)) %>%
      group_by(survival_end_month) %>%
      summarize(`Second 15 days Retention` = mean(retained_15, na.rm = TRUE))
  }, by = "survival_end_month")
