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

### ⚠️ Performance Considerations

The Fisher-Jenks algorithm has **O(k × n²)** computational complexity, making it computationally intensive for large datasets:

| Dataset Size | Typical Performance | Recommendation |
|--------------|---------------------|----------------|
| **< 1,000 values** | **< 5ms** | ✅ **Excellent** - Use freely |
| **1,000-5,000 values** | **5-100ms** | ✅ **Good** - Practical for most use cases |
| **5,000-10,000 values** | **100-500ms** | ⚠️ **Slow** - Consider alternatives |
| **> 10,000 values** | **> 500ms** | ❌ **Too slow** - Use quantile or equal breaks |

**Performance Comparison with R's classInt (N=10,000)**:
- **Julia**: ~308ms (pure Julia implementation)
- **R**: ~2ms (optimized C/FORTRAN)
- **Performance gap**: ~154x slower

**Why the difference?** R's Fisher-Jenks implementation uses decades-optimized C/FORTRAN code with specialized memory access patterns, while Julia uses a general-purpose dynamic programming approach.

**Recommendations**:
1. **For N < 5,000**: Fisher-Jenks provides excellent results with reasonable performance
2. **For N > 5,000**: Consider pre-sampling data or using `quantile_breaks` (7.7x faster than R!)
3. **For N > 10,000**: Use `equal_breaks` or `quantile_breaks` for practical performance

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
- **Julia**: 1.7x slower (much improved from previous 7.8x slower)
- **Julia** outperforms R for smaller datasets due to reduced overhead

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

**Performance**: Quantile breaks are **7.7x faster than R's classInt** and scale efficiently:
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

**Performance**: Equal interval breaks are **3.4x faster than R's classInt** with the best scaling:
- **Complexity**: O(1) - constant time regardless of data size
- **Typical performance**: < 0.1ms for any dataset size
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
| **Data has natural clusters** | Fisher-Jenks (N<5K) or K-means | Optimizes for natural groupings |
| **Equal representation per bin** | Quantile breaks | Each bin contains same number of observations |
| **Interpretable round numbers** | Equal intervals | Easy to understand, clean boundaries |
| **Maximum performance** | Equal intervals | O(1) complexity, 3.4x faster than R |
| **Large datasets (N>10K)** | Quantile breaks | O(n log n), 7.7x faster than R |
| **Real-time applications** | Equal intervals | Fastest possible, consistent performance |

### 🎯 **Performance Ranking** (1K data points)

| Rank | Algorithm | Julia Time | vs R Performance | Complexity |
|------|-----------|------------|------------------|------------|
| 🥇 **1st** | Equal intervals | **0.01ms** | **3.4x faster** | O(1) |
| 🥈 **2nd** | Quantile | **0.01ms** | **7.7x faster** | O(n log n) |
| 🥉 **3rd** | K-means | **0.50ms** | **1.7x slower** | O(k×n×i) |
| 4th | Fisher-Jenks | **3.19ms** | **1.7x slower** | O(k×n²) |

### 📈 **Scaling Recommendations**

```julia
# Dataset size-based recommendations
function recommend_algorithm(data_size::Int)
    if data_size < 1_000
        "Any algorithm - all perform well"
    elseif data_size < 5_000
        "Fisher-Jenks OK, K-means good, Quantile/Equal excellent"
    elseif data_size < 10_000  
        "Avoid Fisher-Jenks, K-means OK, Quantile/Equal recommended"
    else
        "Use Quantile or Equal breaks only - others too slow"
    end
end
```

### 🔬 **Quality vs Performance Trade-off**

- **Highest Quality**: Fisher-Jenks (for clustered data, N<5K)
- **Balanced**: K-means (good clustering, reasonable speed)
- **High Performance**: Quantile (excellent speed, equal representation)
- **Maximum Speed**: Equal intervals (fastest, but may not fit data well)

### ⚡ **Future Improvements**

The Fisher-Jenks performance gap with R may be addressed in future versions through:
1. **O(k × n × log n) algorithm implementation** (10-100x improvement)
2. **BLAS/LAPACK optimization** for matrix operations
3. **C/FORTRAN integration** via BinaryBuilder.jl (if pure Julia approaches insufficient)

## Handling Boundary Values

Breakers.jl handles boundary values (values exactly at a break point) according to R's classInt conventions:

1. Values at the minimum break are assigned to the first bin
2. Values exactly on interior breaks are assigned to the higher bin
3. Values at the maximum break are assigned to the highest bin

This behavior ensures consistency with R's classInt results.
