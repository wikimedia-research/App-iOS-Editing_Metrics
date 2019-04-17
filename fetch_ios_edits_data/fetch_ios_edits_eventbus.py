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
    start_date='2018-08-23',
    end_date=datetime.datetime.today().strftime('%Y-%m-%d'))
query = """
SELECT SUBSTR(rev_timestamp, 0, 10) AS date,
`database` AS wiki,
wikis.database_group AS wiki_group,
wikis.language_name AS language,
IF(`database` = 'wikidatawiki', REGEXP_EXTRACT(comment, '\\\\|(.*) \\\\*\\\\/', 1), NULL) AS language_code,
performer.user_id AS local_user_id,
performer.user_text AS username,
performer.user_registration_dt AS local_user_registration,
ios_first_edit_ts.first_app_edit_ts,
rev_id,
page_namespace AS namespace,
page_id,
FALSE AS is_deleted,
IF(`database` = 'wikidatawiki', 
CASE WHEN INSTR(comment, 'wbsetdescription-add') > 0 THEN 'add'
     WHEN INSTR(comment, 'wbsetdescription-set') > 0 THEN 'change'
     ELSE 'remove' END,
    NULL) AS wikidata_edit_type
FROM event.mediawiki_revision_tags_change t
LEFT JOIN chelsyx.ios_first_edit_ts ON ios_first_edit_ts.username = t.performer.user_text
LEFT JOIN canonical_data.wikis ON (
wikis.database_group = 'wikipedia' 
AND t.`database` = wikis.database_code
)
WHERE datacenter = 'eqiad'
AND array_contains(tags, "ios app edit")
AND rev_timestamp >= '{start_date}'
AND rev_timestamp < '{end_date}'
"""
query = query.format(**query_vars)
print('Querying all ios edits...')
query_results = hive.run(query)

# Update existing data file, or generate a new one
try:
    all_edits = pd.read_csv('/home/chelsyx/fetch_ios_edits_data/data/all_ios_edits_eventbus.tsv',sep='\t')
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
        tempdf = pd.merge(tempdf, active_wikis[['language_code','language_name']], on='language_code', how='left')
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
    'data/all_ios_edits_eventbus.tsv',
    sep='\t',
    index=False)
