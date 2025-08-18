"""
    fixed_breaks(x::Vector{<:Real}, break_points::Vector{<:Real}) -> Vector{Float64}

Create breaks using user-specified break points.

# Arguments
- `x`: Vector of numeric values (used for validation and to add min/max if needed)
- `break_points`: Vector of break point values to use

# Returns
- `Vector{Float64}`: Vector of break points including min and max values

# Details
- This method allows users to specify exact break points rather than letting an algorithm choose them
- Break points are automatically sorted
- Minimum and maximum values from the data are added if not already present
- This integrates with the standard workflow (get_bins, get_bin_indices, cut_data)

# Examples
```julia
# Specify custom break points
data = [1, 5, 10, 15, 20, 25, 30]
breaks = fixed_breaks(data, [10, 20])  # Returns [1.0, 10.0, 20.0, 30.0]

# Use with standard workflow
bin_indices = get_bin_indices_fixed(data, [10, 20])
bin_labels = cut_data(data, fixed_breaks(data, [10, 20]))
```

# See also
- [`get_breaks_raw`](@ref): For accessing all break methods including fixed
- [`cut_data`](@ref): For applying breaks to create labeled bins
"""
function fixed_breaks(x::Vector{T}, break_points::Vector{<:Real}) where T<:Union{Real, Missing}
    if isempty(break_points)
        error("At least one break point must be specified")
    end
    
    # Remove missing values from input data
    x_clean = collect(skipmissing(x))
    
    if isempty(x_clean)
        error("Input vector contains no non-missing values")
    end
    
    # Sort break points and convert to Float64
    breaks_sorted = sort(Float64.(break_points))
    
    # Get data range
    min_val = minimum(x_clean)
    max_val = maximum(x_clean)
    
    # Build final breaks vector with min and max
    final_breaks = Float64[min_val]
    
    # Add user-specified breaks (only those within data range and not duplicating existing)
    for bp in breaks_sorted
        if bp > min_val && bp < max_val && bp > final_breaks[end]
            push!(final_breaks, bp)
        end
    end
    
    # Add maximum (unless it equals minimum for single-value data or is already included)
    if max_val > final_breaks[end]
        push!(final_breaks, max_val)
    end
    
    return final_breaks
end

# Legacy function for backward compatibility - splits into sub-vectors
"""
    split_at_indices(v::Vector, indices::Vector{Int}) -> Vector{Vector}

Split a vector into multiple sub-vectors at specified indices (legacy function).

# Arguments
- `v::Vector`: The input vector to be split
- `indices::Vector{Int}`: Indices where the vector should be split

# Returns
- `Vector{Vector}`: A vector of sub-vectors created by splitting at the specified indices

# Note
This is a legacy function. For modern workflow integration, use `fixed_breaks` with actual values.
"""
function split_at_indices(v::Vector, indices::Vector{Int})
    # Ensure the breaks are sorted and within bounds
    indices = sort(indices)
    if any(i < 1 || i > length(v) for i in indices)
        throw(ArgumentError("Break indices must be within the range of the vector."))
    end
    # Remove missing values
    v_clean = collect(skipmissing(v))
    # Add start and end points to the break indices
    all_indices = [0; indices; length(v_clean)]
    
    # Split the vector into sub-vectors based on the indices
    return [v_clean[all_indices[i]+1:all_indices[i+1]] for i in 1:length(all_indices)-1]
end
