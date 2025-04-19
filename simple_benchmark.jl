#!/usr/bin/env julia

# This script demonstrates how to use BenchmarkTools with the threaded Fisher breaks
# Run with: julia --project=. -t auto simple_benchmark.jl

using Breakers
using BenchmarkTools
using Random
using Threads

# Print thread information
println("Testing with $(Threads.nthreads()) threads")

# Create the test vector
v = rand(1:100, 1000)

# To use @benchmark for a simple case
println("\nBenchmarking fisher_breaks_threaded with vector of 1000 random integers (1-100):")
@benchmark fisher_breaks_threaded($v)

# If you need to specify parameters
println("\nBenchmarking fisher_breaks_threaded with k=5:")
@benchmark fisher_breaks_threaded($v, 5)

# If you want to compare with the regular version
println("\nComparing regular vs threaded versions:")
println("Regular version:")
regular_result = @benchmark fisher_breaks($v)
display(regular_result)

println("\nThreaded version:")
threaded_result = @benchmark fisher_breaks_threaded($v)
display(threaded_result)

# For larger datasets
println("\nTesting with larger dataset (10,000 elements):")
v_large = rand(1:100, 10000)

println("Regular version:")
regular_large = @benchmark fisher_breaks($v_large)
display(regular_large)

println("\nThreaded version:")
threaded_large = @benchmark fisher_breaks_threaded($v_large)
display(threaded_large) 