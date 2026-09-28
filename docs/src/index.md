# Breakers.jl

*A Julia package for data classification and binning with R's classInt compatibility*

## Overview

Breakers.jl provides functions for creating class intervals for mapping or visualization purposes. The package implements several data binning methods commonly used in spatial data analysis and visualization, with a focus on exact compatibility with R's classInt package.

## Features

- Multiple binning methods including Fisher-Jenks natural breaks, k-means clustering, quantile-based, and equal interval binning
- Compatibility with R's classInt package: identical quantile, equal interval and full-data Fisher-Jenks results
- Support for both numeric binning (indices) and categorical binning (strings)
- Proper handling of missing values
- Support for SubArrays and various input types

## Installation

You can install Breakers.jl using Julia's package manager:

```julia
using Pkg
Pkg.add("Breakers")
```

## Example Usage

```julia
using Breakers

# Sample data
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]

# Get binned data with category labels
binned_data = get_bins(values, 5)
fisher_bins = binned_data["fisher"]
kmeans_bins = binned_data["kmeans"]

# Get bin indices (1 to n)
bin_indices = get_bin_indices(values, 5)
fisher_indices = bin_indices["fisher"]
```

## Comparison with R's classInt

Breakers.jl produces the same quantile, equal interval and Fisher-Jenks results as R's classInt package, which helps keep R and Julia workflows consistent. See [R classInt Compatibility](manual/r_classint_compatibility.md) for the details, including how classInt samples large datasets for Fisher-Jenks and why k-means results vary. 