#!/bin/bash

# Check if run as root
if (( $EUID != 0 )) 
then
    echo -e "root access might be needed if your user is not owner of the target file or folder.\n"
fi


# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ $# != 2 ]]
then
  echo "backupwp.sh [target_directory_name] [destination_directory_name]"
  exit
fi

# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -d $1 ]] || [[ ! -d $2 ]]
then
  echo "Invalid directory path provided"
  exit
fi

# define directory
TARGETDIRECTORY=$1
DESTINATIONDIRECTORY=$2

# getting original path
ORIGINALPATH=$(pwd)

# define destiantion path
cd $DESTINATIONDIRECTORY
DESTINATIONPATH=$(pwd)

# define target path
cd $ORIGINALPATH
cd $TARGETDIRECTORY
TARGETPATH=$(pwd)
WPCONFIG="$TARGETPATH/wp-config.php"
cd ..

# check if it is wordpress folder
if [ ! -f $WPCONFIG ]
then
  echo "$TARGETPATH is not a wordpress directory"
  exit
fi

# acquire database username
DBUSER=$(grep DB_USER $WPCONFIG | cut -d \' -f 4)
# acquire database user password
DBPASS=$(grep DB_PASSWORD $WPCONFIG | cut -d \' -f 4)
# Retrieve Database Name
DBNAME=$(grep DB_NAME $WPCONFIG | cut -d \' -f 4)

# generate timestamp
CURRENTTS=$(date +%Y%m%d%H%M)

# get Backup Directory Name
BACKUPDIRECTORYNAME=$( echo $TARGETPATH | rev | cut -d "/" -f1 | rev)

# generate backup file name
BACKUPFILENAME="${CURRENTTS}-$BACKUPDIRECTORYNAME.zip"

# Export Database to file
echo "Exporting Database $DBNAME"
mysqldump -u $DBUSER --password=$DBPASS $DBNAME > ${DBNAME}.sql 2>> error.log
if [ $? == 0 ]
then
  echo "Database $DBNAME is exported to file ${DBNAME}.sql."
else
  echo "Error occur while dumping database ${DBNAME} to file ${DBNAME}.sql"
  exit 
fi


# zip entire directory
echo "Compressing and Archiving files to $BACKUPFILENAME"
zip -r -q $BACKUPFILENAME $BACKUPDIRECTORYNAME "${DBNAME}.sql" 2>> error.log
if [ $? == 0 ]
then
  echo "Backup file $BACKUPFILENAME created."
else
  echo "Error occur compressing backup to file $BACKUPFILENAME"
  exit 
fi

echo "Backup compressed to $BACKUPFILENAME: Done"

# Move to Destination Path
mv $BACKUPFILENAME $DESTINATIONPATH 2>> error.log
if [ $? == 0 ]
then
  echo "backup file located at $DESTINATIONPATH/$BACKUPFILENAME"
else
  echo "Error occur compressing backup to file $BACKUPFILENAME"
  exit 
fi

# remove zipped database file
echo "Removing no longer needed file"
rm "${DBNAME}.sql"
if [ $? == 0 ]
then
  # Remove empty error log file
  if [[ ($(wc -c error.log | grep -oP "\d") == 0) ]]
  then
    rm error.log
    if [[ $? == 0 ]]
    then
      echo "No error found."
    else
      echo "Error occor while removing error.log"
      exit
    fi
  else  
    cat error.log
  fi
  
else
  echo "Error deleting file ${DBNAME}.sql"
  exit 
fi
echo "All backup process done"







