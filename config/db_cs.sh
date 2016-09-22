#!/bin/bash
# =============================================================================
# Author: Dan Gillis
# Created On: 29 Aug 2016
# Purpose: Config file used for dbDeploy.sh, which when executed will take a
#          database environment variable passed as a parameter and dynamically
#          create an Oracle database connect string with the appropriate
#          environment details, for example: "./db_cs.sh ENV1" could yield
#          "hr/oracle@localhost:1521/orcl"
# =============================================================================
#

# Environment 1 Login Variables
ENV1_ORA_USER="hr"                                  # Username
ENV1_ORA_PW="oracle"                                # Password
ENV1_ORA_HOSTNAME="localhost"                       # Hostname
ENV1_ORA_PORT="1521"                                # Port
ENV1_ORA_SERVICE_NAME="orcl"                        # Service name

# Environment 2 Login Variables
ENV2_ORA_USER="hr"                                  # Username
ENV2_ORA_PW="oracle"                                # Password
ENV2_ORA_HOSTNAME="localhost"                       # Hostname
ENV2_ORA_PORT="1521"                                # Port
ENV2_ORA_SERVICE_NAME="orcl"                        # Service name

function set_env_var()
{
  if [[ $1 = "ENV1" ]]; then
    ORA_USER=$ENV1_ORA_USER
    ORA_PW=$ENV1_ORA_PW
    ORA_HOSTNAME=$ENV1_ORA_HOSTNAME
    ORA_PORT=$ENV1_ORA_PORT
    ORA_SERVICE_NAME=$ENV1_ORA_SERVICE_NAME
  elif [[ $1 = "ENV2" ]]; then
    ORA_USER=$ENV2_ORA_USER
    ORA_PW=$ENV2_ORA_PW
    ORA_HOSTNAME=$ENV2_ORA_HOSTNAME
    ORA_PORT=$ENV2_ORA_PORT
    ORA_SERVICE_NAME=$ENV2_ORA_SERVICE_NAME
  else
    echo "Unkown environment parameter passed, please check your script header"
  fi
}

function concat_cs_vars()
{
  set_env_var $1
  ORA_CS=$ORA_USER"/"$ORA_PW"@"$ORA_HOSTNAME":"$ORA_PORT"/"$ORA_SERVICE_NAME
}

concat_cs_vars $1
