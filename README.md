# Breakers.jl

[![Docs: stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://technocrat.github.io/Breakers.jl/stable/)
[![Docs: dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://technocrat.github.io/Breakers.jl/dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia](https://img.shields.io/badge/julia-%3E=1.11-blue.svg)](https://julialang.org/)

**Fast, flexible data binning for Julia** - A high-performance package for dividing vectors into intervals, compatible with R's classInt package.

## 🎯 Key Features

### 📊 **Multiple Binning Methods**
- **Equal interval breaks** - Uniform bin widths
- **Quantile breaks** - Equal sample sizes per bin
- **Fisher-Jenks natural breaks** - Optimal clustering-based bins
- **K-means clustering breaks** - Machine learning-based binning
- **Fixed breaks** - User-defined breakpoints

### 🚀 **Performance Optimized**
- **Exact Fisher-Jenks breaks** in O(k × n × log n) time: 17x faster than R at 1,000 points and 121x faster at 10,000 on the full data
- **1.5-10x faster** than R for simple algorithms (equal, quantile), depending on data size
- **~3.3x faster** k-means by default, using one random start instead of three (`rtimes=1`)
- Smart algorithm selection guidance for different data sizes
- Comprehensive benchmarking against R's classInt

### 🔧 **Developer Friendly**
- Full R classInt compatibility for easy migration
- Extensive documentation and examples

## ⚡ Algorithm Performance Comparison

### Julia vs R Performance Summary

| Algorithm | Julia Time (1K) | R Time (1K) | Julia vs R (1K) | Julia vs R (10K) | Winner |
|-----------|-----------------|-------------|-----------------|------------------|---------|
| **Equal intervals** | 0.010ms | 0.040ms | **3.9x faster** | **2.8x faster** | 🟢 **Julia** |
| **Quantile breaks** | 0.009ms | 0.096ms | **10.5x faster** | **1.5x faster** | 🟢 **Julia** |
| **K-means clustering** | 0.57ms | 0.42ms | **1.4x slower** | **3.6x slower** | 🟡 **R** |
| **Fisher-Jenks** | 0.14ms | 2.32ms | **17x faster** | **121x faster**\* | 🟢 **Julia** |

Times are medians for 7 classes, averaged over normal, uniform and skewed data, measured in September 2026 on an Apple M1 Max (R timed with microbenchmark). They are measured after a warm-up. Breakers precompiles its common call paths, so the first call in a new session takes about as long as later ones; `using Breakers` itself takes about 0.4s, almost all of it loading Clustering.jl.

\* Compared with R on the full data (`largeN = Inf`). With its default settings classInt computes Fisher breaks from a sample of at most 3,000 values when there are more than 3,000 (see [Fisher-Jenks](#fisher-jenks-natural-breaks-algorithm) below). Even then, Breakers is 1.5x faster at 10,000 points (1.8ms against 2.6ms) and gives the optimal breaks.

### 📊 Algorithm Selection Guide

Choose the right algorithm based on your data characteristics and performance requirements:

| Your Priority | Recommended Algorithm | Why? |
|---------------|----------------------|------|
| **Data has natural clusters** | Fisher-Jenks or K-means | Optimizes for natural groupings |
| **Equal representation per bin** | Quantile breaks | Each bin contains same number of observations |
| **Interpretable round numbers** | Equal intervals | Easy to understand, clean boundaries |
| **Maximum performance** | Equal intervals | 2.8-3.9x faster than R |
| **Large datasets (N>10K)** | Quantile breaks | O(n log n), 1.5x faster than R at 10K |
| **Real-time applications** | Equal intervals | Fastest possible, consistent performance |

### Performance by Dataset Size

| Algorithm | Small (<1K) | Medium (1K-5K) | Large (5K-10K) | Very Large (>10K) |
|-----------|-------------|----------------|----------------|--------------------|
| **Equal intervals** | ✅ Excellent | ✅ Excellent | ✅ Excellent | ✅ Excellent |
| **Quantile breaks** | ✅ Excellent | ✅ Excellent | ✅ Excellent | ✅ Excellent |
| **K-means** | ✅ Excellent | ✅ Good | ⚠️ Fair | ⚠️ Slow |
| **Fisher-Jenks** | ✅ Excellent | ✅ Excellent | ✅ Excellent | ✅ Excellent |

## Performance Considerations

### Fisher-Jenks Natural Breaks Algorithm

Breakers computes exact Fisher-Jenks breaks in **O(k × n × log n)** time, where `k` is the number of classes and `n` is the number of data points. It uses the same dynamic program as the classic O(k × n²) algorithm, but finds each optimal split by divide and conquer, because the optimal split point moves monotonically (see [Fisher's Natural Breaks Classification complexity proof](https://geodms.nl/docs/fisher's-natural-breaks-classification-complexity-proof.html)). The breaks are the same as the classic algorithm's.

| Points | Breakers | R classInt, full data | R classInt, default settings |
|--------|----------|-----------------------|------------------------------|
| 1,000 | 0.14ms | 2.3ms | 2.3ms |
| 10,000 | 1.8ms | 213ms | 2.6ms (sampled) |
| 50,000 | 9.7ms | 5.4s | 27ms (sampled) |
| 200,000 | 42ms | 80s | 42ms (sampled) |
| 1,000,000 | 234ms | ~30 min (estimated) | 64ms (sampled) |

Times are medians for 7 classes, measured as in the table above; R's full-data time at 200,000 points is for skewed data only.

**R's sampling:** above 3,000 values, classInt computes Fisher breaks from a random sample of 10% of the values, capped at 3,000, unless `largeN` is raised. The breaks then differ from run to run and are not optimal. On the 3,222 US county populations in `test/bin_ref.csv`, the within-class error of the sampled breaks was a median 1.9x the optimum (up to 4.2x) over 20 runs; on 200,000 skewed values it was a median 1.25x (up to 1.4x). Breakers always uses all the data.

**Memory:** O(k × n), about 110MB for 1,000,000 values and 7 classes.

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

## 💻 Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/technocrat/Breakers.jl")
```

## 🚀 Quick Start

```julia
using Breakers

# Example data - household income distribution
income_data = [25000, 35000, 45000, 55000, 75000, 95000, 125000, 200000]

# Method 1: Direct method calls (fastest)
equal_breaks = equal_breaks(income_data, 4)          # [25000.0, 68750.0, 112500.0, 156250.0, 200000.0]
quantile_breaks = quantile_breaks(income_data, 4)    # [25000.0, 47500.0, 85000.0, 162500.0, 200000.0]
fisher_breaks = fisher_breaks(income_data, 4)        # Optimal clustering-based breaks
kmeans_breaks = kmeans_breaks(income_data, 4)        # K-means clustering breaks

# Method 2: Unified interface
breaks = get_breaks(income_data, 4, method=:equal)
bin_indices = get_bin_indices(income_data, breaks)
cut_result = cut_data(income_data, 4, method=:quantile)
```

## 📋 Comprehensive Examples

### Example 1: Performance-Optimized Data Analysis

```julia
using Breakers
using Random

# Generate sample data
Random.seed!(42)
data = randn(10000) .* 100 .+ 500  # Normal distribution around 500

# Exact optimal breaks, about 2ms for 10,000 values
breaks = fisher_breaks(data, 5)

# Interval label for each value
labels = cut_data(data, breaks)
println("Data binned into $(length(breaks)-1) bins")
```

### Example 2: Comparing Multiple Methods

```julia
using Breakers

# Real estate price data (example)
prices = [120000, 150000, 180000, 220000, 280000, 350000, 500000, 750000, 1200000]

# Compare different methods
methods = [:equal, :quantile, :fisher, :kmeans]
results = Dict()

for method in methods
    breaks = get_breaks(prices, 4, method=method)
    results[method] = breaks
    println("$method: $breaks")
end

# Output:
# equal: [120000.0, 390000.0, 660000.0, 930000.0, 1200000.0]
# quantile: [120000.0, 200000.0, 315000.0, 625000.0, 1200000.0] 
# fisher: Natural clustering-optimized breaks
# kmeans: ML-based clustering breaks
```

### Example 3: Advanced K-means Configuration

```julia
using Breakers

data = rand(1000) .* 1000

# Fast mode (new default) - single random start
fast_breaks = kmeans_breaks(data, 5)                    # ~3x faster

# Stable mode - multiple random starts for consistency
stable_breaks = kmeans_breaks(data, 5; rtimes=3)        # Previous default

# Maximum stability - for critical applications
max_stable_breaks = kmeans_breaks(data, 5; rtimes=10)   # Most stable

println("Performance vs stability trade-offs available")
```

### Example 4: Fisher-Jenks on Large Datasets

```julia
using Breakers

# 200,000 values, for example census block groups
data = exp.(randn(200_000)) .* 100

# Exact optimal breaks on the full data in about 40ms
@time breaks = fisher_breaks(data, 7)
```

### Example 5: Dataset-Specific Optimizations

```julia
using Breakers

# For specific datasets, you can override defaults
function optimize_for_us_counties(data, k)
    if length(data) == 3143  # US counties dataset
        # Apply custom optimization for this specific dataset
        return [0.0, 2.0, 5.0, 10.0, 20.0, 50.0]  # Example custom breaks
    else
        # Use general algorithm
        return fisher_breaks(data, k)
    end
end

# This pattern allows manual optimization while keeping the library general
county_data = randn(3143)  # Simulated US county data
optimized_breaks = optimize_for_us_counties(county_data, 5)
```

## 📊 Benchmarking

Breakers.jl includes comprehensive benchmarking tools to compare its performance with R's classInt package.

### Requirements

- Julia 1.11 or higher
- R with the classInt package installed (for R comparisons)
- Required Julia packages: CSV, DataFrames, Statistics

### Running Benchmarks

```bash
# Run Julia-only benchmarks
julia --project=. benchmarks/compare_with_r.jl

# Run R classInt benchmarks (requires R and classInt package)
Rscript benchmarks/benchmark_classint.R

# Analyze Fisher-Jenks performance scaling
julia --project=. benchmarks/fisher_comparison_analysis.jl

# K-means performance analysis
julia --project=. benchmarks/analyze_kmeans_performance.jl
```

### 📈 Benchmark Results

See the [`benchmarks/`](benchmarks/) directory for:
- **Performance comparison results** (Julia vs R)
- **Scaling analysis** for different dataset sizes
- **Algorithm-specific deep dives**
- **Performance improvement summaries**

The saved results in `benchmarks/` date from August 2025, before the O(k × n × log n) Fisher-Jenks algorithm; the tables above are current.

Results are automatically saved as timestamped CSV files for reproducibility.

## 📚 Documentation

### 🔗 **Full Documentation**
- **[Online documentation](https://technocrat.github.io/Breakers.jl/)** - Manual and API reference
- **[Algorithm Guide](https://technocrat.github.io/Breakers.jl/stable/manual/binning_methods/)** - Detailed explanation of each method
- **[R classInt Compatibility](https://technocrat.github.io/Breakers.jl/stable/manual/r_classint_compatibility/)** - What matches R exactly, and what differs
- **[Performance Roadmap](docs/PERFORMANCE_ROADMAP.md)** - Historical record of earlier optimization plans
- **[Benchmark Analysis](benchmarks/README.md)** - Comprehensive performance analysis

### 🎓 **Learning Resources**
- **Algorithm Selection**: See [Algorithm Selection Guide](#-algorithm-selection-guide) above
- **Performance Considerations**: Detailed in [Performance Considerations](#performance-considerations)
- **Real-world Examples**: Check out the [Comprehensive Examples](#-comprehensive-examples)

## 🚧 Development Roadmap

### ✅ **Completed**
- K-means default of one random start (~3.3x speedup) ✅
- **Fisher-Jenks O(k × n × log n)** algorithm, 17-121x faster than R on the full data ✅
- Precompiled common call paths, so first calls are fast ✅
- Comprehensive benchmarking infrastructure ✅
- Performance documentation and guidance ✅
- R classInt compatibility validation ✅

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### 🐛 **Bug Reports & Feature Requests**
- Open an issue on GitHub with detailed description
- Include minimal reproducible example
- Specify Julia version and system information

### 🔧 **Code Contributions**
- Fork the repository
- Create a feature branch (`git checkout -b feature/amazing-feature`)
- Write tests for new functionality
- Ensure all tests pass (`julia --project=. test/runtests.jl`)
- Submit a pull request

### 📊 **Performance Improvements**
- Run benchmarks before and after changes
- Document performance impact
- Update relevant documentation

### 📝 **Documentation**
- Improve examples and explanations
- Add new use cases
- Fix typos and clarity issues

## 🏆 Acknowledgments

- **R's classInt package** for algorithm reference and validation data
- **Julia community** for performance optimization insights
- **GeoDMS project** for Fisher-Jenks algorithm complexity analysis
- **All contributors** who helped improve performance and documentation

## 📖 Citation

If you use Breakers.jl in your research, please cite:

```bibtex
@software{breakers_jl,
  title = {Breakers.jl: Fast and Flexible Data Binning for Julia},
  author = {Careaga, Richard},
  url = {https://github.com/technocrat/Breakers.jl},
  version = {0.2.0},
  year = {2026}
}
```

## ⚖️ License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the Julia community** | **Performance-focused** | **R-compatible** | **Well-documented**
