# GEDI 2 Manuscript - Reproducible Code

This repository contains reproducible code for generating the figures and analyses presented in the GEDI 2 manuscript. All scripts are numbered sequentially to guide you through the complete workflow.

## Overview

This repository provides a complete pipeline for reproducing the computational analyses and figures from the GEDI 2 manuscript, demonstrating improvements in the GEDI  method for analyzing single-cell RNA sequencing data.

## Prerequisites

### System Requirements
- **R version**: 4.0 or higher recommended
- **RAM**: At least 32GB (32GB+ recommended for full dataset)
- **Storage**: ~50GB for downloaded data and intermediate files
- **OS**: Linux, macOS, or Windows with R installed

### Required R Packages

The following R packages are required:

```r
# Core packages
install.packages(c("Matrix", "data.table", "rsvd", "R6"))

# GEDI packages
# Legacy GEDI (for comparison)
install.packages("GEDI")  # or install from source if needed

# New GEDI implementation
install.packages("gedi")  # or install from GitHub
# devtools::install_github("csglab/gedi")
```

### Additional Tools
- **wget**: Required for downloading data (step 1)
- **psrecord**: Required for benchmarking (install via `panel-C-and-E/3.1.install_psrecord.sh`)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone git@github.com:csglab/gedi2_manuscript.git
   cd gedi2_manuscript
   ```

2. **Download and preprocess data** (steps 1-2)
3. **Run analyses** for specific panels (steps 3-10)
4. **Check outputs** in `results/` and `figures/` directories

## Repository Structure

```
gedi2_manuscript/
├── data/                          # Data download and preprocessing scripts
│   ├── 1.download_via_wget.sh    # Download Allen Brain Atlas data
│   ├── 2.input_pre_proccess.R    # Preprocess expression matrices
│   ├── download_urls.txt         # URLs for data files
│   └── high_variable_genes_vector.rds  # Pre-selected high variable genes
├── panel-B/                       # Scripts for Figure Panel B
│   ├── 5.train_legacy_model.R    # Train legacy GEDI model
│   ├── 6.train_new_model.R       # Train new GEDI model
│   └── 7.scatter_plots_panel_B.R # Generate scatter plots
├── panel-C-and-E/                 # Scripts for Figure Panels C and E
│   ├── 3.1.install_psrecord.sh   # Install benchmarking tool
│   ├── 3.2.run_benchmark.sh      # Run benchmark wrapper
│   ├── 3.run_benchmark.R         # Benchmark script
│   └── 4.generate_plots.R        # Generate benchmark plots
├── panel-D/                       # Scripts for Figure Panel D
│   └── 8.line_plot_panel_D.R     # Generate line plots
├── panel-F/                       # Scripts for Figure Panel F
│   ├── 9.run_benchmark.R         # Benchmark script
│   ├── 9.run_benchmark.sh        # Run benchmark wrapper
│   └── 10.generate_plots.R       # Generate plots
├── results/                       # Generated models and intermediate files
└── figures/                       # Generated figures and plots
```

## Step-by-Step Workflow

### Step 1: Download Data

Download the Allen Brain Atlas 10X Chromium v3 dataset:

```bash
cd data
bash 1.download_via_wget.sh
```

**Expected output**: 
- Directory `data/Allen-brain-10X-V3/` containing `.h5ad` files
- Download time: ~30-60 minutes depending on connection speed

### Step 2: Preprocess Data

Process the downloaded data and extract high variable genes:

```bash
Rscript 2.input_pre_proccess.R
```

**Expected output**:
- `data/WMB_ATLAS_10X_V3.rds` - Preprocessed expression matrix
- Processing time: ~10-30 minutes depending on system

**Note**: Ensure the path in the script matches your data location. The script expects data in `Data/Allen-brain-10X-V3/` (capital D).

### Step 3-4: Benchmark Analysis (Panels C and E)

Install benchmarking tool and run performance comparison:

```bash
cd ../panel-C-and-E

# Install psrecord for profiling
bash 3.1.install_psrecord.sh

# Run benchmarks (this will take significant time)
bash 3.2.run_benchmark.sh

# Generate plots
Rscript 4.generate_plots.R
```

**Expected output**:
- Benchmark logs and profiles in `panel-C-and-E/`
- Performance comparison plots for Panels C and E

**Parameters**: The benchmark script tests different methods, thread counts, and cell numbers. Edit `3.2.run_benchmark.sh` to customize.

### Step 5-7: Model Training and Comparison (Panel B)

Train both legacy and new GEDI models and generate comparison plots:

```bash
cd ../panel-B

# Train legacy GEDI model
Rscript 5.train_legacy_model.R

# Train new GEDI model
Rscript 6.train_new_model.R

# Generate scatter plots comparing models
Rscript 7.scatter_plots_panel_B.R
```

**Expected output**:
- `legacy_gedi_model.rds` - Trained legacy model
- `new_gedi_model.rds` - Trained new model (if saved)
- Scatter plots showing model comparison for Panel B

**Training time**: ~5-20 minutes per model depending on system

### Step 8: Line Plot Generation (Panel D)

Generate line plots for Panel D:

```bash
cd ../panel-D
Rscript 8.line_plot_panel_D.R
```

**Expected output**:
- Line plots for Panel D showing performance metrics

### Step 9-10: Additional Benchmarks (Panel F)

> [!WARNING]
> For this panel, you will need access to a high-performance computing environment. It requires **at least 150 GB of RAM** and **15+ threads**.


Run additional benchmarking analysis:

```bash
cd ../panel-F

# Run benchmarks
bash 9.run_benchmark.sh

# Generate plots
Rscript 10.generate_plots.R
```

**Expected output**:
- Benchmark results and plots for Panel F

---

**Last Updated**: November 2025
