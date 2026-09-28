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

### Performance

Breakers computes exact Fisher-Jenks breaks in **O(k × n × log n)** time. It uses the same dynamic program as the classic O(k × n²) algorithm, but finds each optimal split by divide and conquer, because the optimal split point moves monotonically. The breaks are the same as the classic algorithm's.

| Points | Breakers | R classInt, full data | R classInt, default settings |
|--------|----------|-----------------------|------------------------------|
| 1,000 | 0.14ms | 2.3ms | 2.3ms |
| 10,000 | 1.8ms | 213ms | 2.6ms (sampled) |
| 50,000 | 9.7ms | 5.4s | 27ms (sampled) |
| 200,000 | 42ms | 80s | 42ms (sampled) |
| 1,000,000 | 234ms | ~30 min (estimated) | 64ms (sampled) |

Times are medians for 7 classes, measured in September 2026 on an Apple M1 Max; R's full-data time at 200,000 points is for skewed data only.

**Note on R's defaults**: above 3,000 values, classInt computes Fisher breaks from a random sample of 10% of the values, capped at 3,000, unless `largeN` is raised. The breaks then differ from run to run and are not optimal: on the 3,222 US county populations in `test/bin_ref.csv`, the within-class error of the sampled breaks was a median 1.9x the optimum over 20 runs. Breakers.jl always uses the full data.

**Memory**: O(k × n), about 110MB for 1,000,000 values and 7 classes.

## K-means Clustering

K-means clustering divides the data into k groups where each observation belongs to the cluster with the nearest mean. This method works well for data that forms natural clusters.

```julia
# Get k-means breaks (default: single random start for speed)
kmeans_breaks = Breakers.kmeans_breaks(data, 5)

# For more stable results (slower)
kmeans_breaks = Breakers.kmeans_breaks(data, 5; rtimes=3)

# Get binned data using k-means method
bins = get_bins(data, 5)
kmeans_bins = bins["kmeans"]
```

K-means tends to create bins with similar numbers of observations when the data is uniformly distributed but will adapt to the natural clusters in the data.

### Performance Optimization

**Default Change**: The k-means implementation has been optimized by changing the default number of random starts from 3 to 1, providing a **~3x performance improvement**:

```julia
# Fast (new default): rtimes=1
breaks = kmeans_breaks(data, 5)        # ~0.5ms for 1K points

# Previous behavior: rtimes=3 (more stable, slower)
breaks = kmeans_breaks(data, 5; rtimes=3)  # ~1.5ms for 1K points
```

**Performance vs R's classInt**:
- **1,000 points**: Julia is 1.4x slower (much improved from previous 7.8x slower)
- **10,000 points**: Julia is 3.6x slower

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

### 🚀 Excellent Performance

**Performance**: Quantile breaks are **10.5x faster than R's classInt** at 1,000 points and **1.5x faster** at 10,000:
- **Complexity**: O(n log n) - excellent scaling
- **Typical performance**: < 1ms for most dataset sizes
- **Memory efficient**: No large matrices required

**When to use**:
- ✅ Large datasets (any size)
- ✅ When you need equal sample representation in each bin
- ✅ Performance-critical applications
- ✅ As a fast alternative to Fisher-Jenks for large datasets

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

### ⚡ Fastest Performance

**Performance**: Equal interval breaks are **3.9x faster than R's classInt** at 1,000 points and **2.8x faster** at 10,000:
- **Complexity**: O(n) - a single pass to find the minimum and maximum
- **Typical performance**: < 0.1ms for 10,000 values
- **Memory efficient**: Minimal memory usage

**When to use**:
- ✅ Uniformly distributed data
- ✅ When you need interpretable, round-number breaks
- ✅ Performance-critical applications with any data size
- ✅ Real-time applications
- ✅ When simplicity and speed are priorities

## Algorithm Selection Guide

Choose the right algorithm based on your data characteristics and performance requirements:

### 📊 **Decision Matrix**

| Your Priority | Recommended Algorithm | Why? |
|---------------|----------------------|------|
| **Data has natural clusters** | Fisher-Jenks or K-means | Optimizes for natural groupings |
| **Equal representation per bin** | Quantile breaks | Each bin contains same number of observations |
| **Interpretable round numbers** | Equal intervals | Easy to understand, clean boundaries |
| **Maximum performance** | Equal intervals | 2.8-3.9x faster than R |
| **Large datasets (N>10K)** | Quantile breaks | O(n log n), 1.5x faster than R at 10K |
| **Real-time applications** | Equal intervals | Fastest possible, consistent performance |

### 🎯 **Performance Ranking** (1K data points)

| Rank | Algorithm | Julia Time | vs R Performance | Complexity |
|------|-----------|------------|------------------|------------|
| 🥇 **1st** | Equal intervals | **0.010ms** | **3.9x faster** | O(n) |
| 🥈 **2nd** | Quantile | **0.009ms** | **10.5x faster** | O(n log n) |
| 🥉 **3rd** | Fisher-Jenks | **0.14ms** | **17x faster** | O(k×n×log n) |
| 4th | K-means | **0.57ms** | **1.4x slower** | O(k×n×i) |

### 📈 **Scaling Recommendations**

```julia
# Dataset size-based recommendations
function recommend_algorithm(data_size::Int)
    if data_size < 10_000
        "Any algorithm - all perform well"
    else
        "Fisher-Jenks, Quantile and Equal breaks all fast; K-means slower"
    end
end
```

### 🔬 **Quality vs Performance Trade-off**

- **Highest Quality**: Fisher-Jenks (optimal breaks for clustered data)
- **Balanced**: K-means (good clustering, reasonable speed)
- **High Performance**: Quantile (excellent speed, equal representation)
- **Maximum Speed**: Equal intervals (fastest, but may not fit data well)

## Handling Boundary Values

Breakers.jl handles boundary values (values exactly at a break point) according to R's classInt conventions:

1. Values at the minimum break are assigned to the first bin
2. Values exactly on interior breaks are assigned to the higher bin
3. Values at the maximum break are assigned to the highest bin

This behavior ensures consistency with R's classInt results.
