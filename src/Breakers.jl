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
include("fisher_breaks_threaded.jl")
include("quantile_breaks.jl")
include("get_breaks_raw.jl")    

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

"""
    get_bin_indices_fixed(x::Vector{T}, break_points::Vector{<:Real}) where T<:Union{Real, Missing} -> Vector{Int}

Get bin indices using user-specified break points.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `break_points`: Vector of break point values to use

# Returns
- `Vector{Int}`: Vector of bin indices for each value in x

# Example
```julia
data = [1, 5, 10, 15, 20, 25, 30]
indices = get_bin_indices_fixed(data, [10, 20])
# Returns bin indices based on breaks [1.0, 10.0, 20.0, 30.0]
```
"""
function get_bin_indices_fixed(x::Vector{T}, break_points::Vector{<:Real}) where T<:Union{Real, Missing}
    # Get the breaks using fixed_breaks
    breaks = fixed_breaks(x, break_points)
    
    # Use the standard binning logic
    indices = zeros(Int, length(x))
    
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
            for j in 1:length(breaks)-1
                if value > breaks[j] && value < breaks[j+1]
                    indices[i] = j
                    bin_found = true
                    break
                end
                # Special case for values exactly on breakpoints (except minimum)
                if value == breaks[j+1] && j < length(breaks)-1
                    indices[i] = j+1
                    bin_found = true
                    break
                end
            end
        end
        
        # If value is greater than all break points, assign to last bin
        if !bin_found
            indices[i] = length(breaks) - 1
        end
    end
    
    return indices
end

"""
    get_bins_fixed(x::Vector{T}, break_points::Vector{<:Real}) where T<:Union{Real, Missing} -> Vector{String}

Get bin labels using user-specified break points.

# Arguments
- `x`: Vector of numeric values (will skip missing values)
- `break_points`: Vector of break point values to use

# Returns
- `Vector{String}`: Vector of bin labels for each value in x

# Example
```julia
data = [1, 5, 10, 15, 20, 25, 30]
labels = get_bins_fixed(data, [10, 20])
# Returns bin labels based on breaks [1.0, 10.0, 20.0, 30.0]
```
"""
function get_bins_fixed(x::Vector{T}, break_points::Vector{<:Real}) where T<:Union{Real, Missing}
    # Get the breaks using fixed_breaks
    breaks = fixed_breaks(x, break_points)
    
    # Use cut_data to create the labels
    return cut_data(x, breaks)
end

export get_breaks, cut_data, equal_breaks, fixed_breaks, split_at_indices,
       kmeans_breaks, fisher_clustering, fisher_breaks, fisher_breaks_threaded,
       quantile_breaks, get_bins, get_bin_indices, get_bin_indices_fixed, get_bins_fixed,
       get_breaks_raw

end # module Breakers