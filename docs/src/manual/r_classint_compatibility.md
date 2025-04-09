# R ClassInt Compatibility

Breakers.jl has been specifically designed to produce results identical to R's [classInt](https://cran.r-project.org/web/packages/classInt/index.html) package, which is widely used for data classification in spatial analysis and mapping.

## Compatibility Overview

Extensive testing has confirmed that Breakers.jl produces exactly the same bin assignments as classInt for all implemented methods:

- Fisher-Jenks natural breaks
- K-means clustering
- Quantile breaks
- Equal interval breaks

This ensures consistent results when working across R and Julia in a mixed-language workflow.

## Boundary Value Handling

A key aspect of compatibility is handling boundary values (values that fall exactly on break points):

1. In R's classInt, values exactly at break points (except the minimum) are assigned to the higher bin
2. Breakers.jl precisely replicates this behavior

For example, with breaks [10, 20, 30]:
- A value of exactly 20 is placed in the bin (20-30], not in (10-20]
- The minimum value is included in the first bin

## Usage Example

### In R (using classInt):

```r
library(classInt)

# Sample data
values <- c(1, 5, 7, 9, 10, 15, 20, 30, 50, 100)

# Get 5 classes using Fisher method
breaks <- classIntervals(values, n = 5, style = "fisher")
classes <- findCols(breaks)
```

### In Julia (using Breakers.jl):

```julia
using Breakers

# Sample data
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]

# Get 5 classes using Fisher method
binned_data = get_bin_indices(values, 5)
classes = binned_data["fisher"]
```

The `classes` in both examples will contain exactly the same bin assignments.

## Implementation Differences

While the outputs are identical, there are some differences in implementation:

1. Breakers.jl returns results for all methods at once in a dictionary, whereas classInt processes one method at a time
2. Breakers.jl's API is designed to be more Julia-idiomatic while maintaining result compatibility

## Validation

The compatibility has been validated through extensive testing comparing the results of Breakers.jl against R's classInt on real-world datasets, such as US county population data. 