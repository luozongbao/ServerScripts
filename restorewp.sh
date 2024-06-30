#!/bin/bash

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

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ ( $# < 2 || $# > 5 ) ]]
then
  echo -e "restorewp.sh [archive_file] [destination]"
  echo -e "restorewp.sh [archive_file] [destination] [newsiteurl]"
  echo -e "restorewp.sh [archive_file] [destination] [dbuser] [dbpassword]"
  echo -e "restorewp.sh [archive_file] [destination] [dbuser] [dbpassword] [newsiteurl]"
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

cd $destinationPath
destinationPath=$(pwd)
cd $originPath
cd $archivePath
archivePath=$(pwd)

echo "Extracting file $archiveFileName"
unzip -o -q  $archiveFileName
# Check extracting archive
if [[ ! $? == 0 ]]
then
  echo "Error occor while extracting file"
  exit
fi

# check if extracted archive is a wordpress archive
WPCONFIG=$(find . | grep "/wp-config.php")
if [[ ! -e $WPCONFIG ]]
then
  echo "Could not find wp-config.php"
  exit
fi

wordpressFolder=$(dirname $WPCONFIG | rev | cut -d "/" -f 1 | rev)

mv $wordpressFolder $destinationPath
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

# Configure Site URL
# Get current site URL
#originalURL=$(sudo wp option get siteurl --path=$WPDIR --allow-root)
QUERY="SELECT option_value FROM ${DBPREFIX}options WHERE option_id=1;"
originalURL=$(mysql -u $DBUser $DBName -p$DBPass -e "$QUERY")
originalURL=$(echo $originalURL | grep -oP '\s(.*)$')
echo "current site url is: $originalURL"

if [[ ! -z $(ls /usr/local/bin/ | grep -E "^wp$") ]]
then
  if [[ ($# == 3 || $# == 5) ]]
  then
    if [[ ($# == 3) ]]; then newURL=$3; fi
    if [[ ($# == 5) ]]; then newURL=$5; fi
    wp search-replace $originalURL $newURL --path=$WPDIR --all-tables --allow-root
    if [[ ! $? == 0 ]]
    then
      echo "Error occor while configuring site url"
      exit
    else 
      echo "site url changed to $newURL"
    fi

  fi
fi













