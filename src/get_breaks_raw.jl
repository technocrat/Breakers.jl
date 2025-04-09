"""
    get_breaks_raw(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{Float64}}

Calculate breaks for binning data using multiple classification methods, returning the raw break points.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `n`: Number of classes (resulting in n+1 break points)

# Returns
- `Dict{String, Vector{Float64}}`: A dictionary containing break points for fisher, kmeans, quantile, and equal methods

# Example
```julia
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]
breaks = get_breaks_raw(values, 5)
# Access specific break points:
fisher_breaks = breaks["fisher"]
kmeans_breaks = breaks["kmeans"]
```
"""
function get_breaks_raw(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing}
    # Remove missing values
    x_clean = collect(skipmissing(x))
    
    if isempty(x_clean)
        error("Input vector contains no non-missing values")
    end
    
    if n <= 1
        error("Number of classes must be at least 2")
    end
    
    if length(x_clean) <= n
        @warn "Number of unique values ($(length(unique(x_clean)))) is less than or equal to the number of classes ($n)"
        unique_vals = sort(unique(x_clean))
        return Dict(
            "fisher" => collect(Float64.(unique_vals)),
            "kmeans" => collect(Float64.(unique_vals)),
            "quantile" => collect(Float64.(unique_vals)),
            "equal" => collect(Float64.(unique_vals))
        )
    end
    
    # Calculate breaks using different methods
    # IMPORTANT: Always collect results to ensure they're not SubArrays
    x_float = collect(Float64.(x_clean))
    
    # Safely convert any array/subarray to a simple Vector{Float64}
    function safe_collect(arr)
        # First collect to handle SubArrays
        collected = collect(arr)
        
        # If the result is a Vector of SubArrays, collect each element
        if !isempty(collected) && isa(collected[1], SubArray)
            return Float64[Float64(collect(subarray)[1]) for subarray in collected]
        end
        
        # Otherwise convert directly to Float64
        return Float64[Float64(elem) for elem in collected]
    end
    
    # Ensure we collect each result to avoid SubArrays
    fisher_br = safe_collect(fisher_breaks(x_float, n))
    kmeans_br = safe_collect(kmeans_breaks(x_float, n))
    quantile_br = safe_collect(quantile_breaks(x_float, n))
    
    # equal_breaks now returns a vector of breakpoints directly, no need for special handling
    equal_br = equal_breaks(x_float, n)
    
    # Return dictionary with breaks
    return Dict(
        "fisher" => fisher_br,
        "kmeans" => kmeans_br,
        "quantile" => quantile_br,
        "equal" => equal_br
    )
end 