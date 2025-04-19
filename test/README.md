# Breakers.jl Test Suite

This directory contains test files for the Breakers.jl package.

## Running Tests

To run the standard test suite:

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## Test Files

- `test_get_bins.jl`: Tests for the `get_bins` function
- `test_subarrays.jl`: Tests for handling SubArray inputs
- `compare_to_classInt_R.jl`: Compares Breakers.jl results with R's ClassInt package

## Performance Benchmarks

The test suite includes performance benchmark tests comparing Breakers.jl with R's ClassInt package.

### Requirements

- R with the ClassInt package installed
- RCall.jl and BenchmarkTools.jl packages for Julia

### Running Benchmarks via Test Suite

To run the benchmarks as part of the test suite:

```bash
BREAKERS_BENCHMARK=true julia --project -e 'using Pkg; Pkg.test()'
```

### Running Standalone Benchmarks

For more control over the benchmarks, use the dedicated benchmark script:

```bash
julia ../benchmark.jl
```

See the main README for more benchmark options.

## Benchmark Implementation

The benchmark implementation:

1. Generates synthetic data with different distributions and sizes
2. Times the execution of both Breakers.jl and R's ClassInt package 
3. Compares the results and calculates speedup factors
4. Saves the results for further analysis

By running the benchmarks with different data distributions (normal, uniform, skewed) and sizes, you can get a comprehensive view of the performance characteristics of both implementations. 