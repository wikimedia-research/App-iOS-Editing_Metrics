# iOS Editing Metrics FY18-19

This repo contains all the scripts we used to generate [reports](https://www.mediawiki.org/wiki/Wikimedia_Product/New_Content_Program_Metrics_Reports#iOS) about [iOS Editing Metrics in FY18-19](https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/iOS/Editing_program#Goals).

### Workflow

Use scripts in the `fetch_ios_edits_data` folder to generate data files (`all_ios_edits.tsv`. See `fetch_ios_edits_data/README.md` for more details.), then use `edit_counts.R`, `editor_counts.R`, `revert_rate.R`, `retention.R`, `edits_per_editor.R` to create corresponding metrics and graphs.

#### Editing Funnel Conversion Rate

`conversion_rate.R` queries the tables [MobileWikiAppEdit](https://meta.wikimedia.org/wiki/Schema:MobileWikiAppEdit) and [MobileWikiAppiOSSessions](https://meta.wikimedia.org/wiki/Schema:MobileWikiAppiOSSessions), then compute the conversion rates of editing funnels on the iOS app.
