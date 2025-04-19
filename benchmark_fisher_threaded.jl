#!/usr/bin/env julia

# Add the current directory to the load path to use the local development version
push!(LOAD_PATH, @__DIR__)
using Breakers
using BenchmarkTools
using Random
using Threads
using Printf
using Statistics  # For median function

# Print information about the system and threading configuration
println("Julia version: ", VERSION)
println("Number of threads available: ", Threads.nthreads())
println("Number of CPU cores: ", Sys.CPU_THREADS)

# Set seed for reproducibility
Random.seed!(42)

# Define test case sizes
dataset_sizes = [1_000, 10_000, 50_000]
k_values = [5, 7]

# Header for results table
println("\n", "-"^50)
@printf("%-10s %-5s %-15s %-15s %-10s\n", "Size", "k", "Regular (ms)", "Threaded (ms)", "Speedup")
println("-"^50)

# Run benchmarks for each test case
for n in dataset_sizes
    for k in k_values
        # Generate random data - use the same data for both implementations
        data = rand(1:100, n)
        
        # Benchmark regular implementation
        b_regular = @benchmark fisher_breaks($data, $k)
        
        # Benchmark threaded implementation
        b_threaded = @benchmark fisher_breaks_threaded($data, $k)
        
        # Convert time to milliseconds
        time_regular = median(b_regular.times) / 1_000_000
        time_threaded = median(b_threaded.times) / 1_000_000
        
        # Calculate speedup
        speedup = time_regular / time_threaded
        
        # Print results
        @printf("%-10d %-5d %-15.2f %-15.2f %-10.2f\n", n, k, time_regular, time_threaded, speedup)
    end
end

# More detailed benchmark for a specific size
println("\n", "-"^50)
println("Detailed benchmark for random data of size 50,000 with k=7:")

# Generate a larger random dataset
detailed_data = rand(1:100, 50_000)
k = 7

println("\nRegular fisher_breaks:")
display(@benchmark fisher_breaks($detailed_data, $k))

println("\nThreaded fisher_breaks_threaded:")
display(@benchmark fisher_breaks_threaded($detailed_data, $k))

# Test with your specific example
println("\n", "-"^50)
println("Benchmark for v = rand(1:100, 1000):")

v = rand(1:100, 1000)

println("\nRegular fisher_breaks(v):")
display(@benchmark fisher_breaks($v))

println("\nThreaded fisher_breaks_threaded(v):")
display(@benchmark fisher_breaks_threaded($v)) 