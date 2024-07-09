#!/bin/bash

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ ( $# < 2 || $# > 5 ) ]]
then
  echo -e "Extract archive to destination using same database information.\n\trestorewp.sh [archive_file] [destination]\n"
  echo -e "Extract archive to destination using same database information then update site url.\n\trestorewp.sh [archive_file] [destination] [newsiteurl]\n"
  echo -e "Extract archive to destination update database username and password.\n\trestorewp.sh [archive_file] [destination] [DBUSER] [DBPASSword]\n"
  echo -e "Extract archive to destination update database username and password then update site url\n\trestorewp.sh [archive_file] [destination] [DBUSER] [DBPASSword] [newsiteurl]\n"
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

FULLARCHIVEFILE=$1
DESTINATIONPATH=$2
ORIGINPATH=$(pwd)
ARCHIVEPATH=$(dirname $FULLARCHIVEFILE)
ARCHIVEFILENAME=$(basename $FULLARCHIVEFILE)

# get destination full path
cd $DESTINATIONPATH
DESTINATIONPATH=$(pwd)

# get archive full path
cd $ORIGINPATH
cd $ARCHIVEPATH
ARCHIVEPATH=$(pwd)

# get archive database dump file name
DBFILE=$(unzip -l $ARCHIVEFILENAME | grep ".sql" | grep -oP "\S+\.sql$" | grep -oP "^[^\s\/]+\.sql$") 2>> "error.log"
if [[ -z $DBFILE ]]
then
  if [[ $? == 0 ]]
  then
    echo "Archive does not include database dump file"
  else
    echo "could not open $ARCHIVEFILENAME"
  fi
  exit
fi

# check if extracted archive is a wordpress archive
WPCONFIG=$(unzip -l $ARCHIVEFILENAME | grep "\/wp-config.php") 2>> "error.log"
if [[ -z $WPCONFIG ]]
then
  if [[ $? == 0 ]]
  then
    echo "Could not find wp-config.php"
  else
    echo "could not open $ARCHIVEFILENAME"
  fi
  exit
fi

# Extracting file
echo "Extracting file $ARCHIVEFILENAME"
unzip -o -q  $ARCHIVEFILENAME 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Extracted file from archive $ARCHIVEFILENAME."
else
  echo "Error occor while extracting file"
  exit
fi

WORDPRESSFOLDER=$(echo $WPCONFIG | grep -oP "\S+\/")

# Move folder to destination Path
mv $WORDPRESSFOLDER $DESTINATIONPATH 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "$WORDPRESSFOLDER moved to $DESTINATIONPATH."
else
  echo "Error occor while moving $WORDPRESSFOLDER to $DESTINATIONPATH"
  exit
fi

WPDIR="$DESTINATIONPATH/$WORDPRESSFOLDER/"
WPCONFIG="$DESTINATIONPATH/$WORDPRESSFOLDER/wp-config.php"


# acquire databasename
DBNAME=$(grep DB_NAME $WPCONFIG | cut -d \' -f 4)

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database username
  DBUSER=$(grep DB_USER $WPCONFIG | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBUSER=$3
fi

if [[ ($# == 2 || $# == 3) ]]
then
  # acquire database user password
  DBPASS=$(grep DB_PASSWORD $WPCONFIG | cut -d \' -f 4)
elif [[ ($# == 4 || $# == 5) ]]
then
  DBPASS=$4
fi

# acquire database Prefix
DBPREFIX=$(grep "\$table_prefix" $WPCONFIG | cut -d \' -f 2)

# Create database
echo "Creating database $DBNAME"
mysql -u root -e "CREATE DATABASE $DBNAME;" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Database $DBNAME created."
else
  echo "Error occor while creating database"
  exit
fi

# Create username
echo "Creating database user: $DBUSER"
mysql -u root -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Database user $DBUSER created."
else
  echo "Error occor while creating database user"
  exit
fi

# Grant permisssion to the database
echo "Granting permission on $DBNAME to $DBUSER"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Granted permission on $DBNAME to $DBUSER."
else
  echo "Error occor while granting permission to $DBNAME"
  exit
fi

# Import database
echo "Importing Database $DBNAME"
mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Imported database from file $DBFILE to $DBNAME."
else
  echo "Error occor while importing database $DBNAME from $DBFILE"
  exit
fi

# Configure database username in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database username in wp-config.php"
  sed -i "/DB_USER/s/'[^']*'/'$DBUSER'/2" $WPCONFIG  2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "Configured database user $DBUSER to wp-config.php."
  else
    echo "Error occor while configuring database username"
    exit
  fi
fi

# Configure database password in wp-config.php
if [[ ($# == 4 || $# == 5) ]]
then
  echo "Configuring database password in wp-config.php"
  sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPASS'/2" $WPCONFIG 2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "Configured database password $DBPASS to wp-config.php."
  else
    echo "Error occor while configuring database password"
    exit
  fi
fi

rm $DBFILE 2>> "error.log"
if [[ $? == 0 ]]
then
  echo "Removed imported file $DBFILE."
else
  echo "Error occor while removing $DBFILE"
  exit
fi

# Configure Site URL
# Get current site URL
#ORIGINALURL=$(sudo wp option get siteurl --path=$WPDIR --allow-root)
QUERY="SELECT option_value FROM ${DBPREFIX}options WHERE option_id=1;"
ORIGINALURL=$(mysql -u $DBUSER $DBNAME -p$DBPASS -e "$QUERY")  2>> "error.log"
ORIGINALURL=$(echo $ORIGINALURL | grep -oP '\s(.*)$')
echo "current site url is: $ORIGINALURL"

if [[ ($# == 3) ]]; then NEWURL=$3; fi
if [[ ($# == 5) ]]; then NEWURL=$5; fi
if [[ ! -z $NEWURL ]]
then
  wp search-replace $ORIGINALURL $NEWURL --path=$WPDIR --all-tables --allow-root 2>> "error.log"
  if [[ $? == 0 ]]
  then
    echo "site url changed to $NEWURL"
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










