#!/usr/bin/env julia

# Make sure to run this script with multiple threads:
# julia -t auto threaded_benchmark_example.jl

println("To benchmark the threaded Fisher breaks function with BenchmarkTools, do the following:")
println("\n1. Start Julia with multiple threads: julia -t auto")
println("2. Load the necessary packages:")
println("   using Breakers")
println("   using BenchmarkTools")
println("   using Random")
println("   using Threads")
println("\n3. Create a test vector:")
println("   v = rand(1:100, 1000)")
println("\n4. Run the benchmark:")
println("   @benchmark fisher_breaks_threaded(v)")
println("\n5. You can also specify the number of breaks:")
println("   @benchmark fisher_breaks_threaded(v, 5)")

println("\nThis script will now demonstrate this:")
println("------------------------------------------")

# Load the packages
using Breakers
using BenchmarkTools
using Random
using Threads

# Show thread count
println("Running with $(Threads.nthreads()) threads")

# Create the test vector
v = rand(1:100, 1000)

# Run the benchmark
println("\nBenchmark for fisher_breaks_threaded(v) where v = rand(1:100, 1000):")
result = @benchmark fisher_breaks_threaded($v)
display(result)

# Optionally compare with non-threaded version
println("\nFor comparison, here's the non-threaded version:")
result_regular = @benchmark fisher_breaks($v)
display(result_regular) 