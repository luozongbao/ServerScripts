#! /bin/bash

if (( $EUID != 0 )); then
    echo "Some task might need root access"
    exit
fi

PROCRESULT=""



function CustomPrompt
{
    while true;
    do
        read -p "Install Custom Prompt? [Y/N]: " CUSTOMPROMPT
        case $CUSTOMPROMPT in 
            [yY]|[yY][eE][sS])
                cd ~
                HOMEPATH=$(pwd)
                echo 'Installing Function'
                echo '# Function to get the current git branch' >> $HOMEPATH/.bashrc
                echo 'git_branch() {' >> $HOMEPATH/.bashrc
                echo '  local branch' >> $HOMEPATH/.bashrc
                echo '  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)' >> $HOMEPATH/.bashrc
                echo '  if [ -n "$branch" ]; then' >> $HOMEPATH/.bashrc
                echo '  echo "($branch)"' >> $HOMEPATH/.bashrc
                echo 'fi' >> $HOMEPATH/.bashrc
                echo '}' >> $HOMEPATH/.bashrc

                echo 'Declare Color Variables'
                echo '# Color Variables' >> $HOMEPATH/.bashrc
                echo 'BLACK="\[\033[0;30m\]"' >> $HOMEPATH/.bashrc
                echo 'GREY="\[\033[01;30m\]"' >> $HOMEPATH/.bashrc
                echo 'RED="\[\033[0;31m\]"' >> $HOMEPATH/.bashrc
                echo 'GREEN="\[\033[01;32m\]"' >> $HOMEPATH/.bashrc
                echo 'YELLOW="\[\033[0;33m\]"' >> $HOMEPATH/.bashrc
                echo 'BLUE="\[\033[01;34m\]"' >> $HOMEPATH/.bashrc
                echo 'PURPLE="\[\033[0;35m\]"' >> $HOMEPATH/.bashrc
                echo 'PINK="\[\033[01;35m\]"' >> $HOMEPATH/.bashrc
                echo 'CYAN="\[\033[01;36m\]"' >> $HOMEPATH/.bashrc
                echo 'WHITE="\[\033[0;37m\]"' >> $HOMEPATH/.bashrc
                echo 'RESET="\[\033[0m\]"' >> $HOMEPATH/.bashrc

                echo "Customizing Prompt"
                echo '# PS1 definition with colors and dynamic Git branch' >> $HOMEPATH/.bashrc
                echo 'PS1="${GREEN}\u${WHITE}@${PINK}\h${WHITE}:${BLUE}\w \n${YELLOW}\D{%Y-%m-%d %H:%M:%S}${CYAN}\$(git_branch)${RESET}\$ "' >> $HOMEPATH/.bashrc
                echo '# Add other configuration settings below if needed' >> $HOMEPATH/.bashrc
                echo "Created Custom Prompt"
                
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



function UpdateUpgrade
{
    while true;
    do
        read -p "Unpdate and Upgrade Server Now? [Y/N]: " UP
        case $UP in 
            [yY]|[yY][eE][sS])
                echo "Updating server ..."
                apt update -y 

                echo "Upgrading server, this will take minutes or hours ..."
                apt upgrade -y 

                echo "Update, Upgrade Done" 
                
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
                            fallocate -l ${SWAPSIZE}G /swapfile 

                            dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE)) 

                            chmod 600 /swapfile 

                            mkswap /swapfile 

                            swapon /swapfile

                            echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

                            mount -a 

                            echo "Swap is setted to $SWAPSIZE GB" 
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
                timedatectl set-timezone $TIMEZONE 
                echo "Setted timezone to $TIMEZONE"
                
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
                hostnamectl set-hostname $HOSTNAME 
                echo "Setted hostname to $HOSTNAME"

                
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
        read -p "Install Zip and Unzip Now? [Y/N]: " INSTALLZIPDECISION
        case $INSTALLZIPDECISION in 
            [yY]|[yY][eE][sS])
                
                echo "Installing zip/unzip to the system"
                apt install -y zip unzip 
                echo "Installed zip/unzip"
                
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

    RGXNUMERIC='^[0-9]+$'
    while true;
    do
        read -p "Do you want to install firewall Now? [Y/N]: " FIREWALLDECISIOIN
        case $FIREWALLDECISIOIN in 
            [yY]|[yY][eE][sS])
                if [ -e /etc/init.d/ufw ]
                then
                    echo "UFW firewall already installed"
                else

                    echo "Installing UFW firewall"
                    apt install -y ufw

                    echo "Installed UFW Firewall"

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
	                            ufw allow $ALLOWPORT 
                                echo "Allow port $ALLOWPORT"

                            else    
                                echo "please specify port number"
                            fi
                            ;;
                        [dD][eE][nN][yY])
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify port number to deny: " DENYPORT
                            if [[ $DENYPORT =~ $RGXNUMERIC ]] ; then

                                echo "Denying port $DENYPORT"
	                            ufw deny $DENYPORT 
                                echo "Denied port $DENYPORT"

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
                                    ufw enable 
                                    echo "UFW Enabled"

                                fi
                            ;;
                        [dD][iI][sS][aA][bB][lL][eE])
                            echo "Disabling UFW"
                            ufw disable
                            echo "UFW Disabled"
                            ;;
                        [dD][eE][fF][aA][uU][lL][tT])
                            RGXALLOW="^[aA][lL][lL][oO][wW]$"
                            RGXDENY="^[dD][eE][nN][yY]$"
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify default ports actions ALLOW or DENY?: " DEFAULT
                            if [[ $DEFAULT =~ $RGXALLOW ]] ; 
                            then
                                echo "Setting UFW default to Allow"
	                            ufw default allow 
                                echo "Setted UFW default to Allow"
                            elif [[ $DEFAULT =~ $RGXDENY ]]
                            then
                                echo "Setting UFW default to Deny"
                                ufw default deny 
                                echo "Setted UFW default to Deny"
                            else    
                                echo "Please Specify 'ALLOW' or 'DENY'"
                            fi
                            ;;
                        [eE][xX][iI][tT])
                            echo "UFW configured"
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

main(){
    CustomPrompt
    UpdateUpgrade
    installswap
    ConfigTimeZone
    ConfigHostName
    InstallZipUnzip
    InstallFirewall
}

main