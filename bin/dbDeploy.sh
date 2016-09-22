#!/bin/bash
# =============================================================================
# Author: Dan Gillis
# Created On: 29 Aug 2016
# Purpose: Script takes a sql file, appends leading and trailing statements
#          for compilation as well as cleans out unwanted compile statements
#          After cleanup and file manipulation is complete, file is executed
#          via sqlplus
# =============================================================================
#

# Pull in the header row to the envs variable, which should contain the environments to deploy to
envs=$(head -n 1 ../script/deployment.sql)

# causes variables defined from now on to be automatically exported
set -a 

# Set Email Address List of Recipients.
EMAIL_TO_LIST="some.email@gmail.com,another.email@gmail.com"
EMAIL_SUBJECT="Database Deployment Script Status"

# Because users have to remember to put the environment header row at the top of their script,
# it's good to check that the appropriate text is present in the file
# Print an alert to the terminal and e-mail it as well
for envCheck in $envs
do
  if [[ $envCheck != "ENV"* ]]; then
  	echo 'Your deployment script must have a proper header - please check your script!';
        # echo 'Your deployment script must have a proper header - please check your script!';
        #| mailx -s "Failed: $EMAIL_SUBJECT" $EMAIL_TO_LIST;
  	exit 23;
  fi
done

# Remove the header record (GNU sed version)
# sed -i -e '1d' ../script/deployment.sql 

# Remove the header record (BSD/Mac OS X version)
sed -i '' -e '1d' ../script/deployment.sql

# Remove any end of line windows ^M characters with 
tr -d '\r' < ../script/deployment.sql > ../work/d1.sql

# =============================================================================
# The next two sed statements removes any "Alter ** Compile **"" statements 
# that may be present in the file. Certain "Schema Compare" tools automatically 
# determine any dependent objects for the ones they are deploying and add a 
# compile statement for them regardless of what compilation state they're in.  
# This can cause havoc, particularly with "types" and end up invalidatinga a 
# bunch of other objects.  Appended to the end of the script is a procedure 
# execution that attempts to compile invalidated objects for the given schema  
# =============================================================================

# sed one-liner deletes the lines after the matching regular 
# expression (line starts with alter and ends with compile)
# in the "command grouping" block {n;N;d;}
#   n prints the next line
#   N then reads the line 
#   d deletes them all
sed -e '/^ALTER.*COMPILE.*/{n;N;d;}' < ../work/d1.sql > ../work/d2.sql


# sed one-liner deletes any lines matching the regular 
# expression (line starts with alter and ends with compile)
sed '/^ALTER.*COMPILE.*/ d' < ../work/d2.sql > ../work/d3.sql

# this statement below should work and be able to do what I did above in one line, I believe this works in 
# typical GNU linux, but on the Mac OS X variant (BSD), it doesn't seem to work
###sed -e '/^ALTER.*COMPILE.*/{n;N;d;}' -e '/^ALTER.*COMPILE$/ d' < ../work/d1.sql > ../work/d3.sql

# =============================================================================
# append lines for schema compilation to end of file
# This is optional, but I typically like to run this procedure to compile any
# invalidated objects in the schema. You can find the source code for this
# compilation procedure in the schemaCompile directory
# =============================================================================
echo "" >> ../work/d3.sql
echo "begin hr.p_compile_invalid_objects (p_user => 'HR'); end;" >> ../work/d3.sql
echo "/" >> ../work/d3.sql

# =============================================================================
# The next few statements create a file header 
# =============================================================================

# Appending first line to the file
echo "alter session set plsql_optimize_level = 3;" > ../work/line1

# Appending second line to the file
echo "" > ../work/line2

# Use cat command to concatenate ../work/line1 and ../work/line2 files to new output file named ../work/dbDeploy.sql
cat ../work/line1 ../work/line2 ../work/d3.sql > ../work/dbDeploy.sql

# temp file cleanup
rm ../work/d1.sql
rm ../work/d2.sql
rm ../work/d3.sql
rm ../work/line1
rm ../work/line2

# Variables for file naming below
file_name="dbDeploy"
current_time=$(date "+%Y%m%d_%H%M%S")


# Create backup file name with date/time
backupfile_suffix="sql"
backup_fileName=$file_name$current_time.$backupfile_suffix

# copy deployment script to backup folder
cp ../work/dbDeploy.sql ../backup/$backup_fileName

for env in $envs
do

# Pull in connect string from another file
source ../config/db_cs.sh $env

# Create log file name with date/time
logfile_suffix="log"
log_fileName=$file_name"_"$env"_"$current_time.$logfile_suffix

# If necessary, Set ORACLE_HOME & Library file paths to whichever directory 
# these are present
# ORACLE_HOME=/opt/oracle/database/11.2.0/client
# export LD_LIBRARY_PATH=/opt/oracle/database/11.2.0/client/lib
# $ORACLE_HOME/bin/sqlplus /nolog << EOF

# If not necesary to explicitly set the the path
sqlplus /nolog << EOF

# Connect string
CONNECT $ORA_CS

# Runtime sqlplus configurations
set echo on
set feed on
set time on
set timing on
set lines 300
set trims on
set define off
set serveroutput on size unlimited

SPOOL ../log/$log_fileName

@../work/dbDeploy.sql

SPOOL OFF
EXIT;

EOF

# LOG_ATTACH_LIST="$LOG_ATTACH_LIST -a ../log/$log_fileName"
done

# delete original deployment scripts
rm ../work/dbDeploy.sql ../script/deployment.sql
