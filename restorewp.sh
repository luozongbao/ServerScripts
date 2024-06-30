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
	echo "Please run as root"
	exit
fi

# Check if mysql is installed
if [[ -z $(command -v mysql) ]]
then
  echo "mysql is not installed"
  exit
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

cd $destinationPath
destinationPath=$(pwd)
cd $originPath
cd $archivePath
archivePath=$(pwd)

# get archive database dump file name
dbFile=$(unzip -l $archiveFileName | grep .sql | grep -oP '\S+\.sql$') 2>> "error.log"
if [[ -z $dbFile ]]
then
  echo "could not open $archiveFileName"
  exit
fi

# check if extracted archive is a wordpress archive
WPCONFIG=$(unzip -l $archiveFileName | grep "/wp-config.php") 2>> "error.log"
if [[ -z $WPCONFIG ]]
then
  echo "Could not find wp-config.php"
  exit
fi

echo "Extracting file $archiveFileName"
unzip -o -q  $archiveFileName 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while extracting file"
  exit
fi

wordpressFolder=$(echo $WPCONFIG | grep -oP "\S+\/")

mv $wordpressFolder $destinationPath 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while moving $wordpressFolder to $destinationPath"
  exit
fi

echo "$wordpressFolder moved to $destinationPath"
WPDIR="$destinationPath/$wordpressFolder/"
WPCONFIG="$destinationPath/$wordpressFolder/wp-config.php"


# acquire databasename
DBName=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4)

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database username
  DBUser=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBUser=$3
fi

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database user password
  DBPass=$(cat $WPCONFIG | grep DB_PASSWORD | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBPass=$4
fi
# acquire database Prefix
DBPREFIX=$(cat $WPCONFIG | grep "\$table_prefix" | cut -d \' -f 2)

# Create database
echo "Creating database $DBName"
mysql -u root -e "CREATE DATABASE $DBName;" 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database"
  exit
fi

# Create username
echo "Creating database user: $DBUser"
mysql -u root -e "CREATE USER $DBUser IDENTIFIED BY '$DBPass';" 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while creating database user"
  exit
fi

# Grant permisssion to the database
echo "Granting permission to $DBName to database user: $DBUser"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBName.* TO $DBUser;" 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while granting permission to $DBName"
  exit
fi

# Import database
echo "Importing Database"
mysql -u $DBUser --password="$DBPass" $DBName < $dbFile 2>> "error.log"
if [[ ! $? == 0 ]]
then
  echo "Error occor while importing database $DBName"
  exit
fi

# Configure database username in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database username in wp-config.php"
  sed -i "/DB_USER/s/'[^']*'/'$DBUser'/2" $WPCONFIG  2>> "error.log"
  if [[ ! $? == 0 ]]
  then
    echo "Error occor while configuring database username"
    exit
  fi
fi

# Configure database password in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database password in wp-config.php"
  sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPass'/2" $WPCONFIG 2>> "error.log"
  if [[ ! $? == 0 ]]
  then
    echo "Error occor while configuring database password"
    exit
  fi
fi

echo "removing $dbFile"
rm $dbFile 2>> "error.log"
if [[ ! $? == 0 ]]
then
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

if [[ ! -z $(ls /usr/local/bin/ | grep -E "^wp$") ]]
then
  if [[ ($# == 3 || $# == 5) ]]
  then
    if [[ ($# == 3) ]]; then newURL=$3; fi
    if [[ ($# == 5) ]]; then newURL=$5; fi
    wp search-replace $originalURL $newURL --path=$WPDIR --all-tables --allow-root 2>> "error.log"
    if [[ ! $? == 0 ]]
    then
      echo "Error occor while configuring site url"
      exit
    else 
      echo "site url changed to $newURL"
    fi

  fi
fi













