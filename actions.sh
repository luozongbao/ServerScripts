#! /bin/bash
###################################################################
# Script Name	: Wordpress webserver actions                                                                                     
# Description	: Script to set new server                                                                 
# Args         	:               
# Date          : 20210205
# Version       : 1.0                                                                                
# Author       	: Atipat Lorwongam                                           
# Email        	: asecondsun@outlook.com                               
###################################################################


FILELOC=""
ORIGINALDIR=""
FILEDIR=""
DBNAME=""
DBUSER=""
DBPASS=""
DBPREF=""
URL=""
CURDIR=$(pwd)
FINAL=""
DBFILE=""
BKFILE=""
BKFINAL=""
WPCONFIG=""

SUCCESS=""
FAILED=""
WEBSERVER=""
RGXNUMERIC='^[0-9]+$'

RESULTFILE="$CURDIR/result.log"
ERRORFILE="$CURDIR/error.log"

function initialize
{
    if [ -d /usr/local/lsws ]
    then
        FILELOC=/usr/local/lsws/sites
        if [ ! -e $FILELOC ]
        then
            mkdir $FILELOC
        fi
        WEBSERVER="OLS"
    fi
    if [ -d /etc/apache2 ]
    then
        FILELOC=/var/www
        WEBSERVER="Apache"
    fi
    if [ -d /etc/nginx ]
    then
        FILELOC=/var/www
        WEBSERVER="Nginx"
    fi
}

function display
{
    HLINE="****************************************************************************************************"
    EMPTYLINE="*                                                                                                  *"
    echo "$HLINE"
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "*               $1                   "
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "$HLINE"
    echo
}

function showresult
{
    HLINE="****************************************************************************************************"
    echo "$HLINE"
    echo "*               $1                   "
    echo "$HLINE"
    echo 
    echo $1 >> $RESULTFILE
}

function pauseandclear
{
    read -p "Press ENTER to continue" ENTER
    clear
}

function checkOptional
{
    PROCESSED=$?
    if [ $PROCESSED == 0 ]
    then
        # Successfully Executed
        echo "$SUCCESS"
        echo "$SUCCESS" >> $RESULTFILE
        return 0
    fi
    # Execution Failed
    echo "$FAILED"
    echo "$FAILED" >> $RESULTFILE
    return 1
}

function checkCritical
{
    PROCESSED=$?
    if [ $PROCESSED == 0 ]
    then
        # Successfully Executed
        echo "$SUCCESS"
        echo "$SUCCESS" >> $RESULTFILE

        return 0
    fi
    # Execution Failed
    showresult "$FAILED"
    echo "$FAILED"
    echo "$FAILED" >> $RESULTFILE
    exit 1
}

function CheckFileCritical
{
    if [ -e $1 ]
    then
        return 0
    fi
    showresult "$1 not found"
    exit 1
}

function getWorkingFILEDIRFromUser
{
    while [ ! -e "$FILELOC/$FILEDIR/wp-config.php" ]
    do
        read -p "Please specify wordpress directory (Type 'Exit' to cancel): " FILEDIR 
        if [ -e "$FILELOC/$FILEDIR/wp-config.php" ]
        then
            WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
            BKFILE=$FILEDIR.zip
            FINAL=latest.$FILEDIR.zip
            BKFINAL=old.$FILEDIR.zip
            break
        else
            if [[ $FILEDIR =~ [xX]|[eE][xX][iI][tT] ]]
            then
                exit 
            fi
            echo "$FILEDIR is not a valid wordpress directory"
            FILEDIR=""
        fi
    done
}

function RetrieveDatabaseName
{
    echo "Retrieving Database Name from $WPCONFIG"
    SUCCESS="Retrieved Database Name from $WPCONFIG"
    FAILED="Could not Retrieve Database Name from $WPCONFIG"
    ORIGINALDB=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>>$ERRORFILE
    checkCritical
    echo "Database Name '$ORIGINALDB'"

}

function RetrieveDatabaseUser
{
    echo "Retrieving Database Username from $WPCONFIG"
    SUCCESS="Retrieved Database User from $WPCONFIG"
    FAILED="Could not retrieve Database User from $WPCONFIG"
    ORIGINALUSR=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 2>>$ERRORFILE
    checkCritical
    echo "Database User '$ORIGINALUSR'"
}

