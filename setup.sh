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
        apt update
        apt upgrade -y
        apt install htop vim nano wget curl git ncdu zsh nginx snapd -y
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
                Installing additional QOF packages
-------------------------------------------------------------------------
"
## Additional packages for Debian/Ubuntu
if [[ $OS =~ (debian|ubuntu) ]]; then
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

clear

echo -ne "
-------------------------------------------------------------------------
                   Installing docker and portainer
-------------------------------------------------------------------------
"
## Necessary repo, packages and config

if [[ $OS =~ (debian|ubuntu) ]]; then
	echo "Would you like to install Docker and Portainer? (Nice front-end web gui for docker)"
	echo "(Y/n)? "
	read RESPONSE
    if [[ $RESPONSE == [Yy]* ]]; then
		echo "Downloading Docker setup script..."
		curl -fsSL https://get.docker.com -o get-docker.sh
		sh get-docker.sh
		# Installing Portainer
		read -p "Press enter to continue"
		clear
		echo "## Installing Portainer..."
		docker volume create portainer_data
		docker run -d -p 9443:9443 -p 8000:8000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_stuff:/data portainer/portainer-ce:latest
		# Installing Netdata
		read -p "Press enter to continue"
		clear
		echo "## Installing Netdata..."
		docker run -d --name=netdata -p 19999:19999 -v netdataconfig:/etc/netdata -v netdatalib:/var/lib/netdata -v netdatacache:/var/cache/netdata -v /etc/passwd:/host/etc/passwd:ro -v /etc/group:/host/etc/group:ro -v /proc:/host/proc:ro -v /sys:/host/sys:ro -v /etc/os-release:/host/etc/os-release:ro --restart unless-stopped --cap-add SYS_PTRACE --security-opt apparmor=unconfined netdata/netdata
	else 
		echo "Not installing Docker and Portainer"
	fi
fi

clear

echo -ne "
-------------------------------------------------------------------------
                   	Configuring Nginx's Web Servers
-------------------------------------------------------------------------
"

echo "Would you like to configure and deploy the Nginx's Web Servers for"
echo "Portainer, NetData"
echo "(Y/n)? "
read RESPONSE
if [[ $RESPONSE == [Yy]* ]]; then
	echo "## Creating the virtual host and deploying it"
	# Creating the site
	NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'

	# Create nginx config file
	cat > $NGINX_AVAILABLE_VHOSTS/net.lyzcoote.gay.conf <<EOF
server 
{
    listen 80;
    server_name net.lyzcoote.gay;
    location / 
    {
		proxy_pass http://localhost:19999;
	}
}
EOF

	# Enabling the site
	cp /etc/nginx/sites-available/net.lyzcoote.gay.conf /etc/nginx/sites-enabled/net.lyzcoote.gay.conf

	# Restart
	echo "Do you wish to restart nginx?"
	echo "(Y/n)? "
	read RESPONSE
	if [[ $RESPONSE == [Yy]* ]]; then
	    service nginx restart
	else
		echo "Not restating Nginx"
	fi
	read -p "Press enter to continue"
	clear

	# SSL for Netdata and Portainer
	echo "Do you want to enable SSL to the services created previously?"
	echo "(Y/n)? "
	read RESPONSE
	if [[ $RESPONSE == [Yy]* ]]; then
		echo "## Installing Certbot for Nginx "
		snap install core
		snap refresh core
		snap install --classic certbot
		ln -s /snap/bin/certbot /usr/bin/certbot
		echo "Please input the Certbot Wizard for enable SSL."
		echo "If needed, re-run 'certbot --nginx' multiple times."
		echo "## REMEMBER TO CHECK IF DNS RECORDS FOR 'netdata.' AND 'portainer.' MATCH THE IP OF THE VPS"
		read -p "Press enter to continue"
		clear
		certbot --nginx
		clear
		echo "Netdata Site Created and deployed on: net.lyzcoote.gay"
	else 
		echo "Do you want to install certbot for Nginx?"
		echo "(Y/n)? "
		read RESPONSE
		if [[ $RESPONSE == [Yy]* ]]; then
			echo "## Installing Certbot for Nginx "
			snap install core
			snap refresh core
			snap install --classic certbot
			ln -s /snap/bin/certbot /usr/bin/certbot
		else 
			echo "Not installing Certbot"
		fi
	fi
else 
	echo "You may need to configure the Nginx's Virtual Hosts manually"	
fi


echo -ne "
-------------------------------------------------------------------------
                                  Done!
-------------------------------------------------------------------------
"
exit 0