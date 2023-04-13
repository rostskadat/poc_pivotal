#!/bin/bash

# IMDSv2: let's obtain the session token to access the Metadata:

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/

echo "Bootstrapping EC2 instance, please wait ..."
amazon-linux-extras install -y epel
yum install -y htop
yum clean metadata
yum info amazon-ssm-agent
systemctl status amazon-ssm-agent
echo "Bootstrapping EC2 instance OK."

echo "Installing SymmetricDS, please wait ..."
# REF: https://houseofbrick.com/blog/replicating-from-oracle-on-premise-to-oracle-in-aws-rds-using-symmetricds/
amazon-linux-extras install -y java-openjdk11
curl -o /tmp/symmetric-server-3.14.3.zip "https://altushost-swe.dl.sourceforge.net/project/symmetricds/symmetricds/symmetricds-3.14/symmetric-server-3.14.3.zip"
unzip -o /tmp/symmetric-server-3.14.3.zip -d /opt
cd /opt/symmetric-server-3.14.3/

cat > /opt/symmetric-server-3.14.3/conf/symmetric-server.properties <<EOF
# REF: https://www.symmetricds.org/doc/3.14/html/user-guide.html#_node_properties_file
host.bind.name=0.0.0.0
http.enable=true
http.port=31415
https.enable=false
https.port=31417
https.allow.self.signed.certs=true
https.verified.server.names=all
https.want.client.auth=false
https.need.client.auth=false
auto.registration=true
jmx.http.enable=true
jmx.http.port=31416
EOF

cat > /opt/symmetric-server-3.14.3/engines/src-000.properties <<EOF
# REF: https://www.symmetricds.org/doc/3.14/html/user-guide.html#_node_properties_file

engine.name=src-000
db.driver=oracle.jdbc.driver.OracleDriver
db.url=${src_db_url}
db.user=${db_username}
db.password=${db_password}
sync.url=http://${sync_hostname}:31415/sync/src-000
registration.url=http://${sync_hostname}:31415/sync/src-000
group.id=src
external.id=000

# This is how often the routing job will be run in milliseconds
job.routing.period.time.ms=5000
job.push.period.time.ms=10000
job.pull.period.time.ms=1000
EOF

cat > /opt/symmetric-server-3.14.3/engines/dst-001.properties <<EOF
# REF: https://www.symmetricds.org/doc/3.14/html/user-guide.html#_node_properties_file

engine.name=dst-001
db.driver=oracle.jdbc.driver.OracleDriver
db.url=${dst_db_url}
db.user=${db_username}
db.password=${db_password}
registration.url=http://${sync_hostname}:31415/sync/src-000
sync.url=http://${sync_hostname}:31415/sync/dst-001
group.id=dst
external.id=001

# This is how often the routing job will be run in milliseconds
job.routing.period.time.ms=5000
job.push.period.time.ms=10000
job.pull.period.time.ms=10000
EOF

echo "Installing SymmetricDS OK."


echo "Installing SQL*PLUS, please wait ..."
curl -o /tmp/oracle-instantclient-basic-linuxx64.rpm https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-basic-linuxx64.rpm
curl -o /tmp/oracle-instantclient-sqlplus-linuxx64.rpm https://download.oracle.com/otn_software/linux/instantclient/oracle-instantclient-sqlplus-linuxx64.rpm
yum install -y /tmp/oracle-instantclient-basic-linuxx64.rpm /tmp/oracle-instantclient-sqlplus-linuxx64.rpm
echo "Installing SQL*PLUS OK."

cat > /root/configure_symmetricds.sh <<EOF
#!/bin/bash
echo "Configuring SymmetricDS, please wait ..."
echo "Do not forget to 'sql_plus @scrub_symmetricds.sql'" on SRC_DB and DST_DB
/opt/symmetric-server-3.14.3/bin/symadmin --engine src-000 create-sym-tables
/opt/symmetric-server-3.14.3/bin/symadmin open-registration --engine src-000 dst 001
echo "Do not forget to 'sql_plus @clean_symmetricds.sql'" on SRC_DB and DST_DB
echo "Do not forget to 'sql_plus @configure_symmetricds.sql'" on SRC_DB
echo "Between each test execute 'sql_plus @clean_perf.sql'" on SRC_DB and DST_DB
echo "Configuring SymmetricDS OK."
EOF

