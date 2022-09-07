#!/bin/bash


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
    RAW_DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
    if [[ $RAW_DISTRO==Arch* ]]; then
        echo "Running $RAW_DISTRO"
        pacman -Syy
        pacman -Syu --noconfirm
        pacman -S htop vim nano wget curl git ncdu zsh --noconfirm
    else
        echo "Can't detect current distro!"
        exit 1
    fi
fi

echo -ne "
-------------------------------------------------------------------------
                                  Done!
-------------------------------------------------------------------------
"
exit 0