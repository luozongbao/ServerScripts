#! /bin/bash

WORKINGPATH=''
MYSQLROOTPASSWORD=''
WORDPRESSPATH=''
DBNAME=''
DBPASS=''
DBHOST=''
DBUSER=''

checkForWpconfig(){
    # check if extracted archive is a wordpress archive
    if [[ ! -e wp-config.php ]]
    then
        echo "Could not find wp-config.php, this path may not be a wordpress path"
        exit
    fi
}

getDatabaseInformation(){
    # get database name
    DBNAME=$(grep DB_NAME wp-config.php | cut -d \' -f 4)
    # get database username
    DBUSER=$(grep DB_USER wp-config.php | cut -d \' -f 4)
    # get database username
    DBPASS=$(grep DB_PASSWORD wp-config.php | cut -d \' -f 4)
    # get database username
    DBHOST=$(grep DB_HOST wp-config.php | cut -d \' -f 4)
}

dropDatabase(){
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
}

dropDatabaseOnHost(){
    while true;
    do
        read -p "This will delete database:$DBNAME database user:$DBUSER, continue? [Y/N]: " CHOICE
        case $CHOICE in 
            [yY]|[yY][eE][sS])
                # Drop database
                mysql -h $DBHOST -u root -p$MYSQLROOTPASSWORD -e "DROP DATABASE $DBNAME;" 2>> error.log
                if [[ $? == 0 ]]
                then
                    echo "Database $DBNAME dropped."
                else
                    echo "Error occur while dropping database $DBNAME"
                fi
                # drop database user
                mysql -h $DBHOST -u root -p$MYSQLROOTPASSWORD -e "DROP USER $DBUSER;" 2>> error.log
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
}

deleteWordpress(){
    while true;
    do
        read -p "This will delete wordpress folder $WORDPRESSPATH , continue? [Y/N]: " CHOICE
        case $CHOICE in 
            [yY]|[yY][eE][sS])
                cd $WORDPRESSPATH
                cd ..
                rm -r $WORDPRESSPATH 2>> error.log
                if [[ $? == 0 ]]
                then
                    echo "Directory $WORDPRESSPATH deleted."
                else
                    echo "Error occur while deleting path $WORDPRESSPATH"
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
}

removeEmptyErrorLogFile(){
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
}

main(){
    cd $WORDPRESSPATH
    checkForWpconfig
    getDatabaseInformation
    if [ $(echo $DBHOST | tr '[:lower:]' '[:upper:]') == "LOCALHOST" ]
    then
        dropDatabase
    else
        if [ -z $MYSQLROOTPASSWORD ]
        then
            echo "mysql root password is required"
            exit
        else
            dropDatabaseOnHost
        fi
        
    fi
    deleteWordpress
    removeEmptyErrorLogFile

}



if [ -z "${1}" ]; then
    help
    exit 1
fi
while [ ! -z "${1}" ]; do
    case ${1} in
        -[dD] | -directory | --directory) shift
            if [ -z "${1}" ]; then
                echo "missing define directory"
                exit 1
            fi
            WORDPRESSPATH="${1}"
            if [ ! -d $WORDPRESSPATH ]
            then
                echo "Invalid path provided"
                exit
            fi 
            WORKINGPATH=$(pwd)
            cd $WORDPRESSPATH
            WORDPRESSPATH=$(pwd)
            ;;   
        -[rR] | -rootpassword | --rootpassword) shift
            if [ -z "${1}" ]; then
                echo "missing define root password"
                exit 1
            fi
            MYSQLROOTPASSWORD="${1}"
            ;;         
        *) 
            help
            exit 1
            ;;              
    esac
    shift
done

main