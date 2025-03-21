#!/bin/bash

echo "Starting RStudio and Shiny Server with users from /etc/users.txt"

# Ensure the user list exists
if [[ ! -f /etc/users.txt ]]; then
    echo "Error: /etc/users.txt not found!"
    exit 1
fi

# Ensure data and src directories exist and have proper permissions
mkdir -p /data /src
chmod 777 /data /src

# Create users and set passwords
while IFS=: read -r username password; do
    if ! id "$username" &>/dev/null; then
        echo "Creating user: $username"
        useradd -m "$username" -s /bin/bash
        
        # Create directories for user's Shiny apps
        mkdir -p /srv/shiny-server/${username}
        chown -R ${username}:${username} /srv/shiny-server/${username}
        
        # Create symbolic links to data and src in user's home directory
        if [ ! -L /home/${username}/data ]; then
            ln -s /data /home/${username}/data
        fi
        if [ ! -L /home/${username}/src ]; then
            ln -s /src /home/${username}/src
        fi
        
        # Ensure ownership of symbolic links is correct
        chown -h ${username}:${username} /home/${username}/data /home/${username}/src
    fi
    echo "$username:$password" | chpasswd
done < /etc/users.txt

echo "Users successfully created and passwords set."
echo "Data and source files are available at '/data' and '/src' or as symbolic links in each user's home directory."

# Start both RStudio Server and Shiny Server
exec /init