function RetrieveDatabasePassword
{
    echo "Retrieving Original Database Password from $WPCONFIG"
    SUCCESS="Retrieved Database Password"
    FAILED="Retrieving Database Password failed"
    ORIGINALPASS=$(cat $WPCONFIG | grep DB_PASSWORD | cut -d \' -f 4) 2>>$ERRORFILE
    checkCritical
}

function RetrieveTablePrefix
{
    echo "Retrieve Table prefix"
    SUCCESS="Retrieved Table prefix"
    FAILED="Retrieving Table Prefix failed"
    DBPREF=$(cat $WPCONFIG | grep "\$table_prefix" | cut -d \' -f 2) 2>>$ERRORFILE
    checkCritical
    echo "Table Prefix '$DBPREF'"
}

function RetrieveOriginalURLFromDB
{
    RetrieveFromWPConfig

    echo "Retrieve URL from database"
    SUCCESS="Retrieved URL from database"
    FAILED="Retrieve URL from database failed"
    URLCOMMAND="SELECT option_value FROM ${DBPREF}options WHERE option_id=1;"
    ORIGINALURL=$(mysql -u root $DBNAME -e "$URLCOMMAND") 2>>$ERRORFILE
    checkCritical
    ORIGINALURL=$(echo $ORIGINALURL | grep -oP '\s(.*)$') 2>>$ERRORFILE
    SUCCESS="Extracted URL from result"
    FAILED="Extract URL from result failed"
    checkCritical
    SUCCESS="Trimed white space from URL"
    FAILED="Trim white space from URL failed"
    ORIGINALURL=$(echo $ORIGINALURL | xargs) 2>>$ERRORFILE
    checkCritical
    echo "URL: '$ORIGINALURL'"

}

function checkDBUser
{
    mysql -u root mysql -e "SELECT user FROM user WHERE user='$1';" | grep $1 2>>$ERRORFILE
    return $?
}

function checkDB
{
    mysql -u root -e "USE $1;" 2>>$ERRORFILE
    return $?
}

function getNewDBNAME
{
    checkDB $DBNAME
    while [ -z $DBNAME ] || [ $? -eq 0 ]
    do
        echo
        read -p "Please specify New Database: " DBNAME
        checkDB $DBNAME
    done
}

function getNewDBUSER
{
    checkDBUser $DBUSER
    while [ -z $DBUSER ] || [ $? -eq 0 ]
    do
        echo
        read -p "Please specify New Database User: " DBUSER
        checkDBUser $DBUSER
    done

    while [ -z $DBPASS ] 
    do
        echo
        read -p "Please specify password for $DBUSER: " DBPASS
    done
}

function RollbackFinalBackup
{

    read -p "Pleae input the Original Backup Directory: " FILEDIR
    FINAL=latest.$FILEDIR.zip
    BKFINAL=old.$FILEDIR.zip
    FINALMD5=$FINAL.md5
    BKFINALMD5=$BKFINAL.md5
    
    CheckFileCritical $BKFINAL
    echo "$BKFINAL found"

    if [ -e $FINAL ]
    then
        read -p "This will permanently remove $FINAL, continue? [y/n]: " YN
        if [[ $YN =~ [yY]|[yY][eE][sS] ]]
        then

            SUCCESS="Renamed $BKFINAL to $FINAL"
            FAILED="Rename $BKFINAL to $FINAL failed"
            mv -f $BKFINAL $FINAL 2>>$ERRORFILE
            checkCritical

            if [ -e $FINALMD5 ]
            then
                echo "Old $FINAL also associated with $FINALMD5 no longer needed, removing.. " 
                SUCCESS="Removed $FINALMD5"
                FAILED="Removing $FINALMD5 failed"
                rm $FINALMD5 2>>$ERRORFILE
                checkOptional
            fi

            if [ -e $BKFINALMD5 ]
            then
                echo "$BKFINALMD5 found, rolling back..."
                SUCCESS="Renamed $BKFINALMD5 to $FINALMD5"
                FAILED="Removing $BKFINALMD5 to $FINALMD5 failed"
                mv -f $BKFINALMD5 $FINALMD5 2>>$ERRORFILE
                checkCritical
            fi
            showresult "Rolled Back $FINAL backup"
        fi
    fi
}


function getBackupInformation
{
	echo "Collect Information for backup"
	getWorkingFILEDIRFromUser

	RetrieveDatabaseName
    DBNAME=$ORIGINALDB

	DBFILE=$DBNAME.sql


}

function getRestoreInformation
{

    read -p "Please, input backup original folder name: " ORIGINALDIR
    read -p "Please, input target directory (Blank for same as original): " FILEDIR
    read -p "Please, input target database name (Blank for same as original): " DBNAME
    read -p "Please, input target database username (Blank for same as original): " DBUSER
    read -p "Please, input target database password for '$DBUSER' (Blank for same as original): " DBPASS
    read -p "Please, input new website URL with http/https (Blank for no update): " URL
    FINAL=latest.$ORIGINALDIR.zip
    BKFINAL=old.$ORIGINALDIR.zip
    BKFILE=$ORIGINALDIR.zip

    if [ -z $FILEDIR ] || [ -z $DBNAME ]
    then
        if [ -z $FILEDIR ]
        then
            FILEDIR=$ORIGINALDIR
            echo "Recover to the same directory '$ORIGINALDIR'"
            echo "This may cause some conflict in file system of the websites"
        fi

        if [ -z $DBNAME ]
        then
            echo "This may cause some conflict between websites with the same database"
        fi

        read -p "Do you want to continue? [Y/N]: " YN
        if [[ ! $YN =~ [yY]|[yY][eE][sS] ]]
        then
            exit 
        fi
    fi
}

function getRemoveInformation
{
    getWorkingFILEDIRFromUser

    RetrieveDatabaseName
    DBNAME=$ORIGINALDB
    RetrieveDatabaseUser
    DBUSER=$ORIGINALUSR
}

# CHCEK VALID VARIABLES
function checkBackupVariables
{
    CheckFileCritical $FILELOC
	echo "Directory $FILELOC CHECKED"

	if [ -z "$FILEDIR" ];
	then
		showresult "Files Directory INPUT IS EMPTY" 
		exit 1
	fi

    CheckFileCritical $FILELOC/$FILEDIR
    echo "$FILELOC/$FILEDIR CHECKED"

	showresult "Information CHECKED."  
}

function checkRestorevariables
{

    CheckFileCritical $CURDIR/$FINAL
    echo "Original Backup $CURDIR/$FINAL Found"

    CheckFileCritical $FILELOC
    echo "$FILELOC Found"

    showresult "Variables Checked"
}


function backupbackup
{
	# BACKUP FINAL FILE
    if [ -e $FINAL ] 
    then
		echo "Found Previous Backup File '$FINAL'"
        SUCCESS="Backed up previous backup file $FINAL to $BKFINAL"
        FAILED="Backup Prevouse Backup $FINAL to $BKFINAL Failed"
		mv $FINAL $BKFINAL 2>>$ERRORFILE
        checkCritical
	fi
	# BACKUP FINAL FILE
    if [ -e $FINAL.md5 ]
	then
		echo "Found Previous Backup Hash File '$FINAL.md5'"
        SUCCESS="Backed up previous backup file $FINAL.md5 to $BKFINAL.md5"
        FAILED="Backup Prevouse Backup $FINAL.md5 to $BKFINAL.md5 Failed"
		mv $FINAL.md5 $BKFINAL.md5 2>>$ERRORFILE
        checkCritical
	fi

}

# ARCHIVING DIRECTORY
function ArchiveDirectory
{
    echo "Start Backing up $FILELOC/$FILEDIR Files"
	cd $FILELOC

    echo "Archiving $FILELOC/$FILEDIR ..."
    SUCCESS="$FILELOC/$FILEDIR Archived"
    FAILED="Archiving $FILELOC/$FILEDIR failed"
	zip -r $BKFILE $FILEDIR 2>>$ERRORFILE
    checkCritical

    SUCCESS="$FILELOC/$FILEDIR Moved to $CURDIR"
    FAILED="Moving $FILELOC/$FILEDIR failed"
	mv $BKFILE $CURDIR 2>>$ERRORFILE
    checkCritical

	cd $CURDIR

}

function CheckMD5
{
    if  [ -e $FINAL.md5 ]
    then
        echo "MD5 file found, attempt to check agaist it"
        md5sum -c ${FINAL}.md5
        if [ $? -eq 0 ]
        then
            return 0
        fi
        showresult "Backup File corrupted or not the same as encrypted MD5"
        exit 1
    fi
}

# MOVE ARCHIVED FILE TO DIRECTORY
function PrepareEnvironment
{
    if [ ! -e $FILELOC ]
    then
        SUCCESS="Created $FILELOC"
        FAILED="Creat $FILELOC failed"
        mkdir $FILELOC 2>>$ERRORFILE
        checkCritical
    fi

    CheckFileCritical $CURDIR/$FINAL
    CheckMD5
    
    echo "copying $FINAL to $FILELOC"...
    SUCCESS="Copied $FINAL to $FILELOC"
    FAILED="Copying $FINAL to $FILELOC failed"
    cp -rf $FINAL $FILELOC 2>> $ERRORFILE
    checkCritical
}

function RemoveExistedDirectory
{
    if [ -e $FILELOC/$FILEDIR ]
    then
        echo "Remove $FILELOC/$FILEDIR"
        read -p "Caution! this will delete your previous files, continue? [y/n]: " YN
        if [[ $YN =~ [nN]|[nN][oO] ]]
        then
            exit 
        fi

        echo "removing $FILELOC/$FILEDIR"
        SUCCESS="$FILELOC/$FILEDIR found and removed"
        FAILED="removing $FILELOC/$FILEDIR failed"
        rm -r $FILELOC/$FILEDIR 2>>$ERRORFILE
        checkCritical
    fi
}

function RetrieveFromWPConfig
{
    if [ -z $DBUSER ] || [ -z $DBPASS ] || [ -z $DBNAME ] || [ -z $DBPREF ]
    then

        getWorkingFILEDIRFromUser

        RetrieveTablePrefix
        RetrieveDatabaseUser
        RetrieveDatabaseName
        RetrieveDatabasePassword

        if [ -z $DBUSER ]
        then
            DBUSER=$ORIGINALUSR
        fi

        if [ -z $DBNAME ]
        then
            DBNAME=$ORIGINALDB
        fi

        if [ -z $DBPASS ]
        then
            DBPASS=$ORIGINALPASS
        fi
    fi
}

function RestoringFileDirectory
{
    cd $FILELOC

    echo "Unpacking $FINAL ..."
    SUCCESS="Unziped $FINAL Successful"
    FAILED="Unzip $FINAL failed"
    unzip -o $FINAL 2>> $ERRORFILE
    checkCritical

    TEMPDIR=TempDir$(date '+%Y%m%d%H%M%s')

    echo "Recover Directory from Backup $FILELOC/$TEMPDIR"
    SUCCESS="Recovered $BKFILE to $FILELOC/$TEMPDIR"
    FAILED="Recovered $BKFILE to $FILELOC/$TEMPDIR Failed" 
    unzip -o $BKFILE -d $FILELOC/$TEMPDIR 2>>$ERRORFILE
    checkCritical

    echo "Moving folder from $FILELOC/$TEMPDIR/$ORIGINALDIR to $FILELOC/$FILEDIR"
    SUCCESS="Placed file to $FILELOC/$FILEDIR"
    FAILED="Can not placed file to $FILELOC/$FILEDIR"
    mv $FILELOC/$TEMPDIR/$ORIGINALDIR $FILELOC/$FILEDIR 2>>$ERRORFILE
    checkCritical

    echo "Remove Temp folder $FILELOC/$TEMPDIR"
    SUCCESS="Removed $FILELOC/$TEMPDIR"
    FAILED="Removing $FILELOC/$TEMPDIR failed"
    rm -r $FILELOC/$TEMPDIR 2>>$ERRORFILE
    checkOptional

    WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
    CheckFileCritical $WPCONFIG

    RetrieveFromWPConfig

    cd $CURDIR
}

function ImportDatabase
{
    cd $FILELOC

    DBFILE=$ORIGINALDB.sql
    CheckFileCritical $DBFILE

    echo "importing database from $DBFILE"
    SUCCESS="Imported $DBFILE to database $DBNAME"
    FAILED="Importing $DBFILE to database $DBNAME failed"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>>$ERRORFILE
    checkCritical
    cd $CURDIR
}



function CreateDBUser
{
    echo "Create Database User $DBUSER"
    checkDBUser $DBUSER
    if [ $? -eq 0 ]
    then
        echo "$DBUSER already exist"
    else
        SUCCESS="Created Database User $DBUSER"
        FAILED="Creating database user $DBUSER failed"
        mysql -u root -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>>$ERRORFILE
        checkCritical
    fi
}

function DropDatabase
{
    echo "droping $DBNAME database"
    SUCCESS="Dropped database $DBNAME"
    FAILED="Droping database $DBNAME failed"
    mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE
    checkCritical
}

function createDatabase
{
    checkDB $DBNAME
    while [ $? -eq 0 ]
    do
        echo "Database $DBNAME already exist"
        read -p "Do you want to drop and replace? [y/n]: " YN
        if [[ $YN =~ [yY]|[yY][eE][sS] ]]
        then
            DropDatabase
            break
        fi
        read -p "Do you want to change new database name? [y/n]: " YN
        if [[ $YN =~ [yY]|[yY][eE][sS] ]]
        then
            $DBNAME=""
            while [ -z $DBNAME ]
            do
                read -p "Please, specify new Database Name: " DBNAME
                
            done
            checkDB $DBNAME
        fi
        
    done
    echo "Create Database $DBNAME"
    SUCCESS="Created database $DBNAME"
    FAILED="Creating database $DBNAME failed"
    mysql -u root -e "CREATE DATABASE $DBNAME;" 2>>$ERRORFILE
    checkCritical

    echo "Granting privileges for $DBNAME to $DBUSER"
    SUCCESS="Granted Privileges to $DBUSER"
    FAILED="Granting privileges to $DBUSER failed"
    mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>>$ERRORFILE
    checkCritical
}


function configurewpconfig
{
    cd $FILELOC/$FILEDIR
    if [ -z $URL ]
    then
        RetrieveOriginalURLFromDB
        URL=$ORIGINALURL
    fi
    
    if [ ! "$ORIGINALDB" == "$DBNAME" ]
    then
            echo "Database Name change, configuring $WPCONFIG"
            SUCCESS="Edited database name to ($DBNAME) in $WPCONFIG"
            FAILED="Editing Database name failed"
            sed -i "/DB_NAME/s/'[^']*'/'$DBNAME'/2" $WPCONFIG 2>>$ERRORFILE
            checkCritical
    fi

    if [ ! "$ORIGINALUSR" == "$DBUSER" ]
    then
            echo "Database username change, configuring $WPCONFIG"
            SUCCESS="Edited database username to ($DBUSER) in $WPCONFIG"
            FAILED="Editing database username in $WPCONFIG failed"
            sed -i "/DB_USER/s/'[^']*'/'$DBUSER'/2" $WPCONFIG 2>>$ERRORFILE
            checkCritical
    fi
    if [ ! "$ORIGINALPASS" == "$DBPASS" ]
    then
            echo "Database password change, configuring $WPCONFIG"
            SUCCESS="Edited database password to ($DBPASS) in $WPCONFIG"
            FAILED="Editing database password in $WPCONFIG failed"
            sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPASS'/2" $WPCONFIG 2>>$ERRORFILE
            checkCritical
    fi
    cd $CURDIR
}

function SetFolderPermisson
{
    cd $FILELOC
    if [ $WEBSERVER == "OLS" ]
    then
        echo "Adding Permission nobody:nogroup to $FILEDIR"
        SUCCESS="Setted Permission to $FILEDIR"
        FAILED="Setting Permission to $FILEDIR failed"
        chown -R nobody:nogroup $FILEDIR 2>>$ERRORFILE
        checkCritical
    elif [ $WEBSERVER == "Apache" ]
    then
        echo "Adding Permission www-data:www-data to $FILEDIR"
        SUCCESS="Setted Permission to $FILEDIR"
        FAILED="Setting Permission to $FILEDIR failed"
        chown -R www-data:www-data $FILEDIR 2>>$ERRORFILE
        checkCritical
    fi
    cd $CURDIR
}

# EXPORT DATABASE
function exportDatabase
{
	echo "Dumping Database $DBNAME to $DBFILE"
	# mysqldump -u $DBUSER --password="$DBPASS" $DBNAME > $DBFILE 2>>$ERRORFILE
    SUCCESS="Database exported to $DBFILE"
    FAILED="Exporting database failed"
	mysqldump -u root $DBNAME > $DBFILE 2>>$ERRORFILE
    checkCritical
}

# ARCHIVE BACKUP FILES
function ArchiveBackupFiles
{
	echo "Archiving files..."
    SUCCESS="Archived $BKFILE and $DBFILE to $FINAL"
    FAILED="Archiving $BKFILE and $DBFILE to $FINAL failed"
	zip $FINAL $BKFILE $DBFILE 2>>$ERRORFILE
    checkCritical

    echo "Creating MD5 Hash File"
    SUCCESS="Created MD5 checksum for $FINAL > $FINAL.md5"
    FAILED="Creating MD5 Checksum for $FINAL failed"
    md5sum $FINAL > $FINAL.md5 2>>$ERRORFILE
    checkOptional
}

function BackupRemoveUnecessaryBackFiles
{
	while true;
	do
		read -p "Remove unecessary files? [Y/N]" YN
		case $YN in [yY]|[yY][eE][sS])
			#REMOVE ARCHIVED FILES

			echo "removing unnecessary files..."
            SUCCESS="Removed $DBFILE"
            FAILED="Removing $DBFILE failed"
			rm $DBFILE 2>>$ERRORFILE
            checkOptional

            SUCCESS="Removed $BKFILE"
            FAILED="Removing $BKFILE failed"
			rm $BKFILE 2>>$ERRORFILE
            checkOptional

			break
			;;
		[nN]|[nN][oO])
			break
			;;
		*)
			echo "Please answer Yes/No"
			;;
	esac
	done	
}

