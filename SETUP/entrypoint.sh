#!/bin/bash

echo "Starting RStudio and Shiny Server with a single user"

# Create the user
USER="team3"
PASSWORD="team3_12345678!"

echo "Creating user: $USER"
# Remove existing user if exists
userdel -r "$USER" 2>/dev/null || true
useradd -m "$USER" -s /bin/bash
echo "$USER:$PASSWORD" | chpasswd

# Create app directory in Shiny server
mkdir -p /srv/shiny-server/app
chmod 755 /srv/shiny-server/app

# Create symbolic links in user's home directory
for dir in data src app; do
    if [ ! -L "/home/$USER/$dir" ]; then
        ln -s "/$dir" "/home/$USER/$dir"
    fi
done

# Fix ownership
chown -R "$USER:$USER" "/home/$USER"
chown -h "$USER:$USER" /home/$USER/app /home/$USER/data /home/$USER/src

# Deploying app from /src to /srv/shiny-server/app
echo "Deploying app from /src to /srv/shiny-server/app"

# Clear the target directory to avoid recursion
rm -rf /srv/shiny-server/app/*

# Copy all files from /src to /srv/shiny-server/app
cp -r /src/* /srv/shiny-server/app/

# Set permissions
chmod -R 777 /srv/shiny-server/app

echo "User '$USER' created with password '$PASSWORD'"
echo "Shared app available at '/srv/shiny-server/app'"

# Start RStudio Server
if command -v rstudio-server &> /dev/null; then
    echo "Starting RStudio Server..."
    rstudio-server start
else
    echo "ERROR: RStudio Server is not installed!"
    exit 1
fi

# Start Shiny Server as root
if command -v shiny-server &> /dev/null; then
    echo "Starting Shiny Server..."
    shiny-server
else
    echo "ERROR: Shiny Server is not installed!"
    exit 1
fi

# Keep the container running
tail -f /dev/null
