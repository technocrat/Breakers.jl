#!/usr/bin/env julia
# SPDX-License-Identifier: MIT
#
# Julia-R comparison script
# 
# This script compares the performance and results of Breakers.jl with R's classInt package
# Note: Fisher's algorithm becomes computationally intensive for large datasets (O(k × n²)).
#
# Usage:
#   julia --project=. benchmarks/compare_with_r.jl

using Breakers
using CSV, DataFrames
using Statistics
using Printf

"""
Generate test data matching the R script patterns
"""
function generate_test_data(size::Int, distribution::String; seed::Int=42)
    Random.seed!(seed)
    
    if distribution == "normal"
        return randn(size) .* 100 .+ 500
    elseif distribution == "uniform"
        return rand(size) .* 1000
    elseif distribution == "skewed"
        return exp.(randn(size)) .* 100
    else
        error("Unknown distribution: $distribution")
    end
end

"""
Benchmark Julia methods matching R's test scenarios
"""
function benchmark_julia_methods()
    println("🔬 Julia Breakers.jl Benchmark")
    println("==============================\n")
    
    # Test configurations (matching R script)
    # Note: Fisher algorithm is O(k × n²), so we limit to smaller sizes for reasonable benchmarking
    sizes = [1000, 5000, 10000] # Removed 100,000 size which is computationally intensive
    methods = ["fisher", "kmeans", "quantile", "equal"] # Note: R's kmeans is roughly equivalent to kmeans_breaks
    distributions = ["normal", "uniform", "skewed"]
    n_classes = 7
    
    results = DataFrame(
        Size = Int[],
        Distribution = String[],
        Method = String[],
        MedianTime_ms = Float64[],
        MeanTime_ms = Float64[],
        StdTime_ms = Float64[],
        NBreaks = Int[]
    )
    
    for size in sizes
        for dist in distributions
            println("Testing size = $size, distribution = $dist")
            
            # Generate test data (matching R's seed and distribution)
            data = generate_test_data(size, dist)
            
            for method in methods
                try
                    # Benchmark this method
                    times = Float64[]
                    breaks_result = nothing
                    
                    # Run multiple times for timing
                    for _ in 1:10
                        time_ns = @elapsed begin
                        if method == "fisher"
                                breaks_result = fisher_breaks(data, n_classes)
                            elseif method == "kmeans"
                                breaks_result = kmeans_breaks(data, n_classes)
                            elseif method == "quantile"
                                breaks_result = quantile_breaks(data, n_classes)
                            elseif method == "equal"
                                breaks_result = equal_breaks(data, n_classes)
                            end
                        end
                        push!(times, time_ns * 1000)  # Convert to milliseconds
                    end
                    
                    # Calculate statistics
                    median_time = median(times)
                    mean_time = mean(times)
                    std_time = std(times)
                    n_breaks = length(breaks_result)
                    
                    # Add to results
                    push!(results, (size, dist, method, median_time, mean_time, std_time, n_breaks))
                    
                    @printf("  %-10s: %8.2f ms (median)\n", method, median_time)
                    
                catch e
                    println("  Error with $method: ", e)
                end
            end
            println()
        end
    end
    
    # Save results
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    filename = "benchmarks/julia_breakers_benchmark_$(timestamp).csv"
    CSV.write(filename, results)
    println("📊 Results saved to: $filename\n")
    
    return results
end