function RestoreRemoveFiles
{
    cd $FILELOC
    echo "Removing $BKFILE $DBFILE $FINAL"
    SUCCESS="Removed $BKFILE $DBFLE $FINAL"
    FAILED="Removing $BKFILE $DBFILE $FINAL failed"
    rm $BKFILE $DBFILE $FINAL 2>>$ERRORFILE
    checkOptional
    cd $CURDIR
}

function RemoveFiles
{
    CheckFileCritical $FILELOC/$FILEDIR

    while true;
    do
        echo "This will remove directory $FILELOC/$FILEDIR and files within it permanently"
        read -p "Continue [Y/N]: " YN
        case $YN in
                [yY]|[yY][eE][sS])
                    RemoveExistedDirectory
                    break
                    ;;
                [nN]|[nN][oO])
                    echo "skipped removing $FILELOC/$FILEDIR"
                    break
                    ;;
                *)
                    echo "Please answer Y/N"
                    ;;
        esac
    done
}

function RemoveDatabase
{
    while true;
    do
        read -p "Remove database $DBNAME permanently [Y/N]: " YN
        case $YN in
            [yY]|[yY][eE][sS])
                echo "Removing $DBNAME"
                SUCCESS="Removed $DBNAME"
                FAILED="Removing $DBNAME failed"
                mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE
                checkCritical

                break
                ;;
            [nN]|[nN][oO])
                showresult "skipp removing database $DBNAME"
                break
                ;;
            *)
                echo "Please answer Y/N"
                ;;
        esac
    done
}

