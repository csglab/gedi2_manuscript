# Environment Setup Guide

This guide provides detailed instructions for setting up your environment to reproduce the GEDI 2 manuscript analyses.

## Table of Contents
- [R Installation](#r-installation)
- [Package Installation](#package-installation)
- [System Dependencies](#system-dependencies)
- [Verification](#verification)
- [Configuration](#configuration)

## R Installation

### Recommended Version
- **R 4.0 or higher** is recommended
- Check your R version: `R --version`

### Installation by Platform

#### macOS
```bash
# Using Homebrew
brew install r

# Or download from CRAN
# Visit: https://cran.r-project.org/bin/macosx/
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install r-base r-base-dev
```

#### Linux (CentOS/RHEL)
```bash
sudo yum install R
```

#### Windows
Download and install from [CRAN](https://cran.r-project.org/bin/windows/base/)

## Package Installation

### Core R Packages

Open R and run:

```r
# Install core dependencies
install.packages(c(
  "Matrix",
  "data.table",
  "rsvd",
  "R6",
  "ggplot2",      # For plotting
  "dplyr",        # Data manipulation
  "tidyr"         # Data tidying
))
```

### GEDI Packages

You'll need both the legacy and new versions of GEDI for comparison:

#### Legacy GEDI

```r
# Option 1: From CRAN (if available)
install.packages("GEDI")

# Option 2: From source
# Download the package and install locally
install.packages("path/to/GEDI_legacy.tar.gz", repos = NULL, type = "source")
```

#### New GEDI Implementation

```r
# Option 1: From CRAN (if available)
install.packages("gedi")

# Option 2: From GitHub (recommended for latest version)
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::install_github("csglab/gedi")
```

### Verify Package Installation

```r
# Check that packages load correctly
library(Matrix)
library(data.table)
library(rsvd)
library(R6)
library(GEDI)  # Legacy version
library(gedi)  # New version

# Check versions
packageVersion("GEDI")
packageVersion("gedi")
```

## System Dependencies

### wget (for data download)

#### macOS
```bash
brew install wget
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install wget
```

#### Linux (CentOS/RHEL)
```bash
sudo yum install wget
```

#### Windows
- Download from [GNU Wget](https://www.gnu.org/software/wget/)
- Or use Windows Subsystem for Linux (WSL)

### psrecord (for benchmarking)

The benchmarking scripts use `psrecord` to profile memory and CPU usage:

```bash
# Run the provided installation script
cd panel-C-and-E
bash 3.1.install_psrecord.sh

# Or install manually
pip install psrecord
# or
pip3 install psrecord
```

### Python (for psrecord)

If you don't have Python installed:

#### macOS
```bash
brew install python3
```

#### Linux
```bash
sudo apt-get install python3 python3-pip
```

## System Requirements

### Memory (RAM)

- **Minimum**: 16GB
- **Recommended**: 32GB or more
- **For full dataset**: 64GB ideal

If you have limited RAM:
- Process data in batches
- Use a subset of cells for testing
- Close other applications during processing

### Storage

- **Data files**: ~30-40GB
- **Processed files**: ~10-20GB  
- **Results and figures**: ~1-5GB
- **Total recommended**: 50GB+ free space

### CPU

- **Minimum**: 4 cores
- **Recommended**: 8+ cores for faster processing
- The new GEDI implementation supports multi-threading

## Configuration

### Setting Thread Count

For optimal performance with the new GEDI implementation, set the number of threads:

```r
# In your R scripts, set num_threads parameter
model <- CreateGEDIObject(
  Samples = Sample_vec, 
  M = M, 
  K = 10, 
  verbose = 1, 
  num_threads = 8  # Adjust based on your CPU cores
)
```

Check available cores:
```r
parallel::detectCores()
```

### Memory Management

If you encounter memory issues:

```r
# Increase memory limit (Windows)
memory.limit(size = 32000)  # 32GB

# Force garbage collection
gc()

# Monitor memory usage
pryr::mem_used()
```

### Path Configuration

Some scripts use `Data/` (capital D) while the repository uses `data/` (lowercase). You may need to update paths in scripts:

```r
# Update in scripts as needed:
# Change: M <- readRDS("Data/WMB_ATLAS_10X_V3.rds")
# To:     M <- readRDS("data/WMB_ATLAS_10X_V3.rds")
```

## Verification

### Test Your Setup

Run this verification script to ensure everything is configured correctly:

```r
# verification_test.R
cat("=== Environment Verification ===\n\n")

# Check R version
cat("R Version:", R.version.string, "\n")

# Check required packages
required_packages <- c("Matrix", "data.table", "rsvd", "R6", "GEDI", "gedi")
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✓", pkg, "version", as.character(packageVersion(pkg)), "\n")
  } else {
    cat("✗", pkg, "NOT INSTALLED\n")
  }
}

# Check system resources
cat("\nSystem Resources:\n")
cat("Available cores:", parallel::detectCores(), "\n")
cat("Memory info:\n")
print(gc())

cat("\n=== Verification Complete ===\n")
```

Save this as `verification_test.R` and run:
```bash
Rscript verification_test.R
```

### Expected Output

You should see:
- R version 4.0 or higher
- All required packages installed with version numbers
- Available CPU cores
- Memory information

## Troubleshooting Setup Issues

### Package Compilation Errors

If packages fail to compile, install system dependencies:

#### Ubuntu/Debian
```bash
sudo apt-get install \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libgit2-dev \
  libfontconfig1-dev \
  libharfbuzz-dev \
  libfribidi-dev
```

#### macOS
```bash
brew install openssl libxml2 libgit2
```

### GEDI Installation Issues

If you have trouble installing GEDI packages:

1. **Check R version**: Ensure R >= 4.0
2. **Install from source**: Download the package source and install locally
3. **Check dependencies**: Install all required dependencies first
4. **Contact maintainers**: Reach out to the package maintainers for support

### Permission Issues

If you encounter permission errors:

```bash
# Create a personal R library directory
mkdir -p ~/R/library

# Set in R
.libPaths(c("~/R/library", .libPaths()))
```

Or install packages with:
```r
install.packages("package_name", lib = "~/R/library")
```

## Next Steps

After completing setup:

1. Verify all packages are installed correctly
2. Proceed to [README.md](README.md) for the analysis workflow
3. Start with data download (Step 1)

## Getting Help

If you encounter issues not covered here:

1. Check the main [README.md](README.md) troubleshooting section
2. Review package documentation
3. Open an issue on GitHub
4. Contact the repository maintainers

---

**Last Updated**: November 2025
