#!/home/chelsyx/python_virtualenv/edit_revert/bin/python

import json
import requests
import pandas as pd

# Get a list of active wikipedias


response = requests.get(
    'https://www.mediawiki.org/w/api.php?action=sitematrix&format=json&smtype=language&formatversion=2')
site_matrix = json.loads(response.text)['sitematrix']
if 'count' in site_matrix:
    del site_matrix['count']

active_wikis = pd.DataFrame([])
for index in site_matrix.keys():
    df = pd.DataFrame(
        columns=[
            'code',
            'sitename',
            'url',
            'dbname',
            'closed'],
        data=site_matrix[index]['site'])
    df['language_code'] = site_matrix[index]['code']
    df['language_name'] = site_matrix[index]['localname']
    active_wikis = active_wikis.append(df, ignore_index=True)


active_wikis = active_wikis[(active_wikis.code == 'wiki') & (active_wikis.closed.isnull())]  # only keep active wikipedia
del active_wikis['code']
del active_wikis['closed']
