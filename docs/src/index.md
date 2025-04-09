# Breakers.jl

*A Julia package for data classification and binning with R's classInt compatibility*

## Overview

Breakers.jl provides functions for creating class intervals for mapping or visualization purposes. The package implements several data binning methods commonly used in spatial data analysis and visualization, with a focus on exact compatibility with R's classInt package.

## Features

- Multiple binning methods including Fisher-Jenks natural breaks, k-means clustering, quantile-based, and equal interval binning
- Exact compatibility with R's classInt package for consistent results across languages
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

Breakers.jl has been extensively tested for compatibility with R's classInt package and produces identical results for all binning methods. This makes it perfect for workflows that need to maintain consistency between R and Julia. 