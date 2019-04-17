#!/home/chelsyx/python_virtualenv/edit_revert/bin/python

import mwdb
import mwapi
import mwreverts.db
import mwreverts.api
import multiprocessing
from multiprocessing.dummy import Pool as ThreadPool
import dns.resolver
import glob

def get_mediawiki_section_dbname_mapping(mw_config_path, use_x1):
    db_mapping = {}
    if use_x1:
        dblist_section_paths = [mw_config_path.rstrip('/') + '/dblists/all.dblist']
    else:
        dblist_section_paths = glob.glob(mw_config_path.rstrip('/') + '/dblists/s[0-9]*.dblist')
    for dblist_section_path in dblist_section_paths:
        with open(dblist_section_path, 'r') as f:
            for db in f.readlines():
                db_mapping[db.strip()] = dblist_section_path.strip().rstrip('.dblist').split('/')[-1]

    return db_mapping


def get_dbstore_host_port(db_mapping, use_x1, dbname):
    if dbname == 'staging':
        shard = 'staging'
    elif use_x1:
        shard = 'x1'
    else:
        try:
            shard = db_mapping[dbname]
        except KeyError:
            raise RuntimeError("The database {} is not listed among the dblist files of the supported sections."
                               .format(dbname))
    answers = dns.resolver.query('_' + shard + '-analytics._tcp.eqiad.wmnet', 'SRV')
    host, port = str(answers[0].target), answers[0].port
    return (host,port)


# Functions for checking revert info


def check_reverted_db(wiki, rev_id, page_id, is_deleted, timeout):
    # Checks the revert status of a regular revision
    def check_regular(schema, rev_id, page_id):
        _, reverted, _ = mwreverts.db.check(
            schema, rev_id=rev_id, #page_id=page_id,
            radius=5, window=48 * 60 * 60)
        return (reverted is not None)

    # Checks the revert status of an archived revision
    def check_archive(schema, rev_id):
        _, reverted, _ = mwreverts.db.check_archive(
            schema, rev_id=rev_id, radius=5, window=48 * 60 * 60)
        return (reverted is not None)

    try:
        db_mapping = get_mediawiki_section_dbname_mapping('/srv/mediawiki-config', use_x1=False)
        ans = get_dbstore_host_port(db_mapping, use_x1=False, dbname=wiki)
        host = ans[0][:-1]
        port = ans[1]
        schema = mwdb.Schema(
            'mysql+pymysql://' + host + ':' + str(port) + '/' + wiki +
            '?read_default_file=/etc/mysql/conf.d/research-client.cnf')
        p = ThreadPool(1)
        if is_deleted:
            res = p.apply_async(
                check_archive,
                kwds={
                    'schema': schema,
                    'rev_id': rev_id})
        else:
            res = p.apply_async(
                check_regular,
                kwds={
                    'schema': schema,
                    'rev_id': rev_id,
                    'page_id': page_id})
        # Wait timeout seconds for check_archive or check_regular to complete.
        out = res.get(timeout)
        p.close()
        p.join()
        return out
    except multiprocessing.TimeoutError:
        print(
            "mwreverts.db.check timeout: failed to retrieve revert info for revision " +
            str(rev_id))
        p.terminate()  # kill mwreverts.db.check if it runs more than timeout seconds
        p.join()
        return None


def check_reverted_api(api_session, rev_id, page_id):
    _, reverted, _ = mwreverts.api.check(
        api_session, rev_id=rev_id, #page_id=page_id,
        radius=5, window=48 * 60 * 60)
    return (reverted is not None)


def check_reverted(wiki, api_session, rev_id, page_id, timeout):
    # Use mwreverts.api.check first. If not work, use check_reverted_db
    try:
        out = check_reverted_api(api_session, rev_id, page_id)
        return out
    except mwapi.errors.APIError:
        print(
            "API error: revision " +
            str(rev_id) +
            '. Use mwreverts.db.check instead.')
        return check_reverted_db(wiki, rev_id, page_id, is_deleted=False, timeout=timeout)
    except KeyError as e:
        print(e)
        return check_reverted_db(wiki, rev_id, page_id, is_deleted=True, timeout=timeout)


def iter_check_reverted(df, wiki, api_session, timeout):
    for row in df.itertuples():
        try:
            if row.is_deleted:
                df.at[row.Index, 'is_reverted'] = check_reverted_db(
                    wiki, row.rev_id, row.page_id, is_deleted=True, timeout=timeout)
            else:
                df.at[row.Index, 'is_reverted'] = check_reverted(
                    wiki, api_session, row.rev_id, row.page_id, timeout)
        except RuntimeError:
            print('Failed to get revert info for revision ' + str(row.rev_id))
            continue
    return df
