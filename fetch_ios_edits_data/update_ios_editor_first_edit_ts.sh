#! /bin/bash
DESCRIPTION="Update iOS Editors' First Edit Timestamp"
QUERY="
SET mapred.job.queue.name=nice;
-- Set compression codec to gzip to provide asked format
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.GzipCodec;

DROP TABLE IF EXISTS chelsyx.tmp_ios_first_edit_ts;
CREATE EXTERNAL TABLE IF NOT EXISTS chelsyx.tmp_ios_first_edit_ts
(
    \`username\`                string  COMMENT 'Global username',
    \`first_app_edit_ts\`       string  COMMENT 'The timestamp of first app edit (iOS or Android)',
    \`first_ios_edit_ts\`       string  COMMENT 'The timestamp of first iOS app edit'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
LOCATION '/tmp/ios_edit'
;

WITH unique_ios_editors AS
(
    SELECT
        performer.user_text AS username,
        REGEXP_REPLACE(MIN(rev_timestamp), '[^0-9]', '') AS first_app_edit_ts,
        REGEXP_REPLACE(MIN(rev_timestamp), '[^0-9]', '') AS first_ios_edit_ts
    FROM event.mediawiki_revision_tags_change
    WHERE substr(rev_timestamp, 0, 7) >= '2019-04' -- Should specify the time span from last update date till now; Last update: Jul 3, 2019.
        AND performer.user_id != 0
        AND NOT performer.user_is_bot
        AND NOT array_contains(performer.user_groups, 'bot')
        AND array_contains(tags, 'ios app edit')
        AND year=2019 -- Change partition when needed
    GROUP BY performer.user_text        
)
INSERT OVERWRITE TABLE chelsyx.tmp_ios_first_edit_ts
SELECT 
    username, 
    MIN(first_app_edit_ts) AS first_app_edit_ts,
    MIN(first_ios_edit_ts) AS first_ios_edit_ts
FROM
    (
        SELECT *
        FROM chelsyx.ios_first_edit_ts

        UNION ALL

        SELECT *
        FROM unique_ios_editors
    ) all_editors
GROUP BY username
;

DROP TABLE IF EXISTS chelsyx.tmp_ios_first_edit_ts;
"
THISSCRIPTFILE=`basename "$0"`
RESULTSFILE=~/${THISSCRIPTFILE%.*}_result.txt
{ 
	date ; echo = ; TZ='America/Los_Angeles' date ; echo generated by $THISSCRIPTFILE on $HOSTNAME ; beeline --verbose=true -e "$QUERY" ; 
	hdfs dfs -mv /tmp/ios_edit/000000_0.gz /tmp/ios_edit/data.gz
	hdfs dfs -cp -f /tmp/ios_edit/data.gz /user/chelsyx/ios_first_edit_ts
} &> $RESULTSFILE