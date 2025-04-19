
"""
    get_bins(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{String}}

Calculate and apply data breaks using multiple classification methods, returning binned data.
This function is designed to handle the case where `get_breaks` returns actual breaks instead of
already-binned data.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `n`: Number of classes (resulting in n+1 break points)

# Returns
- `Dict{String, Vector{String}}`: A dictionary containing categorized data using fisher, kmeans, quantile, and equal methods

# Example
```julia
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]
binned_data = get_bins(values, 5)
# Access specific binned data:
fisher_bins = binned_data["fisher"]
kmeans_bins = binned_data["kmeans"]
```
"""
function get_bins(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing}
    # Get the raw breaks
    breaks_dict = get_breaks_raw(x, n)
    
    # Apply cut_data to each set of breaks
    bins_dict = Dict{String, Vector{String}}()
    for (method, breaks) in breaks_dict
        # The breaks should already be cleaned by get_breaks_raw
        bins_dict[method] = cut_data(x, breaks)
    end
    
    return bins_dict
end

"""
    get_bins(x::SubArray{T, 1}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{String}}

Handle SubArray inputs by collecting them first, then forwarding to the Vector version.
"""
function get_bins(x::SubArray{T, 1}, n::Int=7) where T<:Union{Real, Missing}
    # Convert SubArray to Vector and call the Vector method
    return get_bins(collect(x), n)
end

"""