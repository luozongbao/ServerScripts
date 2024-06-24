#!/bin/bash

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ !  ($# == 2 || $# == 4) ]]
then
  echo -e "restorewp.sh [archive_file] [destination] \nrestorewp.sh [archive_file] [destination] [dbuser] [dbpassword]"
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
originPath=$(pwd)
archivePath=$(dirname $fullArchiveFile)
archiveFileName=$(basename $fullArchiveFile)
originalFolder=$(basename $(echo $archiveFileName | cut -d "-" -f2) .zip)
cd $destinationPath
destinationPath=$(pwd)
cd $originPath
cd $archivePath
archivePath=$(pwd)

echo "Extracting file $archiveFileName"
unzip -o -q  $archiveFileName
mv $originalFolder $destinationPath
echo "Place folder to $destinationPath"
WPCONFIG="$destinationPath/$originalFolder/wp-config.php"

# Check extracting archive
if [[ ! $? == 0 ]]
then
  echo "Error occor while extracting file"
  exit
fi

# check if extracted archive is a wordpress archive
if [[ ! -e $WPCONFIG ]]
then
  echo "Could not find wp-config.php"
  exit
fi

# acquire databasename
DBName=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4)

if [[ $# == 2 ]]
then
  # acquire database username
  DBUser=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4)
else
  DBUser=$3
fi

if [[ $# == 2 ]]
then
  # acquire database user password
  DBPass=$(cat $WPCONFIG | grep DB_PASSWORD | cut -d \' -f 4)
else
  DBPass=$4
fi

# Create database
echo "Creating database $DBName"
mysql -u root -e "CREATE DATABASE $DBName;"
if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database"
  exit
fi

# Create username
echo "Creating database user: $DBUser"
mysql -u root -e "CREATE USER $DBUser IDENTIFIED BY '$DBPass';"

if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database user"
  exit
fi

# Grant permisssion to the database
echo "Granting permission to $DBName to database user: $DBUser"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBName.* TO $DBUser;"
if [[ ! $? == 0 ]]
then
  echo "Error occor while granting permission to $DBName"
  exit
fi

# Import database
echo "Importing Database"
mysql -u $DBUser --password="$DBPass" $DBName < ${DBName}.sql
if [[ ! $? == 0 ]]
then
  echo "Error occor while importing database $DBName"
  exit
fi

if [ $# == 4 ]
then
  echo "Configuring database username in wp-config.html"
  sed -i "/DB_USER/s/'[^']*'/'$DBUser'/2" $WPCONFIG 
  if [[ ! $? == 0 ]]
  then
    echo "Error occor while configuring database username"
    exit
  fi
fi

if [ $# == 4 ]
then
  echo "Configuring database password in wp-config.html"
  sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPass'/2" $WPCONFIG
  if [[ ! $? == 0 ]]
  then
    echo "Error occor while configuring database password"
    exit
  fi
fi

echo "removing $DBName.sql"
rm ${DBName}.sql










