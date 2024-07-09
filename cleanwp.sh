#! /bin/bash

# check argument for the process to run
if [[ $# != 1 ]]
then
  echo -e "cleanwp.sh [wordpress_folder]"
  exit
fi

# Check if run as root
if (( $EUID != 0 )) 
then
    echo "Please run as root."
    echo "root access is used to delete database and database user and folder in this script"
    exit
fi

# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -d $1 ]] 
then
  echo "Invalid path provided"
  exit
fi

ORIGINPATH=$(pwd)
cd $1
WPPATH=$(pwd)

# check if extracted archive is a wordpress archive
if [[ ! -e wp-config.php ]]
then
  echo "Could not find wp-config.php, this path may not be a wordpress path"
  exit
fi

# get database name
DBNAME=$(grep DB_NAME wp-config.php | cut -d \' -f 4)
# get database username
DBUSER=$(grep DB_USER wp-config.php | cut -d \' -f 4)
# get database username
DBPASS=$(grep DB_PASSWORD wp-config.php | cut -d \' -f 4)

while true;
do
    read -p "This will delete database:$DBNAME database user:$DBUSER, continue? [Y/N]: " CHOICE
    case $CHOICE in 
        [yY]|[yY][eE][sS])
            # Drop database
            mysql -u root -e "DROP DATABASE $DBNAME;" 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Database $DBNAME dropped."
            else
                echo "Error occur while dropping database $DBNAME"
            fi
            # drop database user
            mysql -u root -e "DROP USER $DBUSER;" 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Database user $DBUSER dropped."
            else
                echo "Error occur while dropping database user $DBUSER"
            fi
            break
            ;;
        [nN]|[nN][oO])
            break
            ;;
        *) 
            echo "Please, answer Yes or No"
        ;;
    esac
done


while true;
do
    read -p "This will delete wordpress folder $WPPATH , continue? [Y/N]: " CHOICE
    case $CHOICE in 
        [yY]|[yY][eE][sS])
            cd $WPPATH
            cd ..
            rm -r $WPPATH 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Directory $WPPATH deleted."
            else
                echo "Error occur while deleting path $WPPATH"
            fi
            break
            ;;
        [nN]|[nN][oO])
            break
            ;;
        *) 
            echo "Please, answer Yes or No"
        ;;
    esac
done

# Remove empty error log file
if [[ ($(wc -c error.log | grep -oP "\d") == 0) ]]
then
  rm error.log
  if [[ $? == 0 ]]
  then
    echo "Clean wordpress system done with no error"
  else
    echo "Error occor while removing error.log"
    exit
  fi
fi


