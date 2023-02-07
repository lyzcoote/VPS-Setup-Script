#!/bin/bash

################################################################################
#                                                                              #
#                                  Functions                                   #
#                                                                              #
################################################################################

function checkOS() {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ $ID == "debian" || $ID == "raspbian" ]]; then
			if [[ $VERSION_ID -lt 9 ]]; then
				echo "⚠️ Your version of Debian is not supported."
				echo ""
				echo "However, if you're using Debian >= 9 or unstable/testing then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		elif [[ $ID == "ubuntu" ]]; then
			OS="ubuntu"
			MAJOR_UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f1)
			if [[ $MAJOR_UBUNTU_VERSION -lt 16 ]]; then
				echo "⚠️ Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu >= 16.04 or beta, then you can continue, at your own risk."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ $CONTINUE == "n" ]]; then
					exit 1
				fi
			fi
		fi
	else
		echo "Looks like you aren't running this installer on a Debian or Ubuntu server"
		exit 1
	fi
}

function installDocker() {
	clear
	echo "Downloading Docker setup script..."
	curl -fsSL https://get.docker.com -o get-docker.sh
	sh get-docker.sh
	clear
	echo "You want to add $USERNAME to the Docker group? "
	echo "(Y/n): "
	read RESPONSE
	if [[ $RESPONSE == [Yy]* ]]; then
	    usermod -aG docker $USERNAME
	    echo "$USERNAME added to the Docker group"
	fi
}

function dockerDialog() {
	DIALOG=${DIALOG=dialog}

	cmd=($DIALOG --title "Install Docker" --menu "Select options:" 0 0 0)

	options=(1 "Docker Standalone"
	         2 "Docker + Portainer CE"
	         3 "Docker + Portainer EE"
	         4 "Docker + Portainer Agent")

	choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

	for choice in $choices
	do
	    case $choice in
	        1)
	            echo "First Option | Standalone"
	            installDocker
	            ;;
	        2)
	            echo "Second Option | Portainer CE"
	            installDocker
				installPortainer "CE"
	            ;;
	        3)
	            echo "Third Option | Portainer EE"
	            installDocker
				installPortainer "EE"
	            ;;
	        4)
	            echo "Fourth Option | Portainer Agent"
	            installDocker
				installPortainer "Agent"
	            ;;
	    esac
	done
}

function updateNdUpgrade() {
	# Show the loading bar for apt-get update
	(
	  apt-get update 2>&1 | dialog --title "Working" --gauge "Updating packages sources, please wait..." 7 70 0
	) | dialog --title "Working" --gauge "Updating packages sources, please wait..." 7 70 20

	# Check if the command execution was successful
	if [ $? -ne 0 ]; then
	  dialog --title "Error!" --msgbox "Update failed!" 5 30
	  exit 1
	fi

	# Show the loading bar for apt-get upgrade
	(
	  apt-get upgrade -y 2>&1 | dialog --title "Working" --gauge "Upgrading packages, please wait..." 7 70 20
	) | dialog --title "Working" --gauge "Upgrading packages, please wait..." 7 70 40

	# Check if the command execution was successful
	if [ $? -ne 0 ]; then
	  dialog --title "Error!" --msgbox "Upgrade failed!" 5 30
	  exit 1
	fi

	# Show the loading bar for apt-get install
	(
	  apt-get install neofetch htop vim nano wget curl git ncdu zsh snapd -y 2>&1 | dialog --title "Working" --gauge "Installing packages, please wait..." 7 70 40) | dialog --title "Working" --gauge "Installing packages, please wait..." 7 70 90

	# Check if the command execution was successful
	if [ $? -ne 0 ]; then
	  dialog --title "Error!" --msgbox "Installation failed!" 5 30
	  exit 1
	fi

	# Show success message
	dialog --title "Done!" --msgbox "System update and installation successful!" 6 30
	clear
}

