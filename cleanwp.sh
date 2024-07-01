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

originPath=$(pwd)
cd $1
wpPath=$(pwd)

# check if extracted archive is a wordpress archive
if [[ ! -e wp-config.php ]]
then
  echo "Could not find wp-config.php, this path may not be a wordpress path"
  exit
fi

# get database name
DBName=$(cat wp-config.php | grep DB_NAME | cut -d \' -f 4)
# get database username
DBUser=$(cat wp-config.php | grep DB_USER | cut -d \' -f 4)
# get database username
DBPass=$(cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4)

while true;
do
    read -p "This will delete database:$DBName database user:$DBUser, continue? [Y/N]: " Choice
    case $Choice in 
        [yY]|[yY][eE][sS])
            # Drop database
            mysql -u root -e "DROP DATABASE $DBName;" 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Database $DBName dropped."
            else
                echo "Error occur while dropping database $DBName"
            fi
            # drop database user
            mysql -u root -e "DROP USER $DBUser;" 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Database user $DBUser dropped."
            else
                echo "Error occur while dropping database user $DBUser"
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
    read -p "This will delete wordpress folder $wpPath , continue? [Y/N]: " Choice
    case $Choice in 
        [yY]|[yY][eE][sS])
            cd $wpPath
            cd ..
            rm -r $wpPath 2>> error.log
            if [[ $? == 0 ]]
            then
                echo "Directory $wpPath deleted."
            else
                echo "Error occur while deleting path $wpPath"
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


