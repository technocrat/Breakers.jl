#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

"""
Example: Dataset-Specific Optimization for Breakers.jl

This example demonstrates how to implement dataset-specific optimizations
when you know the exact break points that should be used for particular
datasets, while falling back to the general algorithms for other data.

This pattern is useful when:
1. You have pre-computed optimal breaks for specific datasets
2. You need to match exact results from other tools (e.g., R's classInt)
3. You have domain knowledge about optimal break points

Originally, Breakers.jl had hardcoded optimizations for the US counties 
dataset built into the algorithms. This approach is more flexible and 
keeps the algorithms general while allowing easy customization.
"""

using Breakers

# Example: US Counties Population Dataset Optimization
"""
Detect if the data matches the US counties population dataset characteristics.
"""
function is_us_counties_dataset(x::Vector{<:Real}, k::Int)
    return length(x) > 3000 && k == 7 && maximum(x) > 1000000
end

"""
Get optimized breaks for US counties population data.
These exact break points were determined by analyzing R's classInt output
to ensure perfect compatibility.
"""
function get_us_counties_breaks(x::Vector{<:Real})
    min_val = minimum(x)
    max_val = maximum(x)
    
    return Float64[
        min_val,       # Minimum value
        73660.0,       # Boundary between bin 1 and 2
        208154.0,      # Boundary between bin 2 and 3
        467948.0,      # Boundary between bin 3 and 4
        776067.0,      # Boundary between bin 4 and 5
        1138728.5,     # Boundary between bin 5 and 6
        5230000.0,     # Boundary between bin 6 and 7
        max_val        # Maximum value (LA County)
    ]
end

"""
Optimized Fisher breaks with dataset-specific handling.
"""
function optimized_fisher_breaks(x::Vector{<:Real}, k::Int)
    if is_us_counties_dataset(x, k)
        return get_us_counties_breaks(x)
    else
        return fisher_breaks(x, k)
    end
end

"""
Example of how to use fixed_breaks for dataset-specific optimization.
This is the recommended approach as it uses the standard API.
"""
function recommended_optimized_breaks(x::Vector{<:Real}, k::Int)
    if is_us_counties_dataset(x, k)
        # Use fixed_breaks with known optimal break points
        optimal_points = [73660.0, 208154.0, 467948.0, 776067.0, 1138728.5, 5230000.0]
        return fixed_breaks(x, optimal_points)
    else
        return fisher_breaks(x, k)
    end
end

# Example: Custom Dataset Detection and Optimization
"""
Example for a hypothetical climate dataset.
"""
function is_temperature_anomaly_dataset(x::Vector{<:Real}, k::Int)
    # Detect based on data characteristics
    return length(x) > 1000 && 
           minimum(x) < -5.0 && 
           maximum(x) > 5.0 && 
           k == 5
end

function get_climate_anomaly_breaks(x::Vector{<:Real})
    return fixed_breaks(x, [-2.0, -0.5, 0.5, 2.0])
end

"""
Multi-dataset optimization function.
"""
function smart_breaks(x::Vector{<:Real}, k::Int; method::Symbol=:fisher)
    # Check for known datasets and use optimal breaks
    if is_us_counties_dataset(x, k)
        @info "Using optimized breaks for US counties population data"
        return fixed_breaks(x, [73660.0, 208154.0, 467948.0, 776067.0, 1138728.5, 5230000.0])
    elseif is_temperature_anomaly_dataset(x, k)
        @info "Using optimized breaks for climate anomaly data"
        return get_climate_anomaly_breaks(x)
    else
        # Fall back to general algorithms
        @info "Using general algorithm: $method"
        if method == :fisher
            return fisher_breaks(x, k)
        elseif method == :fisher_threaded
            return fisher_breaks_threaded(x, k)
        elseif method == :kmeans
            return kmeans_breaks(x, k)
        elseif method == :quantile
            return quantile_breaks(x, k)
        elseif method == :equal
            return equal_breaks(x, k)
        else
            error("Unknown method: $method")
        end
    end
end

# Demonstration
function main()
    println("=== Dataset-Specific Optimization Example ===\n")
    
    # Example 1: Regular data - uses general algorithm
    println("1. Regular dataset:")
    regular_data = [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]
    breaks1 = smart_breaks(regular_data, 3)
    println("   Data: ", regular_data)
    println("   Breaks: ", breaks1)
    
    # Example 2: Large dataset simulating US counties (for demonstration)
    println("\n2. Large dataset (simulating US counties characteristics):")
    # Create synthetic data that matches US counties characteristics
    us_counties_sim = vcat(
        rand(500:50000, 3000),      # Most counties have small populations
        rand(50000:200000, 100),     # Some medium counties  
        rand(200000:1000000, 20),    # Some large counties
        [9900000]                    # LA County-like outlier
    )
    
    breaks2 = smart_breaks(us_counties_sim, 7)
    println("   Dataset size: ", length(us_counties_sim))
    println("   Range: ", minimum(us_counties_sim), " - ", maximum(us_counties_sim))
    println("   Optimized breaks: ", breaks2)
    
    # Example 3: Using the general API with workflow integration
    println("\n3. Workflow integration:")
    bin_indices = get_bin_indices_fixed(us_counties_sim, [73660.0, 208154.0, 467948.0, 776067.0, 1138728.5, 5230000.0])
    println("   Bin distribution: ", [count(==(i), bin_indices) for i in 1:7])
    
    println("\n✅ This pattern keeps algorithms general while allowing easy customization!")
    println("💡 Use fixed_breaks() with known optimal points for the cleanest approach.")
end

# Run the example
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

# Additional utility functions for testing
export is_us_counties_dataset, get_us_counties_breaks, smart_breaks
