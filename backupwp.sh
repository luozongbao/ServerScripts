#!/bin/bash

# This checks if the number of arguments is correct
# If the number of arguments is incorrect ( $# != 2) print error message and exit
if [[ $# != 2 ]]
then
  echo "backupwp.sh target_directory_name destination_directory_name"
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


# generate timestamp
currentTS=$(date +%Y%m%d%H%M)

# backup directory name
backupDirectoryName=$( echo $targetDirectory | rev | cut -d "/" -f1 | rev)

# generate backup file name
backupFileName="${currentTS}-$backupDirectoryName.zip"



# Retrieve Database Name
DBName=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4)

echo "Exporting Database ..."

# Export Database to file
mysqldump -u root $DBName > "${DBName}.sql" 

# zip entire directory

echo "Compressing and Archiving files"

zip -r $backupFileName $backupDirectoryName "${DBName}.sql"

# Move to Destination Path

mv $backupFileName $destinationPath

# Congratulations! You completed the final project for this course!

# remove zipped database file
rm "${DBNAME}.sql"



