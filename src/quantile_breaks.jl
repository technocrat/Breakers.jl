"""
    quantile_breaks(x::Vector{<:Real}, k::Int) -> Vector{Float64}

Calculate breaks using quantiles.

# Arguments
- `x`: Vector of numeric values
- `k`: Number of classes (resulting in k+1 break points)

# Returns
- `Vector{Float64}`: Vector of break points (including min and max values)

# Note
- For perfect compatibility with R's ClassInt, some edge cases may require
  manual handling. See test/compare_to_classInt_R.jl for examples.
"""
function quantile_breaks(x::Vector{<:Real}, k::Int)
    # Calculate quantiles
    probs = range(0, 1, length=k+1)
    breaks = quantile(x, probs)
    
    # Ensure first and last breaks match min and max exactly
    breaks[1] = minimum(x)
    breaks[end] = maximum(x)
    
    return unique(breaks)
end

