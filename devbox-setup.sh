#!/bin/bash

USERNAMES_FILE=".users.db"
COMPOSE_OUT_PATH="./composers.d"
NGINX_OUT_PATH="./mounts/nginx/conf.d"
NGINX_TEMPLATE="./templates/nginx_template.conf"
DC_HEAD_TEMPLATE="./templates/docker-compose_head-template.yml"
DC_DELTA_TEMPLATE="./templates/docker-compose_delta-template.yml"

# Retrieve OS commands abs path
CP=`which cp`
RM=`which rm`
TR=`which tr`
WC=`which wc`
CAT=`which cat`
CUT=`which cut`
SED=`which sed`
ECHO=`which echo`
FOLD=`which fold`
GREP=`which grep`
HEAD=`which head`
TOUCH=`which touch`
NETSTAT=`which netstat`

# Check if the created_domains.txt file exists, create it if not
if [ ! -r "$USERNAMES_FILE" ]; then
	$TOUCH "$USERNAMES_FILE"
fi

# This function will check if the username supplied is valid
is_valid_username() {
	# Check if the string matches a valid domain pattern
	[[ "$1" =~ ^[a-zA-Z0-9]+$ ]]
}

# This function will check if the dev username already exists
username_exists() {
	$GREP -q "^$1|" $USERNAMES_FILE
}

# This function will check for an already existing port 
# associated to a dev
port_exists() {
	while IFS= read -r line
	do
		line_arr=(${line//|/ })
		if [ "${line_arr[1]}" == "$1" ]; then
			# 0 = true
			return 0
		fi
	done < $USERNAMES_FILE

	# 1 = false
	return 1
}

isdev_empty() {
	num=$(${WC} -m ${USERNAMES_FILE} | $CUT -d' ' -f 1)
	if [ "$num" -gt "1" ]; then
		# 1 = false
		return 1
	fi

	# 1 = false
	return 0
}

# This Function will add a new dev seat
add_dev() {
	local userInput=""
	local portInput=""

	# Autogenerate a random password
	PASSWORD=$($TR -cd '[:alnum:]' < /dev/urandom | $FOLD -w15 | $HEAD -n 1)

	while [ -z "$userInput" ]; do
		$ECHO -ne "	$(ColorBlue 'Please provide the new dev username (no input to return):') "
		read -p " " userInput
		if [ $? == 1 ] || [ -z "$userInput" ] ; then
			$ECHO -e "	$(ColorRed 'ee)') Operation aborted!"
			sleep 1
			return 1
			userInput=""
		fi
		# Validate the input
		if ! is_valid_username "$userInput"; then
			$ECHO -e "	$(ColorRed 'ee)') Invalid entry. Please enter a valid username!" 
			sleep 1
			userInput=""
		fi
		# Check if the username already exists
		if username_exists "$userInput"; then
			# Return a warning and check for a new username
			$ECHO -e "	$(ColorOrange '!!)') Username $userInput already exists. Please provide a different one!"
			sleep 1
			userInput=""
		fi
	done

	while [ -z "$portInput" ]; do
		$ECHO -ne "	$(ColorBlue 'Please provide the new dev seat binding port (no input to return):') "
		read -p " " portInput
		if [ $? == 1 ] || [ -z "$portInput" ] ; then
			$ECHO -e "	$(ColorRed 'ee)') Operation aborted!"
			sleep 1
			return 1
			portInput=""
		fi
		# Check if the username already exists
		if port_exists "$portInput"; then
			# Return a warning and check for a new port
			$ECHO -e "	$(ColorOrange '!!)') Port $portInput already exists. Please provide a different one!"
			sleep 1
			portInput=""
		fi
		# Check if the port is already bound in the system
		resp=`$NETSTAT -tunl | $GREP ":$portInput "`
		if [ ! -z "$resp" ]; then
			$ECHO -ne "	$(ColorOrange '!!)') Port $portInput is already bound on local system, do you want to continue? (yes/no): "
			read -p " " answer 
			case $answer in
				[Yy][Ee][Ss])
					$ECHO -e "	$(ColorOrange '!!)') Forcing the binding assigment ..."
					sleep 1
					;;
				[Nn][Oo])
					$ECHO -e "	$(ColorRed 'ee)') Operation aborted!"
					sleep 1
					return 1
					portInput=""
					;;
				*)
					$ECHO -e "	$(ColorRed 'ee)') Invalid answer!" 
					sleep 1
					portInput=""
					;;
			esac
		fi
	done

	# Add the new domain to the list
	$SED -i '/^$/d' $USERNAMES_FILE
	$ECHO "$userInput|$portInput|$PASSWORD" >> $USERNAMES_FILE
	$ECHO -e "	$(ColorGreen 'Dev seat successfully added!')"
	sleep 1
}

