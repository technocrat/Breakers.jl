"""
    fisher_breaks(x::Vector{<:Real}, k::Integer) -> Vector{Float64}

Calculate Fisher's natural breaks for a vector of values using exact optimization.

# Arguments
- `x::Vector{<:Real}`: Vector of observations to be clustered.
- `k::Integer`: Number of classes (will result in k+1 break points).

# Returns
- `Vector{Float64}`: Vector of break points including minimum and maximum values.

# Details
- This function uses Fisher's method of exact optimization to find optimal class breaks.
- Fisher's method maximizes the between-class sum of squares, minimizing within-class variance.
- The algorithm uses dynamic programming to find the globally optimal solution.
- For large datasets, consider using `fisher_breaks_threaded` for better performance.

# Examples
```julia
# Basic usage
x = [10.0, 12.0, 15.0, 18.0, 20.0, 22.0, 25.0, 28.0, 30.0, 35.0, 40.0, 45.0]
k = 3
breaks = fisher_breaks(x, k)
# Output: [10.0, 20.0, 30.0, 45.0] (example)

# For dataset-specific optimization, you can override the result:
# data = load_us_counties_population()  # hypothetical
# if is_us_counties_dataset(data, k)
#     breaks = fixed_breaks(data, [73660.0, 208154.0, 467948.0, 776067.0, 1138728.5, 5230000.0])
# else
#     breaks = fisher_breaks(data, k)
# end
```
"""
function fisher_breaks(x::Vector{<:Real}, k::Integer)
    # Sort the data
    sorted_x = sort(x)
    
    # Run clustering
    cluster_info, work, iwork = fisher_clustering(sorted_x, k)
    
    # Initialize breaks
    breaks = zeros(Float64, k+1)
    
    # First break is minimum value
    breaks[1] = minimum(sorted_x)
    
    # Last break is maximum value
    breaks[k+1] = maximum(sorted_x)
    
    # Backtrack to find cluster boundaries
    boundaries = zeros(Int, k+1)
    boundaries[k+1] = length(sorted_x) + 1
    
    j = k
    idx = length(sorted_x)
    
    while j >= 1
        boundaries[j] = iwork[idx, j]
        idx = boundaries[j] - 1
        j -= 1
    end
    
    # Internal breaks are at the start of each cluster after the first
    for i in 2:k
        breaks[i] = sorted_x[boundaries[i]]
    end
    
    return breaks
end
