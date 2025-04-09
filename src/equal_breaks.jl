"""
    equal_breaks(x::AbstractVector{<:Real}, n::Integer) -> Vector{Float64}

Calculate equal interval breaks for data binning.

# Arguments
- `x`: Vector of numeric values
- `n`: Number of classes (resulting in n+1 break points)

# Returns
- `Vector{Float64}`: Vector of break points at equal intervals, including min and max values

# Details
- The function divides the range of values into `n` equal intervals
- This is equivalent to R's classIntervals() with style="equal"
- Returns n+1 break points including minimum and maximum values

# Examples
```julia
v = [1, 5, 10, 20, 50, 100]
equal_breaks(v, 4)
# result == [1.0, 25.75, 50.5, 75.25, 100.0]
```
"""
function equal_breaks(x::AbstractVector{<:Real}, n::Integer)
    # Check for empty vector
    if isempty(x)
        error("Input vector cannot be empty")
    end
    
    # Check for valid number of classes
    if n <= 0
        error("Number of classes must be positive")
    end
    
    # Sort the vector (in case it's not already sorted)
    x_sorted = sort(x)
    
    # Get min and max values
    min_val = x_sorted[1]
    max_val = x_sorted[end]
    
    # Handle case when all values are the same
    if min_val == max_val
        return Float64[min_val, max_val]
    end
    
    # Calculate interval width
    range_val = max_val - min_val
    interval_width = range_val / n
    
    # Generate breaks at equal intervals
    breaks = Float64[min_val + interval_width * i for i in 0:n]
    
    return breaks
end
