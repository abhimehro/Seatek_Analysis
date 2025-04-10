[![CodeQL Advanced](https://github.com/abhimehro/Seatek_Analysis/actions/workflows/codeql.yml/badge.svg)](https://github.com/abhimehro/Seatek_Analysis/actions/workflows/codeql.yml)

# Seatek Analysis (R-Tier)

## Project Overview
This repository contains the R-based analysis tier for processing Seatek sensor data and generating Excel workbooks. It is part of a three-tier analysis system:

1. **R-Tier (This Repository)**: Handles data entry, conversions, and primary analyses
2. **Excel-Tier**: Manages intermediate data processing and basic visualizations
3. **Python-Tier**: Handles advanced data visualization and large-scale data processing

## Repository Structure
```
.
├── Data/
│   ├── Series_26/        # Series 26 sensor data and analysis
│   ├── Series_27/        # Series 27 sensor data and analysis
│   ├── Raw_Data_*.xlsx   # Raw data files by year
│   ├── S26_*.txt         # Processed text files for Series 26
│   └── *_Data.xlsx      # Processed data workbooks
├── Seatek_Analysis.R     # Main analysis script
└── Seatek_Analysis.Rproj # R project configuration
```

## Setup and Usage
1. Clone this repository
2. Open the project in RStudio using `Seatek_Analysis.Rproj`
3. Install required R packages (list will be provided in requirements.R)
4. Run analyses using the main script: `Seatek_Analysis.R`

## Data Flow
1. Raw data is processed through R scripts
2. Generated Excel workbooks are used by the Python tier for visualization
3. Results feed into the broader analysis system

## Related Repositories
- [Hydrograph_Versus_Seatek_Sensors_Project](https://github.com/abhimehro/Hydrograph_Versus_Seatek_Sensors_Project) - Python visualization tier

## Requirements
- R >= 4.0.0
- RStudio (recommended)
- Required R packages (see requirements.R)

## Contributing
1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