function upgradeDialog() {
	DIALOG=${DIALOG=dialog}

	$DIALOG --title "Update and Upgrade System" --clear \
	        --yesno "Would you like to update and upgrade the system?" 0 0 

	case $? in
	  0)
	    updateNdUpgrade
	    ;;
	  1)
	    echo "No chosen.";;
	  255)
	    echo "ESC pressed.";;
	esac
}

function showDialog() {
	DIALOG=${DIALOG=dialog}

	$DIALOG --title "$1" --clear \
	        --yesno "$2" 0 0 

	case $? in
	  0)
	    $3
	    ;;
	  1)
	    echo "No chosen.";;
	  255)
	    echo "ESC pressed.";;
	esac
}

function installPortainer() {
	portainerType=$1
	if [[ $portainerType == "CE" ]]; then
		echo "## Installing Portainer CE..."
		docker volume create portainer_data
		docker run -d -p 9443:9443 -p 8000:8000 --name portainer_ce --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_stuff:/data portainer/portainer-ce:latest
	elif [[ $portainerType == "EE" ]]; then
		echo "## Installing Portainer EE..."
		docker volume create portainer_data
		docker run -d -p 9443:9443 -p 8000:8000 --name portainer_ee --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_stuff:/data portainer/portainer-ee:latest
	elif [[ $portainerType == "Agent" ]]; then
		echo "## Installing Portainer Agent..."
		docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent:2.16.2
	else
		echo "[!] Invalid Portainer type";
		exit 1;
	fi
}

################################################################################
#                                                                              #
#                                  Main Code                                   #
#                                                                              #
################################################################################

# Bruh, variables don't iniziate by itself
checkOS

# Checking if the user running the script is root
if [ "$EUID" -ne 0 ]
  then echo "Please run this script as root"
  exit
fi

apt install -y dialog

clear

echo -ne "
-------------------------------------------------------------------------
                    			Adding User
-------------------------------------------------------------------------
"
# Checking if there's a sudo or wheel group
if [ $(getent group sudo) ]; then
    USER_GROUP=sudo
elif [ $(getent group wheel) ]; then
    USER_GROUP=wheel
else
    echo "Cannot find 'wheel' or 'sudo' group, aborting!"
    exit 1
fi
if [ $(whoami) = "root"  ]; then
	echo "Would you like to add a new username?"
	echo "(Y/n)? "
	read RESPONSE
    if [[ $RESPONSE == [Yy]* ]]; then
	    echo "Insert the username: "
	    read USERNAME
	    echo "You want to add $USERNAME to the $USER_GROUP group? "
		echo "(Y/n): "
	    read RESPONSE
	    if [[ $RESPONSE == [Yy]* ]]; then
	        useradd -m -G $USER_GROUP -s /bin/bash $USERNAME
	        echo "$USERNAME created, home directory created, added to $USER_GROUP group and default shell set to /bin/bash"
	    else
	        useradd -m -s /bin/bash $USERNAME
	        echo "$USERNAME created, home directory created and default shell set to /bin/bash"
	    fi
	    echo "Setting up password for $USERNAME"
    	passwd $USERNAME
	else 
		echo "Not adding a new username"
	fi
fi

clear

echo -ne "
-------------------------------------------------------------------------
                Updating and installing necessary packages
-------------------------------------------------------------------------
"

# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    if [[ $OS =~ (debian|ubuntu) ]]; then
        upgradeDialog
    else
        echo "Can't detect current distro!"
        exit 1
    fi
else
	echo "This script only supports Linux based OSes :/"
	exit 0
fi


clear

echo -ne "
-------------------------------------------------------------------------
                   Installing Docker and Portainer
-------------------------------------------------------------------------
"
## Necessary repo, packages and config

if [[ $OS =~ (debian|ubuntu) ]]; then
	dockerDialog
fi

clear


echo -ne "
-------------------------------------------------------------------------
                                  Done!
-------------------------------------------------------------------------
"
exit 0
