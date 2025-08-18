#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

"""
Example: R classInt Comparison Benchmarking

This example shows how to benchmark Breakers.jl against R's classInt package
using RCall.jl. This requires:

1. R installed on your system
2. R's classInt package installed: install.packages("classInt")
3. RCall.jl package: Pkg.add("RCall")

Usage:
    julia --project=. examples/r_classint_comparison.jl

This demonstrates how to set up R comparison benchmarking for users who need
exact compatibility validation or performance comparisons.
"""

# Check if RCall is available
try
    using RCall
    @info "RCall.jl is available - R comparison benchmarking enabled"
    R_AVAILABLE = true
catch
    @warn """
    RCall.jl not available. To enable R comparison benchmarking:
    
    1. Install R: https://www.r-project.org/
    2. Install R's classInt package:
       R> install.packages("classInt")
    3. Add RCall.jl:
       julia> using Pkg; Pkg.add("RCall")
    """
    R_AVAILABLE = false
end

using Pkg
Pkg.activate(@__DIR__)

using Breakers
using BenchmarkTools
using Statistics
using Random
using DataFrames
using CSV
using Printf

function setup_r_environment()
    if !R_AVAILABLE
        error("RCall.jl is not available. See setup instructions above.")
    end
    
    # Load R's classInt package
    R"""
    if (!require("classInt", quietly = TRUE)) {
        install.packages("classInt")
        library(classInt)
    }
    """
    @info "R environment set up successfully"
end

function benchmark_against_r()
    if !R_AVAILABLE
        @warn "Skipping R comparison - RCall not available"
        return nothing
    end
    
    setup_r_environment()
    
    println("🔬 Breakers.jl vs R classInt Benchmark")
    println("======================================\n")
    
    # Test configurations
    sizes = [1000, 10000, 50000]
    methods = [:fisher, :kmeans, :quantile, :equal]
    n_classes = 7
    
    results = DataFrame(
        Size = Int[],
        Method = String[],
        Julia_Time_ms = Float64[],
        R_Time_ms = Float64[],
        Speedup = Float64[],
        Results_Match = Bool[]
    )
    
    for size in sizes
        println("Testing dataset size: $size")
        
        # Generate test data
        Random.seed!(42)
        data = randn(size) * 100 .+ 500
        
        for method in methods
            println("  Method: $method")
            
            try
                # Benchmark Julia implementation
                julia_func = get_julia_method_function(method)
                julia_benchmark = @benchmark $julia_func($data, $n_classes)
                julia_time = median(julia_benchmark.times) / 1_000_000  # Convert to ms
                julia_breaks = julia_func(data, n_classes)
                
                # Benchmark R implementation  
                r_method = get_r_method_name(method)
                
                # Transfer data to R and benchmark
                R"""
                r_data <- $(data)
                r_method <- $(r_method)
                n_classes <- $(n_classes)
                
                # Benchmark R implementation
                r_benchmark <- microbenchmark::microbenchmark(
                    classIntervals(r_data, n = n_classes, style = r_method),
                    times = 10
                )
                r_time_ms <- median(r_benchmark$time) / 1e6  # Convert to ms
                
                # Get R result for comparison
                r_result <- classIntervals(r_data, n = n_classes, style = r_method)
                r_breaks <- r_result$brks
                """
                
                r_time = @rget r_time_ms
                r_breaks = @rget r_breaks
                
                # Compare results (allowing small floating point differences)
                results_match = length(julia_breaks) == length(r_breaks) && 
                               all(abs.(julia_breaks .- r_breaks) .< 1e-10)
                
                speedup = r_time / julia_time
                
                # Add to results
                push!(results, (size, string(method), julia_time, r_time, speedup, results_match))
                
                @printf "    Julia: %8.2f ms | R: %8.2f ms | Speedup: %5.2fx | Match: %s\n" julia_time r_time speedup (results_match ? "✓" : "✗")
                
                if !results_match
                    @warn "Results don't match exactly - small numerical differences expected"
                    println("    Julia breaks: ", julia_breaks[1:min(5, end)], "...")
                    println("    R breaks:     ", r_breaks[1:min(5, end)], "...")
                end
                
            catch e
                @warn "Failed to benchmark $method: $e"
            end
        end
        println()
    end
    
    # Save results
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    filename = "benchmarks/r_comparison_$(timestamp).csv"
    mkpath(dirname(filename))
    CSV.write(filename, results)
    println("📊 Results saved to: $filename")
    
    # Print summary
    print_r_comparison_summary(results)
    
    return results
end

function get_julia_method_function(method)
    if method == :fisher
        return fisher_breaks
    elseif method == :kmeans
        return kmeans_breaks
    elseif method == :quantile
        return quantile_breaks
    elseif method == :equal
        return equal_breaks
    else
        error("Unknown method: $method")
    end
end

function get_r_method_name(method)
    if method == :fisher
        return "fisher"
    elseif method == :kmeans
        return "kmeans"
    elseif method == :quantile
        return "quantile"
    elseif method == :equal
        return "equal"
    else
        error("Unknown method: $method")
    end
end

function print_r_comparison_summary(results)
    println("📈 R COMPARISON SUMMARY")
    println("=======================\n")
    
    # Overall performance summary
    avg_speedup = mean(results.Speedup)
    match_rate = mean(results.Results_Match)
    
    @printf "Average speedup: %.2fx faster than R\n" avg_speedup
    @printf "Result accuracy: %.1f%% exact matches\n" (match_rate * 100)
    println()
    
    # Performance by method
    println("Performance by method:")
    for method in unique(results.Method)
        method_results = filter(row -> row.Method == method, results)
        avg_method_speedup = mean(method_results.Speedup)
        @printf "  %-10s: %.2fx speedup\n" method avg_method_speedup
    end
    println()
    
    # Performance by size
    println("Performance by dataset size:")
    for size in sort(unique(results.Size))
        size_results = filter(row -> row.Size == size, results)
        avg_size_speedup = mean(size_results.Speedup)
        @printf "  Size %-8d: %.2fx speedup\n" size avg_size_speedup
    end
end

function run_internal_benchmarks_only()
    println("🔬 Breakers.jl Internal Performance Test")
    println("=========================================\n")
    println("(For R comparison, install RCall.jl and rerun)")
    
    # Simple internal benchmark
    sizes = [1000, 10000, 50000]
    methods = [:fisher, :kmeans, :quantile, :equal]
    
    for size in sizes
        println("Dataset size: $size")
        Random.seed!(42)
        data = randn(size) * 100 .+ 500
        
        for method in methods
            julia_func = get_julia_method_function(method)
            benchmark_result = @benchmark $julia_func($data, 7)
            time_ms = median(benchmark_result.times) / 1_000_000
            @printf "  %-10s: %8.2f ms\n" method time_ms
        end
        println()
    end
end

# Main execution
function main()
    if R_AVAILABLE
        try
            benchmark_against_r()
        catch e
            @warn "R benchmarking failed: $e"
            @warn "Running internal benchmarks only"
            run_internal_benchmarks_only()
        end
    else
        run_internal_benchmarks_only()
    end
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
