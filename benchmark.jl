#!/usr/bin/env julia
# SPDX-License-Identifier: MIT
#
# Script to run Breakers.jl benchmarks comparing to R's ClassInt package
#
# Usage:
#   julia benchmark.jl [options]
#
# Options:
#   --sizes=size1,size2,...       Dataset sizes to benchmark (default: 10000,100000,1000000)
#   --methods=method1,method2,... Binning methods to benchmark (default: fisher,kmeans,quantile,equal)
#   --distributions=dist1,dist2,..Data distributions to benchmark (default: normal,uniform,skewed)
#   --bins=n                      Number of bins to use (default: 7)
#   --help, -h                    Show this help message

# Add parent directory to load path
using Pkg
if !isfile(joinpath(@__DIR__, "Project.toml"))
    Pkg.activate(".")
else
    Pkg.activate(@__DIR__)
end

# Check required packages
required_pkgs = ["Breakers", "BenchmarkTools", "RCall", "CSV", "DataFrames", "Statistics", "Random", "Printf"]
for pkg in required_pkgs
    if !haskey(Pkg.project().dependencies, pkg)
        @info "Installing required package: $pkg"
        Pkg.add(pkg)
    end
end

# Load test script
include(joinpath(@__DIR__, "test", "benchmark_classint.jl"))

# Parse command line arguments and run benchmarks
function run()
    if "--help" in ARGS || "-h" in ARGS
        println("Usage: julia benchmark.jl [options]")
        println("Options:")
        println("  --sizes=size1,size2,...       Dataset sizes to benchmark (default: 10000,100000,1000000)")
        println("  --methods=method1,method2,... Binning methods to benchmark (default: fisher,kmeans,quantile,equal)")
        println("  --distributions=dist1,dist2,..Data distributions to benchmark (default: normal,uniform,skewed)")
        println("  --bins=n                      Number of bins to use (default: 7)")
        println("  --help, -h                    Show this help message")
        exit(0)
    end

    # Run the benchmarks
    results = main()

    # Return results for potential further processing
    return results
end

# Run the script
run() 