# Edit funnel
query <- "
select
substr(dt, 0, 10) as `date`,
case when event.wikidataDescriptionEdit is null then 'wikipedia'
else 'wikidata' end as edit_type,
event.action,
count(distinct event.session_token) as n_sessions,
count(distinct event.app_install_id) as n_users
from mobilewikiappedit
where year=2019 and (
(month=2 and day> 20) or
month > 2
)
and useragent.os_family = 'iOS'
and useragent.wmf_app_version >= '6.2'
and not useragent.is_bot
group by substr(dt, 0, 10),
case when event.wikidataDescriptionEdit is null then 'wikipedia'
else 'wikidata' end,
event.action
"

edit_funnel_raw <- readr::read_csv("data/edit_funnel.csv")
edit_funnel_raw %<>%
  mutate(date = lubridate::ymd(date))
anchor <- seq(min(edit_funnel_raw$date), max(edit_funnel_raw$date), by=7)
edit_funnel <- edit_funnel_raw %>%
  mutate(week = findInterval(date, anchor)) %>%
  group_by(week, edit_type, action) %>%
  summarize(n_sessions = sum(n_sessions)) %>%
  spread(action, n_sessions)

wikipedia_conversion_rate <- edit_funnel %>%
  ungroup %>%
  filter(edit_type == "wikipedia") %>%
  select(start, preview, saveAttempt, saved) %>%
  summarize_all(sum) %>%
  mutate(start_to_save = saved/start,
         start_to_preview = preview/start,
         preview_to_saveAttempt = saveAttempt/preview,
         saveAttempt_to_saved = saved/saveAttempt
         )
wikidata_conversion_rate <- edit_funnel %>%
  ungroup %>%
  filter(edit_type == "wikidata") %>%
  select(start, ready, saveAttempt, saved) %>%
  summarize_all(sum) %>%
  mutate(start_to_save = saved/start,
         start_to_ready = ready/start,
         ready_to_saveAttempt = saveAttempt/ready,
         saveAttempt_to_saved = saved/saveAttempt
         )

# Unique users
query <- "
select count(*) as n_users,
count(distinct wp_editor.app_install_id) as n_wp_editor,
count(distinct wd_editor.app_install_id) as n_wd_editor
from
(select
distinct event.app_install_id
from mobilewikiappiossessions
where year=2019 and (
(month=2 and day> 20) or
month > 2
)
and useragent.os_family = 'iOS'
and useragent.wmf_app_version >= '6.2'
and not useragent.is_bot) all_users left join

(select distinct event.app_install_id
from mobilewikiappedit
where year=2019 and (
(month=2 and day> 20) or
month > 2
)
and useragent.os_family = 'iOS'
and useragent.wmf_app_version >= '6.2'
and not useragent.is_bot
and event.wikidataDescriptionEdit is null
) wp_editor on all_users.app_install_id=wp_editor.app_install_id

left join
(select distinct event.app_install_id
from mobilewikiappedit
where year=2019 and (
(month=2 and day> 20) or
month > 2
)
and useragent.os_family = 'iOS'
and useragent.wmf_app_version >= '6.2'
and not useragent.is_bot
and event.wikidataDescriptionEdit is not null
) wd_editor on all_users.app_install_id=wd_editor.app_install_id
"
