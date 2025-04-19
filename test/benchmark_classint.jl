#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

using Pkg
Pkg.activate(@__DIR__)
using Breakers
using BenchmarkTools
using RCall
using Random
using Statistics
using CSV
using DataFrames
using Printf
"""
Generate a large vector for benchmarking.

Parameters:
- size: Number of elements in the vector (default: 1,000,000)
- distribution: :uniform, :normal, or :skewed (default: :normal)
- seed: Random seed for reproducibility (default: 42)

Returns:
- Vector{Float64}: A large vector for benchmarking
"""
function generate_benchmark_data(size::Int=1_000_000; 
                                distribution::Symbol=:normal, 
                                seed::Int=42)
    Random.seed!(seed)
    
    if distribution == :uniform
        # Uniform distribution between 0 and 1,000,000
        return rand(size) .* 1_000_000
    elseif distribution == :normal
        # Normal distribution with mean 500,000 and std 100,000
        return randn(size) .* 100_000 .+ 500_000
    elseif distribution == :skewed
        # Log-normal distribution (positively skewed)
        return exp.(randn(size)) .* 100_000
    else
        error("Unknown distribution: $distribution")
    end
end

"""
Benchmark a single binning method in Breakers.jl.

Parameters:
- data: Vector of data to bin
- n_bins: Number of bins to use
- method: Binning method to benchmark

Returns:
- BenchmarkTools.Trial: Benchmark results
"""
function benchmark_breakers(data, n_bins=7, method="fisher")
    # Warm up run
    Breakers.get_bin_indices(data, n_bins)
    
    # Benchmark
    return @benchmark Breakers.get_bin_indices($data, $n_bins)
end

function benchmark_threadedbreakers(data, n_bins=7, method="fisher")
    # Warm up run
    Breakers.get_bin_indices(data, n_bins)
    
    # Benchmark
    return @benchmark Breakers.get_bin_indices($data, $n_bins)
end
"""
Benchmark a single binning method in R's ClassInt package.

Parameters:
- data: Vector of data to bin
- n_bins: Number of bins to use
- method: Binning method to benchmark

Returns:
- Float64: Elapsed time in seconds
"""
function benchmark_classint(data, n_bins=7, method="fisher")
    # Convert method name to R style
    r_method = method
    
    # Prepare R code
    r_code = """
    function(data, n_bins, method) {
        library(classInt)
        
        # Time the operation
        start_time <- Sys.time()
        
        # Run the binning operation
        intervals <- classIntervals(data, n = n_bins, style = method)
        bins <- findInterval(data, intervals$brks)
        
        # Calculate elapsed time
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        return(elapsed)
    }
    """
    
    # Run the R code
    r_func = R(r_code)
    
    # Warm up run
    r_func(data, n_bins, r_method)
    
    # Real benchmark (repeat 5 times and take the minimum)
    times = Float64[]
    for _ in 1:5
        push!(times, r_func(data, n_bins, r_method))
    end
    
    return minimum(times)
end

"""
Run benchmarks comparing Breakers.jl and R's ClassInt package.

Parameters:
- sizes: Vector of dataset sizes to benchmark
- methods: Vector of binning methods to benchmark
- distributions: Vector of data distributions to benchmark
- n_bins: Number of bins to use

Returns:
- DataFrame: Benchmark results
"""
function run_benchmarks(sizes=[10_000, 100_000, 1_000_000], 
                       methods=["fisher", "kmeans", "quantile", "equal"],
                       distributions=[:normal, :uniform, :skewed],
                       n_bins=7)
    # Initialize results DataFrame
    results = DataFrame(
        size = Int[],
        distribution = Symbol[],
        method = String[],
        julia_time_ms = Float64[],
        r_time_ms = Float64[],
        speedup = Float64[]
    )
    
    # Run benchmarks for each combination
    for size in sizes
        for dist in distributions
            # Generate data
            println("Generating $size $dist distributed data points...")
            data = generate_benchmark_data(size, distribution=dist)
            
            for method in methods
                println("Benchmarking $method method with $size $dist distributed data points...")
                
                # Benchmark Breakers.jl
                julia_bench = benchmark_breakers(data, n_bins, method)
                julia_time_ms = minimum(julia_bench.times) / 1_000_000  # Convert ns to ms
                
                # Benchmark R's ClassInt
                r_time_sec = benchmark_classint(data, n_bins, method)
                r_time_ms = r_time_sec * 1000  # Convert seconds to ms
                
                # Calculate speedup
                speedup = r_time_ms / julia_time_ms
                
                # Add to results
                push!(results, (
                    size,
                    dist,
                    method,
                    julia_time_ms,
                    r_time_ms,
                    speedup
                ))
                
                # Print results
                println("  Julia time: $(round(julia_time_ms, digits=2)) ms")
                println("  R time: $(round(r_time_ms, digits=2)) ms")
                println("  Speedup: $(round(speedup, digits=2))x")
            end
        end
    end
    
    return results
