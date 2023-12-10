#!/bin/bash

USERNAMES_FILE=".users.db"
NGINX_TEMPLATE="./templates/nginx_template.conf"
DOCKER_COMPOSE_TEMPLATE="./templates/docker-compose_template.yml"

# Check if the created_domains.txt file exists, create it if not
if [ ! -e "$USERNAMES_FILE" ]; then
    touch "$USERNAMES_FILE"
fi

is_valid_username() {
    # Check if the string matches a valid domain pattern
    [[ "$1" =~ ^[a-zA-Z0-9]+$ ]]
}

# Function to check if a domain exists in the system
username_exists() {
    grep -q "^$1$" $USERNAMES_FILE
}

# Function to remove a domain from the system
remove_domain() {
    sed -i "/^$1$/d" $USERNAMES_FILE
    rm "nginx_$1.conf" "docker-compose_$1.yml"
    echo "Username $1 removed successfully."
}

# Function to get user input using whiptail
get_user_input() {
    local prompt="$1"
    local userInput=""

    while [ -z "$userInput" ]; do
        userInput=$(whiptail --inputbox "$prompt" 10 60 3>&1 1>&2 2>&3)
        # Validate the input
        if ! is_valid_username "$userInput"; then
            whiptail --msgbox "Invalid entry. Please enter a valid username." 10 60
            userInput=""
        fi
    done

    echo "$userInput"
}

# Get user input for domain
USERNAME=$(get_user_input "Enter the username to manage:")

# Check if the domain already exists
if username_exists "$USERNAME"; then
    # Ask user if they want to remove the existing domain
    if whiptail --yesno "Username $USERNAME already exists. Do you want to remove it?" 10 60; then
        remove_domain "$USERNAME"
    else
        echo "Error: Username $USERNAME already exists."
        exit 1
    fi
fi

# Add the new domain to the list
echo "$USERNAME" >> $USERNAMES_FILE

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
