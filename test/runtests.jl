#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

using Test
using Breakers
using CSV

@testset "Breakers.jl" begin
    @testset "get_bins" begin
        include("test/test_get_bins.jl")
    end
    
    @testset "SubArrays" begin
        include("test/test_subarrays.jl")
    end
end

@testset "Breakers.jl" begin
    # Write your tests here.
    @test 1 == 1
end

@testset "SubArrays .jl" begin
    include("test/test_subarrays.jl")
end

@testset "get_bins.jl" begin
    include("test/test_get_bins.jl")
end