"""
    Breaks

A struct containing various types of data breaks.

# Fields
- `fisher::Vector{Float64}`: Breaks calculated using Fisher's natural breaks algorithm
- `kmeans::Vector{Float64}`: Breaks calculated using k-means clustering
- `quantile::Vector{Float64}`: Breaks at quantile positions
- `equal::Vector{Float64}`: Evenly spaced breaks
"""
struct Breaks
    fisher::Vector{Float64}
    kmeans::Vector{Float64}
    quantile::Vector{Float64}
    equal::Vector{Float64}
end

"""
    get_breaks(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{String}}

Calculate breaks for binning data using multiple classification methods and apply them to the data.
This is a wrapper around get_bins for backward compatibility.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `n`: Number of classes (resulting in n+1 break points)

# Returns
- `Dict{String, Vector{String}}`: A dictionary containing categorized data using fisher, kmeans, quantile, and equal methods

# Example
```julia
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]
categorized_data = get_breaks(values, 5)
# Access specific categorizations:
fisher_categories = categorized_data["fisher"]
kmeans_categories = categorized_data["kmeans"]
```
"""
function get_breaks(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing}
    # This is just a wrapper around get_bins for backward compatibility
    return get_bins(x, n)
end 