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
ln -s /srv/shiny-server/app /home/$USER/app
ln -s /data /home/$USER/data
ln -s /src /home/$USER/src

# Fix ownership
chown -R $USER:$USER /home/$USER
chown -h $USER:$USER /home/$USER/app /home/$USER/data /home/$USER/src

# If app files are mounted at /deploy_app, deploy them to the app directory
if [ -d "/deploy_app" ]; then
    echo "Deploying app from /deploy_app to /srv/shiny-server/app"
    cp -r /deploy_app/* /srv/shiny-server/app/
    chmod -R 755 /srv/shiny-server/app
    
    # Process data if needed
    if [ -f "/srv/shiny-server/app/SRC/data_processing.R" ]; then
        echo "Processing data..."
        Rscript /srv/shiny-server/app/SRC/data_processing.R
    fi
fi

echo "User '$USER' created with password '$PASSWORD'"
echo "Shared app available at '/srv/shiny-server/app'"

# Start both RStudio Server and Shiny Server
exec /init