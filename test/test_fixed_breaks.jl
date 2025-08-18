# SPDX-License-Identifier: MIT

using Test
using Breakers

@testset "Fixed Breaks Integration Tests" begin
    # Test data
    test_data = [1, 5, 10, 15, 20, 25, 30, 35, 40]
    
    @testset "Basic fixed_breaks functionality" begin
        # Test basic functionality
        breaks = fixed_breaks(test_data, [10, 20, 30])
        @test breaks == [1.0, 10.0, 20.0, 30.0, 40.0]
        
        # Test with break points outside data range (should be filtered)
        breaks_filtered = fixed_breaks(test_data, [0, 10, 20, 30, 50])
        @test breaks_filtered == [1.0, 10.0, 20.0, 30.0, 40.0]
        
        # Test with single break point
        breaks_single = fixed_breaks(test_data, [15])
        @test breaks_single == [1.0, 15.0, 40.0]
        
        # Test with break points at extremes
        breaks_extremes = fixed_breaks(test_data, [1, 40])
        @test breaks_extremes == [1.0, 40.0]
    end
    
    @testset "Integration with get_breaks_raw" begin
        # Test that fixed breaks work with get_breaks_raw
        breaks_dict = get_breaks_raw(test_data, [10, 20, 30])
        @test haskey(breaks_dict, "fixed")
        @test breaks_dict["fixed"] == [1.0, 10.0, 20.0, 30.0, 40.0]
        
        # Test with custom method name
        breaks_custom = get_breaks_raw(test_data, [10, 20, 30]; method="custom")
        @test haskey(breaks_custom, "custom")
        @test breaks_custom["custom"] == [1.0, 10.0, 20.0, 30.0, 40.0]
    end
    
    @testset "Convenience functions" begin
        # Test get_bin_indices_fixed
        indices = get_bin_indices_fixed(test_data, [10, 20, 30])
        expected_indices = [1, 1, 2, 2, 3, 3, 4, 4, 4]
        @test indices == expected_indices
        
        # Test get_bins_fixed
        labels = get_bins_fixed(test_data, [10, 20, 30])
        @test length(labels) == length(test_data)
        @test labels[1] == "≤ 1.0"
        @test labels[3] == "10.0 - 20.0"  # value 10 should be in higher bin
        @test labels[end] == "> 30.0"
    end
    
    @testset "Integration with cut_data" begin
        # Test that fixed breaks work with cut_data
        breaks = fixed_breaks(test_data, [10, 25])
        labels = cut_data(test_data, breaks)
        
        @test length(labels) == length(test_data)
        @test labels[1] == "≤ 1.0"  # First value
        @test labels[3] == "10.0 - 25.0"  # Value 10
        @test labels[end] == "> 25.0"  # Last value
    end
    
    @testset "Edge cases and error handling" begin
        # Test empty break points
        @test_throws ErrorException fixed_breaks(test_data, Float64[])
        
        # Test empty data
        @test_throws ErrorException fixed_breaks(Int[], [10, 20])
        
        # Test with missing values
        data_with_missing = [1, missing, 10, 15, missing, 25, 30]
        breaks = fixed_breaks(data_with_missing, [10, 20])
        @test breaks == [1.0, 10.0, 20.0, 30.0]
        
        # Test bin indices with missing values
        indices = get_bin_indices_fixed(data_with_missing, [10, 20])
        @test indices[1] == 1  # 1 -> bin 1
        @test indices[2] == 0  # missing -> 0
        @test indices[3] == 2  # 10 -> bin 2
        
        # Test bin labels with missing values
        labels = get_bins_fixed(data_with_missing, [10, 20])
        @test labels[1] == "≤ 1.0"
        @test labels[2] == "Missing"
        @test labels[3] == "10.0 - 20.0"
    end
    
    @testset "Backward compatibility - split_at_indices" begin
        # Test that the legacy function still works
        legacy_result = split_at_indices([1, 2, 3, 4, 5, 6, 7, 8], [3, 6])
        expected_legacy = [[1, 2, 3], [4, 5, 6], [7, 8]]
        @test legacy_result == expected_legacy
        
        # Test with missing values
        data_missing = [1, missing, 3, 4, missing, 6, 7, 8]
        legacy_missing = split_at_indices(data_missing, [3, 5])
        expected_missing = [[1, 3, 4], [6, 7], [8]]  # Missing values removed
        @test legacy_missing == expected_missing
    end
    
    @testset "Comparison with other methods" begin
        # Compare fixed breaks results with automatic methods
        # to ensure consistency in boundary handling
        sample_data = [5, 10, 15, 20, 25]
        
        # Fixed breaks
        fixed_labels = get_bins_fixed(sample_data, [10, 20])
        
        # The boundary handling should be consistent:
        # Value exactly on break point should go to higher bin
        @test fixed_labels[1] == "≤ 5.0"      # 5 -> first bin
        @test fixed_labels[2] == "10.0 - 20.0" # 10 -> second bin (on boundary)
        @test fixed_labels[4] == "20.0 - 25.0" # 20 -> third bin (on boundary)
    end
end
