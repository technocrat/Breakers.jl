#!/usr/bin/env julia
# SPDX-License-Identifier: MIT
#
# Script to run Breakers.jl internal benchmarks comparing different algorithms
#
# Usage:
#   julia benchmark.jl [options]
#   julia -t auto benchmark.jl [options]  # For threading benchmarks
#
# Options:
#   --sizes=size1,size2,...       Dataset sizes to benchmark (default: 1000,10000,100000)
#   --methods=method1,method2,... Binning methods to benchmark (default: fisher,fisher_threaded,kmeans,quantile,equal)
#   --distributions=dist1,dist2,..Data distributions to benchmark (default: normal,uniform,skewed)
#   --bins=n                      Number of bins to use (default: 7)
#   --help, -h                    Show this help message
#
# Note: For R classInt comparison, you can create a separate script using RCall.jl

# Activate current project
using Pkg
Pkg.activate(@__DIR__)

# For development, we don't need to install Breakers as it's the current project
# Just check and install other required packages
required_dev_pkgs = ["BenchmarkTools", "CSV", "DataFrames"]
for pkg in required_dev_pkgs
    if !haskey(Pkg.project().dependencies, pkg)
        @info "Installing required package: $pkg"
        Pkg.add(pkg)
    end
end

# Load required packages
using Breakers
using BenchmarkTools 
using Statistics
using Random
using DataFrames
using CSV
using Printf
using Dates

# Parse command line arguments and run benchmarks
function run()
    if "--help" in ARGS || "-h" in ARGS
        println("Usage: julia benchmark.jl [options]")
        println("Options:")
        println("  --sizes=size1,size2,...       Dataset sizes to benchmark (default: 1000,10000,100000)")
        println("  --methods=method1,method2,... Binning methods to benchmark (default: fisher,kmeans,quantile,equal)")
        println("  --distributions=dist1,dist2,..Data distributions to benchmark (default: normal,uniform,skewed)")
        println("  --bins=n                      Number of bins to use (default: 7)")
        println("  --help, -h                    Show this help message")
        println("")
        println("Note: This benchmarks Breakers.jl methods against each other.")
        println("For R classInt comparison, install RCall.jl separately.")
        exit(0)
    end

    # Run the benchmarks
    results = run_breakers_benchmark()

    # Return results for potential further processing
    return results
end

# Main benchmarking function
function run_breakers_benchmark()
    println("🔬 Breakers.jl Internal Benchmarks")
    println("==================================\n")
    
    # Parse arguments or use defaults
    sizes = parse_arg("--sizes", [1000, 10000, 100000])
    methods = parse_arg("--methods", [:fisher, :fisher_threaded, :kmeans, :quantile, :equal])
    distributions = parse_arg("--distributions", [:normal, :uniform, :skewed])
    bins = parse_arg("--bins", 7)
    
    results = DataFrame(
        Size = Int[],
        Distribution = String[],
        Method = String[],
        MedianTime_ms = Float64[],
        MeanTime_ms = Float64[],
        StdTime_ms = Float64[],
        Allocations = Int[],
        Memory_MB = Float64[]
    )
    
    for size in sizes
        for dist in distributions
            println("Testing size=$(size), distribution=$(dist)")
            
            # Generate test data
            data = generate_test_data(size, dist)
            
            for method in methods
                if method == :fisher_threaded && Threads.nthreads() == 1
                    @warn "Skipping fisher_threaded - no threads available. Run with `julia -t auto` for threading."
                    continue
                end
                
                try
                    # Run benchmark
                    benchmark_result = @benchmark $(get_method_function(method))($(data), $(bins))
                    
                    # Extract results
                    median_time = median(benchmark_result.times) / 1_000_000  # Convert to ms
                    mean_time = mean(benchmark_result.times) / 1_000_000
                    std_time = std(benchmark_result.times) / 1_000_000
                    
                    # Add to results
                    push!(results, (
                        size,
                        string(dist),
                        string(method),
                        median_time,
                        mean_time, 
                        std_time,
                        benchmark_result.allocs,
                        benchmark_result.memory / (1024^2)  # Convert to MB
                    ))
                    
                    @printf "  %-15s: %8.2f ms (median), %8.2f MB\n" string(method) median_time (benchmark_result.memory / (1024^2))
                    
                catch e
                    @warn "Failed to benchmark $method: $e"
                end
            end
            println()
        end
    end
    
    # Save results
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    filename = "benchmarks/breakers_benchmark_$(timestamp).csv"
    mkpath(dirname(filename))
    CSV.write(filename, results)
    println("📊 Results saved to: $filename")
    
    # Print summary
    print_benchmark_summary(results)
    
    return results
end

# Helper functions
function parse_arg(arg_name, default)
    for arg in ARGS
        if startswith(arg, "$(arg_name)=")
            value_str = split(arg, '=')[2]
            if arg_name == "--sizes"
                return [parse(Int, x) for x in split(value_str, ',')]
            elseif arg_name == "--methods"
                return [Symbol(x) for x in split(value_str, ',')]
            elseif arg_name == "--distributions"
                return [Symbol(x) for x in split(value_str, ',')]
            elseif arg_name == "--bins"
                return parse(Int, value_str)
            end
        end
    end
    return default
end

function generate_test_data(size, distribution)
    Random.seed!(42)  # For reproducible benchmarks
    
    if distribution == :normal
        return randn(size) * 100 .+ 500
    elseif distribution == :uniform
        return rand(size) * 1000
    elseif distribution == :skewed
        return exp.(randn(size)) * 100
    else
        error("Unknown distribution: $distribution")
    end
end

function get_method_function(method)
    if method == :fisher
        return fisher_breaks
    elseif method == :fisher_threaded
        return fisher_breaks_threaded
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

function print_benchmark_summary(results)
    println("\n📈 BENCHMARK SUMMARY")
    println("===================\n")
    
    # Group by size and show fastest method for each
    for size in sort(unique(results.Size))
        size_results = filter(row -> row.Size == size, results)
        println("Size $size:")
        
        for dist in unique(size_results.Distribution)
            dist_results = filter(row -> row.Distribution == dist, size_results)
            if !isempty(dist_results)
                fastest = dist_results[argmin(dist_results.MedianTime_ms), :]
                @printf "  %-10s: %s (%.2f ms)\n" string(dist) string(fastest.Method) fastest.MedianTime_ms
            end
        end
        println()
    end
    
    if Threads.nthreads() > 1
        fisher_results = filter(row -> row.Method == "fisher", results)
        fisher_threaded_results = filter(row -> row.Method == "fisher_threaded", results)
        
        if !isempty(fisher_results) && !isempty(fisher_threaded_results)
            println("🚀 THREADING PERFORMANCE:")
            for size in intersect(fisher_results.Size, fisher_threaded_results.Size)
                regular_time = mean(filter(row -> row.Size == size, fisher_results).MedianTime_ms)
                threaded_time = mean(filter(row -> row.Size == size, fisher_threaded_results).MedianTime_ms)
                speedup = regular_time / threaded_time
                @printf "  Size %-8d: %.2fx speedup with %d threads\n" size speedup Threads.nthreads()
            end
        end
    end
end

# Run the script
run() 