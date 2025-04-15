# Traffic Accidents Analysis Dashboard
[![Deployed App](https://img.shields.io/badge/Live%20App-Traffic%20Accidents%20Dashboard-brightgreen)](https://traffic-accidents-shiny.onrender.com/)

**Access the live R Shiny application here:**
👉 [https://traffic-accidents-shiny.onrender.com/](https://traffic-accidents-shiny.onrender.com/)

**Team 3 - Group Project for Data Analytics with R**

A comprehensive Shiny dashboard for analyzing traffic accidents data across multiple countries. The dashboard provides interactive visualizations including heatmaps, time series analysis, and severity correlations.

## Features

- **Interactive Map Visualization**
  - Heatmap showing accident density
  - Individual accident markers with severity information
  - Dynamic country-based filtering
  - Clustered markers for better performance

- **Time Series Analysis**
  - Stacked bar chart showing accident distribution by severity
  - Average severity score trend line
  - Year range selection
  - Severity level filtering

- **Risk Analysis**
  - Correlation analysis between risk factors and accident severity
  - Weather condition impact analysis
  - Severity score distribution

## Data

The dashboard uses processed accident data with the following key features:
- Geographic coordinates (Latitude/Longitude)
- Accident severity levels (Minor to Critical)
- Weather conditions
- Temporal data (Year)
- Severity scores
- Economic impact metrics
- Response times

## Project Structure

```
r-final-project/
├── DATA/               # Data files and processed datasets
├── SRC/               # Application source code
│   ├── app.R         # Main Shiny application
│   └── data_processing.R  # Data processing scripts
├── SETUP/             # Docker and deployment configuration
│   ├── dockerfile    # Docker configuration
│   ├── docker-compose.yaml # Docker Compose configuration
│   ├── .dockerignore # Docker ignore patterns
│   ├── entrypoint.sh # Container startup script
│   ├── setup_domain.sh # Domain setup configuration
│   └── requirements.R # R package requirements
├── INSTRUCTIONS/      # Project instructions and guidelines
├── LICENSE           # MIT License
├── README.md         # Project documentation
└── .gitignore       # Git ignore patterns
```

## Technical Requirements

- R 4.0 or higher
- Docker and Docker Compose
- Minimum 8GB RAM (6GB allocated to container)
- Sufficient disk space for data storage

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd r-final-project
```

2. Build and run the Docker container:
```bash
cd SETUP
docker build -t traffic-accidents-dashboard .
docker run -d -p 3838:3838 -p 8787:8787 traffic-accidents-dashboard
```

## Usage

### Accessing the Application

1. **Shiny Dashboard**:
   - Open http://localhost:3838/app in your browser
   - Use the sidebar filters to analyze different aspects of the data
   - Interact with the map and visualizations

2. **RStudio Development**:
   - Open http://localhost:8787 in your browser
   - Login credentials:
     - Username: team3
     - Password: team3_12345678!

### Data Processing

The data processing pipeline is located in `SRC/data_processing.R`. This script:
- Cleans and preprocesses raw data
- Generates geographic coordinates
- Calculates derived metrics
- Exports processed data for the dashboard

> Note: Run locally before push/pulling into your deployment server or change the `.dockerignore` file if you want to preprocess the data in the server.

### Development Workflow

1. Make changes to the source code in `SRC/`
2. Rebuild the container if dependencies change:
```bash
docker-compose down # to stop and remove existing container
docker-compose build # optional: add --no-cache for changes to libraries to rebuild the image
docker-compose up -d # to create & run the container in the background
```

### Deployment with Custom Domain

For deploying to a server with a custom domain:

1. **Prerequisites**:
   - A server with Docker and Docker Compose installed
   - A domain name pointing to your server
   - Root/sudo access for SSL certificate setup

2. **Setup Steps**:
```bash
cd SETUP

# Make the setup script executable
chmod +x setup_domain.sh

# Run the setup script with your domain
sudo ./setup_domain.sh your-domain.com
```

This will:
- Install and configure Nginx as a reverse proxy
- Set up SSL certificates using Let's Encrypt
- Configure your domain to serve:
  - RStudio at: `https://your-domain.com`
  - Shiny app at: `https://your-domain.com/shiny/`

3. **Start the Application**:
```bash
# Start the containers
docker-compose up -d

# Check logs if needed
docker-compose logs
```

4. **Access the Application**:
   - RStudio: `https://your-domain.com` (same credentials as local setup)
   - Shiny Dashboard: `https://your-domain.com/shiny/app`

> Note: Make sure ports 80 and 443 are open on your server for the SSL setup to work.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Data source: [Global Road Accidents Dataset](https://www.kaggle.com/datasets/ankushpanday1/global-road-accidents-dataset) - synthetically generated (in a really bad way), so it required a lot of pre-processing to make it usuable / extract insights, because all variables are evenly distributed
- R packages and their maintainers
- Team members
- Ruben & Adriá