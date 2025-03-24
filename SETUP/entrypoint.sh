#!/bin/bash

echo "Starting RStudio and Shiny Server with a single user"

# Create the user
USER="team3"
PASSWORD="team3_12345678!"

echo "Creating user: $USER"
useradd -m "$USER" -s /bin/bash
echo "$USER:$PASSWORD" | chpasswd

# Create app directory in Shiny server
mkdir -p /srv/shiny-server/app
chmod 755 /srv/shiny-server/app

# Create symbolic links in user's home directory
if [ ! -L /home/$USER/data ]; then
    ln -s /data /home/$USER/data
fi

if [ ! -L /home/$USER/src ]; then
    ln -s /src /home/$USER/src
fi

if [ ! -L /home/$USER/app ]; then
    ln -s /srv/shiny-server/app /home/$USER/app
fi

# Fix ownership
chown -R $USER:$USER /home/$USER
chown -h $USER:$USER /home/$USER/app /home/$USER/data /home/$USER/src


# Deploying app from /src to /srv/shiny-server/app
echo "Deploying app from /src to /srv/shiny-server/app"

# Clear the target directory to avoid recursion
rm -rf /srv/shiny-server/app/*

# Copy only the contents of /src, excluding the app directory itself
cp -r /src/* /srv/shiny-server/app/

chmod -R 755 /srv/shiny-server/app

echo "User '$USER' created with password '$PASSWORD'"
echo "Shared app available at '/srv/shiny-server/app'"

# Start RStudio Server
if command -v rstudio-server &> /dev/null; then
    echo "Starting RStudio Server..."
    rstudio-server start
else
    echo "RStudio Server is not installed!"
fi

# Start Shiny Server
if command -v shiny-server &> /dev/null; then
    echo "Starting Shiny Server..."
    shiny-server
else
    echo "Shiny Server is not installed!"
fi

# Keep the container running
tail -f /dev/null