# Fetch iOS Edits Data

This repo contains all the scripts we used to generate the `all_ios_edits.tsv` file used by the R scripts in the parent directory to create metrics and reports.

### Workflow

- Use `generate_ios_editor_first_edit_ts.sh` and `update_ios_editor_first_edit_ts.sh` to generate and update table `chelsyx.ios_first_edit_ts` in Hive. This table contains all the usernames that have ever edit on the iOS app and their first iOS edit timestamp.
- Then use `fetch_ios_edits_mediawiki_history.py` to query and output the `all_ios_edits.tsv` file. (As of July 2019, `fetch_ios_edits_production_replica.py`, `fetch_ios_edits_eventbus.py` and their utility scripts `functions.py`, `proj_utils.py` are deprecated because of the in-progress refatoring of MediaWiki tables.)
