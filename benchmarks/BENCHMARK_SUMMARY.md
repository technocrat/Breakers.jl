# Breakers.jl vs R classInt Benchmark Summary

This document summarizes the performance comparison between Breakers.jl and R's classInt package.

## Test Environment

- **Julia**: 1.11.6
- **R**: 4.5.1
- **R classInt version**: 0.4.11
- **Platform**: aarch64-apple-darwin24.4.0 (Apple Silicon Mac)
- **Date**: August 18, 2025

## Methodology

### Dataset Sizes Tested
- Small: 1,000 values
- Medium: 5,000 values (Julia only, due to R performance constraints)  
- Large: 10,000 values

### Data Distributions
- Normal: μ=500, σ=100
- Uniform: [0, 1000]
- Skewed: exp(N(0,1)) × 100

### Methods Compared
- **Fisher**: Fisher-Jenks natural breaks
- **K-means**: K-means clustering breaks  
- **Quantile**: Quantile-based breaks
- **Equal**: Equal interval breaks

## Key Performance Findings

### Julia vs R Performance (Median Times)

| Method   | Dataset Size | Julia Performance vs R | Notes |
|----------|-------------|----------------------|-------|
| **Equal** | 1,000 | **2.7x faster** | Consistently faster across all distributions |
| **Quantile** | 1,000 | **4.7x faster** | Significant advantage for Julia |
| **Fisher** | 1,000 | **3.4x slower** | Julia implementation less optimized |
| **K-means** | 1,000 | **7.3x slower** | Julia k-means significantly slower |

### Fisher Algorithm Scaling Issues

The Fisher-Jenks algorithm demonstrates severe performance degradation with larger datasets due to its O(k × n²) complexity:

| Dataset Size | Julia Fisher Time | R Fisher Time | Julia vs R |
|-------------|------------------|---------------|------------|
| 1,000 values | ~3 ms | ~1.8 ms | 1.7x slower |
| 10,000 values | ~300 ms | ~2.1 ms | **143x slower** |

### Performance by Algorithm Complexity

1. **Equal Interval**: O(1) - Fastest, Julia consistently outperforms R
2. **Quantile**: O(n log n) - Fast, Julia significantly faster than R
3. **K-means**: O(k × n × i) - Moderate, R implementation much faster
4. **Fisher-Jenks**: O(k × n²) - Slowest, becomes prohibitive for large datasets

## Computational Complexity Recommendations

### Fisher-Jenks Algorithm Limitations

**Current Implementation**: O(k × n²) time complexity

**Practical Limits**:
- ✅ **< 5,000 values**: Reasonable performance (< 100ms)
- ⚠️ **5,000-10,000 values**: Slow but usable (100ms-300ms)
- ❌ **> 10,000 values**: Becomes computationally prohibitive (> 300ms)

**Future Enhancement Opportunity**:
The [GeoDMS O(k × n × log(n)) algorithm](https://geodms.nl/docs/fisher's-natural-breaks-classification-complexity-proof.html) could provide significant performance improvements for large datasets.

### Alternative Recommendations

For large datasets (> 5,000 values):

1. **Pre-sampling**: Sample data to ~5,000 values before applying Fisher-Jenks
2. **Use Quantile breaks**: Fast and often produces similar categorical results
3. **Use Equal intervals**: Fastest option when data is approximately uniform

## Method-Specific Performance Notes

### Equal Interval Breaks
- **Julia Advantage**: 2.7x faster than R on average
- **Use Case**: Best for uniformly distributed data
- **Complexity**: O(1) - scales perfectly

### Quantile Breaks  
- **Julia Advantage**: 4.7x faster than R on average
- **Use Case**: When you need equal sample sizes per bin
- **Complexity**: O(n log n) - good scaling

### Fisher-Jenks Natural Breaks
- **R Advantage**: R implementation is significantly more optimized
- **Use Case**: Best for naturally clustered data with < 5,000 values
- **Complexity**: O(k × n²) - poor scaling, computationally intensive

### K-means Clustering
- **R Advantage**: R's k-means implementation is much faster
- **Use Case**: Good for clustered data when Fisher is too slow
- **Complexity**: O(k × n × iterations) - moderate scaling

## Summary and Recommendations

### Choose Breakers.jl when:
- You need **equal interval** or **quantile breaks** (significantly faster than R)
- Working with **small to medium datasets** (< 10,000 values)
- You want **native Julia performance** without R dependencies

### Consider R's classInt when:
- You need **Fisher-Jenks breaks** for large datasets (> 5,000 values)
- **K-means clustering** performance is critical
- You're already in an R-centric workflow

### Best Practices:
1. **Fisher Algorithm**: Limit to < 5,000 distinct values for practical performance
2. **Large Datasets**: Use quantile or equal intervals, or pre-sample data
3. **Performance Critical**: Profile your specific use case, as results may vary by data characteristics

## Files Generated

- `r_classint_benchmark_2025-08-18_15-34-32.csv` - R performance results
- `julia_breakers_benchmark_2025-08-18_15-47-44.csv` - Julia performance results  
- `julia_r_comparison_2025-08-18_15-47-45.csv` - Direct comparison metrics
- `r_comparison_data.rds` - R reference break points for validation

This benchmarking provides a comprehensive performance baseline for choosing the appropriate binning method and implementation for your specific use case.
