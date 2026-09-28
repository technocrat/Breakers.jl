# Breakers.jl Test Suite

This directory contains the tests for the Breakers.jl package.

## Running Tests

```bash
julia --project -e 'using Pkg; Pkg.test()'
```

## Test Files

- `test_get_bins.jl`: `get_bins`, `get_bin_indices` and boundary handling
- `test_subarrays.jl`: SubArray inputs
- `test_fixed_breaks.jl`: Fixed break points
- `test_bin_ref.jl`: Compares quantile, equal interval and Fisher-Jenks bin assignments with R classInt results stored in `bin_ref.csv`

## Reference Data

`bin_ref.csv` holds the populations of 3,222 US counties with the bin each was assigned by R's classInt using 7 classes, numbered with R's `findInterval`. The Fisher-Jenks column was computed on the full data (`largeN = Inf`). The k-means column is not tested, because k-means starts from random centres in both packages.

## Benchmarks

Benchmarks are not part of the test suite. See `benchmark.jl` in the project root and the `benchmarks/` directory.
