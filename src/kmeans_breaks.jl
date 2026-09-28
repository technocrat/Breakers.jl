"""
    kmeans_breaks(x::Vector{<:Real}, k::Int; rtimes::Int=1) -> Vector{Float64}

Calculate breaks using k-means clustering, following R's classInt implementation.

# Arguments
- `x`: Vector of numeric values
- `k`: Number of classes (resulting in k+1 break points)
- `rtimes`: Number of random starts (default: 1 for performance, was 3 in previous versions)

# Returns
- `Vector{Float64}`: Vector of break points (including min and max values)

# Details
- Uses k-means clustering to find natural break points in data
- As in classInt, each interior break lies midway between the largest value
  of one cluster and the smallest value of the next
- Results can differ between calls because k-means starts from random
  centers; use `Random.seed!` for repeatable results
- Multiple random starts improve stability but increase computation time
- For performance-critical applications, use `rtimes=1` (default)
- For stability-critical applications, use `rtimes=3` or higher

# Performance Notes
- **Default changed**: `rtimes=1` provides ~3x better performance vs previous `rtimes=3`
- This brings Julia k-means performance much closer to R's classInt
- The Clustering.jl backend is well-optimized and reliable

# Examples
```julia
# Basic usage (fast, single random start)
data = [1, 5, 10, 15, 20, 25, 30, 35, 40]
breaks = kmeans_breaks(data, 3)

# More stable results (slower, multiple random starts)
breaks = kmeans_breaks(data, 3; rtimes=3)

# Maximum stability (slowest)
breaks = kmeans_breaks(data, 3; rtimes=10)
```
"""
function kmeans_breaks(x::Vector{<:Real}, k::Int; rtimes::Int=1)
    # If very few unique values, just return them
    unique_vals = unique(x)
    if length(unique_vals) <= k
        return sort(unique_vals)
    end
    
    # Get min and max values
    min_val = Float64(minimum(x))
    max_val = Float64(maximum(x))
    
    # Use optimized Clustering.jl implementation
    return _kmeans_clustering_jl(x, k, rtimes, min_val, max_val)
end

"""
    _kmeans_clustering_jl(x::Vector{<:Real}, k::Int, rtimes::Int, min_val::Float64, max_val::Float64) -> Vector{Float64}

Clustering.jl backend for k-means clustering (fallback implementation).
"""
function _kmeans_clustering_jl(x::Vector{<:Real}, k::Int, rtimes::Int, min_val::Float64, max_val::Float64)
    # Use standard k-means clustering approach
    # Reshape data for clustering
    data = reshape(Float64.(x), 1, :)
    
    # Run k-means multiple times with different random initializations
    # and keep the best result (lowest total within-cluster sum of squares)
    best_wcss = Inf
    best_result = nothing

    for i in 1:rtimes
        # Run k-means clustering with more iterations
        result = kmeans(data, k; maxiter=200)

        # Calculate within-cluster sum of squares
        wcss = result.totalcost

        # Keep the best result
        if wcss < best_wcss
            best_wcss = wcss
            best_result = result
        end
    end

    # Range of each non-empty cluster, ordered by cluster center
    assignments = best_result.assignments
    order = sortperm(vec(best_result.centers))
    ranges = Tuple{Float64, Float64}[]
    for c in order
        members = x[assignments .== c]
        isempty(members) && continue
        push!(ranges, (Float64(minimum(members)), Float64(maximum(members))))
    end

    # As in classInt, interior breaks lie midway between the maximum of one
    # cluster and the minimum of the next
    interior = [(ranges[i][2] + ranges[i+1][1]) / 2 for i in 1:length(ranges)-1]

    return unique([min_val; interior; max_val])
end
