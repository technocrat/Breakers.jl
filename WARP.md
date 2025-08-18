# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

Breakers.jl is a Julia package that provides multiple methods for dividing numeric vectors into intervals, similar to R's classInt package. The package focuses on statistical binning algorithms with R compatibility and performance optimization.

## Core Architecture

### Main Module Structure
- **`src/Breakers.jl`**: Main module file that exports all public functions and includes all algorithm implementations
- **Algorithm Files**: Each binning method has its own implementation file:
  - `equal_breaks.jl`: Equal interval breaks
  - `quantile_breaks.jl`: Quantile-based breaks  
  - `fisher_breaks.jl`: Fisher-Jenks natural breaks (single-threaded)
  - `fisher_breaks_threaded.jl`: Multi-threaded Fisher-Jenks implementation
  - `kmeans_breaks.jl`: K-means clustering breaks
  - `fixed_breaks.jl`: User-specified fixed breaks
- **Core Functions**:
  - `get_breaks_raw.jl`: Returns raw break points for all methods
  - `get_bins.jl`: Returns string interval labels
  - `cut_data.jl`: High-level interface for data binning
  - `get_breaks.jl`: Backward compatibility wrapper

### Key Design Patterns
- **Multi-method dispatch**: All algorithms follow the pattern `method_breaks(x::Vector{<:Real}, n::Integer)`
- **R Compatibility**: Exact boundary handling matching R's classInt package behavior
- **Performance optimization**: Threaded implementations for computationally intensive algorithms
- **Missing value handling**: All functions properly handle `Vector{Union{Real, Missing}}`

## Development Commands

### Environment Setup
```bash
# Activate the package environment
julia --project=.

# Install dependencies
julia -e 'using Pkg; Pkg.instantiate()'

# Add development dependencies
julia -e 'using Pkg; Pkg.add(["BenchmarkTools", "RCall"])'
```

### Testing
```bash
# Run all tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Run specific test file
julia --project=. test/test_get_bins.jl

# Run tests with threading (for threaded algorithm tests)
julia --project=. -t auto test/test_threaded_fisher.jl
```

### Benchmarking
```bash
# Run internal benchmarks (comparing Breakers.jl methods)
julia benchmark.jl

# Custom benchmark parameters
julia benchmark.jl --sizes=1000,10000 --methods=fisher,kmeans --bins=5

# Run threaded benchmarks
julia -t auto benchmark.jl --methods=fisher,fisher_threaded

# Run specific algorithm examples
julia --project=. benchmark_example.jl

# For R classInt comparison (requires RCall.jl)
julia --project=. examples/r_classint_comparison.jl
```

### Documentation
```bash
# Build documentation locally
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=".")); Pkg.instantiate()'
julia --project=docs docs/make.jl

# View documentation
open docs/build/index.html
```

## Algorithm Implementation Notes

### Fisher-Jenks Natural Breaks
- Two implementations: single-threaded (`fisher_breaks.jl`) and multi-threaded (`fisher_breaks_threaded.jl`)
- Both use dynamic programming with exact optimization (globally optimal solution)
- Fully general algorithms - no hardcoded dataset-specific optimizations
- For dataset-specific optimization, use `fixed_breaks()` with known optimal break points

### R Compatibility Requirements
- **Boundary handling**: Values exactly on break points go to the higher bin (except minimum)
- **Missing values**: Return 0 for bin indices, "Missing" for string labels
- **Extreme outliers**: Values far beyond breaks may get assigned to bin n+1
- **Break point precision**: Must match R's floating point precision for identical results

### Threading Considerations
- Use `julia -t auto` or `julia -t N` to enable threading for `fisher_breaks_threaded`
- Threaded algorithms are most beneficial for datasets >10,000 observations
- Thread-safe implementations use local reduction variables

## Testing Strategy

### Unit Tests
- `test_get_bins.jl`: Core functionality and boundary handling
- `test_subarrays.jl`: SubArray compatibility  
- `test_threaded_fisher.jl`: Multi-threaded algorithm validation

### R Compatibility Testing
- Boundary value tests ensure exact R classInt behavior
- Special handling for extreme outliers (e.g., LA County population in US counties dataset)
- String interval formatting must match R's output format

### Performance Testing
- Benchmarks compare Julia vs R performance across different data sizes and distributions
- Results saved to `benchmarks/` directory as CSV files

## Common Development Patterns

### Adding New Binning Methods
1. Create `new_method_breaks.jl` with function signature `new_method_breaks(x::Vector{<:Real}, n::Integer)`
2. Add include and export statements to `src/Breakers.jl`
3. Update `get_breaks_raw.jl` to include the new method
4. Add comprehensive tests following existing patterns
5. Update documentation in `docs/src/`

### Performance Optimization
- Profile with `@profile` and `ProfileView.jl` for algorithm bottlenecks
- Use `BenchmarkTools.jl` for micro-benchmarks: `@benchmark method_breaks(data, n)`
- Consider threading for O(n²) or higher complexity algorithms
- Validate threaded implementations against single-threaded versions

### R Compatibility Validation
- Use `RCall.jl` to compare results with R's classInt
- Pay special attention to edge cases: empty vectors, single values, duplicate values
- Test boundary handling with values exactly on break points

## Dependencies and Compatibility

- **Julia version**: 1.11+ (specified in Project.toml and CI)
- **Key dependencies**: Clustering.jl, StatsBase.jl, Statistics.jl
- **Development dependencies**: BenchmarkTools.jl, RCall.jl (for R comparisons)
- **Cross-platform**: CI tests on Ubuntu, Windows, and macOS

## Build and CI

- **GitHub Actions**: Automated testing on push/PR with matrix of OS and Julia versions
- **Documentation**: Auto-built and deployed via Documenter.jl
- **Package registration**: Ready for Julia General registry submission
