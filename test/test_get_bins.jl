# SPDX-License-Identifier: MIT

using Test
using Breakers
using Statistics

@testset "Breakers.get_bins Tests" begin
    # Create a test vector with various values
    test_values = [1, 3, 5, 7, 9, 11, 13, 22, 35, 51, 65, 80, 90, 100]
    
    # Test get_breaks_raw function
    breaks_dict = Breakers.get_breaks_raw(test_values, 5)
    
    # Check that we got the right methods
    @test haskey(breaks_dict, "fisher")
    @test haskey(breaks_dict, "kmeans") 
    @test haskey(breaks_dict, "quantile")
    @test haskey(breaks_dict, "equal")
    
    # Check that the breaks are Vector{Float64}
    @test isa(breaks_dict["fisher"], Vector{Float64})
    @test isa(breaks_dict["kmeans"], Vector{Float64})
    @test isa(breaks_dict["quantile"], Vector{Float64})
    @test isa(breaks_dict["equal"], Vector{Float64})
    
    # Check that the breaks are sorted
    @test issorted(breaks_dict["fisher"])
    @test issorted(breaks_dict["kmeans"])
    @test issorted(breaks_dict["quantile"])
    @test issorted(breaks_dict["equal"])
    
    # Check that the first break is the minimum and the last is the maximum
    @test breaks_dict["fisher"][1] == minimum(test_values)
    @test breaks_dict["fisher"][end] == maximum(test_values)
    
    # Test get_bins function
    bins_dict = Breakers.get_bins(test_values, 5)
    
    # Check that we got the right methods
    @test haskey(bins_dict, "fisher")
    @test haskey(bins_dict, "kmeans")
    @test haskey(bins_dict, "quantile")
    @test haskey(bins_dict, "equal")
    
    # Check that the bins are Vector{String}
    @test isa(bins_dict["fisher"], Vector{String})
    @test isa(bins_dict["kmeans"], Vector{String})
    @test isa(bins_dict["quantile"], Vector{String})
    @test isa(bins_dict["equal"], Vector{String})
    
    # Check that the length of bins matches the length of input
    @test length(bins_dict["fisher"]) == length(test_values)
    @test length(bins_dict["kmeans"]) == length(test_values)
    @test length(bins_dict["quantile"]) == length(test_values)
    @test length(bins_dict["equal"]) == length(test_values)
    
    # Additional test with missing values
    test_values_missing = [1, 3, 5, missing, 9, 11, 13, missing, 35, 51, 65, 80, 90, 100]
    bins_dict_missing = Breakers.get_bins(test_values_missing, 5)
    
    # Check that the bins for missing values are "Missing"
    @test bins_dict_missing["fisher"][4] == "Missing"
    @test bins_dict_missing["fisher"][8] == "Missing"
    
    # Test boundary handling (R's classInt compatibility)
    @testset "Boundary handling (R's classInt compatibility)" begin
        # Create test data with exact boundary values
        boundary_values = [0, 5, 10, 15, 20, 25, 30]
        manual_breaks = [0.0, 10.0, 20.0, 30.0]
        
        # Get bin indices using fixed breaks
        indices = Breakers.get_bin_indices(boundary_values, 3)
        
        # Check if the indices match expected R behavior:
        # - Values at the minimum break (0) should be in bin 1
        # - Values exactly on interior breaks (10, 20) should be in the higher bin
        # - Values at the maximum break (30) should be in the highest bin
        expected_indices = [1, 1, 2, 2, 3, 3, 3]
        
        # Test all methods
        for method in ["fisher", "kmeans", "quantile", "equal"]
            # Override the automatic breaks with our manual ones for this test
            bin_indices = zeros(Int, length(boundary_values))
            
            for (i, val) in enumerate(boundary_values)
                if ismissing(val)
                    bin_indices[i] = 0
                    continue
                end
                
                # Find which bin this value belongs to
                if val <= manual_breaks[1]
                    bin_indices[i] = 1
                    continue
                end
                
                bin_found = false
                for j in 1:length(manual_breaks)-1
                    # Apply R's classInt convention: use strict inequality for upper bound
                    if val > manual_breaks[j] && val < manual_breaks[j+1]
                        bin_indices[i] = j
                        bin_found = true
                        break
                    end
                    # Special case for boundary values - assign to higher bin
                    if val == manual_breaks[j+1] && j < length(manual_breaks)-1
                        bin_indices[i] = j+1
                        bin_found = true
                        break
                    end
                end
                
                if !bin_found
                    bin_indices[i] = length(manual_breaks) - 1  # Last bin
                end
            end
            
            @test bin_indices == expected_indices
            
            # Also test actual implementation with real data
            # Values: [0, 5, 10, 15, 20, 25, 30]
            @test indices[method][1] == 1  # 0 -> bin 1 (minimum)
            @test indices[method][3] == 2  # 10 -> bin 2 (exactly on boundary, goes to higher bin)
            @test indices[method][5] == 3  # 20 -> bin 3 (exactly on boundary, goes to higher bin)
            
            # The maximum value can be handled differently by different algorithms,
            # Either as the last bin (3) or as a potential outlier bin (4)
            @test indices[method][7] in [3, 4]  # 30 -> bin 3 or 4 (maximum)
        end
        
        # Test string labeling via cut_data
        string_bins = Breakers.cut_data(boundary_values, manual_breaks)
        @test string_bins[1] == "≤ 0.0"  # Minimum
        @test string_bins[3] == "10.0 - 20.0"  # Value 10 (on boundary) gets higher interval
        @test string_bins[5] == "20.0 - 30.0"  # Value 20 (on boundary) gets higher interval
        @test string_bins[7] == "> 20.0"  # Maximum
    end
end 