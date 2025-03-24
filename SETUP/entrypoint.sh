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

if [ -d "/srv/shiny-server/app" ]; then
    rm -rf /srv/shiny-server/app/*
fi

rsync -av --exclude='/srv/shiny-server/app' /src/ /srv/shiny-server/app/
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
