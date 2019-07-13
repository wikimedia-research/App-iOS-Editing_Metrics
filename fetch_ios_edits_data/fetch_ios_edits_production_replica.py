#!/home/chelsyx/venv/bin/python3

import sys
import datetime
import time
import mwapi
import pandas as pd
import multiprocessing
from functools import partial
import functions
from proj_utils import active_wikis
from wmfdata import hive # pip install git+https://github.com/neilpquinn/wmfdata.git


# Query all the revisions and fetch revert information

query_vars = dict(
    start_date='20180701',
    start_date_1='2018-07-01',
    end_date='20190401',
    end_date_1='2019-04-01',
    snapshot = '2019-03'
    )
query = """
SELECT
`date`,
ios_app_edits.wiki AS wiki,
wikis.database_group AS wiki_group,
COALESCE(wikis.language_name, wikidata_edits.language_code) AS language,
ios_app_edits.local_user_id AS local_user_id,
ios_app_edits.username,
u.user_registration AS user_registration,
ios_first_edit_ts.first_app_edit_ts,
ios_app_edits.device,
ios_app_edits.rev_id,
ios_app_edits.namespace,
ios_app_edits.page_id,
ios_app_edits.is_deleted,
wikidata_edits.wikidata_edit_type
FROM (
-- Edits made with iOS app on visible pages:
SELECT
SUBSTR(r.rev_timestamp, 0, 8) AS `date`,
r.wiki_db AS wiki,
r.rev_user AS local_user_id,
COALESCE(IF(r.rev_user = 0, MD5(CONCAT(c.cuc_ip, c.cuc_agent)), r.rev_user_text), r.rev_user_text) AS username,
-- rev_user and rev_user_text are deprecated and replaced by revision_actor_temp table since May 30th, but revision_actor_temp is not in data lake at the moment
CASE WHEN INSTR(c.cuc_agent, 'Tablet') > 0 THEN 'iPad'
     WHEN INSTR(c.cuc_agent, 'Phone') > 0 THEN 'iPhone'
     ELSE NULL END AS device,
r.rev_id,
p.page_namespace AS namespace,
r.rev_page AS page_id,
FALSE AS is_deleted
FROM wmf_raw.mediawiki_change_tag t
INNER JOIN wmf_raw.mediawiki_change_tag_def d ON (
t.snapshot = '{snapshot}'
AND d.snapshot = '{snapshot}'
AND t.wiki_db = d.wiki_db
AND t.ct_tag_id = d.ctd_id
AND d.ctd_name = 'ios app edit'
)
INNER JOIN wmf_raw.mediawiki_revision r ON (
t.snapshot = '{snapshot}'
AND r.snapshot = '{snapshot}'
AND t.wiki_db = r.wiki_db
AND r.rev_id = t.ct_rev_id
AND r.rev_timestamp >= '{start_date}'
AND r.rev_timestamp < '{end_date}'
)
LEFT JOIN wmf_raw.mediawiki_page p ON (
p.snapshot = '{snapshot}'
AND r.snapshot = '{snapshot}'
AND p.wiki_db = r.wiki_db
AND r.rev_page = p.page_id
)
LEFT JOIN wmf_raw.mediawiki_private_cu_changes c ON (
c.month <= '{snapshot}'
AND r.snapshot = '{snapshot}'
AND c.wiki_db = r.wiki_db
-- AND r.rev_page = c.cuc_page_id 
AND r.rev_id = c.cuc_this_oldid
)

UNION ALL

-- Edits made with iOS app on deleted pages:
SELECT
SUBSTR(a.ar_timestamp, 0, 8) AS `date`,
a.wiki_db AS wiki,
a.ar_user AS local_user_id,
COALESCE(IF(a.ar_user = 0, MD5(CONCAT(c.cuc_ip, c.cuc_agent)), a.ar_user_text), a.ar_user_text) AS username,
CASE WHEN INSTR(c.cuc_agent, 'Tablet') > 0 THEN 'iPad'
     WHEN INSTR(c.cuc_agent, 'Phone') > 0 THEN 'iPhone'
     ELSE NULL END AS device,
a.ar_rev_id AS rev_id,
a.ar_namespace AS namespace,
a.ar_page_id AS page_id,
TRUE AS is_deleted
FROM wmf_raw.mediawiki_change_tag t
INNER JOIN wmf_raw.mediawiki_change_tag_def  d ON (
t.snapshot = '{snapshot}'
AND d.snapshot = '{snapshot}'
AND t.wiki_db = d.wiki_db
AND t.ct_tag_id = d.ctd_id
AND d.ctd_name = 'ios app edit'
)
INNER JOIN wmf_raw.mediawiki_archive a ON (
t.snapshot = '{snapshot}'
AND a.snapshot = '{snapshot}'
AND t.wiki_db = a.wiki_db
AND a.ar_rev_id = t.ct_rev_id
AND a.ar_timestamp >= '{start_date}'
AND a.ar_timestamp < '{end_date}'
)
LEFT JOIN wmf_raw.mediawiki_private_cu_changes c ON (
c.month <= '{snapshot}'
AND a.snapshot = '{snapshot}'
AND c.wiki_db = a.wiki_db
-- AND a.ar_page_id = c.cuc_page_id 
AND a.ar_rev_id = c.cuc_this_oldid
)
) AS ios_app_edits

LEFT JOIN (
-- wikidata edit language and type
SELECT `database` as wiki, rev_id, page_id,
REGEXP_EXTRACT(comment, '\\\\|(.*) \\\\*\\\\/', 1) AS language_code,
CASE WHEN INSTR(comment, 'wbsetdescription-add') > 0 THEN 'add'
     WHEN INSTR(comment, 'wbsetdescription-set') > 0 THEN 'change'
     ELSE 'remove' END AS wikidata_edit_type
FROM event.mediawiki_revision_tags_change
WHERE datacenter = 'eqiad'
AND `database` = 'wikidatawiki'
AND rev_timestamp >= '{start_date_1}'
AND rev_timestamp < '{end_date_1}'
AND array_contains(tags, "ios app edit") 
AND INSTR(comment, 'wbsetdescription') > 0
) AS wikidata_edits ON (
ios_app_edits.wiki = wikidata_edits.wiki
AND ios_app_edits.rev_id = wikidata_edits.rev_id
-- AND ios_app_edits.page_id = wikidata_edits.page_id
)

LEFT JOIN (
-- global registration date
SELECT user_name, MIN(user_registration) AS user_registration
FROM wmf_raw.mediawiki_user 
WHERE snapshot = '{snapshot}'
GROUP BY user_name
) AS u ON ios_app_edits.username = u.user_name

LEFT JOIN chelsyx.ios_first_edit_ts ON ios_first_edit_ts.username = ios_app_edits.username

LEFT JOIN canonical_data.wikis ON (
wikis.database_group = 'wikipedia' 
AND ios_app_edits.wiki = wikis.database_code
)
"""
query = query.format(**query_vars)
print('Querying all ios edits...')
query_results = hive.run(query)

