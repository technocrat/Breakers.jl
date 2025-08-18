#!/usr/bin/env julia
# SPDX-License-Identifier: MIT
#
# K-means Performance Analysis Script
# 
# This script investigates whether k-means slowness is due to compilation overhead
# or algorithmic performance differences between Julia and R implementations
#
# Usage:
#   julia --project=. benchmarks/analyze_kmeans_performance.jl

using Breakers
using Clustering
using Statistics
using Printf
using Random

"""
Generate test data for k-means analysis
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
Detailed k-means timing analysis
"""
function analyze_kmeans_timing()
    println("🔍 K-MEANS PERFORMANCE ANALYSIS")
    println("================================\n")
    
    # Test different sizes to see scaling behavior
    sizes = [100, 500, 1000, 2000, 5000, 10000]
    k = 7
    n_runs = 20  # More runs for better statistics
    
    results = []
    
    for size in sizes
        println("Analyzing size: $size")
        data = generate_test_data(size, "normal")
        
        # Warm up compilation (run once and discard)
        println("  Warming up compilation...")
        _ = kmeans_breaks(data, k)
        
        # Time individual components
        times_total = Float64[]
        times_kmeans_only = Float64[]
        times_sorting = Float64[]
        
        for run in 1:n_runs
            # Time the full kmeans_breaks function
            total_time = @elapsed begin
                result = kmeans_breaks(data, k)
            end
            push!(times_total, total_time * 1000)  # Convert to ms
            
            # Time just the core k-means clustering part
            data_matrix = reshape(Float64.(data), 1, :)
            kmeans_time = @elapsed begin
                kmeans_result = kmeans(data_matrix, k; maxiter=200)
            end
            push!(times_kmeans_only, kmeans_time * 1000)  # Convert to ms
            
            # Time the sorting operation
            centers = vec(kmeans_result.centers)
            sort_time = @elapsed begin
                sort!(centers)
            end
            push!(times_sorting, sort_time * 1000)  # Convert to ms
        end
        
        # Calculate statistics
        total_median = median(times_total)
        total_std = std(times_total)
        kmeans_median = median(times_kmeans_only)
        kmeans_std = std(times_kmeans_only)
        sort_median = median(times_sorting)
        
        push!(results, (
            size = size,
            total_median = total_median,
            total_std = total_std,
            kmeans_median = kmeans_median,
            kmeans_std = kmeans_std,
            sort_median = sort_median,
            overhead_median = total_median - kmeans_median - sort_median
        ))
        
        @printf("  Total time:   %6.2f ± %5.2f ms\n", total_median, total_std)
        @printf("  K-means core: %6.2f ± %5.2f ms\n", kmeans_median, kmeans_std)
        @printf("  Sorting:      %6.2f ms\n", sort_median)
        @printf("  Other overhead: %6.2f ms\n", total_median - kmeans_median - sort_median)
        println()
    end
    
    return results
end

"""
Compare Julia's Clustering.jl with manual k-means implementation
"""
function compare_kmeans_implementations()
    println("🔬 COMPARING K-MEANS IMPLEMENTATIONS")
    println("====================================\n")
    
    size = 1000
    k = 7
    data = generate_test_data(size, "normal")
    
    # Warm up both implementations
    _ = kmeans_breaks(data, k)
    _ = simple_kmeans(data, k)
    
    println("Testing with $size data points, $k clusters")
    println("Running 10 iterations each...\n")
    
    # Time Clustering.jl implementation
    clustering_times = Float64[]
    for i in 1:10
        time_ns = @elapsed begin
            data_matrix = reshape(Float64.(data), 1, :)
            result = kmeans(data_matrix, k; maxiter=200)
        end
        push!(clustering_times, time_ns * 1000)  # Convert to ms
    end
    
    # Time simple manual implementation
    simple_times = Float64[]
    for i in 1:10
        time_ns = @elapsed begin
            result = simple_kmeans(data, k)
        end
        push!(simple_times, time_ns * 1000)  # Convert to ms
    end
    
    clustering_median = median(clustering_times)
    simple_median = median(simple_times)
    
    @printf("Clustering.jl k-means: %6.2f ms (median)\n", clustering_median)
    @printf("Simple k-means:        %6.2f ms (median)\n", simple_median)
    @printf("Ratio: %.1fx %s\n", 
           max(clustering_median, simple_median) / min(clustering_median, simple_median),
           clustering_median > simple_median ? "slower" : "faster")
