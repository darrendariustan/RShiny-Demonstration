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

# Create symbolic links in user's home directory
for dir in data src; do
    if [ ! -L "/home/$USER/$dir" ]; then
        ln -s "/$dir" "/home/$USER/$dir"
    fi
done

# Fix ownership
chown -R "$USER:$USER" "/home/$USER"
chown -h "$USER:$USER" /home/$USER/data /home/$USER/src

# Deploying app from /src directly to /srv/shiny-server/
echo "Deploying app from /src directly to /srv/shiny-server/"

# Clear the target directory to avoid recursion but preserve the sample app
mkdir -p /tmp/sample-apps
cp -r /srv/shiny-server/sample-apps /tmp/

# Clear the shiny-server directory
rm -rf /srv/shiny-server/*

# Restore sample apps directory
mkdir -p /srv/shiny-server/sample-apps
cp -r /tmp/sample-apps/* /srv/shiny-server/sample-apps/

# Copy all files from /src to /srv/shiny-server/
cp -r /src/* /srv/shiny-server/

# Set permissions
chmod -R 755 /srv/shiny-server/

echo "User '$USER' created with password '$PASSWORD'"
echo "Shared app available at '/srv/shiny-server/'"

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