cat > /root/scrub_symmetricds.sql <<EOF
DROP TABLE SYM_NODE_GROUP CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_GROUP_CHANNEL_WND CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_GROUP_LINK CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_HOST CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_HOST_CHANNEL_STATS CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_HOST_JOB_STATS CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_HOST_STATS CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_IDENTITY CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_SECURITY CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NOTIFICATION CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_OUTGOING_BATCH CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_PARAMETER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_REGISTRATION_REDIRECT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_REGISTRATION_REQUEST CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_ROUTER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_SEQUENCE CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TABLE_RELOAD_REQUEST CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TABLE_RELOAD_STATUS CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRANSFORM_COLUMN CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRANSFORM_TABLE CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRIGGER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRIGGER_HIST CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRIGGER_ROUTER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_TRIGGER_ROUTER_GROUPLET CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_CHANNEL CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_CONFLICT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_CONTEXT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_DATA CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_DATA_EVENT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_DATA_GAP CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_EXTENSION CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_EXTRACT_REQUEST CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_FILE_INCOMING CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_FILE_SNAPSHOT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_FILE_TRIGGER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_FILE_TRIGGER_ROUTER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_GROUPLET CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_GROUPLET_LINK CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_INCOMING_BATCH CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_INCOMING_ERROR CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_JOB CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_LOAD_FILTER CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_LOCK CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_MONITOR CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_MONITOR_EVENT CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_CHANNEL_CTL CASCADE CONSTRAINTS PURGE;
DROP TABLE SYM_NODE_COMMUNICATION CASCADE CONSTRAINTS PURGE;
EXIT;
EOF

cat > /root/scrub_perf.sql <<EOF
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PERF_SMALL';
    EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF;
END;
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PERF_MEDIUM';
    EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF;
END;
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PERF_LARGE';
    EXCEPTION WHEN OTHERS THEN IF SQLCODE <> -942 THEN RAISE; END IF;
END;

CREATE TABLE PERF_SMALL (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
    TEXT VARCHAR2(128) DEFAULT NULL,
    TIME TIMESTAMP DEFAULT SYSDATE,
    PRIMARY KEY (ID)
    )

CREATE TABLE PERF_MEDIUM (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
    TEXT VARCHAR2(4000) DEFAULT NULL,
    TIME TIMESTAMP DEFAULT SYSDATE,
    PRIMARY KEY (ID)
    )

CREATE TABLE PERF_LARGE (
    ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
    TEXT CLOB DEFAULT NULL,
    TIME TIMESTAMP DEFAULT SYSDATE,
    PRIMARY KEY (ID)
)
EXIT;
EOF



cat > /root/clean_perf.sql <<EOF
TRUNCATE TABLE perf_small;
TRUNCATE TABLE perf_medium;
TRUNCATE TABLE perf_large;
COMMIT;
EXIT;
EOF

cat > /root/clean_symmetricds.sql <<EOF
------------------------------------------------------------------------------
-- REF: https://www.symmetricds.org/doc/3.14/html/tutorials.html#_configure
------------------------------------------------------------------------------
-- Clear and load SymmetricDS Configuration
------------------------------------------------------------------------------

DELETE FROM sym_trigger_router;
DELETE FROM sym_trigger;
DELETE FROM sym_router;
DELETE FROM sym_channel where channel_id in ('perf_channel');
DELETE FROM sym_node_group_link;
DELETE FROM sym_node_group;
DELETE FROM sym_node_host;
DELETE FROM sym_node_identity;
DELETE FROM sym_node_security;
DELETE FROM sym_node;
COMMIT;
EXIT;
EOF

cat > /root/configure_symmetricds.sql <<EOF
------------------------------------------------------------------------------
-- Node Groups
------------------------------------------------------------------------------
-- https://www.symmetricds.org/doc/3.14/html/user-guide.html#_groups
INSERT INTO sym_node_group (node_group_id) VALUES ('src');
INSERT INTO sym_node_group (node_group_id) VALUES ('dst');

------------------------------------------------------------------------------
-- Node Group Links
------------------------------------------------------------------------------
-- https://www.symmetricds.org/doc/3.14/html/user-guide.html#_group_links
-- src sends changes to dst when dst pulls from src
-- dst sends changes to src when dst pushes to src
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action) VALUES ('src', 'dst', 'W');
INSERT INTO sym_node_group_link (source_node_group_id, target_node_group_id, data_event_action) VALUES ('dst', 'src', 'P');

