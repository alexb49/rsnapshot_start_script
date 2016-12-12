# project=Backup
# file=Backup_Websites.sh
# version=1.0.0
# type=bash
# date=2014-09-12

### Little script to backup a website with rsnapshot
### Does a mysqlDump and DL the dump first
### Then starts the rsnapshot backup
### Don't forget to change the variables values for:
### ipserverweb / ipserverbackup / user / backup_folder / 


#!/bin/bash
set -u
set -e

# Variables
id=`date +%Y-%m-%d_%H`
# Ips of the machines on the CPN
ipserverweb=X.X.X.X
ipserverbackup=X.X.X.X

user="XXX"
backup_folder="/home/XXX/Documents/Backup-Websites"
KoB=$(echo weekly monthly yearly)
today=`date`

## Usage message
Usage () {

          echo
          echo "DESCRIPTION"
          echo "     This is a helper tool for backuping my Website"
          echo
          echo "     The options are as follows:"
          echo
          echo "     -t      def: time. weekly | monthly | yearly"
          echo
          echo
          echo "EXAMPLES"
          echo
          echo "$0 -t weekly"
          echo
          exit 1
}

while getopts t: flag; do
  case $flag in
    t)
      time_stamp="${OPTARG}"
      ;;
  esac
done

## Make sure we have what we need or print usage ##
if [ ${time_stamp} = "" ]; then
  echo "Setup a type of backup"
  echo
  Usage
fi

## Test if the -p is correct ##
for TIME in ${KoB}; do
  if [ ${TIME} = ${time_stamp} ]; then
    TIME_EXISTS=1
    break
  else
    TIME_EXISTS=0
  fi
done

if [ ${TIME_EXISTS} -eq 0 ]; then
  echo "Wrong Parameter"
  echo
  Usage
fi

last_backup=$(date -r ${backup_folder}/weekly.0)

# Test Serveur Web joignable
connected=`ping -c 3 ${ipserverweb} | grep icmp_req | wc -l`

# Test Backup deja en cours
prossId=$(ps aux | grep Backup_Websites | wc -l)

# Si Web Server est joignable
if [ ${connected} -eq 0 ]; then

  # Si le process n'est pas déjà en cours
  if [ ${prossId} -gt 0 ]; then
	
    echo "==============================================================================="
    echo "                          This is a ${time_stamp} Backup"
    echo
    echo "Rsnapshot wrapper script started the ${today}"
    echo "Date of last backup : ${last_backup}"
    echo
    echo

    # Delete previous dump
    ssh ${user}@${ipserverweb} "rm -rf /var/www/WEBSITEDIR/Backup_BD/*"

    # Dump DataBase
    ssh ${user}@${ipserverweb} "mysqldump -u DBUSER --password=DBPASSWORD DBNAME > /var/www/html/WEBSITEDIR/Backup_BD/A-DB-Backup-${id}.sql" > /dev/null

    # DB done
    echo "DB dump done at ${id}"

    # Execution de rsnapshot
    /usr/bin/rsnapshot -c /etc/rsnapshot.conf ${time_stamp}

    echo "rsnapshot wrapper script completed the ${today}"
    echo 

  else
    echo "rsnapshot was already in progress the ${today}"
    echo
 
  fi

else
  echo "Server web unreachable the ${today}"
  echo
 
fi >> ${backup_folder}/backup.log