function RemoveDatabaseUser
{
    while true;
    do
            echo "Your Database User might be used with other database.  "
            read -p "Do you want to remove database user $DBUSER [Y/N]: " YN
            case $YN in
                    [yY]|[yY][eE][sS])
                        echo "Removing $DBUSER"
                        SUCCESS="Removed Database User $DBUSER"
                        FAILED="Removing database user $DBUSER failed"
                        mysql -u root -e "DROP USER $DBUSER;" 2>> $ERRORFILE
                        checkCritical

                        break
                        ;;
                    [nN]|[nN][oO])
                        echo "skipping remove database user $DBUSER"
                        break
                        ;;
                    *)
                        echo "Please answer Y/N"
                        ;;
            esac
    done
}



function discourageSearchEnging
{
    
    
    read -p "Discourage search engines from indexing the site? [y/n]: " YN
    if [[ $YN =~ [yY]|[yY][eE][sS] ]]
    then
        getWorkingFILEDIRFromUser
        cd $FILELOC/$FILEDIR
        SUCCESS="Discouraged search engines from indexing the site"
        FAILED="Discoruaging search engines failed"
        wp option set blog_public 0 --allow-root 2>> $ERRORFILE
        checkOptional
        cd $CURDIR
    fi

}

function disableThemes
{
    while true;
    do
        echo
        echo " List Themes and status for $FILELOC/$FILEDIR/wp-config.php"
        wp theme list --allow-root
        echo
        read -p "(Type 'DONE' to exit) Type theme name to activate: " THEME
        if [ "$THEME" == "DONE" ]
        then
            break
        fi
        echo "Deactivate theme $THEME"
        SUCCESS="Disabled theme $THEME"
        FAILED="Disabling theme $THEME failed"
        wp theme activate $THEME --allow-root 2>> $ERRORFILE
        checkOptional
    
    done
}

function updateThemes
{
    while true;
    do
        echo
        echo " List Themes and status for $FILELOC/$FILEDIR/wp-config.php"
        sudo wp theme list --allow-root
        echo
        read -p "Type 'DONE' to exit, Type 'ALL' update all themes, or type theme name to Update: " THEME
        if [ "$THEME" == "DONE" ]
        then
            break
        elif  [ "$THEME" == "ALL" ]
        then
            echo "Update all themes"
            SUCCESS="Updated all themes"
            FAILED="Updating all themes failed"
            wp theme update --all --allow-root 2>> $ERRORFILE
            checkOptional
        else
            echo "Updating theme $THEME"
            SUCCESS="Updated theme $THEME"
            FAILED="Updating theme $THEME failed"
            wp theme update $THEME --allow-root 2>> $ERRORFILE
            checkOptional
        fi
    done
}

function disablePlugins
{
    while true;
    do
        echo
        echo " List Plugins and status for $FILELOC/$FILEDIR/wp-config.php"
        wp plugin list --allow-root
        echo
        read -p "(Type 'DONE' to exit) Type plugin name to disable: " PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
            break
        fi
        echo "Deactivate Plugin $PLUGIN"
        SUCCESS="Disabled plugin $PLUGIN"
        FAILED="Disabling plugin $Plugin failed"
        wp plugin deactivate $PLUGIN --allow-root 2>> $ERRORFILE
        checkOptional
        
    done
}

function updatePlugins
{
    while true;
    do
        echo
        echo " List Plugins and status for $FILELOC/$FILEDIR/wp-config.php"
        sudo wp plugin list --allow-root
        echo
        read -p "Type 'DONE' to exit, Type 'ALL' update all plugins, or type plugin name to Update: " PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
            break
        elif  [ "$PLUGIN" == "ALL" ]
        then
            echo "Update all plugins"
            SUCCESS="Updated all plugins"
            FAILED="Updating all plugins failed"
            wp plugin update --all --allow-root 2>> $ERRORFILE
            checkOptional
        else
            echo "Updating plugin $PLUGIN"
            SUCCESS="Updated plugin $PLUGIN"
            FAILED="Updating plugin $PLUGIN failed"
            wp plugin update $PLUGIN --allow-root 2>> $ERRORFILE
            checkOptional
        fi
    done

}

function ManagePlugins
{
    getWorkingFILEDIRFromUser

    if [ -e $FILELOC/$FILEDIR/wp-config.php ]
    then
        cd $FILELOC/$FILEDIR
        disablePlugins
        updatePlugins
        wp plugin list --allow-root
        cd $CURDIR
    fi
}

function ManageThemes
{
    getWorkingFILEDIRFromUser

    if [ -e $FILELOC/$FILEDIR/wp-config.php ]
    then
        cd $FILELOC/$FILEDIR
        disableThemes
        updateThemes
        wp theme list --allow-root
        cd $CURDIR
    fi
}

function showURL
{
    
    RetrieveFromWPConfig


    display "homeurl and siteurl in table ${DBPREF}options is shown below"
    SELECTCOMMAND="SELECT * FROM ${DBPREF}options WHERE option_id=1 OR option_id=2;"

    mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND" >> $RESULTFILE

}

function UpdateURL
{
    echo "Modifying HomeURL and SiteURL"

    RetrieveFromWPConfig

    DBCOMMAND="UPDATE ${DBPREF}options SET option_value = '$URL' WHERE option_id =1 OR option_id=2;"
    
    echo "Updating homeURL/siteURL to $URL"
    SUCCESS="Updated homeurl/siteURL to $URL"
    FAILED="Updating homeurl/siteURL failed"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$DBCOMMAND" 2>>$ERRORFILE
    checkCritical

    showURL
}

function completeURLChanged
{

    getWorkingFILEDIRFromUser

    while [ -z $URL ]
    do
        read -p "Please input your new website url with http/https: " URL
    done
    while [ -z $ORIGINALURL ]
    do
        read -p "Do you want to retrieve original url from database? [y/n]: " YN
        case $YN in 
            [yY]|[yY][eE][sS])
            
            RetrieveOriginalURLFromDB
            break
            ;;
            [nN]|[nN][oO])
                echo "*** THIS IS IMPORTANT DO NOT MISS TYPED ***"
                echo "*** Please check and recheck before press ENTER" 
                read -p "Please input your original website url with http/https: " ORIGINALURL
            break
            ;;
            *)
                echo "Please answer with Yes or No"
            ;;
        esac
    done

    if [ ! $ORIGINALURL == $URL ]
    then
        while true;
        do
            echo "$URL (New) and $ORIGINALURL (Original)appear not to be the same"
            read -p "Do you want to update the site URL? [Y/N]: " YN
            case $YN in
                [yY]|[yY][eE][sS])
                    
                    cd $FILELOC/$FILEDIR

                    echo "Replacing $ORIGINALURL to $URL"
                    SUCCESS="Searched and Replaced $ORIGINALURL to $URL"
                    FAILED="Search and Replace $ORIGINALURL to $URL failed"
                    wp search-replace $ORIGINALURL $URL --all-tables --allow-root 2>>$ERRORFILE
                    checkCritical

                    cd $CURDIR

                    showresult "Searched and replaced URL in database $ORIGINALURL to $URL" 
                    showURL
                    break
                    ;;
                [nN]|[nN][oO])
                    break
                    ;;
                *)
                    echo "please answer yes or no"
                    ;;
            esac
        done
    fi
}