# Update existing data file, or generate a new one
try:
    all_edits = pd.read_csv('/home/chelsyx/fetch_ios_edits_data/data/all_ios_edits_production_replica.tsv',sep='\t')
    all_edits = all_edits[all_edits.date < query_vars['start_date']]
except FileNotFoundError:
    all_edits = pd.DataFrame([])

# Loop through all distinct wiki and check revert

print('Checking revert...')
for wiki in query_results.wiki.unique():

    print(wiki + ' start!')
    init = time.perf_counter()
    tempdf = query_results[query_results.wiki == wiki].copy()
    tempdf['is_reverted'] = None
    if wiki == 'wikidatawiki':
        wiki_url = 'https://www.wikidata.org'
        tempdf = pd.merge(tempdf, active_wikis[['language_code','language_name']], left_on='language', right_on='language_code', how='left')
        tempdf = tempdf.drop(columns=['language', 'language_code'])
        tempdf = tempdf.rename(columns={"language_name": "language"})
    else:
        wiki_url = active_wikis.url[active_wikis.dbname == wiki].to_string(index=False)
    
    if wiki_url == 'Series([], )':
        continue
    else:
        api_session = mwapi.Session(wiki_url, user_agent="Revert detection <cxie@wikimedia.org>")
        timeout = 10  # kill check_reverted_db if it runs more than 10 seconds

        # fetch revert info for each revision
        num_processes = 8  # use 8 processes
        if tempdf.shape[0] >= 1000:  # if the data frame has more than 1000 rows, use multiprocessing
            chunk_size = int(tempdf.shape[0] / num_processes)
            chunks = [tempdf.iloc[i:i + chunk_size] for i in range(0, tempdf.shape[0], chunk_size)]

            pool = multiprocessing.Pool(processes=num_processes)
            result = pool.map(
                partial(
                    functions.iter_check_reverted,
                    wiki=wiki,
                    api_session=api_session,
                    timeout=timeout),
                chunks)
            for i in range(len(result)):
                tempdf.loc[result[i].index] = result[i]

            pool.close()
            pool.join()
        else:
            tempdf = functions.iter_check_reverted(tempdf, wiki, api_session, timeout=timeout)

    # append to all_edits data frame
    all_edits = all_edits.append(tempdf, ignore_index=True, sort=True)
    elapsed = time.perf_counter() - init
    print("{} completed in {:0.0f} s".format(wiki, elapsed))


all_edits = all_edits.sort_values('date')
all_edits.to_csv(
    'data/all_ios_edits_production_replica.tsv',
    sep='\t',
    index=False)
