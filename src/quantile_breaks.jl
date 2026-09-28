"""
    quantile_breaks(x::Vector{<:Real}, k::Int) -> Vector{Float64}

Calculate breaks using quantiles.

# Arguments
- `x`: Vector of numeric values
- `k`: Number of classes (resulting in k+1 break points)

# Returns
- `Vector{Float64}`: Vector of break points (including min and max values)

# Note
- Matches R's `classIntervals(x, k, style = "quantile")`; see test/test_bin_ref.jl.
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

