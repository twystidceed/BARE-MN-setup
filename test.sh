#!/bin/bash
# Twystid's Masternode Setup Script V3.2 for Ubuntu
#
# Script will attempt to auto detect primary public IP address
# This script is capable of installing with or without swap depending on your VPS
# Usage:
# bash bare-setup.sh 
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

#TCP port
PORT=32201
RPC=32202

#GLOBAL VARIABLES - Check the daemon deployment section for proper deployment

#this is the Github Source for the binaries

SOURCEA=https://github.com/BareCrypto/BARE-coin/releases/download/v2.0.0.6/BARE_v2.0.0.6_Ubuntu18_daemon.tar.xz
#Version for ubuntu 16.04
SOURCEB='https://github.com/BareCrypto/BARE-coin/releases/download/v2.0.0.6/BARE_v2.0.0.6_Ubuntu16_daemon.tar.xz'

#The archive itself from the source
#18.04
ARCHIVEA=BARE_v2.0.0.6_Ubuntu18_daemon.tar.xz
#16.04
ARCHIVEB=BARE_v2.0.0.6_Ubuntu16_daemon.tar.xz

#ADDNODES
ADDNODEA=51.79.26.4:32201
ADDNODEB=185.183.98.68:32201
ADDNODEC=5.45.105.212


#name of the folder created with the git clone when clonign the repository
FOLDER=BARE-MN-setup

#official name
NAME='Bare'

#name2 is the actual name of the binary when installed on VPS [CASE SENSISTIVE]
NAME2=bare

#Simply the Ticker of the coin for referenceing in the script - no usage case not sensitive
TICKER=BARE

#actual name of the hidden folder for the coin [CASE SENSITIVE]
HIDDEN=.barev2

#Actual name of the conf file in the hidden folder [CASE SENSITIVE]
CONF=bare.conf

#actual name od the coin daemon [CASE SENSITIVE]
DAEMON=bared

#Actual name of the coin daemon -cli [CASE SENSITIVE]
CLI=bare-cli

#name of the monitor script [CASE SENSITIVE]
MONITOR=baremon.sh

#only enable if needed due to binaries being extracted to a second folder within the cloned folder
#FOLDER2=if needed 


#####################################
#     END OF GLOBAL VARIABLES       #
#####################################

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x $DAEMON > /dev/null; then
        echo -e "${YELLOW}Attempting to stop $DAEMON${NC}"
        $CLI stop
        delay 30
        if pgrep -x $DAEMON > /dev/null; then
            echo -e "${RED}$DAEMON daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            pkill -9 $DAEMON
            delay 30
            if pgrep -x $DAEMON > /dev/null; then
                echo -e "${RED}Can't stop $DAEMON! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}




#Process command line parameters
genkey=$1

clear
echo -e "${PURPLE}####### #     # #     #  #####  ####### ### ######  ${NC}"
echo -e "${PURPLE}   #    #  #  #  #   #  #     #    #     #  #     # ${NC}"
echo -e "${PURPLE}   #    #  #  #   # #   #          #     #  #     # ${NC}"
echo -e "${PURPLE}   #    #  #  #    #     #####     #     #  #     # ${NC}"
echo -e "${PURPLE}   #    #  #  #    #          #    #     #  #     # ${NC}"
echo -e "${PURPLE}   #    #  #  #    #    #     #    #     #  #     # ${NC}"
echo -e "${PURPLE}   #     ## ##     #     #####     #    ### ######  ${NC}"
echo -e
echo -e "${PURPLE}      #     # ### #     # ### #     #  #####  ${NC}"
echo -e "${PURPLE}      ##   ##  #  ##    #  #  ##    # #     # ${NC}"
echo -e "${PURPLE}      # # # #  #  # #   #  #  # #   # #       ${NC}"
echo -e "${PURPLE}      #  #  #  #  #  #  #  #  #  #  # #  #### ${NC}"
echo -e "${PURPLE}      #     #  #  #   # #  #  #   # # #     # ${NC}"
echo -e "${PURPLE}      #     #  #  #    ##  #  #    ## #     # ${NC}"
echo -e "${PURPLE}      #     # ### #     # ### #     #  #####  ${NC}"
echo -e
echo -e "${GREEN}$NAME Masternode Setup Script V3 for Ubuntu LTS${NC}"
echo -e
echo -e "${GREEN}This script contains multiple options - please choose proper selections${NC}"
echo -e
echo -e 
sleep 5

echo -e "${YELLOW}Do you want me to generate a masternode private key for you? [y/n]${NC}"
  read DOSETUP
if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address

sudo apt-get update -y

dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
#Check Deps
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Dependencies already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev
sudo apt-get install -y unzip
sudo apt-get install -y dtrx
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev
sudo apt-get -y install libminiupnpc-dev
sudo apt-get -y install fail2ban
sudo service fail2ban restart
sudo apt-get install -y libdb5.3++-dev libdb++-dev libdb5.3-dev libdb-dev && ldconfig
sudo apt-get install -y libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5
   fi
sudo apt-get install libboost-all-dev
#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for tourd JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)


echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e 
echo -e "${PURPLE}===========Optional SWAP Installation================${NC}"
echo -e
echo -e "${RED}Some providers do not allow you to install swap!${NC}"
echo -e 
echo -e "${GREEN}If you have VPS with locked swap select N to continue${NC}"
echo -e "${GREEN}If you need to install SWAP or are unsure select Y${NC}"
echo -e
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e

 read SWAP
 
	if [[ $SWAP =~ "y" ]] ; then
			echo "installing SWAP"
			if grep -q "swapfile" /etc/fstab; then
				echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
			else
				echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
				touch /var/swap.img
				chmod 600 /var/swap.img
				dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
				mkswap /var/swap.img 2> /dev/null
				swapon /var/swap.img 2> /dev/null
				if [ $? -eq 0 ]; then
					echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
					echo -e "${GREEN}Swap was created successfully!${NC} \n"
				else
					echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
					rm /var/swap.img
				fi
			fi
	fi
	clear

