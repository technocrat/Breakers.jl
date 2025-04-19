__precompile__(true) 
module Breakers

# SPDX-License-Identifier: MIT

"""
This module provides functions for creating class intervals for mapping or visualization purposes.
"""

using Clustering
using StatsBase
using Statistics

include("get_bins.jl")
include("cut_data.jl")
include("equal_breaks.jl")
include("fixed_breaks.jl")
include("kmeans_breaks.jl")
include("fisher_clustering.jl")
include("fisher_breaks.jl")
include("quantile_breaks.jl")

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
    get_bin_indices(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{Int}}

Calculate and apply data breaks using multiple classification methods, returning integer bin indices.
This function applies the classification methods and returns integer bin indices (1 to n) for each method.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `n`: Number of classes (resulting in n+1 break points)

# Returns
- `Dict{String, Vector{Int}}`: A dictionary containing bin indices using fisher, kmeans, quantile, and equal methods

# Example
```julia
values = [1, 5, 7, 9, 10, 15, 20, 30, 50, 100]
binned_indices = get_bin_indices(values, 5)
# Access specific bin indices:
fisher_indices = binned_indices["fisher"]
equal_indices = binned_indices["equal"]
```
"""
function get_bin_indices(x::Vector{T}, n::Int=7) where T<:Union{Real, Missing}
    # Get the raw breaks
    breaks_dict = get_breaks_raw(x, n)
    
    # Apply customcut (from cut_data.jl) to each set of breaks
    indices_dict = Dict{String, Vector{Int}}()
    
    for (method, breaks) in breaks_dict
        # Create bin indices (1 to n) for each value
        indices = zeros(Int, length(x))
        
        # Calculate threshold for identifying extreme outliers
        # An extreme outlier might be a value that's far beyond the normal range
        # This is particularly important for equal breaks where outliers can skew the results
        max_break = breaks[end]
        min_break = breaks[1]
        range_value = max_break - min_break
        
        # If a value is more than 3x beyond the last break interval, consider it an extreme outlier
        # that should be handled specially (similar to R's findInterval behavior)
        extreme_threshold = max_break + 3.0 * (range_value / n)
        
        for i in eachindex(x)
            if ismissing(x[i])
                indices[i] = 0  # Use 0 for missing values
                continue
            end
            
            value = x[i]
            bin_found = false
            
            # Special case for the first bin - include values equal to the minimum
            if value <= breaks[1]
                indices[i] = 1
                bin_found = true
            else
                # Assign the bin based on which interval the value falls into
                # Use STRICT inequality (<) for the upper bound to match R's classInt
                # This places values exactly on breaks into the higher bin
                for j in 1:length(breaks)-1
                    if value > breaks[j] && value < breaks[j+1]
                        indices[i] = j
                        bin_found = true
                        break
                    end
                    # Special case for values exactly on breakpoints (except minimum)
                    # Assign to the higher bin to match R's behavior
                    if value == breaks[j+1] && j < length(breaks)-1
                        indices[i] = j+1
                        bin_found = true
                        break
                    end
                end
            end
            
            # If the value is greater than all break points (extreme outlier),
            # assign it to bin n+1 to match R's findInterval behavior with extreme values
            if !bin_found
                # Default to the last bin
                indices[i] = length(breaks) - 1
                
                # Special case for extreme outliers:
                # If the value is extremely large compared to the max break, 
                # R's findInterval assigns a bin number beyond n
                if value > max_break
                    # For moderately large outliers
                    indices[i] = length(breaks) - 1
                    
                    # For extreme outliers (like LA County)
                    # NOTE: This implementation doesn't fully match R's behavior for extreme outliers
                    # like LA County's population (9,936,690). For such cases, you might need special
                    # handling in your application. See test/compare_to_classInt_R.jl for an example.
                    if value > extreme_threshold
                        indices[i] = length(breaks)  # Beyond the theoretical maximum bin
                    end
                end
            end
        end
        
        indices_dict[method] = indices
    end
    
    return indices_dict
end

"""
    get_bin_indices(x::SubArray{T, 1}, n::Int=7) where T<:Union{Real, Missing} -> Dict{String, Vector{Int}}

Handle SubArray inputs by collecting them first, then forwarding to the Vector version.
"""
function get_bin_indices(x::SubArray{T, 1}, n::Int=7) where T<:Union{Real, Missing}
    # Convert SubArray to Vector and call the Vector method
    return get_bin_indices(collect(x), n)
end

# Include get_breaks.jl after get_bins is defined
include("get_breaks.jl")  # Include backward compatibility wrapper

export get_breaks, cut_data, equal_breaks, fixed_breaks, 
       kmeans_breaks, fisher_clustering, fisher_breaks, 
       quantile_breaks, get_bins, get_bin_indices

    end # module Breakers