del_dev() {
	local userInput=""

	while [ -z "$userInput" ]; do
		$ECHO -ne "	$(ColorBlue 'Please provide the dev username to delete (no input to return):') "
		read -p " " userInput
		if [ $? == 1 ] || [ -z "$userInput" ] ; then
			$ECHO -e "	$(ColorRed 'ee)') Operation aborted!"
			sleep 1
			return 1
			userInput=""
		fi
		# Validate the input
		if ! is_valid_username "$userInput"; then
			$ECHO -e "	$(ColorRed 'ee)') Invalid entry. Please enter a valid username!" 
			sleep 1
			userInput=""
		fi
		# Check if the username already exists
		if username_exists "$userInput"; then
			# Ask user if they want to remove the existing username
			$ECHO -ne "	$(ColorOrange '!!)') Do you really want to remove $userInput seat? (yes/no): "
			read -p " " answer 
			case $answer in
				[Yy][Ee][Ss])
					$SED -i '/^$/d' $USERNAMES_FILE
					$SED -i "/^$userInput$/d" $USERNAMES_FILE
					$ECHO -e "	$userInput seat removed successfully."
					sleep 1
					;;
				*)
					$ECHO -e "	$(ColorRed 'ee)') Invalid answer!" 
					sleep 1
					userInput=""
					;;
			esac
		fi
	done
}

list_dev() {
	# File maintenance
	$SED -i '/^$/d' $USERNAMES_FILE

	count=0
	while IFS= read -r line
	do
		line_arr=(${line//|/ })
		$ECHO "	> $(ColorGreen ${line_arr[0]}) on port $(ColorOrange ${line_arr[1]})"
	done < $USERNAMES_FILE

	# Wait for an input to continue
	$ECHO -ne "	$(ColorOrange '!!)') Press a key to continue"
	read -p " " justakey
}

rewrite_conf() {
	# Check for dev existence before proceeding
	if isdev_empty ; then
		$ECHO -e "	$(ColorRed 'ee)') No dev seats configured, please create some before!" 
		sleep 1
		return 1
	fi

	# Check for default out paths, if does
	# not exists just create it!
	if [ ! -d "${NGINX_OUT_PATH}" ]; then
		mkdir -p "${NGINX_OUT_PATH}"
	fi
	if [ ! -d "${COMPOSE_OUT_PATH}" ]; then
		mkdir -p "${COMPOSE_OUT_PATH}"
	fi

	# Create the base docker-compose
	DOCKER_COMPOSE_OUTPUT="${COMPOSE_OUT_PATH}/docker-compose.yml"
	$CP "$DC_HEAD_TEMPLATE" "$DOCKER_COMPOSE_OUTPUT"

	$ECHO "	$(ColorGreen 'Configuration files generated'):"
	while IFS= read -r line
	do
		# Split by user and port
		line_arr=(${line//|/ })

		echo "Username size ${#line_arr[0]}, port size ${#line_arr[1]}"

		# Skip the line if invalid
		[[ "${#line_arr[0]}" -le "1" ]] && continue
		[[ "${#line_arr[1]}" -le "1" ]] && continue

		echo "Continuo?"
		sleep 1

		# Delete Nginx configuration file if already exists
		# and dump it again from template
		NGINX_OUTPUT="${NGINX_OUT_PATH}/nginx_${line_arr[0]}.conf"
		[[ -r "${NGINX_OUTPUT}" ]] && $RM -fr "${NGINX_OUTPUT}"
		$CP "$NGINX_TEMPLATE" "$NGINX_OUTPUT"

		# Replace placeholders
		$SED -i "s/{{USERNAME}}/${line_arr[0]}/g" $NGINX_OUTPUT
		$SED -i "s/{{PORT}}/${line_arr[1]}/g" $NGINX_OUTPUT
		$ECHO "	- Nginx Configuration: $(ColorGreen ${NGINX_OUTPUT})"

		# Create Docker Compose file
		DOCKER_COMPOSE_TMP_OUTPUT="${COMPOSE_OUT_PATH}/docker-compose_${line_arr[0]}.yml"
		$CP "$DC_DELTA_TEMPLATE" "$DOCKER_COMPOSE_TMP_OUTPUT"
		$SED -i "s/{{USERNAME}}/${line_arr[0]}/g" $DOCKER_COMPOSE_TMP_OUTPUT
		$SED -i "s/{{PORT}}/${line_arr[1]}/g" $DOCKER_COMPOSE_TMP_OUTPUT
		$CAT "$DOCKER_COMPOSE_TMP_OUTPUT" >> "$DOCKER_COMPOSE_OUTPUT"
		$RM -fr "$DOCKER_COMPOSE_TMP_OUTPUT"
	done < $USERNAMES_FILE

	# Last line
	$ECHO "	- Docker Compose File: $(ColorGreen ${DOCKER_COMPOSE_OUTPUT})"

	# Wait for proper reading
	sleep 2
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
	$ECHO -ne $red$1$clear
}
ColorGreen() {
	$ECHO -ne $green$1$clear
}
ColorOrange() {
	$ECHO -ne $orange$1$clear
}
ColorBlue() {
	$ECHO -ne $blue$1$clear
}

menu() {
	printf "\033c"
	$ECHO -ne "
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
		*) $ECHO -e $red "	Wrong option." $clear; sleep 1 ; menu ;;
	esac
}

# Call the menu function
menu

# Dead code ?
exit 0