end

"""
Simple k-means implementation for comparison
"""
function simple_kmeans(data::Vector, k::Int)
    n = length(data)
    
    # Initialize centroids randomly
    centroids = rand(data, k)
    
    # Run k-means iterations
    for iter in 1:50  # Fewer iterations than Clustering.jl default
        # Assign points to closest centroid
        assignments = zeros(Int, n)
        for i in 1:n
            best_dist = Inf
            best_centroid = 1
            for j in 1:k
                dist = abs(data[i] - centroids[j])
                if dist < best_dist
                    best_dist = dist
                    best_centroid = j
                end
            end
            assignments[i] = best_centroid
        end
        
        # Update centroids
        new_centroids = copy(centroids)
        for j in 1:k
            cluster_points = data[assignments .== j]
            if !isempty(cluster_points)
                new_centroids[j] = mean(cluster_points)
            end
        end
        
        # Check for convergence
        if maximum(abs.(new_centroids .- centroids)) < 1e-6
            break
        end
        centroids = new_centroids
    end
    
    return sort(centroids)
end

"""
Profile memory allocations
"""
function profile_kmeans_allocations()
    println("💾 MEMORY ALLOCATION PROFILING")
    println("==============================\n")
    
    size = 1000
    k = 7
    data = generate_test_data(size, "normal")
    
    # Profile kmeans_breaks
    println("Profiling kmeans_breaks()...")
    @time result1 = kmeans_breaks(data, k)
    
    # Profile direct Clustering.jl usage
    println("Profiling direct Clustering.jl usage...")
    @time begin
        data_matrix = reshape(Float64.(data), 1, :)
        result2 = kmeans(data_matrix, k; maxiter=200)
        centers = sort(vec(result2.centers))
    end
    
    # Profile simple implementation
    println("Profiling simple k-means...")
    @time result3 = simple_kmeans(data, k)
    
    println()
    @printf("Results comparison:\n")
    @printf("kmeans_breaks:     [%.2f, %.2f, ..., %.2f]\n", result1[1], result1[2], result1[end])
    @printf("Clustering.jl:     [%.2f, %.2f, ..., %.2f]\n", centers[1], centers[2], centers[end])
    @printf("Simple k-means:    [%.2f, %.2f, ..., %.2f]\n", result3[1], result3[2], result3[end])
end

"""
Main analysis function
"""
function main()
    println("K-means Performance Deep Dive")
    println("=============================\n")
    
    # Check compilation effects
    results = analyze_kmeans_timing()
    
    # Compare different implementations
    compare_kmeans_implementations()
    
    # Profile allocations
    profile_kmeans_allocations()
    
    println("\n📊 SCALING ANALYSIS")
    println("===================")
    
    println("Size\tTotal(ms)\tK-means(ms)\tOverhead(ms)")
    for result in results
        @printf("%d\t%.2f\t\t%.2f\t\t%.2f\n", 
               result.size, result.total_median, result.kmeans_median, result.overhead_median)
    end
    
    println("\n🔍 ANALYSIS CONCLUSIONS")
    println("=======================")
    println("• If k-means core time scales linearly, it's algorithmic")
    println("• If total time has high overhead, it's implementation/compilation")
    println("• Memory allocation patterns show efficiency differences")
    println("\n✅ Analysis completed!")
end

# Run the analysis
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
