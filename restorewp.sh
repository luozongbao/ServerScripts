#!/bin/bash

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ $# != 4 ]]
then
  echo "restorewp.sh [archive_file] [destination] [DBUser] [DBPassword]"
  exit
fi

# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -e $1 ]] 
then
  echo "Invalid archive file path provided"
  exit
fi

# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -d $2 ]]
then
  echo "Invalid directory path provided"
  exit
fi

fullArchiveFile=$1
destinationPath=$2
DBUser=$3
DBPass=$4
originPath=$(pwd)
archivePath=$(dirname $fullArchiveFile)
archiveFileName=$(basename $fullArchiveFile)
originalFolder=$(basename $(echo $archiveFileName | cut -d "-" -f2) .zip)
cd $destinationPath
destinationPath=$(pwd)
cd $originPath
cd $archivePath
archivePath=$(pwd)
WPCONFIG="$archivePath/$originalFolder/wp-config.php"

echo "Extracting file $archiveFileName"
unzip -o -q  $archiveFileName

if [[ ! $? == 0 ]]
then
  echo "Error occor while extracting file"
  exit
fi

if [[ ! -e $WPCONFIG ]]
then
  echo "Could not find wp-config.php"
  exit
fi

DBName=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4)

echo "Creating database $DBName"
mysql -u root -e "CREATE DATABASE $DBName;"
if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database"
  exit
fi

echo "Creating database user: $DBUser"
mysql -u root -e "CREATE USER $DBUser IDENTIFIED BY '$DBPass';"

if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database user"
  exit
fi

echo "Granting permission to $DBName to database user: $DBUser"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBName.* TO $DBUser;"
if [[ ! $? == 0 ]]
then
  echo "Error occor while granting permission to $DBName"
  exit
fi

echo "Importing Database"
mysql -u $DBUser --password="$DBPass" $DBName < ${DBName}.sql
if [[ ! $? == 0 ]]
then
  echo "Error occor while importing database $DBName"
  exit
fi

echo "removing $DBName.sql and moving $originalFolder to $destinationPath"
rm ${DBName}.sql
mv $originalFolder $destinationPath









