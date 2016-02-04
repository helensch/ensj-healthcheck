#!/bin/bash -l
# Script for healthcheck execution with locking

div='ens'

function msg {
    echo $(date +"%Y-%m-%d %H:%M:%S") $1
}

properties=${div,,}-database.properties

hive_host=$(sed -n 's/.*hive.host *= *\([^ ]*.*\)/\1/p' < $properties)
hive_port=$(sed -n 's/.*hive.port *= *\([^ ]*.*\)/\1/p' < $properties)
hive_user=$(sed -n 's/.*hive.user *= *\([^ ]*.*\)/\1/p' < $properties)
hive_pass=$(sed -n 's/.*hive.password *= *\([^ ]*.*\)/\1/p' < $properties)

hive="mysql -h $hive_host -P $hive_port -u $hive_user -p$hive_pass"


LOG_FILE=${div}.log
msg "Running hived checks for Ensembl as process $$ on $(hostname)"
cd $(dirname $0)
if [ -z "$JAVA_OPTS" ]; then
    JAVA_OPTS=-Xmx15g
fi
export JAVA_OPTS
cwd=$(pwd)
export PATH=$HOME/src/ensembl/ensembl-hive/scripts:$HOME/ensj-healthcheck:$PATH
export PERL5LIB=$cwd/perl:$HOME/src/ensembl/ensembl/modules:$HOME/src/ensembl/ensembl-hive/modules:$PERL5LIB

# Get parameters for HC database.
HCDB=$(sed -n 's/.*output.database *= *\([^ ]*.*\)/\1/p' < $properties)
HCDB_HOST=$(sed -n 's/.*output.host *= *\([^ ]*.*\)/\1/p' < $properties)
HCDB_PORT=$(sed -n 's/.*output.port *= *\([^ ]*.*\)/\1/p' < $properties)
HCDB_USER=$(sed -n 's/.*output.user *= *\([^ ]*.*\)/\1/p' < $properties)
HCDB_PASS=$(sed -n 's/.*output.password *= *\([^ ]*.*\)/\1/p' < $properties)
group=$(sed -n 's/^groups *= *\([^ ]*.*\)/\1/p' < $properties)
exclude_dbs=$(sed -n 's/^exclude_dbs *= *\([^ ]*.*\)/\1/p' < $properties)
TIMINGS_FILE=/tmp/timings.txt
touch $LOG_FILE
touch $TIMINGS_FILE
chmod g+rwx $LOG_FILE
chmod g+rwx $TIMINGS_FILE

# Check if there's a lock.
MYSQL_CMD="mysql --skip-secure-auth --host=$HCDB_HOST --port=$HCDB_PORT --user=$HCDB_USER --password=$HCDB_PASS $HCDB"
msg "Looking for lock"
LOCK_EXISTS=$($MYSQL_CMD --column-names=false -e "select count(*) from information_schema.tables where table_name=\"hc_lock\" and table_schema=\"$HCDB\"" 2>/dev/null)

if [ "$LOCK_EXISTS" == "1" ]; then
  LOCK_DETAILS=$($MYSQL_CMD --skip-column-names -e 'SELECT user, hostname from hc_lock;')
  echo "Execution of healthchecks failed - database locked by " $LOCK_DETAILS 1>&2;
  exit
else
    msg "No lock found"    
  # Generate lock table.
  LOCK_SQL="CREATE TABLE hc_lock "
  LOCK_SQL+="(user varchar(25), hostname varchar(100), process_id varchar(25), lsf_job_id varchar(25)) "
  LOCK_SQL+="ENGINE=MyISAM; "

  LOCK_SQL+="INSERT INTO hc_lock VALUES (\"$USER\", \"$HOSTNAME\", \"$$\", \"local\"); "
  echo $LOCK_SQL > /tmp/${HCDB}.sql
  $MYSQL_CMD < /tmp/${HCDB}.sql
  msg "Lock generated"
fi

msg "Starting healthcheck run for ${div}"
# do hive stuff
pipeline_db="run_${HCDB}"
hc_url=mysql://$HCDB_USER:$HCDB_PASS@$HCDB_HOST:$HCDB_PORT/$HCDB
msg "Creating hive ${USER}_$pipeline_db"
init_pipeline.pl Bio::EnsEMBL::Healthcheck::Pipeline::RunHealthchecks_ens_conf -hc_conn $hc_url -pipeline_db -user=$hive_user -pipeline_db -pass=$hive_pass -pipeline_db -host=$hive_host -pipeline_db -port=$hive_port -hive_force_init 1 -division $div -hc_cmd "./run_ens_hc_hive.sh #division# #dbname# #session_id# #properties# #group#" -pipeline_name $pipeline_db -properties $properties -group "$group" -exclude_dbs "$exclude_dbs"
msg "Running beekeeper"
hive_url=mysql://$hive_user:$hive_pass@$hive_host:$hive_port/${USER}_${pipeline_db}
beekeeper.pl -url $hive_url -loop >& $LOG_FILE.hive
msg "Beekeeper complete"

failN=$($hive --column-names=false ${USER}_${pipeline_db} -e "select count(*) from job where status=\"FAILED\"")

if [ "$failN" != "0" ]; then
    echo "$failN failures found for $url" 1>&2 
    echo "$failN failed hive jobs found when running healthchecks for division $div - please check the hive $url for details" | #mail -s Failure ${USER}@ebi.ac.uk
    exit 2
fi

# Populate log table and remove lock.
LOG_SQL="CREATE TABLE IF NOT EXISTS last_log "
LOG_SQL+="(hostname varchar(100), std_err_out varchar(255), timings varchar(255)) "
LOG_SQL+="ENGINE=MyISAM; "

LOG_SQL+="TRUNCATE TABLE last_log; "

LOG_SQL+="INSERT INTO last_log VALUES (\"$HOSTNAME\", \"$LOG_FILE\", \"/tmp/timings.txt\"); "

$MYSQL_CMD -e "$LOG_SQL"

$MYSQL_CMD -e "DROP TABLE hc_lock;"

msg "Completed healthcheck run for ${div}"

exit 0