end

function print_summary(results)
    println("\n========== BENCHMARK SUMMARY ==========\n")
    
    # Group by method and calculate average speedup
    method_summary = combine(
        groupby(results, :method), 
        :speedup => mean => :avg_speedup
    )
    
    println("Average speedup by method:")
    for row in eachrow(sort(method_summary, :avg_speedup, rev=true))
        @printf("  %s: %.2fx\n", row.method, row.avg_speedup)
    end
    
    # Group by size and calculate average speedup
    size_summary = combine(
        groupby(results, :size), 
        :speedup => mean => :avg_speedup
    )
    
    println("\nAverage speedup by data size:")
    for row in eachrow(sort(size_summary, :size))
        @printf("  %d points: %.2fx\n", row.size, row.avg_speedup)
    end
    
    # Group by distribution and calculate average speedup
    dist_summary = combine(
        groupby(results, :distribution), 
        :speedup => mean => :avg_speedup
    )
    
    println("\nAverage speedup by distribution:")
    for row in eachrow(sort(dist_summary, :avg_speedup, rev=true))
        @printf("  %s: %.2fx\n", row.distribution, row.avg_speedup)
    end
    
    # Overall average
    overall_speedup = mean(results.speedup)
    println("\nOverall average speedup: $(round(overall_speedup, digits=2))x")
    
    # Find best and worst cases
    best_case = results[argmax(results.speedup), :]
    worst_case = results[argmin(results.speedup), :]
    
    println("\nBest case:")
    @printf("  %s method with %d %s distributed points: %.2fx\n", 
            best_case.method, best_case.size, best_case.distribution, best_case.speedup)
    
    println("\nWorst case:")
    @printf("  %s method with %d %s distributed points: %.2fx\n", 
            worst_case.method, worst_case.size, worst_case.distribution, worst_case.speedup)
end

function save_results(results)
    # Create directory if it doesn't exist
    benchmark_dir = abspath(joinpath(@__DIR__, "..", "benchmarks"))
    mkpath(benchmark_dir)
    
    # Save results
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    csv_file = joinpath(benchmark_dir, "benchmark_results_$(timestamp).csv")
    CSV.write(csv_file, results)
    
    println("\nResults saved to: $csv_file")
    return csv_file
end

function main()
    println("Starting benchmarks comparing Breakers.jl with R's ClassInt package...")
    
    # Default benchmark parameters
    sizes = [10_000, 100_000, 1_000_000]  # Dataset sizes
    methods = ["fisher", "kmeans", "quantile", "equal"]  # Binning methods
    distributions = [:normal, :uniform, :skewed]  # Data distributions
    n_bins = 7  # Number of bins
    
    # Parse command line arguments
    for arg in ARGS
        if startswith(arg, "--sizes=")
            sizes_str = split(replace(arg, "--sizes=" => ""), ",")
            sizes = [parse(Int, s) for s in sizes_str]
        elseif startswith(arg, "--methods=")
            methods = split(replace(arg, "--methods=" => ""), ",")
        elseif startswith(arg, "--distributions=")
            dists_str = split(replace(arg, "--distributions=" => ""), ",")
            distributions = [Symbol(d) for d in dists_str]
        elseif startswith(arg, "--bins=")
            n_bins = parse(Int, replace(arg, "--bins=" => ""))
        elseif arg == "--help" || arg == "-h"
            println("Usage: julia benchmark_classint.jl [options]")
            println("Options:")
            println("  --sizes=size1,size2,...       Dataset sizes to benchmark")
            println("  --methods=method1,method2,... Binning methods to benchmark")
            println("  --distributions=dist1,dist2,..Data distributions to benchmark")
            println("  --bins=n                     Number of bins to use")
            println("  --help, -h                   Show this help message")
            exit(0)
        end
    end
    
    # Run benchmarks
    results = run_benchmarks(sizes, methods, distributions, n_bins)
    
    # Print summary
    print_summary(results)
    
    # Save results
    save_results(results)
end

# Run main function if script is run directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 

random_integers = rand(1:100, 10_000)
@benchmark Breakers.get_bin_indices($random_integers, 7)







