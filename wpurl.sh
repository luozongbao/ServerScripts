#! /bin/bash

WPCONFIG=""
WORDPRESSPATH=""
URL=""
ORIGINALUSR=""
ORIGINALDB=""
ORIGINALPASS=""
DBPREF=""
ORIGINALURL=""

help(){
    echo "-w <wordpress> : define wordpress path"
    echo "-u <url> : define new url"
}

CheckWordpressPath(){
    if [ -z $WPCONFIG ]
    then

        if [ -f "$(pwd)/wp-config.php" ]
        then
        
            WORDPRESSPATH=$(pwd)
            WPCONFIG="$(pwd)/wp-config.php"

        else

            echo "please define wordpress path"
            exit

        fi
    fi
}

RetrieveDatabaseName(){
    # echo "Retrieving Database Name"
    ORIGINALDB=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 
    # echo "Database Name '$ORIGINALDB'"

}

RetrieveDatabaseUser(){
    # echo "Retrieving Database Username"
    ORIGINALUSR=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 
    # echo "Database User '$ORIGINALUSR'"
}

RetrieveDatabasePassword(){
    # echo "Retrieving Original Database Password"
    ORIGINALPASS=$(cat $WPCONFIG | grep DB_PASSWORD | cut -d \' -f 4) 
}

function RetrieveTablePrefix
{
    # echo "Retrieve Table prefix"
    DBPREF=$(cat $WPCONFIG | grep "\$table_prefix" | cut -d \' -f 2) 
    # echo "Table Prefix '$DBPREF'"
}

RetrieveURL(){

    URLCOMMAND="SELECT option_value FROM ${DBPREF}options WHERE option_id=1;"
    # echo $URLCOMMAND
    ORIGINALURL=$(mysql -u $ORIGINALUSR --password="$ORIGINALPASS" -e "$URLCOMMAND" $ORIGINALDB) 
    ORIGINALURL=$(echo $ORIGINALURL | grep -oP '\s(.*)$'| xargs)
    echo "SYSTEM URL: $ORIGINALURL"
}

main(){
    CheckWordpressPath
    RetrieveDatabaseName
    RetrieveDatabaseUser
    RetrieveDatabaseUser
    RetrieveTablePrefix
    RetrieveURL

    if [ ! -z $URL ]
    then
        wp search-replace $ORIGINALURL $URL --all-tables --path="$WORDPRESSPATH"
        if [ $? == 0 ]
        then

            echo "URL Changed to: $URL"

        fi 
    fi


}

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
        -[uU] | -url | --url) shift
            if [ -z "${1}" ]; then
                echo "define url missing"
                exit 1
            fi
            URL=$(echo "${1}" | grep -oP "(https:\/\/www\.|http:\/\/www\.|https:\/\/|http:\/\/)?[a-zA-Z0-9]{2,}\.[a-zA-Z0-9]{2,}\.[a-zA-Z0-9]{2,}(\.[a-zA-Z0-9]{2,})?")
            if [ -z $URL ]
            then
                echo "invalid URL."
                exit 1
            else
                echo $URL
            fi

            ;;          
        *) 
            help
            exit 1
            ;;              
    esac
    shift
done

main
