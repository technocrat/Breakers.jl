# Breakers.jl

Breakers.jl provides methods to divide a vector into intervals, similar to R's classInt package.

## Features

- Multiple methods for interval determination:
  - Equal interval breaks
  - Quantile breaks
  - Fisher-Jenks natural breaks
  - K-means clustering breaks
  - Fixed breaks

- High compatibility with R's classInt package
- Optimized for Julia's performance characteristics

## Performance Considerations

### Fisher-Jenks Natural Breaks Algorithm

The Fisher-Jenks algorithm has **O(k × n²)** time complexity where `k` is the number of classes and `n` is the number of data points. This makes it computationally intensive for large datasets.

**Recommendations:**
- Use Fisher-Jenks for datasets with fewer than **5,000 distinct values** for practical performance
- For larger datasets, consider using `quantile_breaks` or `equal_breaks` which have much better performance characteristics
- For very large datasets (>10,000 values), consider pre-sampling your data before applying Fisher-Jenks

**Future Enhancements:**
A future version may implement the more efficient **O(k × n × log(n))** algorithm described in [Fisher's Natural Breaks Classification complexity proof](https://geodms.nl/docs/fisher's-natural-breaks-classification-complexity-proof.html) for better performance on large datasets.

### K-means Clustering Performance Optimization

**Performance Improvement**: The k-means implementation has been optimized by changing the default number of random starts from 3 to 1. This provides a **~3x performance improvement** while maintaining good clustering quality for most use cases.

- **Default behavior**: `rtimes=1` (fast, single random initialization)
- **High stability**: `rtimes=3` (slower, multiple random starts like previous versions)
- **Maximum stability**: `rtimes=10` (slowest, for critical applications)

```julia
# Fast (new default)
breaks = kmeans_breaks(data, 5)  # rtimes=1

# Previous behavior (more stable, slower)
breaks = kmeans_breaks(data, 5; rtimes=3)
```

This optimization brings Julia k-means performance much closer to R's classInt without requiring additional dependencies.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/technocrat/Breakers.jl")
```

## Usage

```julia
using Breakers

# Example data
data = [1, 2, 3, 4, 5, 10, 20, 30, 40, 50]

# Get equal interval breaks with 4 bins
breaks = get_breaks(data, 4, method=:equal)

# Get the bin indices for each value
bin_indices = get_bin_indices(data, breaks)

# Alternatively, use the higher-level function
cut_result = cut_data(data, 4, method=:equal)
```

## Benchmarking

Breakers.jl includes benchmarking tools to compare its performance with R's ClassInt package.

### Requirements

- Julia 1.11 or higher
- R with the ClassInt package installed (for R comparisons)
- Required Julia packages: CSV, DataFrames, Statistics

### Running Benchmarks

```bash
# Run Julia-only benchmarks
julia --project=. benchmarks/benchmark_breakers.jl

# Run R classInt benchmarks (requires R and classInt package)
Rscript benchmarks/benchmark_classint.R

# Compare Julia and R results
julia --project=. benchmarks/compare_with_r.jl
```

### Performance Notes

Benchmarking of the Fisher algorithm is limited to smaller datasets due to its O(k × n²) complexity:
- Dataset sizes tested: 1,000, 5,000, and 10,000 values
- Larger sizes (>10,000) become computationally intensive

Results are saved in the `benchmarks/` directory as CSV files with timestamps.

## License

MIT License
