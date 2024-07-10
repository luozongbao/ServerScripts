#!/bin/bash

WORKINGPATH=$(pwd)
TIMESTAMP=$(date +%Y%m%d%H%M)
ERRORLOG="$WORKINGPATH/${TIMESTAMP}-error.log"
WORDPRESSPATH=''
DESTINATIONPATH=''
WPCONFIG=''
DBUSER=''
DBPASS=''
DBNAME=''
DBHOST=''

WORDPRESSDIRECTORYNAME=''
BACKUPFILENAME=''

help(){
    echo "-w <wordpress> : define wordpress path to be backup"
    echo "-d <destination> : define backup storage path"
}

accquireDatabaseInformation(){
    # acquire database username
    DBUSER=$(grep DB_USER $WPCONFIG | cut -d \' -f 4)
    # acquire database user password
    DBPASS=$(grep DB_PASSWORD $WPCONFIG | cut -d \' -f 4)
    # Retrieve Database Name
    DBNAME=$(grep DB_NAME $WPCONFIG | cut -d \' -f 4)
    # Retrieve Database host
    DBHOST=$(grep DB_HOST $WPCONFIG | cut -d \' -f 4)

}

workingVariable(){
    # get Backup Directory Name
    WORDPRESSDIRECTORYNAME=$( echo $WORDPRESSPATH | rev | cut -d "/" -f1 | rev)
    # generate backup file name
    BACKUPFILENAME="${TIMESTAMP}-$WORDPRESSDIRECTORYNAME.zip"
}

displayVariables(){
    echo "Database Name: $DBNAME"
    echo "Database User: $DBUSER"
    echo "Database Host: $DBHOST"
    echo "Database Pass: $DBPASS"
}

exportDatabase(){
    # Export Database to file
    echo "Exporting Database $DBNAME"
    mysqldump -h $DBHOST -u $DBUSER --password="$DBPASS" $DBNAME > ${DBNAME}.sql 2>> $ERRORLOG
    if [ $? == 0 ]
    then
        echo "Database $DBNAME is exported to file ${DBNAME}.sql."
    else
        echo "Error occur while dumping database ${DBNAME} to file ${DBNAME}.sql"
        exit 
    fi
}

ownerBackup(){
    stat -c '%U:%G' $WORDPRESSPATH > owner.txt
}

archivingFiles(){
    # zip entire directory
    echo "Compressing and Archiving files to $BACKUPFILENAME"
    # zip -r -q $BACKUPFILENAME $WORDPRESSDIRECTORYNAME "${DBNAME}.sql" owner.txt 2>> $ERRORLOG
    zip -r -q $BACKUPFILENAME $WORDPRESSDIRECTORYNAME "${DBNAME}.sql" 2>> $ERRORLOG
    if [ $? == 0 ]
    then
        echo "Backup file $BACKUPFILENAME created."
    else
        echo "Error occur compressing backup to file $BACKUPFILENAME"
        exit 
    fi
}

moveArchivetoDestination(){
    # Move to Destination Path

    if [[ -z $DESTINATIONPATH ]]; then DESTINATIONPATH=$WORKINGPATH; fi

    mv $BACKUPFILENAME $DESTINATIONPATH 2>> $ERRORLOG
    if [ $? == 0 ]
    then
        echo "backup file located at $DESTINATIONPATH/$BACKUPFILENAME"
    else
        echo "Error occur compressing backup to file $BACKUPFILENAME"
        exit 
    fi
}

removeUnnecessaryFiles(){
    # remove zipped database file
    echo "Removing no longer needed file"
    # rm owner.txt 2>> $ERRORLOG
    rm "${DBNAME}.sql" 2>> $ERRORLOG
    if [ $? != 0 ]
    then
        echo "Error deleting file ${DBNAME}.sql"
        exit 
    fi

    # Remove empty error log file
    if [[ ($(wc -c $ERRORLOG | cut -d " " -f 1) == 0) ]]
    then
        rm $ERRORLOG
        if [[ $? == 0 ]]
        then
            echo "No error found."
        else
            echo "Error occor while removing $ERRORLOG"
            exit
        fi
    else
        echo -e "\nError during processes\n*******************"
        cat $ERRORLOG
    fi

}

main(){
    cd $WORKINGPATH
    accquireDatabaseInformation
    workingVariable
    cd $WORDPRESSPATH
    cd ..
    # displayVariables
    exportDatabase
    # ownerBackup
    archivingFiles
    moveArchivetoDestination
    removeUnnecessaryFiles
    echo "All backup process done"
}

if [ -z "${1}" ]; then
    help
    exit 1
fi
while [ ! -z "${1}" ]; do
    case ${1} in
        -[wW] | -wordpress | --wordpress) shift
            if [ -z "${1}" ]; then
                echo "missing define wordpress directory"
                exit 1
            fi
            WORDPRESSPATH="${1}"
            cd $WORKINGPATH
            if [ ! -d $WORDPRESSPATH ]
            then
                echo "Invalid wordpress path provided"
                exit
            fi 
            cd $WORDPRESSPATH
            WORDPRESSPATH=$(pwd)
            WPCONFIG="$WORDPRESSPATH/wp-config.php"
            if [ ! -f $WPCONFIG ]
            then
                echo "wp-config.php notfound at $WPCONFIG"
                exit
            fi 
            ;;   
        -[dD] | -destination | --destination) shift
            if [ -z "${1}" ]; then
                echo "missing define destination directory"
                exit 1
            fi
            DESTINATIONPATH="${1}"
            cd $WORKINGPATH
            if [ ! -d $DESTINATIONPATH ]
            then
                echo "Invalid destination path provided"
                exit
            fi 
            cd $DESTINATIONPATH
            DESTINATIONPATH=$(pwd)
            ;;          
        *) 
            help
            exit 1
            ;;              
    esac
    shift
done

main