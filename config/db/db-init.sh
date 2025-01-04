#!/bin/bash

# Variables for the database credentials
IAM_USERNAME=${IAM_DB_USERNAME}
IAM_PASSWORD=${IAM_DB_PASSWORD}

# SQL script to create user and grant privileges
SQL=$(cat <<EOF
-- Create the 'iam' schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS iam;

-- Create the user with credentials from environment variables
CREATE USER IF NOT EXISTS '${IAM_USERNAME}'@'%' IDENTIFIED BY '${IAM_PASSWORD}';

-- Grant all privileges on the 'iam' schema to the created user
GRANT ALL PRIVILEGES ON iam.* TO '${IAM_USERNAME}'@'%';

-- Apply changes to the database privileges
FLUSH PRIVILEGES;
EOF
)

# Execute the SQL commands
echo "Initializing IAM user and schema..."
echo "$SQL" | mariadb -u root -p"${MARIADB_ROOT_PASSWORD}"
