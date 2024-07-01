#! /bin/bash

if [[ $# != 1 ]]
then
  echo -e "cleanwp.sh [wordpress_folder]"
  exit
fi

# This checks if argument 1 and argument 2 are valid directory paths
if [[ ! -d $1 ]] 
then
  echo "Invalid archive file path provided"
  exit
fi

originPath=$(pwd)
cd $1
wpPath=$(pwd)

echo "Working Path: $originPath"
echo "Wordpress Path: $wpPath"

# check if extracted archive is a wordpress archive
if [[ ! -e wp-config.php ]]
then
  echo "Could not find wp-config.php"
  exit
fi

# get database name
DBName=$(cat wp-config.php | grep DB_NAME | cut -d \' -f 4)
# get database username
DBUser=$(cat wp-config.php | grep DB_USER | cut -d \' -f 4)

while true;
do
    read -p "This will delete database:$DBName database user:$DBUser, continue? [Y/N]: " Choice
    case $Choice in 
        [yY]|[yY][eE][sS])
            # Drop database
            mysql -u root -e "DROP DATABASE $DBName;"
            if [[ $? == 0 ]]
            then
                echo "Database $DBName dropped: DONE"
            else
                echo "Error occur while dropping database $DBName"
                exit
            fi
            # drop database user
            mysql -u root -e "DROP USER $DBUser;"
            if [[ $? == 0 ]]
            then
                echo "Database user $DBUser dropped: DONE"
            else
                echo "Error occur while dropping database user $DBUser"
                exit
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
            rm -r $wpPath 
            if [[ $? == 0 ]]
            then
                echo "Directory $wpPath deleted: DONE"
            else
                echo "Error occur while deleting path $wpPath"
                exit
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



