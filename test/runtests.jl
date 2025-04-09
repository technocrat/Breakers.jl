#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

using Test
using Breakers
using CSV

@testset "Breakers.jl" begin
    @testset "get_bins" begin
        include("test_get_bins.jl")
    end
    
    @testset "SubArrays" begin
        include("test_subarrays.jl")
    end
    
    @testset "R ClassInt Comparison" begin
        include("compare_to_classInt_R.jl")
    end
end
