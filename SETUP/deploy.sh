#!/bin/bash

# Define variables
REPO_URL="https://github.com/yourusername/r-final-project.git"
REPO_BRANCH="main"
APP_DIR="/srv/shiny-server/app"
TEMP_DIR="/tmp/r-final-project"

echo "=== Deploying Shiny App from GitHub ==="

# Pull latest code
echo "Pulling latest code from GitHub..."
rm -rf $TEMP_DIR
git clone --branch $REPO_BRANCH $REPO_URL $TEMP_DIR

# Copy app files to Shiny server
echo "Copying files to Shiny server..."
sudo rm -rf $APP_DIR/*
sudo cp -r $TEMP_DIR/SRC/* $APP_DIR/
sudo cp -r $TEMP_DIR/DATA $APP_DIR/

# Fix path in app.R
echo "Updating data path in app.R..."
sudo sed -i 's|data <- read.csv("../DATA/road_accidents_dataset.csv")|data <- read.csv("DATA/road_accidents_dataset.csv")|g' $APP_DIR/app.R

# Set permissions
echo "Setting permissions..."
sudo chmod -R 755 $APP_DIR

# Clean up
rm -rf $TEMP_DIR

echo "=== Deployment complete! ==="
echo "Your app should be available at: http://your-server-ip:3838/app/"