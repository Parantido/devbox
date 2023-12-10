#!/bin/bash

USERNAMES_FILE=".users.db"
NGINX_TEMPLATE="./templates/nginx_template.conf"
DOCKER_COMPOSE_TEMPLATE="./templates/docker-compose_head-template.yml"

# Check if the created_domains.txt file exists, create it if not
if [ ! -e "$USERNAMES_FILE" ]; then
	touch "$USERNAMES_FILE"
fi

# This function will check if the username supplied is valid
is_valid_username() {
	# Check if the string matches a valid domain pattern
	[[ "$1" =~ ^[a-zA-Z0-9]+$ ]]
}

# This function will check if the dev username already exists
username_exists() {
	grep -q "^$1$" $USERNAMES_FILE
}

# This Function will add a new dev seat
add_dev() {
	local userInput=""

	while [ -z "$userInput" ]; do
		echo -ne "	$(ColorBlue 'Please provide the new dev username:') "
		read -p " " userInput
		if [ $? == 1 ] || [ -z "$userInput" ] ; then
			echo -e "	$(ColorRed 'ee)') Operation aborted!"
			sleep 1
			exit 1
		fi
		# Validate the input
		if ! is_valid_username "$userInput"; then
			echo -e "	$(ColorRed 'ee)') Invalid entry. Please enter a valid username!" 
			sleep 1
			userInput=""
		fi
		# Check if the username already exists
		if username_exists "$userInput"; then
			# Return a warning and check for a new username
			echo -e "	$(ColorOrange '!!)') Username $userInput already exists. Please provide a different one?"
			sleep 1
			userInput=""
		fi
	done

	# Add the new domain to the list
	echo "$userInput" >> $USERNAMES_FILE
	echo -e "	$(ColorGreen 'Dev seat successfully added!')"
	sleep 1
}

del_dev() {
	local userInput=""

	while [ -z "$userInput" ]; do
		echo -ne "	$(ColorBlue 'Please provide the dev username to delete:') "
		read -p " " userInput
		if [ $? == 1 ] || [ -z "$userInput" ] ; then
			echo -e "	$(ColorRed 'ee)') Operation aborted!"
			sleep 1
			exit 1
		fi
		# Validate the input
		if ! is_valid_username "$userInput"; then
			echo -e "	$(ColorRed 'ee)') Invalid entry. Please enter a valid username!" 
			sleep 1
			userInput=""
		fi
		# Check if the username already exists
		if username_exists "$userInput"; then
			# Ask user if they want to remove the existing username
			echo -e "	$(ColorOrange '!!)') Do you really want to remove $userInput seat? (yes/no)"
			read -p " " answer 
			case $answer in
				[Yy][Ee][Ss])
					sed -i "/^$userInput$/d" $userInputS_FILE
					# rm "nginx_$userInput.conf"
					echo "$userInput seat removed successfully."
					sleep 1
					;;
				*)
					echo -e "	$(ColorRed 'ee)') Invalid answer!" 
					sleep 1
					userInput=""
					;;
			esac
		fi
	done
}

list_dev() {
	count=0
	while IFS= read -r line
	do
		((count+=1))
		echo "	> $(ColorGreen $count) $line on port $(ColorOrange $count)"
	done < $USERNAMES_FILE

	# Wait for an input to continue
	echo -ne "	$(ColorOrange '!!)') Press a key to continue"
	read -p " " justakey
}

rewrite_conf() {
	# Set up paths
	NGINX_OUTPUT="nginx_${USERNAME}.conf"
	DOCKER_COMPOSE_OUTPUT="docker-compose_${USERNAME}.yml"

	# Create Nginx configuration file
	cp $NGINX_TEMPLATE $NGINX_OUTPUT
	sed -i "s/{{USERNAME}}/$USERNAME/g" $NGINX_OUTPUT
	
	# Create Docker Compose file
	cp $DOCKER_COMPOSE_TEMPLATE $DOCKER_COMPOSE_OUTPUT
	sed -i "s/{{USERNAME}}/$USERNAME/g" $DOCKER_COMPOSE_OUTPUT
	
	echo "Configuration files generated:"
	echo "Nginx Configuration: $NGINX_OUTPUT"
	echo "Docker Compose File: $DOCKER_COMPOSE_OUTPUT"
}

find_next_available_number() {
	local non_sequential_numbers=("$@")
	local min_choosable_number=$1
	local max_choosable_number=$2

	for (( number=min_choosable_number; number<=max_choosable_number; number++ )); do
		if [[ ! " ${non_sequential_numbers[@]} " =~ " $number " ]]; then
			echo "$number"
			return 0
		fi
	done

    # No available number found
    echo "Error: No available number found within the specified range."
    return 1
}

##
# Color  Variables
##
red='\e[31m'
green='\e[32m'
orange='\e[33m'
blue='\e[34m'
clear='\e[0m'

##
# Color Functions
##
ColorRed() {
	echo -ne $red$1$clear
}
ColorGreen() {
	echo -ne $green$1$clear
}
ColorOrange() {
	echo -ne $orange$1$clear
}
ColorBlue() {
	echo -ne $blue$1$clear
}

menu() {
	printf "\033c"
	echo -ne "
	DevBox Helper
	$(ColorGreen '1)') Add a new dev seat
	$(ColorGreen '2)') Delete a dev seat
	$(ColorGreen '3)') List all seats
	$(ColorGreen '4)') Rewrite docker-compose.yml
	$(ColorGreen '0)') Exit
	$(ColorBlue 'Choose an option:') "
	read a
	case $a in
		1) add_dev ; menu ;;
		2) del_dev ; menu ;;
		3) list_dev ; menu ;;
		4) rewrite_conf ; menu ;;
		0) printf "\033c" ; exit 0 ;;
		*) echo -e $red "	Wrong option." $clear; sleep 1 ; menu ;;
	esac
}

# Call the menu function
menu

# Dead code ?
exit 0
