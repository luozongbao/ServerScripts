#!/bin/bash

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ ( $# < 2 || $# > 5 ) ]]
then
  echo -e "Extract archive to destination using same database information.\n\trestorewp.sh [archive_file] [destination]\n"
  echo -e "Extract archive to destination using same database information then update site url.\n\trestorewp.sh [archive_file] [destination] [newsiteurl]\n"
  echo -e "Extract archive to destination update database username and password.\n\trestorewp.sh [archive_file] [destination] [dbuser] [dbpassword]\n"
  echo -e "Extract archive to destination update database username and password then update site url\n\trestorewp.sh [archive_file] [destination] [dbuser] [dbpassword] [newsiteurl]\n"
  exit
fi

# Check if run as root
if (( $EUID != 0 )) 
then
	echo "Please run as root."
  echo "root access is used to create database and database user in this script"
	exit
fi

# Check if mysql is installed
if [[ -z $(command -v mysql) ]]
then
  echo "mysql is not installed"
  exit
fi

if [[ ($# == 3 || $# == 5) ]]
then
  if [[ -z $(ls /usr/local/bin/ | grep -E "^wp$") ]]
  then
    echo "Couldn't perform url change since wp-cli has not been installed"
    exit 
  fi
fi


# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -f $1 ]] 
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

# get destination full path
cd $destinationPath
destinationPath=$(pwd)

# get archive full path
cd $originPath
cd $archivePath
archivePath=$(pwd)

# get archive database dump file name
dbFile=$(unzip -l $archiveFileName | grep ".sql" | grep -oP "\S+\.sql$" | grep -oP "^[^\s\/]+\.sql$") 2>> "error.log"
if [[ -z $dbFile ]]
then
  if [[ $? == 0 ]]
  then
    echo "Archive does not include database dump file"
  else
    echo "could not open $archiveFileName"
  fi
  exit
fi

# check if extracted archive is a wordpress archive
WPCONFIG=$(unzip -l $archiveFileName | grep "\/wp-config.php") 2>> "error.log"
if [[ -z $WPCONFIG ]]
then
  if [[ $? == 0 ]]
  then
    echo "Could not find wp-config.php"
  else
    echo "could not open $archiveFileName"
  fi
  exit
fi

# Extracting file
echo "Extracting file $archiveFileName"
unzip -o -q  $archiveFileName 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Extracted file from archive $archiveFileName."
else
  echo "Error occor while extracting file"
  exit
fi

wordpressFolder=$(echo $WPCONFIG | grep -oP "\S+\/")

# Move folder to destination Path
mv $wordpressFolder $destinationPath 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "$wordpressFolder moved to $destinationPath."
else
  echo "Error occor while moving $wordpressFolder to $destinationPath"
  exit
fi

WPDIR="$destinationPath/$wordpressFolder/"
WPCONFIG="$destinationPath/$wordpressFolder/wp-config.php"


# acquire databasename
DBName=$(grep DB_NAME $WPCONFIG | cut -d \' -f 4)

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database username
  DBUser=$(grep DB_USER $WPCONFIG | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBUser=$3
fi

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database user password
  DBPass=$(grep DB_PASSWORD $WPCONFIG | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBPass=$4
fi

# acquire database Prefix
DBPREFIX=$(grep "\$table_prefix" $WPCONFIG | cut -d \' -f 2)

# Create database
echo "Creating database $DBName"
mysql -u root -e "CREATE DATABASE $DBName;" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Database $DBName created."
else
  echo "Error occor while creating database"
  exit
fi

# Create username
echo "Creating database user: $DBUser"
mysql -u root -e "CREATE USER $DBUser IDENTIFIED BY '$DBPass';" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Database user $DBUser created."
else
  echo "Error occor while creating database user"
  exit
fi

# Grant permisssion to the database
echo "Granting permission on $DBName to $DBUser"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBName.* TO $DBUser;" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Granted permission on $DBName to $DBuser."
else
  echo "Error occor while granting permission to $DBName"
  exit
fi

# Import database
echo "Importing Database $DBName"
mysql -u $DBUser --password="$DBPass" $DBName < $dbFile 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Imported database from file $dbFile to $DBName."
else
  echo "Error occor while importing database $DBName from $dbFile"
  exit
fi

# Configure database username in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database username in wp-config.php"
  sed -i "/DB_USER/s/'[^']*'/'$DBUser'/2" $WPCONFIG  2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "Configured database user $DBUser to wp-config.php."
  else
    echo "Error occor while configuring database username"
    exit
  fi
fi

# Configure database password in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database password in wp-config.php"
  sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPass'/2" $WPCONFIG 2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "Configured database password $DBPass to wp-config.php."
  else
    echo "Error occor while configuring database password"
    exit
  fi
fi

rm $dbFile 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Removed imported file $dbFile."
else
  echo "Error occor while removing $dbFile"
  exit
fi

# Configure Site URL
# Get current site URL
#originalURL=$(sudo wp option get siteurl --path=$WPDIR --allow-root)
QUERY="SELECT option_value FROM ${DBPREFIX}options WHERE option_id=1;"
originalURL=$(mysql -u $DBUser $DBName -p$DBPass -e "$QUERY")  2>> "error.log"
originalURL=$(echo $originalURL | grep -oP '\s(.*)$')
echo "current site url is: $originalURL"

if [[ ($# == 3) ]]; then newURL=$3; fi
if [[ ($# == 5) ]]; then newURL=$5; fi
if [[ ! -z $newURL ]]
then
  wp search-replace $originalURL $newURL --path=$WPDIR --all-tables --allow-root 2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "site url changed to $newURL"
  else 
    echo "Error occor while configuring site url"
    exit
  fi
fi

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
fi

echo "All restore process done."










