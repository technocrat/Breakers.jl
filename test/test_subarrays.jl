#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

# Test script for SubArray handling in Breakers.jl
using Test
using Breakers

@testset "SubArray Handling in Breakers.jl" begin
    @testset "Basic functionality" begin
        # Test with regular Vector
        v1 = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
        result1 = Breakers.get_bins(v1)
        
        # Test all methods are present
        @test haskey(result1, "fisher")
        @test haskey(result1, "kmeans")
        @test haskey(result1, "quantile")
        @test haskey(result1, "equal")
        
        # Test with Vector{Union{Missing, Float64}}
        v2 = convert(Vector{Union{Missing, Float64}}, v1)
        result2 = Breakers.get_bins(v2)
        
        # Test all methods are present
        @test haskey(result2, "fisher")
        @test haskey(result2, "kmeans")
        @test haskey(result2, "quantile")
        @test haskey(result2, "equal")
        
        # Test with SubArray
        sub_v = view(v1, 2:7)
        result3 = Breakers.get_bins(sub_v)
        
        # Test all methods are present
        @test haskey(result3, "fisher")
        @test haskey(result3, "kmeans")
        @test haskey(result3, "quantile")
        @test haskey(result3, "equal")
        
        # Test that SubArray results match what we'd get from a regular vector with the same values
        sub_v_as_vector = collect(sub_v)
        result4 = Breakers.get_bins(sub_v_as_vector)
        
        for method in ["fisher", "kmeans", "quantile", "equal"]
            @test result3[method] == result4[method]
        end
    end
    
    @testset "Boundary handling with SubArrays" begin
        # Create test data with exact boundary values
        boundary_values = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0]
        
        # Create a SubArray view
        sub_boundary = view(boundary_values, 1:7)
        
        # Calculate bin indices with SubArray
        indices_sub = Breakers.get_bin_indices(sub_boundary, 3)
        
        # Test boundary handling with SubArray
        for method in ["fisher", "kmeans", "quantile", "equal"]
            # Check boundary handling specifically
            # - Values at the minimum break (0) should be in bin 1
            # - Values exactly on interior breaks (10, 20) should be in the higher bin
            # - Values at the maximum break (30) should be in the highest bin
            @test indices_sub[method][1] == 1  # 0 -> bin 1 (minimum)
            @test indices_sub[method][3] == 2  # 10 -> bin 2 (exactly on boundary, goes to higher bin)
            @test indices_sub[method][5] == 3  # 20 -> bin 3 (exactly on boundary, goes to higher bin)
            
            # The maximum value can be handled differently by different algorithms,
            # Either as the last bin (3) or as a potential outlier bin (4)
            @test indices_sub[method][7] in [3, 4]  # 30 -> bin 3 or 4 (maximum)
        end
        
        # Test string labels from cut_data with SubArrays
        # We need to collect the SubArray since cut_data doesn't accept SubArrays directly
        sub_boundary_vec = collect(sub_boundary)
        string_bins = Breakers.cut_data(sub_boundary_vec, [0.0, 10.0, 20.0, 30.0])
        
        @test string_bins[1] == "≤ 0.0"  # Minimum
        @test string_bins[3] == "10.0 - 20.0"  # Value 10 (on boundary) gets higher interval
        @test string_bins[5] == "20.0 - 30.0"  # Value 20 (on boundary) gets higher interval
        @test string_bins[7] == "> 20.0"  # Maximum
    end
end 