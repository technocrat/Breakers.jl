# API Reference

## Types

```@docs
Breakers.Breaks
```

## Main Functions

```@docs
get_bins
get_bin_indices
get_bins_fixed
get_bin_indices_fixed
get_breaks
get_breaks_raw
cut_data
```

## Binning Methods

```@docs
fisher_breaks
fisher_clustering
kmeans_breaks
quantile_breaks
equal_breaks
fixed_breaks
split_at_indices
```

## Internal Functions

These functions are not part of the public API and may change without notice.

```@docs
Breakers._kmeans_clustering_jl
```
