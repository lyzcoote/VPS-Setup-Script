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
	elif [[ -e /etc/system-release ]]; then
		source /etc/os-release
		if [[ $ID == "fedora" || $ID_LIKE == "fedora" ]]; then
			OS="fedora"
		fi
		if [[ $ID == "centos" || $ID == "rocky" || $ID == "almalinux" ]]; then
			OS="centos"
			if [[ ! $VERSION_ID =~ (7|8|9) ]]; then
				echo "⚠️ Your version of CentOS is not supported."
				echo ""
				echo "The script only support CentOS 7 and CentOS 8."
				echo ""
				exit 1
			fi
		fi
		if [[ $ID == "ol" ]]; then
			OS="oracle"
			if [[ ! $VERSION_ID =~ (8) ]]; then
				echo "Your version of Oracle Linux is not supported."
				echo ""
				echo "The script only support Oracle Linux 8."
				exit 1
			fi
		fi
		if [[ $ID == "amzn" ]]; then
			OS="amzn"
			if [[ $VERSION_ID != "2" ]]; then
				echo "⚠️ Your version of Amazon Linux is not supported."
				echo ""
				echo "The script only support Amazon Linux 2."
				echo ""
				exit 1
			fi
		fi
	elif [[ -e /etc/arch-release ]]; then
		OS=arch
	else
		echo "Looks like you aren't running this installer on a Debian, Ubuntu, Fedora, CentOS, Amazon Linux 2, Oracle Linux 8 or Arch Linux system"
		exit 1
	fi
}

################################################################################
#                                                                              #
#                                  Main Code                                   #
#                                                                              #
################################################################################

checkOS

echo -ne "
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ░░░░░░░░░░░░░
▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒
▒   ▒▒▒▒▒▒▒▒   ▒▒▒   ▒     ▒   ▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒   ▒▒▒▒▒    ▒  ▒▒▒▒   ▒▒▒▒
▓   ▓▓▓▓▓▓▓▓▓   ▓   ▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓   ▓▓   ▓▓▓   ▓▓   ▓▓▓▓   ▓▓▓▓  ▓▓▓   ▓
▓   ▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓   ▓▓▓▓   ▓   ▓▓▓▓   ▓▓▓   ▓▓▓         ▓
▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓   ▓▓   ▓▓   ▓▓▓   ▓▓   ▓▓▓▓   ▓ ▓  ▓▓▓▓▓▓▓▓
█          ████   ████         ██████████     ██████   ████████   ████████   ████     ███
██████████████   ████████████████████████████████████████████████████████████████████████
"

echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"

if [ $(getent group sudo) ]; then
    USER_GROUP=sudo
elif [ $(getent group wheel) ]; then
    USER_GROUP=wheel
else
    echo "Cannot find 'wheel' or 'sudo' group, aborting!"
    exit 1
fi
if [ $(whoami) = "root"  ]; then
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

# use chpasswd to enter $USERNAME:$password
    echo "Setting up password for $USERNAME"
    passwd $USERNAME
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
    # If available, use LSB to identify distribution
    if [[ $OS =~ (arch) ]]; then
        pacman -Syy
        pacman -Syu --noconfirm
        pacman -S htop vim nano wget curl git ncdu zsh --noconfirm
    elif [[ $OS =~ (debian|ubuntu) ]]; then
        apt update
        apt upgrade -y
        apt install htop vim nano wget curl git ncdu zsh -y
    elif [[ $OS =~ (centos|amzn|oracle) ]]; then
        yum update -y
        yum install htop vim nano wget curl git ncdu zsh -y
    elif [[ $OS =~ (fedora) ]]; then
        dnf update -y
        dnf install htop vim nano wget curl git ncdu zsh -y
    else
        echo "Can't detect current distro!"
        exit 1
    fi
fi


clear

echo -ne "
-------------------------------------------------------------------------
                Installing additional QOF packages
-------------------------------------------------------------------------
"
## Additional packages for Debian/Ubuntu
if [[ $OS =~ (debian|ubuntu) ]]; then
	#echo $OS
	#echo $VERSION_CODENAME
	#echo $VERSION_ID
	echo "Would you like to install Nala? (Nice front-end for apt)"
	echo "(Y/n)? "
	read RESPONSE
    if [[ $RESPONSE == [Yy]* ]]; then
		echo "deb [arch=amd64,arm64,armhf] http://deb.volian.org/volian/ scar main" | tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list
		wget -qO - https://deb.volian.org/volian/scar.key | tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null
		if [[ $OS =~ (debian) ]] && [[ $VERSION_CODENAME = "bullseye" ]]; then
			apt update
			apt install nala-legacy -y
		elif [[ $OS =~ (debian) ]] && [[ $VERSION_CODENAME =~ (testing|bookworm|sid) ]]; then
			apt update
			apt install nala -y
		elif [[ $OS =~ (ubuntu) ]] && [[ $VERSION_ID = "22.04" ]]; then
			apt update
			apt install nala -y
		elif [[ $OS =~ (ubuntu) ]] && [[ $VERSION_ID =~ (21.04|20.04) ]]; then
			apt update
			apt install nala-legacy -y
		else
			echo "Cannot find a proper canditate OS for Nala or Nala-legacy :/"
		fi
	else
		echo "Not installing Nala/Nala-Legacy."
	fi
fi


echo -ne "
-------------------------------------------------------------------------
                                  Done!
-------------------------------------------------------------------------
"
exit 0