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
    
    @testset "Threaded Fisher Breaks" begin
        include("test_threaded_fisher.jl")
    end
    
    # Run benchmark tests only when BREAKERS_BENCHMARK environment variable is set
    if haskey(ENV, "BREAKERS_BENCHMARK")
        @testset "Performance Benchmarks" begin
            # Check if RCall is available
            try
                using RCall
                using BenchmarkTools
                
                @info "Running performance benchmarks comparing Breakers.jl to R's ClassInt package..."
                include("benchmark_classint.jl")
                
                # Run with smaller data sizes for CI testing
                if get(ENV, "CI", "false") == "true"
                    results = run_benchmarks([1_000, 10_000], 
                                            ["fisher", "kmeans", "quantile", "equal"],
                                            [:normal],
                                            7)
                else
                    results = run_benchmarks()
                end
                
                print_summary(results)
                save_results(results)
                
                # Simple test to ensure we have results
                @test size(results, 1) > 0
            catch e
                if isa(e, ArgumentError) && occursin("Package RCall", e.msg)
                    @warn "RCall package not available, skipping benchmarks. Install RCall to run benchmarks."
                elseif isa(e, ArgumentError) && occursin("Package BenchmarkTools", e.msg)
                    @warn "BenchmarkTools package not available, skipping benchmarks. Install BenchmarkTools to run benchmarks."
                else
                    @warn "Error running benchmarks: $(e)"
                end
            end
        end
    end
end

@testset "Werks.jl" begin
    # Write your tests here.
    @test 1 == 1
end
