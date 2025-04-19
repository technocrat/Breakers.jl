# Binning Methods

Breakers.jl implements several different binning methods commonly used in spatial data analysis and visualization. Each method has different characteristics and is suitable for different types of data distributions.

## Fisher-Jenks Natural Breaks

The Fisher-Jenks algorithm (also known as Jenks Natural Breaks) is an optimization algorithm that minimizes the variance within classes while maximizing the variance between classes. It's ideal for data that clusters naturally.

```julia
# Get Fisher breaks
fisher_breaks = Breakers.fisher_breaks(data, 5)

# Get binned data using Fisher method
bins = get_bins(data, 5)
fisher_bins = bins["fisher"]
```

Fisher-Jenks is particularly useful for data that forms natural clusters. It tries to find "gaps" in the data distribution and place break points optimally to minimize in-class variance.

### Threaded Fisher-Jenks Implementation

For large datasets, a multi-threaded implementation of the Fisher-Jenks algorithm is also available. This can provide significant performance improvements on multi-core systems.

```julia
using Threads  # Make sure threading is enabled

# Get threaded Fisher breaks - same interface as the standard version
fisher_breaks = Breakers.fisher_breaks_threaded(data, 5)
```

The threaded implementation produces identical results to the standard version but can be significantly faster for large datasets when multiple CPU cores are available. To check how many threads Julia is using, run `Threads.nthreads()`.

## K-means Clustering

K-means clustering divides the data into k groups where each observation belongs to the cluster with the nearest mean. This method works well for data that forms natural clusters.

```julia
# Get k-means breaks
kmeans_breaks = Breakers.kmeans_breaks(data, 5)

# Get binned data using k-means method
bins = get_bins(data, 5)
kmeans_bins = bins["kmeans"]
```

K-means tends to create bins with similar numbers of observations when the data is uniformly distributed but will adapt to the natural clusters in the data.

## Quantile Breaks

Quantile binning creates classes with an equal number of observations in each bin. This is useful when you want to have a similar number of data points in each category.

```julia
# Get quantile breaks
quantile_breaks = Breakers.quantile_breaks(data, 5)

# Get binned data using quantile method
bins = get_bins(data, 5)
quantile_bins = bins["quantile"]
```

Quantile breaks ensure each bin contains approximately the same number of data points, which can be useful for choropleth maps when you want each color to represent an equal proportion of the data.

## Equal Interval Breaks

Equal interval binning divides the data range into equal-sized bins. This is straightforward and works well for uniformly distributed data.

```julia
# Get equal interval breaks
equal_breaks = Breakers.equal_breaks(data, 5)

# Get binned data using equal interval method
bins = get_bins(data, 5)
equal_bins = bins["equal"]
```

Equal interval breaks are the simplest to understand but may not represent the data well if it has a skewed distribution or outliers.

## Handling Boundary Values

Breakers.jl handles boundary values (values exactly at a break point) according to R's classInt conventions:

1. Values at the minimum break are assigned to the first bin
2. Values exactly on interior breaks are assigned to the higher bin
3. Values at the maximum break are assigned to the highest bin

This behavior ensures consistency with R's classInt results. 