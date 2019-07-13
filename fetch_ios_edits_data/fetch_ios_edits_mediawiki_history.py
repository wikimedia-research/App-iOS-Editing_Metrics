# On stat1007
# pyspark2 --master yarn --executor-memory 8G --executor-cores 2 --driver-memory 8G

import datetime

query_vars = dict(
	snapshot='2019-06',
    start_date='2018-07-01',
    end_date=datetime.datetime.today().strftime('%Y-%m-%d'))
query = """
SELECT SUBSTR(event_timestamp, 0, 10) AS date,
wiki_db AS wiki,
COALESCE(w1.database_group, 'wikidata') AS wiki_group,
COALESCE(w1.language_name, w2.language_name) AS language,
event_user_id AS local_user_id,
event_user_text AS username,
event_user_registration_timestamp AS local_user_registration,
ios_first_edit_ts.first_app_edit_ts,
revision_id AS rev_id,
page_namespace AS namespace,
page_id,
revision_is_deleted_by_page_deletion AS is_deleted,
IF(wiki_db = 'wikidatawiki', 
CASE WHEN INSTR(event_comment, 'wbsetdescription-add') > 0 THEN 'add'
     WHEN INSTR(event_comment, 'wbsetdescription-set') > 0 THEN 'change'
     ELSE 'remove' END,
    NULL) AS wikidata_edit_type,
revision_is_identity_reverted AS is_reverted
FROM wmf.mediawiki_history mh
LEFT JOIN chelsyx.ios_first_edit_ts ON ios_first_edit_ts.username = mh.event_user_text
LEFT JOIN canonical_data.wikis w1 ON (
w1.database_group = 'wikipedia' 
AND mh.wiki_db = w1.database_code
)
LEFT JOIN (
    SELECT DISTINCT language_code, language_name
    FROM canonical_data.wikis
) AS w2 ON (
mh.wiki_db = 'wikidatawiki'
AND REGEXP_EXTRACT(mh.event_comment, '\\\\|(.*) \\\\*\\\\/', 1) = w2.language_code
)
WHERE snapshot = '{snapshot}'
AND array_contains(revision_tags, "ios app edit")
AND event_timestamp >= '{start_date}'
AND event_timestamp < '{end_date}'
AND event_entity = 'revision'
AND event_type = 'create'
"""
query = query.format(**query_vars)
result = spark.sql(query)
output = result.toPandas()

output.to_csv(
    'data/all_ios_edits_mediawiki_history.tsv',
    sep='\t',
    index=False)
