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
elif if [ $(getent group wheel) ]; then
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
    elif [[$RESPONSE == == [Nn]* ]]; then
        useradd -m -s /bin/bash $USERNAME 
        echo "$USERNAME created, home directory created and default shell set to /bin/bash"
    fi

# use chpasswd to enter $USERNAME:$password
    echo "Setting up password for $USERNAME"
    passwd $USERNAME
fi

echo -ne "
-------------------------------------------------------------------------
                                  Done!
-------------------------------------------------------------------------
"
exit 0