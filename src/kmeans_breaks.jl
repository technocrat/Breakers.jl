"""
    kmeans_breaks(x::Vector{<:Real}, k::Int; rtimes::Int=3) -> Vector{Float64}

Calculate breaks using k-means clustering, following R's classInt implementation.

# Arguments
- `x`: Vector of numeric values
- `k`: Number of classes (resulting in k+1 break points)
- `rtimes`: Number of random starts (default: 3, matching R's classInt default)

# Returns
- `Vector{Float64}`: Vector of break points (including min and max values)

# Details
- This implementation follows R's classInt package approach:
  - Uses multiple random starts to improve stability (rtimes parameter)
  - Selects the best result based on the within-cluster sum of squares
  - Returns cluster centers as break points, with data minimum and maximum

# Examples
```julia
# Basic usage
data = [1, 5, 10, 15, 20, 25, 30, 35, 40]
breaks = kmeans_breaks(data, 3)

# With more random starts for stability
breaks = kmeans_breaks(data, 3; rtimes=10)

# For dataset-specific optimization, override as needed:
# if is_special_dataset(data)
#     breaks = fixed_breaks(data, custom_break_points)
# else
#     breaks = kmeans_breaks(data, k)
# end
```
"""
function kmeans_breaks(x::Vector{<:Real}, k::Int; rtimes::Int=3)
    # If very few unique values, just return them
    unique_vals = unique(x)
    if length(unique_vals) <= k
        return sort(unique_vals)
    end
    
    # Get min and max values
    min_val = minimum(x)
    max_val = maximum(x)
    
    # Use standard k-means clustering approach
    # Reshape data for clustering
    data = reshape(Float64.(x), 1, :)
    
    # Run k-means multiple times with different random initializations
    # and keep the best result (lowest total within-cluster sum of squares)
    best_wcss = Inf
    best_centers = nothing
    
    for i in 1:rtimes
        # Run k-means clustering with more iterations
        result = kmeans(data, k; maxiter=200)
        
        # Calculate within-cluster sum of squares
        wcss = result.totalcost
        
        # Keep the best result
        if wcss < best_wcss
            best_wcss = wcss
            best_centers = result.centers
        end
    end
    
    # Get cluster centers and sort them
    centers = vec(best_centers)
    sort!(centers)
    
    # Return complete breaks including min and max
    return unique([min_val; centers; max_val])
end
