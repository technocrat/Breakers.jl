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

## Installation

```julia
using Pkg
Pkg.add("https://github.com/technocrat/Breakers.jl")
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
- R with the ClassInt package installed
- RCall.jl and BenchmarkTools.jl packages

### Running Benchmarks

```bash
# Install the required packages if not already installed
julia -e 'using Pkg; Pkg.add(["BenchmarkTools", "RCall"])'

# Run the benchmarks
julia benchmark.jl
```

You can customize the benchmark parameters:

```bash
# Run with specific dataset sizes
julia benchmark.jl --sizes=10000,50000,100000

# Run specific methods only
julia benchmark.jl --methods=fisher,kmeans

# Run with specific data distributions
julia benchmark.jl --distributions=normal,skewed

# Run with a different number of bins
julia benchmark.jl --bins=5
```

Results are saved in the `benchmarks` directory as CSV files.

## License

MIT License
