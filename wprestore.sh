#!/bin/bash

WORKINGPATH=$(pwd)
TIMESTAMP=$(date +%Y%m%d%H%M)
ERRORLOG="$WORKINGPATH/${TIMESTAMP}-error.log"
ARCHIVEFILE=''
DESTINATIONPATH=''
DBHOST=''
MYSQLROOTPASSWORD=''
NEWURL=''
ARCHIVEPATH=''
ARCHIVEFILENAME=''
DBFILE=''
WPDIR=''
WPCONFIG=''
WORDPRESSFOLDER=''
DBNAME=''
DBUSER=''
DBPASS=''
DBPREFIX=''
ORIGINALURL=''

help(){
    echo "-a <archive>: define archive to be extracted and resotre"
    echo "-d <directory>: define a directory extracted archive folder should be in"
    echo "-h <hostname>: define mysql hostname or IP address if needed"
    echo "-r <password>: mysql client root password is needed when using mysql on other host"
    echo "-u <url>: define new site url (this option will not work if wp-cli has not been installed)"
}

echovalues(){
    echo "Archive File : $ARCHIVEFILE"
    echo "Destination Path : $DESTINATIONPATH"
    echo "Mysql DBHost : $DBHOST" 
    echo "Mysql Root Password : $MYSQLROOTPASSWORD"
    echo "New URL : $NEWURL"
}

checkArchive(){
    # get archive database dump file name
    DBFILE=$(unzip -l $ARCHIVEFILENAME | grep ".sql" | grep -oP "\S+\.sql$" | grep -oP "^[^\s\/]+\.sql$") 2>> $ERRORLOG
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
    WPCONFIG=$(unzip -l $ARCHIVEFILENAME | grep "\/wp-config.php") 2>> $ERRORLOG
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
    WORDPRESSFOLDER=$(echo $WPCONFIG | grep -oP "\S+\/")
}

extractArchive(){
    # Extracting file
    echo "Extracting file $ARCHIVEFILENAME"
    unzip -o -q  $ARCHIVEFILENAME 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Extracted file from archive $ARCHIVEFILENAME."
    else
        echo "Error occor while extracting archive file"
        exit
    fi
    WPDIR="$ARCHIVEPATH/$WORDPRESSFOLDER/"
    WPCONFIG="$ARCHIVEPATH/$WORDPRESSFOLDER/wp-config.php"
}

movePath(){
    # Move folder to destination Path
    cd $ARCHIVEPATH
    
    if [[ -z $DESTINATIONPATH ]]; then DESTINATIONPATH=$WORKINGPATH; fi

    mv $WORDPRESSFOLDER $DESTINATIONPATH 2>> $ERRORLOG
    
    if [[ $? == 0 ]]
    then
        echo "$WORDPRESSFOLDER moved to $DESTINATIONPATH."
    else
        echo "Error occor while moving $WORDPRESSFOLDER to $DESTINATIONPATH"
        exit
    fi
    WPDIR="$DESTINATIONPATH/$WORDPRESSFOLDER/"
    WPCONFIG="$DESTINATIONPATH/$WORDPRESSFOLDER/wp-config.php"
}

