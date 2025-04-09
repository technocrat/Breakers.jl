"""
    fixed_breaks(v::Vector, breaks::Vector{Int})

Split a vector `v` into multiple sub-vectors at specified break indices.

# Arguments
- `v::Vector`: The input vector to be split.
- `breaks::Vector{Int}`: Indices where the vector should be split.

# Returns
- `Vector{Vector}`: A vector of sub-vectors created by splitting the original vector at the specified break points.

# Details
- Missing values are removed from the input vector before splitting.
- Break indices are sorted automatically.
- The function creates segments: [1:breaks[1]], [breaks[1]+1:breaks[2]], ..., [breaks[end]+1:end].
- Break indices must be within the valid range of the vector (1 to length).

# Examples
```julia
v = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
breaks = [3, 7]
result = fixed_breaks(v, breaks)
# result == [[1, 2, 3], [4, 5, 6, 7], [8, 9, 10]]

v_with_missing = [1, missing, 3, 4, 5, missing, 7, 8, 9, 10]
result = fixed_breaks(v_with_missing, breaks)
# result == [[1, 3, 4], [5, 7, 8], [9, 10]]

Throws

ArgumentError: If any break index is less than 1 or greater than the length of the vector.
"""


function fixed_breaks(v::Vector, breaks::Vector{Int})
    # Ensure the breaks are sorted and within bounds
    breaks = sort(breaks)
    if any(b < 1 || b > length(v) for b in breaks)
        throw(ArgumentError("Break indices must be within the range of the vector."))
    end
    # Remove missing values
    v_clean = collect(skipmissing(v))
    # Add start and end points to the break indices
    all_breaks = [0; breaks; length(v_clean)]
    
    # Split the vector into sub-vectors based on the breaks
    return [v_clean[all_breaks[i]+1:all_breaks[i+1]] for i in 1:length(all_breaks)-1]
end
