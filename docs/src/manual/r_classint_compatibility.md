# R ClassInt Compatibility

Breakers.jl is designed to match R's [classInt](https://cran.r-project.org/web/packages/classInt/index.html) package, which is widely used for data classification in spatial analysis and mapping.

## Compatibility Overview

How closely the bin assignments match classInt depends on the method:

- **Quantile breaks** and **equal interval breaks**: identical to classInt.
- **Fisher-Jenks natural breaks**: identical to classInt when classInt uses all the data. Above 3,000 values classInt computes Fisher breaks from a random sample of at most 3,000 values unless `largeN` is raised, for example `classIntervals(x, n, style = "fisher", largeN = Inf)`; Breakers.jl always uses all the data. When tied values make two different sets of breaks equally optimal, the two packages may choose different ones.
- **K-means clustering**: computed the same way as classInt, with each break midway between neighbouring clusters, but both packages start k-means from random centres, so results vary from run to run and are not expected to match exactly.

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

There are also some differences in the interface:

1. Breakers.jl returns results for all methods at once in a dictionary, whereas classInt processes one method at a time
2. Breakers.jl's API is designed to be more Julia-idiomatic while maintaining result compatibility

## Validation

The test suite compares Breakers.jl with classInt results for 3,222 US county populations stored in `test/bin_ref.csv` (see `test/test_bin_ref.jl`). Quantile, equal interval and full-data Fisher-Jenks assignments match for every county. 