"""
Compare Julia and R benchmark results
"""
function compare_julia_r_performance()
    println("📊 JULIA vs R PERFORMANCE COMPARISON")
    println("=====================================\n")
    
    # Find the most recent R and Julia benchmark files
    r_files = filter(x -> startswith(x, "r_classint_benchmark"), readdir("benchmarks"))
    julia_files = filter(x -> startswith(x, "julia_breakers_benchmark"), readdir("benchmarks"))
    
    if isempty(r_files)
        println("❌ No R benchmark results found. Run the R script first.")
        return
    end
    
    if isempty(julia_files)
        println("❌ No Julia benchmark results found. Running Julia benchmark now...\n")
        julia_results = benchmark_julia_methods()
        julia_files = filter(x -> startswith(x, "julia_breakers_benchmark"), readdir("benchmarks"))
    end
    
    # Load the most recent results
    r_file = joinpath("benchmarks", sort(r_files)[end])
    julia_file = joinpath("benchmarks", sort(julia_files)[end])
    
    println("📁 Loading R results from: ", basename(r_file))
    println("📁 Loading Julia results from: ", basename(julia_file))
    println()
    
    r_results = CSV.read(r_file, DataFrame)
    julia_results = CSV.read(julia_file, DataFrame)
    
    # Method mapping (R -> Julia)
    method_mapping = Dict(
        "fisher" => "fisher",
        "kmeans" => "kmeans",  # Direct comparison with kmeans_breaks
        "quantile" => "quantile", 
        "equal" => "equal"
    )
    
    println("⚡ SPEED COMPARISON")
    println("==================")
    println("Format: Julia_method vs R_method (Speedup: Jx faster)")
    println()
    
    comparison_results = DataFrame(
        Size = Int[],
        Distribution = String[],
        Julia_Method = String[],
        R_Method = String[],
        Julia_Time_ms = Float64[],
        R_Time_ms = Float64[],
        Speedup = Float64[]
    )
    
    for size in [1000, 5000, 10000]
        for dist in ["normal", "uniform", "skewed"]
            println("Size: $size, Distribution: $dist")
            
            # Get results for this size/distribution
            r_subset = filter(row -> row.Size == size && row.Distribution == dist, r_results)
            julia_subset = filter(row -> row.Size == size && row.Distribution == dist, julia_results)
            
            for (r_method, julia_method) in method_mapping
                r_row = filter(row -> row.Method == r_method, r_subset)
                julia_row = filter(row -> row.Method == julia_method, julia_subset)
                
                if !isempty(r_row) && !isempty(julia_row)
                    r_time = r_row[1, :MedianTime_ms]
                    julia_time = julia_row[1, :MedianTime_ms]
                    speedup = r_time / julia_time
                    
                    push!(comparison_results, (size, dist, julia_method, r_method, julia_time, r_time, speedup))
                    
                    speedup_str = speedup >= 1.0 ? @sprintf("%.1fx faster", speedup) : @sprintf("%.1fx slower", 1/speedup)
                    @printf("  %-8s vs %-8s: %6.2f ms vs %6.2f ms (%s)\n", 
                           julia_method, r_method, julia_time, r_time, speedup_str)
                end
            end
            println()
        end
    end
    
    # Overall summary
    println("📈 OVERALL SUMMARY")
    println("==================")
    
    # Average speedup by method
    for (r_method, julia_method) in method_mapping
        method_comparisons = filter(row -> row.R_Method == r_method, comparison_results)
        if !isempty(method_comparisons)
            avg_speedup = mean(method_comparisons.Speedup)
            speedup_str = avg_speedup >= 1.0 ? @sprintf("%.1fx faster", avg_speedup) : @sprintf("%.1fx slower", 1/avg_speedup)
            @printf("%-8s vs %-8s (average): %s\n", julia_method, r_method, speedup_str)
        end
    end
    
    # Save comparison results
    timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
    comparison_file = "benchmarks/julia_r_comparison_$(timestamp).csv"
    CSV.write(comparison_file, comparison_results)
    println("\n💾 Comparison results saved to: $comparison_file")
    
    return comparison_results
end

"""
Generate comparison data for result validation
"""
function generate_julia_comparison_data()
    println("\n🔍 GENERATING JULIA COMPARISON DATA")
    println("===================================\n")
    
    # Generate the same datasets as R
    datasets = Dict(
        "small_normal" => generate_test_data(1000, "normal"),
        "medium_uniform" => generate_test_data(10000, "uniform"),
        "large_skewed" => generate_test_data(50000, "skewed")
    )
    
    julia_comparison = Dict()
    
    for (dataset_name, data) in datasets
        println("Dataset: $dataset_name")
        
        dataset_results = Dict()
        for method in ["fisher", "kmeans", "quantile", "equal"]
            try
                if method == "fisher"
                    breaks = fisher_breaks(data, 7)
                elseif method == "kmeans"
                    breaks = kmeans_breaks(data, 7)
                elseif method == "quantile"
                    breaks = quantile_breaks(data, 7)
                elseif method == "equal"
                    breaks = equal_breaks(data, 7)
                end
                
                dataset_results[method] = breaks
                @printf("  %-10s: [%.2f, %.2f, ..., %.2f, %.2f] (%d breaks)\n", 
                       method, breaks[1], breaks[2], breaks[end-1], breaks[end], length(breaks))
                       
            catch e
                println("  $method: ERROR - $e")
            end
        end
        julia_comparison[dataset_name] = dataset_results
        println()
    end
    
    return julia_comparison
end

"""
Main function
"""
function main()
    println("Julia-R Benchmarking Comparison")
    println("===============================\n")
    
    # First run Julia benchmarks
    println("🚀 Running Julia benchmarks...")
    julia_results = benchmark_julia_methods()
    
    # Compare with R results
    comparison_results = compare_julia_r_performance()
    
    # Generate comparison data 
    julia_comparison_data = generate_julia_comparison_data()
    
    println("✅ Comparison completed successfully!")
    println("📁 Check the 'benchmarks/' directory for output files.")
end

# Only run if script is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    using Random, Dates
    main()
end