####TEST FOR OPTION TO INSTALL FOR UBUNTU 18 OR 16 

echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e 
echo -e "${PURPLE}===========Choose Your Ubuntu Version================${NC}"
echo -e
echo -e 
echo -e "${GREEN}To install for Ubuntu 18.04 select 1 ${NC}"
echo -e
echo -e "${GREEN}To install for Ubuntu 16.04 select 2 ${NC}"
echo -e
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e
 read VERSION
 ##install option for ubuntu 18.04 - will exit if 16.04 is detected
	if [[ $VERSION =~ "1" ]] ; then
			echo "Installing for 18.04"
			#Function detect_ubuntu

				if [[ $(lsb_release -d) == *18.04* ]]; then
				UBUNTU_VERSION=18
					#Extracting Daemon
					cd ~/$FOLDER
					sudo wget $SOURCEA
					sudo dtrx -n -f $ARCHIVEA
					rm -rf $ARCHIVEA
				else
				echo -e "${RED}You are not running Ubuntu 18.04, Use install for 16.04 - Installation is cancelled.${NC}"
				exit 1

				fi
	fi
	clear
	
	if [[ $VERSION =~ "2" ]] ; then
				echo "Installing for 16.04"
				#Function detect_ubuntu
	
					if [[ $(lsb_release -d) == *16.04* ]]; then
					UBUNTU_VERSION=16
						#Extracting Daemon
						cd ~/$FOLDER
						sudo wget $SOURCEB
						sudo dtrx -n -f $ARCHIVEB
						rm -rf $ARCHIVEA
					else
					echo -e "${RED}You are not running Ubuntu 18.04, Use install for 16.04 - Installation is cancelled.${NC}"
					exit 1
	
					fi
	fi
	clear
	
	
#### END TEST FOR VERSION



 
 stop_daemon
 
 # Deploy binaries to /usr/bin
 cd ~/$FOLDER/$FOLDER2/
 sudo cp $NAME2* /usr/bin/
 sudo chmod 755 -R ~/$FOLDER
 sudo chmod 755 /usr/bin/$NAME2*
 
 # Deploy masternode monitoring script
 cp ~/$FOLDER/$MONITOR /usr/local/bin/
 sudo chmod 711 /usr/local/bin/$MONITOR
 
 #Create datadir
 if [ ! -f ~/$HIDDEN/$CONF ]; then 
 	sudo mkdir ~/$HIDDEN
 fi

echo -e "${YELLOW}Creating $CONF...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/$HIDDEN/$CONF
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/$HIDDEN/$CONF

    #Starting daemon first time just to generate masternode private key
    $DAEMON -daemon
echo -ne '[#         ] (10%)\r'
sleep 10
echo -ne '[##        ] (20%)\r'
sleep 10
echo -ne '[###       ] (30%)\r'
sleep 10 
echo -ne '[####      ] (40%)\r'
sleep 10
echo -ne '[#####     ] (50%)\r'
sleep 10
echo -ne '[######    ] (60%)\r'
sleep 10
echo -ne '[#######   ] (70%)\r'
sleep 10
echo -ne '[########  ] (80%)\r'
sleep 10
echo -ne '[######### ] (90%)\r'
sleep 10
echo -ne '[##########] (100%)\r'
echo -ne '\n'

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$($CLI masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR: Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create $CONF
    stop_daemon
fi

# Create $CONF
cat <<EOF > ~/$HIDDEN/$CONF
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcport=$RPC
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logintimestamps=1
maxconnections=10
externalip=$publicip:$PORT
masternode=1
masternodeprivkey=$genkey
addnode=$ADDNODEA
addnode=$ADDNODEB
addnode=$ADDNODEC

EOF

#Finally, starting daemon with new $CONF
$DAEMON -daemon
delay 10

#Setting auto start cron job daemon
cronjob="@reboot sleep 30 && $DAEMON -daemon"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your $TICKER collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the $TICKER network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a complete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true' or status 999.

At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!

Currently your masternode is syncing with the $TICKER network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in $CONF:
${YELLOW}cat ~/$HIDDEN/$CONF${NC}
Here is your $CONF generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/$HIDDEN/$CONF
echo -e "${NC}-------------------------------------------------
NOTE: To edit $CONF, first stop the $DAEMON daemon,
then edit the $CONF file and save it in nano: (Ctrl-X + Y + Enter),
then start the $DAEMON daemon back up:
             to stop:   ${YELLOW}$CLI stop${NC}
             to edit:   ${YELLOW}nano ~/$HIDDEN/$CONF${NC}
             to start:  ${YELLOW}$DAEMON -daemon{NC}
========================================================================
To view LSR debug log showing all MN network activity in realtime:
             ${YELLOW}tail -f ~/$HIDDEN/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the $MONITOR script:
                 ${YELLOW}$MONITOR${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your $TICKER Masternode and thanks for using this setup script!

If you found this script useful, please donate to : 
${GREEN}no donations at this time ${NC}
...and make sure to check back for updates!

Contact Twystidceed#4126 on discord if you need additional support
"
delay 10
# Run $MONITOR
sudo $MONITOR

# EOF
