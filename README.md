# Traffic Accidents Analysis Dashboard
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

2. Install required R packages:
```bash
cd SETUP
Rscript requirements.R
```

3. Build and run with Docker:
```bash
docker-compose up -d
```

The application will be available at:
- Dashboard: http://your-server:3838
- RStudio Server: http://your-server:8787

## Docker Configuration

The application runs in a Docker container with the following specifications:
- Base image: rocker/verse
- Memory limit: 6GB
- Memory reservation: 4GB
- Ports: 3838 (Shiny), 8787 (RStudio)
- Volumes:
  - r_home: R package storage
  - shiny_apps: Shiny application files
  - DATA: Accident data
  - SRC: Source code

## Project Structure

```
r-final-project/
├── SRC/
│   └── app.R              # Main Shiny application
├── DATA/
│   └── processed_accidents.RData  # Processed accident data
└── SETUP/
    ├── requirements.R     # R package requirements
    ├── dockerfile        # Docker configuration
    ├── docker-compose.yaml
    ├── entrypoint.sh     # Container startup script
    └── setup_domain.sh   # Domain setup script
```

## Performance Considerations

The dashboard is optimized for performance with:
- Default view limited to recent years
- Focus on severe accidents by default
- Clustered map markers
- Efficient data filtering
- Resource limits in Docker configuration

## Deployment

1. Server Requirements:
   - Linux server with Docker and Docker Compose
   - 8GB RAM minimum
   - Sufficient disk space

2. Deployment Steps:
```bash
# Clone repository
git clone <repository-url>
cd r-final-project

# Build and start containers
cd SETUP
docker-compose up -d
```

3. Monitoring:
```bash
# View logs
docker logs terrific-traffic

# Monitor resources
docker stats terrific-traffic
```

## Acknowledgements

Shoutout to Ruben & Adria