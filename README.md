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

## License

MIT License
