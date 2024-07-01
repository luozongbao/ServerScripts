#!/bin/bash

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
targetDirectory=$1
destinationDirectory=$2

# getting original path
originalPath=$(pwd)

# define destiantion path
cd $destinationDirectory
destinationPath=$(pwd)

# define target path
cd $originalPath
cd $targetDirectory
targetPath=$(pwd)
WPCONFIG="$targetPath/wp-config.php"
cd ..

# check if it is wordpress folder
if [ ! -e $WPCONFIG ]
then
  echo "$targetPath is not a wordpress directory"
  exit
fi

# acquire database username
DBUser=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4)
# acquire database user password
DBPass=$(cat $WPCONFIG | grep DB_PASSWORD | cut -d \' -f 4)
# Retrieve Database Name
DBName=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4)

# generate timestamp
currentTS=$(date +%Y%m%d%H%M)

# get Backup Directory Name
backupDirectoryName=$( echo $targetPath | rev | cut -d "/" -f1 | rev)

# generate backup file name
backupFileName="${currentTS}-$backupDirectoryName.zip"





echo "Exporting Database ..."

# Export Database to file
mysqldump -u $DBUser $DBName --password="$DBPass" > "${DBName}.sql" 
if [ ! $? == 0 ]
then
  echo "Error occur at mysql dumping database ${DBName} to file ${DBName}.sql"
  exit 
fi

echo "mysql dumping database ${DBName} to file ${DBName}.sql: Done"

# zip entire directory

echo "Compressing and Archiving files to $backupFileName"

zip -r -q $backupFileName $backupDirectoryName "${DBName}.sql"
if [ ! $? == 0 ]
then
  echo "Error occur compressing backup to file $backupFileName"
  exit 
fi

echo "Backup compressed to $backupFileName: Done"

# Move to Destination Path
mv $backupFileName $destinationPath
echo -e "backup file located at $destinationPath/$backupFileName"
echo "All backup process done"

# remove zipped database file
rm "${DBName}.sql"
if [ ! $? == 0 ]
then
  echo "Error deleting file ${DBName}.sql"
  exit 
fi