------------------------------------------------------------------------------
-- Routers
------------------------------------------------------------------------------
-- https://www.symmetricds.org/doc/3.14/html/user-guide.html#_routers
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, router_type, create_time, last_update_time) VALUES ('src_2_dst', 'src', 'dst', 'default', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO sym_router (router_id, source_node_group_id, target_node_group_id, router_type, create_time, last_update_time) VALUES ('dst_2_src', 'dst', 'src', 'default', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

------------------------------------------------------------------------------
-- Channels
------------------------------------------------------------------------------
-- https://www.symmetricds.org/doc/3.14/html/user-guide.html#_channels
INSERT INTO sym_channel (channel_id, processing_order, max_batch_size, max_batch_to_send, extract_period_millis, batch_algorithm, enabled, contains_big_lob, description) VALUES ('perf_channel', 10, 1000, 10, 0, 'default', 1, 1, 'Perf Tables channel');

------------------------------------------------------------------------------
-- Triggers
------------------------------------------------------------------------------

-- Triggers for tables on "perf" channel
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, last_update_time, create_time) VALUES ('perf_small', 'perf_small', 'perf_channel', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, last_update_time, create_time) VALUES ('perf_medium', 'perf_medium', 'perf_channel', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO sym_trigger (trigger_id, source_table_name, channel_id, last_update_time, create_time) VALUES ('perf_large', 'perf_large', 'perf_channel', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

------------------------------------------------------------------------------
-- Trigger Routers
------------------------------------------------------------------------------

-- Send everything from src to dst
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('perf_small', 'src_2_dst', 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('perf_medium', 'src_2_dst', 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
INSERT INTO sym_trigger_router (trigger_id, router_id, initial_load_order, last_update_time, create_time) VALUES ('perf_large', 'src_2_dst', 100, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
COMMIT;
EXIT;
EOF

cat > /root/stress_test.sh <<EOF
#!/bin/bash
TABLE=$1
if [ -z "$TABLE" ]; then
    echo "Specify the table name (PERF_SMALL | PERF_MEDIUM | PERF_LARGE)"
    exit 1
fi

SRC_HOST=sicyc-dev-src-replica20221215172414176100000002.cv3bqn9qsiga.eu-central-1.rds.amazonaws.com
DST_HOST=sicyc-dev-dst-replica20221215172201303300000001.cv3bqn9qsiga.eu-central-1.rds.amazonaws.com

# The truncate do not trigger any update...
sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$SRC_HOST:1527/SPSOL01 @clean_perf.sql
sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$DST_HOST:1527/SPSOL01 @clean_perf.sql

rm -f $TABLE.csv

python3 symmetricsds_test.py --quiet --username 'OPS$CREDISEG' --password OPSCREDISEG_PASSW --hostname $DST_HOST --db-name SPSOL01 --action monitor --table $TABLE --csv &

for i in $(seq 1 1000); do
    echo "$(date +"%H:%M:%S") | Test $i/1000 (1 record)..."
    python3 symmetricsds_test.py --quiet --username 'OPS$CREDISEG' --password OPSCREDISEG_PASSW --hostname $SRC_HOST --db-name SPSOL01 --action write --table $TABLE --row-count 1
    sleep 0.1
done
for i in $(seq 1 1000); do
    echo "$(date +"%H:%M:%S") | Test $i/1000 (10 records)..."
    python3 symmetricsds_test.py --quiet --username 'OPS$CREDISEG' --password OPSCREDISEG_PASSW --hostname $SRC_HOST --db-name SPSOL01 --action write --table $TABLE --row-count 10
    sleep 0.1
done
for i in $(seq 1 1000); do
    echo "$(date +"%H:%M:%S") | Test $i/1000 (100 records)..."
    python3 symmetricsds_test.py --quiet --username 'OPS$CREDISEG' --password OPSCREDISEG_PASSW --hostname $SRC_HOST --db-name SPSOL01 --action write --table $TABLE --row-count 100
    sleep 0.1
done
for i in $(seq 1 1000); do
    echo "$(date +"%H:%M:%S") | Test $i/1000 (1000 records)..."
    python3 symmetricsds_test.py --quiet --username 'OPS$CREDISEG' --password OPSCREDISEG_PASSW --hostname $SRC_HOST --db-name SPSOL01 --action write --table $TABLE --row-count 1000
    sleep 0.1
done

echo "Use 'pkill' to kill the monitoring python3 process..."
ps

EOF
