#!/usr/bin/env julia

# Run this script with: julia --project=. -t auto benchmark_example.jl

"""
This script demonstrates how to benchmark the threaded Fisher breaks
algorithm with BenchmarkTools using the requested example:
    @benchmark fisher_breaks_threaded(v) where v = rand(1:100,1000)
"""

# Activate the current project - if running from the project directory
# This ensures the Breakers package is available
import Pkg
Pkg.activate(".")

# Load the necessary packages
using Breakers
using BenchmarkTools
using Random
using Threads

# Print thread information
println("Running with $(Threads.nthreads()) threads")

# Create the test vector as requested
v = rand(1:100, 1000)

# Run the benchmark with the exact requested format
println("\nBenchmarking fisher_breaks_threaded(v) where v = rand(1:100,1000):")
result = @benchmark fisher_breaks_threaded($v)
display(result)

# Also compare with the non-threaded version to see the difference
println("\nFor comparison, benchmarking the non-threaded version:")
result_regular = @benchmark fisher_breaks($v)
display(result_regular)

# Show expected use case with larger dataset where threading helps more
println("\nNote: For a small dataset of 1,000 elements, you might not see a significant")
println("performance improvement. Below is a benchmark with a larger dataset (50,000 elements)")
println("where the threaded implementation should show better performance:")

# Create a larger test vector
v_large = rand(1:100, 50000)

println("\nRegular version with 50,000 elements:")
result_large_regular = @benchmark fisher_breaks($v_large)
display(result_large_regular)

println("\nThreaded version with 50,000 elements:")
result_large_threaded = @benchmark fisher_breaks_threaded($v_large)
display(result_large_threaded)

# Calculate and display speedup
median_regular = median(result_large_regular.times) / 1_000_000_000  # seconds
median_threaded = median(result_large_threaded.times) / 1_000_000_000  # seconds
speedup = median_regular / median_threaded

println("\nSpeedup with $(Threads.nthreads()) threads: $(round(speedup, digits=2))x") 