function CustomMOTD
{
    while true;
    do
        read -p "Install Custom MOTD? [Y/N]: " MOTD
        case $MOTD in 
            [yY]|[yY][eE][sS])

                echo "Updating Server"
                SUCCESS="Updated Server"
                FAILED="Update server failed" 
                apt update -y 2>>$ERRORFILE
                checkOptional

                echo "Installing ScreenFetch"
                SUCCESS="Installed screenfetch"
                FAILED="Install screenfetch failed"
                apt install screenfetch -y 2>> $ERRORFILE
                checkOptional

                echo "#! $(which bash)" > /etc/update-motd.d/motd
                echo "echo 'GENERAL INFORMATION'" >> /etc/update-motd.d/motd
                echo "$(which screenfetch)" >> /etc/update-motd.d/motd

                echo "Disabling Old Message of the Day"
                SUCCESS="Changed Permission to files"
                FAILED="Change permission to files failed"
                chmod -x /etc/update-motd.d/*
                checkOptional

                echo "Enable New Message of the Day (MOTD)"
                SUCCESS="Added execute permission to motd"
                FAILED="Add execute permission to motd failed"
                chmod +x /etc/update-motd.d/motd
                checkOptional

                showresult "Created New Message of the day (MOTD)"
                
                
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

function CustomPrompt
{
    echo 'Installing Function'
    echo '# Function to get the current git branch' >> $CURDIR/.bashrc
    echo 'git_branch() {' >> $CURDIR/.bashrc
    echo '  local branch' >> $CURDIR/.bashrc
    echo '  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)' >> $CURDIR/.bashrc
    echo '  if [ -n "$branch" ]; then' >> $CURDIR/.bashrc
    echo '  echo "($branch)"' >> $CURDIR/.bashrc
    echo 'fi' >> $CURDIR/.bashrc
    echo '}' >> $CURDIR/.bashrc

    echo 'Declare Color Variables'
    echo '# Color Variables' >> $CURDIR/.bashrc
    echo 'BLACK="\[\033[0;30m\]"' >> $CURDIR/.bashrc
    echo 'GREY="\[\033[01;30m\]"' >> $CURDIR/.bashrc
    echo 'RED="\[\033[0;31m\]"' >> $CURDIR/.bashrc
    echo 'GREEN="\[\033[01;32m\]"' >> $CURDIR/.bashrc
    echo 'YELLOW="\[\033[0;33m\]"' >> $CURDIR/.bashrc
    echo 'BLUE="\[\033[01;34m\]"' >> $CURDIR/.bashrc
    echo 'PURPLE="\[\033[0;35m\]"' >> $CURDIR/.bashrc
    echo 'PINK="\[\033[01;35m\]"' >> $CURDIR/.bashrc
    echo 'CYAN="\[\033[01;36m\]"' >> $CURDIR/.bashrc
    echo 'WHITE="\[\033[0;37m\]"' >> $CURDIR/.bashrc
    echo 'RESET="\[\033[0m\]"' >> $CURDIR/.bashrc

    echo "Customizing Prompt"
    echo '# PS1 definition with colors and dynamic Git branch' >> $CURDIR/.bashrc
    echo 'PS1="${GREEN}\u${WHITE}@${PINK}\h${WHITE}:${BLUE}\w \n${CYAN}\D{%Y-%m-%d %H:%M:%S}${YELLOW}\$(git_branch)${RESET}\$ "' >> $CURDIR/.bashrc
    echo '# Add other configuration settings below if needed' >> $CURDIR/.bashrc
    showresult "Created Custom Prompt"
}

function installswap
{
    while true;
    do
        read -p "Do you want to install swap? [Y/N]: " YN
        case $YN in 
            [yY]|[yY][eE][sS])
                while true;
                do
                    read -p "Install Swap Size in GB: (0 to skip) " SWAPSIZE
                    case $SWAPSIZE in 
                        [1]|[2]|[3]|[4]|[5]|[6]|[7]|[8]|[9])
                            echo "Configuring Swap ..."
                            SUCCESS="Fallocated"
                            FAILED="Fallocated failed"
                            fallocate -l ${SWAPSIZE}G /swapfile 2>>$ERRORFILE
                            checkCritical

                            SUCCESS="dd for swapfile"
                            FAILED="dd failed"
                            dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE)) 2>>$ERRORFILE
                            checkCritical

                            SUCCESS="Locked swap location"
                            FAILED="Locking swap location failed"
                            chmod 600 /swapfile 2>>$ERRORFILE
                            checkCritical

                            SUCCESS="Created swap"
                            FAILED="Create swap failed"
                            mkswap /swapfile 2>>$ERRORFILE
                            checkCritical

                            SUCCESS="Enabled swap"
                            FAILED="Enable swap failed" 
                            swapon /swapfile 2>>$ERRORFILE
                            checkCritical

                            SUCCESS="Added swap at system start"
                            FAILED="Add swap to system start failed"
                            echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                            checkCritical

                            SUCCESS="Mounted swap"
                            FAILED="Mount swap failed"
                            mount -a 2>>$ERRORFILE
                            checkOptional

                            showresult "Swap is setted to $SWAPSIZE GB" 
                            break
                            ;;
                        [0])
                            break
                            ;;
                        *) 
                            echo "Please, identify 1-9"
                            ;;
                    esac
                done
                break
                ;;
            [nN]|[nN][oO])
                showresult "Skip Installing Swap"
                break
                ;;
            *)
                echo "Please Answer with Yes or No."
                ;;
        esac
    done

}

function UpdateUpgrade
{
    while true;
    do
        read -p "Unpdate and Upgrade Server Now? [Y/N]: " UP
        case $UP in 
            [yY]|[yY][eE][sS])
                echo "Updating server ..."
                SUCCESS="Updated Server"
                FAILED="Update Server failed"
                apt update -y 2>>$ERRORFILE
                checkCritical

                echo "Upgrading server, this will take minutes or hours ..."
                SUCCESS="Upgraded server"
                FAILED="Upgrade Server Failed"
                apt upgrade -y 2>>$ERRORFILE
                checkCritical

                showresult "Update, Upgrade Done" 
                
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

function ConfigHostName
{
    while true;
    do
        read -p "Congfigure HostName? [Y/N]: " HN
        case $HN in 
            [yY]|[yY][eE][sS])
                read -p "What is your Host Name (HostName): " HOSTNAME
                if [ -z $HOSTNAME ] 
                then 
                    HOSTNAME=HostName 
                fi
                echo "Setting hostname to $HOSTNAME"
                SUCCESS="Setted hostname to $HOSTNAME"
                FAILED="Set hostname failed"
                hostnamectl set-hostname $HOSTNAME 2>>$ERRORFILE
                checkCritical

                showresult "$SUCCESS"

                
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

function InstallDocker
{
    while true;
    do
        read -p "Install Docker? [Y/N]: " Docker
        case $Docker in 
            [yY]|[yY][eE][sS])

                sudo apt-get update
                sudo apt-get install ca-certificates curl
                sudo install -m 0755 -d /etc/apt/keyrings
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc

                echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update

                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                sudo usermod -aG docker $USER && su - $USER
                
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

function ConfigTimeZone
{
    while true;
    do
        read -p "Congfigure Timezone? [Y/N]: " TZ
        case $TZ in 
            [yY]|[yY][eE][sS])
                read -p "What Time Zone (Asia/Bangkok): " TIMEZONE
                if [ -z $TIMEZONE ] 
                then 
                    TIMEZONE=Asia/Bangkok 
                fi
                echo "Setting timezone to $TIMEZONE"
                SUCCESS="Setted timezone to $TIMEZONE"
                FAILED="Set timezone failed"
                timedatectl set-timezone $TIMEZONE 2>>$ERRORFILE
                checkCritical

                showresult "$SUCCESS"
                
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

function InstallZipUnzip
{
    while true;
    do
        read -p "Install Zip and Unzip Now? [Y/N]: " ZIP
        case $ZIP in 
            [yY]|[yY][eE][sS])
                
                echo "Installing zip/unzip to the system"
                SUCCESS="Installed zip/unzip"
                FAILED="Install zip/unzip failed"
                apt install -y zip unzip 2>>$ERRORFILE
                checkCritical

                showresult "$SUCCESS"
                
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

function InstallFirewall
{
    while true;
    do
        read -p "Do you want to install firewall Now? [Y/N]: " FIREWALL
        case $FIREWALL in 
            [yY]|[yY][eE][sS])
                if [ -e /etc/init.d/ufw ]
                then
                    showresult "UFW firewall already installed"
                else

                    echo "Installing UFW firewall"
                    SUCCESS="Installed UFW Firewall"
                    FAILED="Install UFW failed"
                    apt install -y ufw
                    checkCritical

                    showresult "$SUCCESS"

                fi
                while true;
                do
                    echo "This might interupt server connection please be sure."
                    echo "Options: [Type 'SHOW' 'ALLOW' 'DENY' 'ENABLE' 'DISABLE' 'DEFAULT' 'EXIT']"
                    read -p "Do you want to Allow oer Deny Enable Disable Firewall now?: " UFWSETTINGS
                    case $UFWSETTINGS in
                        [sS][hH][oO][wW])
                            ufw status
                            ;;
                        [aA][lL][lL][oO][wW])
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify port number to allow: " ALLOWPORT
                            if [[ $ALLOWPORT =~ $RGXNUMERIC ]] ; then
                                echo "Allowing port $ALLOWPORT"
                                SUCCESS="Allowed port $ALLOWPORT"
                                FAILED="Allowing port $ALLOWPORT failed"
	                            ufw allow $ALLOWPORT 2>> $ERRORFILE
                                checkOptional

                            else    
                                echo "please specify port number"
                            fi
                            ;;
                        [dD][eE][nN][yY])
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify port number to deny: " DENYPORT
                            if [[ $DENYPORT =~ $RGXNUMERIC ]] ; then

                                echo "Denying port $DENYPORT"
                                SUCCESS="Denied port $DENYPORT"
                                FAILED="Denying port $DENYPORT failed"
	                            ufw deny $DENYPORT 2>> $ERRORFILE
                                checkOptional

                            else    
                                echo "please specify port number"
                            fi
                            ;;
                        [eE][nN][aA][bB][lL][eE])
                                RGXYES="^[yY]|[yY][eE][sS]$"
                                read -p "This might interupt server connection, do you want to continue? [Y/N]: " CONTINUE
                                if [[ $CONTINUE =~ $RGXYES ]]
                                then

                                    echo "Enabling UFW"
                                    SUCCESS="UFW Enabled"
                                    FAILED="UFW Enabling failed"
                                    ufw enable 2>> $ERRORFILE
                                    checkOptional

                                fi
                            ;;
                        [dD][iI][sS][aA][bB][lL][eE])
                            echo "Disabling UFW"
                            SUCCESS="UFW Disabled"
                            FAILED="UFW Disabling failed"
                            ufw disable 2>> $ERRORFILE
                            checkOptional
                            ;;
                        [dD][eE][fF][aA][uU][lL][tT])
                            RGXALLOW="^[aA][lL][lL][oO][wW]$"
                            RGXDENY="^[dD][eE][nN][yY]$"
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify default ports actions ALLOW or DENY?: " DEFAULT
                            if [[ $DEFAULT =~ $RGXALLOW ]] ; 
                            then
                                echo "Setting UFW default to Allow"
                                SUCCESS="Setted UFW default to Allow"
                                FAILED="Failed setting UFW default to Allow "
	                            ufw default allow 2>> $ERRORFILE
                                checkOptional
                            elif [[ $DEFAULT =~ $RGXDENY ]]
                            then
                                echo "Setting UFW default to Deny"
                                SUCCESS="Setted UFW default to Deny"
                                FAILED="Failed setting UFW default to Deny "
                                ufw default deny 2>> $ERRORFILE
                                checkOptional
                            else    
                                echo "Please Specify 'ALLOW' or 'DENY'"
                            fi
                            ;;
                        [eE][xX][iI][tT])
                            showresult "UFW configured"
                            ufw status
                            break
                            ;;
                        *)
                            echo "Options: Type 'ALLOW' 'DENY' 'ENABLE' 'DISABLE' 'EXIT'"
                            ;;
                    esac

                done
                
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

function InstallWebmin
{
    while true;
    do
        read -p "Install Webmin Now? [Y/N]: " WEBMIN
        case $WEBMIN in 
            [yY]|[yY][eE][sS])

                echo "Add webmin repository"
                SUCCESS="Added webmin repository"
                FAILED="Add webmin repository failed"
                echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
                checkCritical

                echo "Download jcameron-key"
                SUCCESS="Downloaded jcameron-key"
                FAILED="Download jcameron-key failed"
                wget https://download.webmin.com/jcameron-key.asc 2>>$ERRORFILE
                checkCritical

                echo "Add jcameron-key"
                SUCCESS="Added jcameron-key to system"
                FAILED="Add jcameron-key failed"
                apt-key add jcameron-key.asc 2>> $ERRORFILE
                checkCritical

                echo "Install apt-transport-htps"
                SUCCESS="Installed apt-transport-https"
                FAILED="Install apt-transport-htps failed"
                apt-get install apt-transport-https 2>>$ERRORFILE
                checkCritical

                echo "Update server"
                SUCCESS="Updated server"
                FAILED="Update server failed"
                apt-get -y update  2>> $ERRORFILE
                checkCritical

                echo "Install webmin"
                SUCCESS="Installed webmin"
                FAILED="Install webmin failed"
                apt-get install webmin 2>>$ERRORFILE
                checkCritical

                showresult "Webmin Installed"
                
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

function InstallNetDATA
{
    while true;
    do
        read -p "Install NetData Now? [Y/N]: " NETDATA
        case $NETDATA in 
            [yY]|[yY][eE][sS])

                echo "Install NetData"
                SUCCESS="Installed NetData"
                FAILED="Install Netdata failed"
                bash <(curl -Ss https://my-netdata.io/kickstart.sh)
                checkCritical
                
                
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

function securemysql
{
    mysql_secure_installation <<EOF

n
y
y
y
y
y
EOF
showresult "Database mysql installation secured"
}


function InstallMariadb
{
    while true;
    do
        read -p "Install Mariadb Server Now? [Y/N]: " MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                echo "Installing MariaDB"
                SUCCESS="Installed Mariadb-server"
                FAILED="Install Mariadb failed"
                apt install -y mariadb-server  2>>$ERRORFILE
                checkOptional

                securemysql
                
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


function InstalPHP
{
    while true;
    do
        read -p "Install PHP to webServer Now? [Y/N]: " PHP
        case $PHP in 
            [yY]|[yY][eE][sS])
                echo "Installing PHP"
                SUCCESS="Installed php prerequisites"
                FAILED="Install php prerequisites failed"
                apt install ca-certificates apt-transport-https software-properties-common -y 2>>$ERRORFILE
                SUCCESS="Installed required repository"
                FAILED="Install php repository failed"
                add-apt-repository ppa:ondrej/php 2>>$ERRORFILE
                SUCCESS="Installed php"
                FAILED="Install php failed"
                apt install php8.1 php8.1-fpm php8.1-zip php8.1-mysql php8.1-oauth php8.1-mbstring php8.1-memcache php8.1-curl php8.1-xml php8.1-cli -y 2>>$ERRORFILE
                checkOptional

                
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




function InstallApache
{
    while true;
    do
        read -p "Install Apache Web Server Now? [Y/N]: " APCHE
        case $APCHE in 
            [yY]|[yY][eE][sS])
                echo "Install Apache2"
                SUCCESS="Installed Apache2"
                FAILED="Install Apache2 failed"
                apt-get install -y apache2 2>>$ERRORFILE
                checkCritical

                display "Install PHP"
                InstalPHP
 
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

function InstallNginx
{
    while true;
    do
        read -p "Install Nginx Web Server Now? [Y/N]: " ENGINEX
        case $ENGINEX in 
            [yY]|[yY][eE][sS])

                echo "Install Nginx"
                SUCCESS="Installed Nginx"
                FAILED="Install Nginx failed"
                apt-get install -y nginx 2>>$ERRORFILE
                checkCritical

                display "Install PHP"
                InstalPHP
 
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

function InstallOpenLiteSpeed
{
    while true;
    do
        read -p "Install OpenLiteSpeed Web Server Now? [Y/N]: " OLS
        case $OLS in 
            [yY]|[yY][eE][sS])

                echo "Download and install Openlitespeed"
                SUCCESS="Downloaded and installed Openlitespeed"
                FAILED="Download and install Openlitespeed failed"
                wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh 2>>$ERRORFILE
                checkCritical

                echo "Remove OLS installation script"
                SUCCESS="Removed Openlitespeed installation script"
                FAILED="Remove Openlitespeed installation script failed"
                rm ols1clk.sh 2>>$ERRORFILE 
                checkCritical

                echo "Create site folder"
                SUCCESS="Created /usr/local/lsws/sites"
                FAILED="Creating /usr/local/lsws/sites failed"
                mkdir /usr/local/lsws/sites 2>> $ERRORFILE
                checkCritical

                showresult "OpenLiteSpeed installed"
                cat /usr/local/lsws/password
                cat /usr/local/lsws/password >> $RESULTFILE
                


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

function InstallWordpress
{

    while true;
    do
        read -p "Install Wordpress Now? [Y/N]: " YN
        case $YN in 
            [yY]|[yY][eE][sS])

                if [ ! -e $FILELOC ]
                then
                    SUCCESS="Created $FILELOC"
                    FAILED="Create $FILELOC failed"
                    mkdir $FILELOC 2>>$ERRORFILE
                    checkCritical
                fi
                
                cd $FILELOC 2>>$ERRORFILE

                while [ -z $FILEDIR ] || [ -d $FILELOC/$FILEDIR ] 
                do 
                    echo
                    echo "Specify New Website Folder"
                    read -p "Please specify new website directory: " FILEDIR
                done

                echo "Downloading wordpress"
                SUCCESS="Downloaded wordpress"
                FAILED="Download wordpress failed"
                wget https://wordpress.org/latest.zip 2>>$ERRORFILE
                checkCritical

                echo "Extract wordpress"
                SUCCESS="Extracted wordpress"
                FAILED="Extract wordpress failed"
                unzip latest.zip 2>>$ERRORFILE
                checkCritical

                if [! -d $FILELOC/$FILEDIR]
                then
                    SUCCESS="moved $FILELOC/wordpress to $FILELOC/$FILEDIR"
                    FAILED="move $FILELOC/wordpress to $FILELOC/$FILEDIR failed"
                    mv $FILELOC/wordpress $FILELOC/$FILEDIR 2>>$ERRORFILE
                    checkCritical
                fi

                echo "Configure wordpress folder permission"
                SUCCESS="Changed wordpress folder owner"
                FAILED="Change wordpress folder owner failed"
                if [$WEBSERVER = "OLS"]
                then
                    chown -R nobody:nogroup $FILELOC/$FILEDIR 2>>$ERRORFILE
                else
                    chown -R www-data:www-data $FILELOC/$FILEDIR 2>>$ERRORFILE
                fi

                checkCritical

                echo "Remove archive file"
                SUCCESS="Removed archive file"
                FAILED="Remove archive file failed"
                rm latest.zip 2>>$ERRORFILE
                checkCritical

                showresult "Wordpress Installed at $FILELOC"

                echo 
                echo "Setting UP Database"

                getNewDBNAME
                getNewDBUSER
                getNewDBPREF

                CreateDBUser
                createDatabase

                echo
                read -p "Please specify Table Prefix: (Blank for default 'wp_') " DBPREF
                if [ -z $DBPREF ]
                then
                    DBPREF="wp_"
                fi

                cd $FILELOC/$FILEDIR
                echo 
                echo "Create wp-config.php"
                SUCCESS="Created wp-config.php"
                FAILED="Create wp-config.php failed"
                wp config create --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPASS --dbprefix=$DBPREF --allow-root
                checkCritical
                cd $CURDIR

                display "wpconfig created"

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

function InstallWPCLI
{
    if [ -e /usr/local/bin/wp ]
    then
        echo "WP CLI already installed"
        return 0
    fi
    while true;
    do
        read -p "Installing WP CLI for Openlitespeed continue? [Y/N]: " YN
        case $YN in
            [yY]|[yY][eE][sS])
            echo "Installing Wordpress Console Line Interfacie (WP-CLI)"
            SUCCESS="Downloaded wpcli"
            FAILED="Download wpcli failed"
            curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE
            checkCritical

            echo "Add execute permission to wpcli"
            SUCCESS="Added execute permission to wpcli"
            FAILED="Add execute permission to wpcli failed"
            chmod +x wp-cli.phar 2>>$ERRORFILE
            checkCritical

            echo "Move file to default folder"
            SUCCESS="Moved file to default folder"
            FAILED="Move file to default folder failed"
            if [ $WEBSERVER == "OLS" ]
            then
                mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
                checkCritical

                echo "Copy php file"
                SUCCESS="Copied php"
                FAILED="Copy php failed"
                cp /usr/local/lsws/lsphp74/bin/php /usr/bin/ 2>>$ERRORFILE
                checkCritical

            elif [ $WEBSERVER == "Apache" ]
            then
                mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
                checkCritical
            elif [ $WEBSERVER == "Nginx" ]
            then
                mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
                checkCritical
            fi

            showresult "WP-CLI Installed"
            break
            ;;
        [nN]|[nN][oO])
            break
            ;;
        *)
            echo "Please answer with Yes or No"
        ;;
        esac
    done
}







function InstallCron
{
    while true;
    do
        read -p "Install reset cron schedule Now? [Y/N]: " CRON
        case $CRON in 
            [yY]|[yY][eE][sS])
                if [ $(crontab -l) -eq 0 ]
                then
                    echo "Importing previous cron jobs"
                    SUCCESS="Imported Previous cron jobs"
                    FAILED="Importing previous cron jobs failed"
                    crontab -l > mycron 2>>$ERRORFILE
                    checkOptional
                fi
                
                #echo new cron into cron file
                echo "Adding cron jobs to file"
                SUCCESS="Added new cron to file"
                FAILED="Add new cron to file failed"
                echo "30 3 * * * shutdown -r now" >> mycron
                checkCritical

                #install new cron file
                echo "Apply cron file"
                SUCCESS="Applied cron file to cron"
                FAILED="Apply cron file to cron failed"
                crontab mycron 2>>$ERRORFILE
                checkCritical

                echo "Remove applied cron file"
                SUCCESS="Removed applied cron file"
                FAILED="Removing applied cron file failed"
                rm mycron 2>>$ERRORFILE
                checkCritical

                showresult "Cron Installed"
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

function SelectVirtualHostServer
{
    while true;
    do
        read -p "Select your virtual host server 'Apache' 'Nginx' Or 'OpenLiteSpeed'? (A/N/O/C)" ANOC
        case $ANOC in 
            [aA]|[aA][pP][aA][cC][hH][eE])
                InstallApache
                initialize

                break
                ;;

            [nN]|[nN][gG][iI][nN][xX])
                InstallNginx
                initialize
                break
                ;;
            [oO]|[oO][pP][eE][nN][lL][iI][tT][eE][sS][pP][eE][eE][dD])
                InstallOpenLiteSpeed
                initialize

                break
                ;;
            [cC]|[cC][aA][nN][cC][eE][lL])
                echo "Canceled"
                break
                ;;
            *) 
                echo "Please, answer Apache or OpenLiteSpeed or Cancel"
            ;;
        esac
    done
}


function InstallWebServer
{
    while true;
    do
        read -p "Do you want to install Web Server Now? [Y/N]: " WS
        case $WS in 
            [yY]|[yY][eE][sS])
                display "Select Virtual Host server"
                SelectVirtualHostServer

                display "Install MariaDB"
                InstallMariadb

                display "Install Wordpress CLI"
                InstallWPCLI

                display "Install Wordpress"
                InstallWordpress



                InstallCron
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



function Finalize
{
	cd $CURDIR
	showresult " ----==== ALL DONE ====----" 
	cat $RESULTFILE

}

function BackupWebsite
{
    getBackupInformation
    checkBackupVariables
    backupbackup
    ArchiveDirectory
    exportDatabase
    ArchiveBackupFiles
    BackupRemoveUnecessaryBackFiles
    Finalize
}

function RestoreWebsite
{
    getRestoreInformation
    checkRestorevariables
    PrepareEnvironment
    RemoveExistedDirectory
    RestoringFileDirectory
    CreateDBUser
    createDatabase
    ImportDatabase
    configurewpconfig
    SetFolderPermisson
    RestoreRemoveFiles
    #UpdateURL
    completeURLChanged
    discourageSearchEnging
    ManagePlugins
    ManageThemes
    Finalize
    echo "***************** WP INFO *****************"
    wp --info
}

function RemoveWebsite
{
    clear
    getRemoveInformation
    RemoveFiles
    RemoveDatabase
    RemoveDatabaseUser
    Finalize
}

function Newsvr
{

    CustomPrompt
    CustomMOTD
    UpdateUpgrade
    installswap
    ConfigTimeZone
    ConfigHostName
    InstallZipUnzip
    InstallFirewall
    InstallWebmin
    InstallNetDATA
    InstallWebServer
    
    Finalize
    echo "***************** WP INFO *****************"
    wp --info
}

function main
{
    initialize
    clear
    if (( $EUID != 0 )); then
        echo "Some task might need root access"
    fi
    echo
    echo "Make sure you run program in user home directory"
    echo "Current Directory: $PWD"
    echo "Virtual Web Hosting Server: $WEBSERVER"
    echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE
    while true;
    do
        FILEDIR=""
        URL=""
        ORIGINALURL=""
        DBUSER=""
        DBNAME=""
        DBPASS=""  
        DBPREF=""
        echo
        echo "Select Actions"
        echo "=============="
        echo
        echo "   New)         NEW Server Setup                     Rollback)  ROLLBACK Final Backup"
        echo "   MOTD)        Install new MOTD                     Plugins)   Manage WP PLUGINS"
        echo "   PROMPT)      My Custom PROMPT                     Themes)    Manage WP THEMES"
        echo "   Backup)      BACKUP Website                       SiteURL)   Change SITEURL"
        echo "   Restore)     RESTORE Website                      SHOWURL)   SHOWURL"
        echo "   Remove)      REMOVE Website                       Docker)    Install Docker"
        echo "   DBServer)    Install DBSERVER - Mariadb"
        echo "   Webserver)   Install Webserver"
        echo "   Webmin)      Install WEBMIN (Large)"
        echo "   NetData)     Install NetData (Large)"
        echo "   Wordpress)   Install WORDPRESS"
        echo "   WPCLI)       Install WPCLI"
        echo "   UFW)         Install UFW firewall"
        echo "   Discourage)  Discourage Search Engine"
        echo "   [x]Exit)     EXIT Script"
        echo "=================================================="
        echo " FILELOC=$FILELOC  |  FILEDIR=$FILEDIR"
        echo " WEBSERVER=$WEBSERVER  | CURDIR=$CURDIR"
        echo "=================================================="
        echo
        read -p "What is your action?: " ANS
        case $ANS in 
            [dD][oO][cC][kK][eE][rR])
                clear
                display "Install Docker"
                InstallDocker
                ;;
            [nN][eE][wW])
                clear
                display "Set New server"
                Newsvr
                ;;
            [rR][oO][lL][lL][bB][aA][cC][kK])
                clear
                display "Rollback FInal Backup"
                RollbackFinalBackup
                
                ;;
            [mM][oO][tT][dD])
                clear
                display "Install Login welcome"
                CustomMOTD
                ;;
            [pP][rR][oO][mM][pP][tT])
                clear
                display "Install custom prompt"
                CustomPrompt
                ;;
            [bB][aA][cC][kK][uU][pP])
                clear
                display "Backup website"
                BackupWebsite
                ;;
            [rR][eE][sS][tT][oO][rR][eE])
                clear
                display "Restore from Backup"
                RestoreWebsite
                ;;
            [rR][eE][mM][oO][vV][eE])
                clear
                display "Removing Webiste"
                RemoveWebsite
                ;;
            [dD][bB][sS][eE][rR][vV][eE][rR])
                clear
                display "Install MariaDB"
                InstallMariadb
                ;;
            [wW][eE][bB][sS][eE][rR][vV][eE][rR])
                Clear
                display "Install Virtual Host Server"
                InstallWebServer
                ;;
            [wW][eE][bB][mM][iI][nN])
                clear
                display "Install Webmin"
                InstallWebmin
                ;;
            [nN][eE][tT][dD][aA][tT][aA])
                clear
                display "Install NetDATA"
                InstallNetDATA
                ;;
            [wW][oO][rR][dD][pP][rR][eE][sS][sS])
                display "Wordpress for Apache Server \n*   This will install Following \n*     - wordpress \n*     - wp-cli"
                InstallWordpress
                cat $RESULTFILE
                wp --info
                
                ;;
            [sS][iI][tT][eE][uU][rR][lL])
                display "Change Site URL"
                completeURLChanged
                cat $RESULTFILE
                wp --info

                ;;
            [sS][hH][oO][wW][uU][rR][lL])
                clear
                display "This is current site URL/Home URL"
                showURL
                ;;
            [wW][pP][cC][lL][iI])
                clear
                display "Install Wordpress CLI"
                InstallWPCLI
                cat $RESULTFILE
                wp --info
                
                ;;
            [uU][fF][wW])
                clear
                display "Install Firewall"
                InstallFirewall
                cat $RESULTFILE
                
                ;;

            [pP][lL][uU][gG][iI][nN][sS])
                clear
                display "Manage Plugins, WP CLI must already been installed"
                ManagePlugins
                wp --info
                ;;

            [tT][hH][eE][mM][eE][sS])
                clear
                display "Manage Themes, WP CLI must already been installed"
                ManageThemes
                wp --info
                ;;

            [dD][iI][sS][cC][oO][uU][rR][aA][gG][eE])
                clear
                display "Discourage Search Engine indexing site"
                discourageSearchEnging
                cat $RESULTFILE
                wp --info
                ;;
            [xX]|[eE][xX][iI][tT])
                break
                ;;
            *)
                display "Please use specific letter or the word written in uppercase"
                
                ;; 
        esac
    
    done
}

main