accquireDatabaseInformation(){
    # acquire databasename
    DBNAME=$(grep DB_NAME $WPCONFIG | cut -d \' -f 4)
    # acquire database username
    DBUSER=$(grep DB_USER $WPCONFIG | cut -d \' -f 4)
    # acquire database user password
    DBPASS=$(grep DB_PASSWORD $WPCONFIG | cut -d \' -f 4)
    # acquire database Prefix
    DBPREFIX=$(grep "\$table_prefix" $WPCONFIG | cut -d \' -f 2)
    # if [ -z $DBHOST ]
    # then
    #     # acquire database Host
    #     DBHOST=$(grep DB_HOST $WPCONFIG | cut -d \' -f 4)
    # fi 
}

workDatabase(){
    # Create database
    echo "Creating database $DBNAME"
    mysql -u root -e "CREATE DATABASE $DBNAME;" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Database $DBNAME created."
    else
        echo "Error occor while creating database"
        exit
    fi

    # Create username
    echo "Creating database user: $DBUSER"
    mysql -u root -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Database user $DBUSER created."
    else
        echo "Error occor while creating database user"
        exit
    fi

    # Grant permisssion to the database
    echo "Granting permission on $DBNAME to $DBUSER"
    mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Granted permission on $DBNAME to $DBUSER."
    else
        echo "Error occor while granting permission to $DBNAME"
        exit
    fi

    # Import database
    echo "Importing Database $DBNAME"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Imported database from file $DBFILE to $DBNAME."
    else
        echo "Error occor while importing database $DBNAME from $DBFILE"
        exit
    fi

}

workDatabaseOnDBHost(){
    # Create database
    echo "Creating database $DBNAME"
    mysql -h $DBHOST -u root --password="$MYSQLROOTPASSWORD" -e "CREATE DATABASE $DBNAME;" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Database $DBNAME created."
    else
        echo "Error occor while creating database"
        exit
    fi

    # Create username
    echo "Creating database user: $DBUSER"
    mysql -h $DBHOST -u root --password="$MYSQLROOTPASSWORD" -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Database user $DBUSER created."
    else
        echo "Error occor while creating database user"
        exit
    fi

    # Grant permisssion to the database
    echo "Granting permission on $DBNAME to $DBUSER"
    mysql -h $DBHOST -u root --password="$MYSQLROOTPASSWORD" -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Granted permission on $DBNAME to $DBUSER."
    else
        echo "Error occor while granting permission to $DBNAME"
        exit
    fi

    # Import database
    echo "Importing Database $DBNAME"
    mysql -h $DBHOST -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Imported database from file $DBFILE to $DBNAME."
    else
        echo "Error occor while importing database $DBNAME from $DBFILE"
        exit
    fi


}

removeImportedDatabaseFile(){
    rm $DBFILE 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Removed imported file $DBFILE."
    else
        echo "Error occor while removing $DBFILE"
        exit
    fi
}

configWpconfig(){
    echo "Configuring database host in wp-config.php"
    sed -i "/DB_HOST/s/'[^']*'/'$DBHOST'/2" $WPCONFIG 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "Configured database host $DBHOST to wp-config.php."
    else
        echo "Error occor while configuring database password"
        exit
    fi
}

currentURL(){
    # Get current site URL
    QUERY="SELECT option_value FROM ${DBPREFIX}options WHERE option_id=1;"
    ORIGINALURL=$(mysql -h $DBHOST -u $DBUSER $DBNAME -p$DBPASS -e "$QUERY")  2>> $ERRORLOG
    ORIGINALURL=$(echo $ORIGINALURL | grep -oP '\s(.*)$')
    echo "current site url is: $ORIGINALURL"

}

updateURL(){
    # Update site URL
    wp search-replace $ORIGINALURL $NEWURL --path=$WPDIR --all-tables --allow-root 2>> $ERRORLOG
    if [[ $? == 0 ]]
    then
        echo "site url updated to $NEWURL"
    else 
        echo "Error occor while configuring site url"
        exit
    fi
}

removeEmptyErrorLogFile(){
    # Remove empty error log file
    if [[ ($(wc -c $ERRORLOG | cut -d " " -f 1) == 0) ]]
    then
        rm $ERRORLOG
        if [[ $? == 0 ]]
        then
            echo "No error found."
        else
            echo "Error occor while removing error.log"
            exit
        fi
    else
        echo -e "\nError during processes\n*******************"
        cat $ERRORLOG
    fi
}

main(){
    # echovalues
    if [[ -z $ARCHIVEFILE ]]
    then
        echo "Archive file path must be defined for script to work"
        exit 
    else
        cd $ARCHIVEPATH
        checkArchive
        extractArchive
    fi

    movePath

    accquireDatabaseInformation

    if [[ $(echo $DBHOST | tr '[:lower:]' '[:upper:]') == "LOCALHOST" || -z $DBHOST ]]
    then
        workDatabase
        removeImportedDatabaseFile
    else
        if [ -z $MYSQLROOTPASSWORD ]
        then
            echo "Mysql Root Password must be define while access mysql on $DBHOST"
            exit 
        else
            workDatabaseOnDBHost
            removeImportedDatabaseFile
            configWpconfig
        fi
    fi 



    if [[ -z $NEWURL ]]
    then
        currentURL
    else
        updateURL
    fi

    removeEmptyErrorLogFile

    echo "All restore process done."

}

if [ -z "${1}" ]; then
    help
    exit 1
fi
while [ ! -z "${1}" ]; do
    case ${1} in
        -[hH] | -host | --host) shift
            if [ -z "${1}" ]; then
                echo "missing define mysql DBhost value"
                exit 1
            fi
            DBHOST="${1}"
            ;;
        -[aA] | -archive | --archive) shift
            if [ -z "${1}" ]; then
                echo "missing define archive file path"
                exit 1
            fi
            ARCHIVEFILE="${1}"
            if [[ -f $ARCHIVEFILE ]]
            then
                ARCHIVEPATH=$(dirname $ARCHIVEFILE)
                ARCHIVEFILENAME=$(basename $ARCHIVEFILE)
                cd $WORKINGPATH
                cd $ARCHIVEPATH
                ARCHIVEPATH=$(pwd)
                cd $WORKINGPATH
            else
                echo "Invalid Archive file path provided"
                exit 1
            fi
            ;;
        -[dD] | -destination | --destination) shift
            if [ -z "${1}" ]; then
                echo "missing define destination path"
                exit 1
            fi
            DESTINATIONPATH="${1}"
            if [[ -d $DESTINATIONPATH ]]
            then
                cd $WORKINGPATH
                cd $DESTINATIONPATH
                DESTINATIONPATH=$(pwd)
                cd $WORKINGPATH
            else
                echo "Invalid destination path provided $DESTINATIONPATH"
                exit
            fi 
            ;;
        -[rR] | -rootpassword | --rootpassword) shift
            if [ -z "${1}" ]; then
                echo "missing define root password"
                exit 1
            fi
            MYSQLROOTPASSWORD="${1}"
            ;;      
        -[uU] | -url | --url) shift
            if [ -z "${1}" ]; then
                echo "missing define new url"
                exit 1
            fi
            NEWURL="${1}"
            ;;      
        *) 
            help
            exit 1
            ;;              
    esac
    shift
done

# Check if run as root
# if [ $(cat owner.txt | cut -d ':' -f 1) != $(whoami) && $EUID != 0 ]
# then
#     echo "Please run as root."
#     echo "root access is used to create database and database user in this script"
#     exit
# fi

# Check if mysql is installed
if [[ -z $(command -v mysql) ]]
then
    echo "mysql is not installed"
    echo "system should at least have mysql client installed in order for script to connect to external database."
    exit
fi

# Check if WP-CLI is installed
if [ ! -z $NEWURL ]
then
    if [[ -z $(ls /usr/local/bin/ | grep -E "^wp$") ]]
    then
        echo "Couldn't perform url change since wp-cli has not been installed"
        exit 
    fi
fi

main

