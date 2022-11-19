#!/bin/bash

########################################################################################################################
# Find Us                                                                                                              #
# Author: Mehmet ÖĞMEN                                                                                                 #
# Web   : https://x-shell.codes/scripts/config                                                                         #
# Email : mailto:config.script@x-shell.codes                                                                           #
# GitHub: https://github.com/x-shell-codes/config                                                                      #
########################################################################################################################
# Contact The Developer:                                                                                               #
# https://www.mehmetogmen.com.tr - mailto:www@mehmetogmen.com.tr                                                       #
########################################################################################################################

########################################################################################################################
# Constants                                                                                                            #
########################################################################################################################
NORMAL_LINE=$(tput sgr0)
RED_LINE=$(tput setaf 1)
YELLOW_LINE=$(tput setaf 3)
GREEN_LINE=$(tput setaf 2)
BLUE_LINE=$(tput setaf 4)
POWDER_BLUE_LINE=$(tput setaf 153)
BRIGHT_LINE=$(tput bold)
REVERSE_LINE=$(tput smso)
UNDER_LINE=$(tput smul)

########################################################################################################################
# Line Helper Functions                                                                                                #
########################################################################################################################
function ErrorLine() {
  echo "${RED_LINE}$1${NORMAL_LINE}"
}

function WarningLine() {
  echo "${YELLOW_LINE}$1${NORMAL_LINE}"
}

function Succeconfigine() {
  echo "${GREEN_LINE}$1${NORMAL_LINE}"
}

function InfoLine() {
  echo "${BLUE_LINE}$1${NORMAL_LINE}"
}

########################################################################################################################
# Version                                                                                                              #
########################################################################################################################
function Version() {
  echo "config version 1.0.0"
  echo
  echo "${BRIGHT_LINE}${UNDER_LINE}Find Us${NORMAL}"
  echo "${BRIGHT_LINE}Author${NORMAL}: Mehmet ÖĞMEN"
  echo "${BRIGHT_LINE}Web${NORMAL}   : https://x-shell.codes/scripts/config"
  echo "${BRIGHT_LINE}Email${NORMAL} : mailto:config.script@x-shell.codes"
  echo "${BRIGHT_LINE}GitHub${NORMAL}: https://github.com/x-shell-codes/config"
}

########################################################################################################################
# Help                                                                                                                 #
########################################################################################################################
function Help() {
  echo "Server configuration script."
  echo
  echo "Options:"
  echo "-d | --domain        Domain name (example.com)"
  echo "-h | --help        Display this help."
  echo "-V | --version     Print software version and exit."
  echo
  echo "For more details see https://github.com/x-shell-codes/config."
}

########################################################################################################################
# Arguments Parsing                                                                                                    #
########################################################################################################################
for i in "$@"; do
  case $i in
  -d=* | --domain=*)
    domain="${i#*=}"
    shift
    ;;
  -h | --help)
    Help
    exit
    ;;
  -V | --version)
    Version
    exit
    ;;
  -* | --*)
    ErrorLine "Unexpected option: $1"
    echo
    echo "Help:"
    Help
    exit
    ;;
  esac
done

########################################################################################################################
# CheckRootUser Function                                                                                               #
########################################################################################################################
function CheckRootUser() {
  if [ "$(whoami)" != root ]; then
    ErrorLine "You need to run the script as user root or add sudo before command."
    exit 1
  fi
}

########################################################################################################################
# Main Program                                                                                                         #
########################################################################################################################
echo "${POWDER_BLUE_LINE}${BRIGHT_LINE}${REVERSE_LINE}CONFIGURATION${NORMAL_LINE}"

CheckRootUser

export DEBIAN_FRONTEND=noninteractive

# Disable Password Authentication Over SSH
sed -i "/PasswordAuthentication yes/d" /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "" | sudo tee -a /etc/ssh/sshd_config
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config

# Restart SSH
ssh-keygen -A
service ssh restart

# Set The Hostname If Necessary
if [[ ! -z "$domain" ]]; then
  sed -i 's/127\.0\.1\.1.*$domain $domain/127.0.0.1 $domain.localdomain $domain/' /etc/hosts
fi

# Set The Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Create The Root SSH Directory If Necessary
if [ ! -d /root/.ssh ]; then
  mkdir -p /root/.ssh
  touch /root/.ssh/authorized_keys
fi

# Setup Deployer User
useradd deployer
mkdir -p /home/deployer/.ssh
mkdir -p /home/deployer/.x-shell.codes
adduser deployer sudo

# Setup Bash For Deployer User
chsh -s /bin/bash deployer
cp /root/.profile /home/deployer/.profile
cp /root/.bashrc /home/deployer/.bashrc

# Set The Sudo Password For Deployer
#PASSWORD=$(mkpasswd -m sha-512 %password%)
#usermod --password $PASSWORD deployer

# Authorize Deployer's Unique Server Public Key
#cat > /root/.ssh/authorized_keys << EOF
## x-shell-codes deployer
# ssh-rsa

#EOF

cp /root/.ssh/authorized_keys /home/deployer/.ssh/authorized_keys

# Create The Server SSH Key
ssh-keygen -f /home/deployer/.ssh/id_rsa -t rsa -N ''

# Copy Source Control Public Keys Into Known Hosts File
ssh-keyscan -H github.com >> /home/deployer/.ssh/known_hosts
ssh-keyscan -H bitbucket.org >> /home/deployer/.ssh/known_hosts
ssh-keyscan -H gitlab.com >> /home/deployer/.ssh/known_hosts

# Setup Deployer Home Directory Permissions
chown -R deployer:deployer /home/deployer
chmod -R 755 /home/deployer
chmod 700 /home/deployer/.ssh/id_rsa
chmod 600 /home/deployer/.ssh/authorized_keys

echo "" | tee -a /etc/crontab
echo "# x-shell.codes Scheduler" | tee -a /etc/crontab
tee -a /etc/crontab <<"CRONJOB"
0 0 * * 0 root apt autoremove && apt autoclean > /home/deployer/.x-shell.codes/apt.autoclean.log 2>&1
CRONJOB
