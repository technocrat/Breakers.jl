# Getting Started

## Installation

You can install Breakers.jl from the Julia REPL using:

```julia
using Pkg
Pkg.add("Breakers")
```

## Basic Usage

First, import the package:

```julia
using Breakers
```

### Binning Data into Categories

To bin data into categories (returning string labels for each bin):

```julia
# Sample data
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]

# Get binned data with 5 classes
binned_data = get_bins(values, 5)

# Access specific methods
fisher_bins = binned_data["fisher"]
kmeans_bins = binned_data["kmeans"]
quantile_bins = binned_data["quantile"] 
equal_bins = binned_data["equal"]
```

### Getting Bin Indices

To get bin indices (numeric values from 1 to n) instead of string labels:

```julia
# Get bin indices with 5 classes
bin_indices = get_bin_indices(values, 5)

# Access specific methods
fisher_indices = bin_indices["fisher"]
kmeans_indices = bin_indices["kmeans"]
```

### Handling Missing Values

Breakers.jl handles missing values gracefully:

```julia
# Data with missing values
values_with_missing = [1, 5, missing, 10, 15, 20, missing, 100]

# Get binned data
binned_data = get_bins(values_with_missing, 5)

# Missing values will be labeled as "Missing" in the result
```

### Getting Raw Break Points

If you need just the break points rather than the binned data:

```julia
# Get raw break points
breaks = get_breaks_raw(values, 5)

# Access specific methods
fisher_breaks = breaks["fisher"]
kmeans_breaks = breaks["kmeans"]
```

### Custom Binning with Existing Break Points

You can bin data using existing break points:

```julia
# Define custom breaks
custom_breaks = [0.0, 10.0, 50.0, 100.0]

# Bin data using custom breaks
categories = cut_data(values, custom_breaks)
``` 