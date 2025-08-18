#!/usr/bin/env Rscript
# SPDX-License-Identifier: MIT
#
# R benchmarking script for classInt package
# 
# This script benchmarks R's classInt package using the same test data
# that Breakers.jl uses for comparison purposes.
#
# Usage:
#   Rscript benchmarks/benchmark_classint.R
#
# Requirements:
#   install.packages(c("classInt", "microbenchmark"))

# Check and install required packages
required_packages <- c("classInt", "microbenchmark")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if(length(missing_packages) > 0) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages, repos = "https://cran.r-project.org/")
}

# Load required libraries
suppressPackageStartupMessages({
  library(classInt)
  library(microbenchmark)
})

#' Generate test data matching Breakers.jl test patterns
#' @param size Number of observations
#' @param distribution Type of distribution ("normal", "uniform", "skewed")
#' @param seed Random seed for reproducibility
#' @return Numeric vector of test data
generate_test_data <- function(size, distribution, seed = 42) {
  set.seed(seed)
  
  switch(distribution,
    "normal" = rnorm(size, mean = 500, sd = 100),
    "uniform" = runif(size, min = 0, max = 1000), 
    "skewed" = exp(rnorm(size, mean = 0, sd = 1)) * 100,
    stop("Unknown distribution: ", distribution)
  )
}

#' Benchmark a single method
#' @param data Numeric vector to bin
#' @param method Method name for classInt
#' @param n_classes Number of classes
#' @param times Number of benchmark repetitions
#' @return List with timing results and breaks
benchmark_method <- function(data, method, n_classes, times = 10) {
  # Run microbenchmark
  timing <- microbenchmark(
    result = classIntervals(data, n = n_classes, style = method),
    times = times
  )
  
  # Get actual result for validation
  result <- classIntervals(data, n = n_classes, style = method)
  breaks <- result$brks
  
  list(
    method = method,
    median_time_ms = median(timing$time) / 1e6,  # Convert to milliseconds
    mean_time_ms = mean(timing$time) / 1e6,
    std_time_ms = sd(timing$time) / 1e6,
    breaks = breaks,
    n_breaks = length(breaks)
  )
}

#' Main benchmarking function
run_classint_benchmark <- function() {
  cat("🔬 R classInt Benchmark\n")
  cat("=======================\n\n")
  
  # Test configurations
  sizes <- c(1000, 10000, 100000)
  methods <- c("fisher", "kmeans", "quantile", "equal")
  distributions <- c("normal", "uniform", "skewed")
  n_classes <- 7
  
  # Initialize results data frame
  results <- data.frame(
    Size = integer(),
    Distribution = character(),
    Method = character(),
    MedianTime_ms = numeric(),
    MeanTime_ms = numeric(),
    StdTime_ms = numeric(),
    NBreaks = integer(),
    stringsAsFactors = FALSE
  )
  
  for (size in sizes) {
    for (dist in distributions) {
      cat("Testing size =", size, ", distribution =", dist, "\n")
      
      # Generate test data
      data <- generate_test_data(size, dist)
      
      for (method in methods) {
        tryCatch({
          # Benchmark this method
          bench_result <- benchmark_method(data, method, n_classes)
          
          # Add to results
          results <- rbind(results, data.frame(
            Size = size,
            Distribution = dist,
            Method = method,
            MedianTime_ms = bench_result$median_time_ms,
            MeanTime_ms = bench_result$mean_time_ms,
            StdTime_ms = bench_result$std_time_ms,
            NBreaks = bench_result$n_breaks,
            stringsAsFactors = FALSE
          ))
          
          cat(sprintf("  %-10s: %8.2f ms (median)\n", method, bench_result$median_time_ms))
          
        }, error = function(e) {
          cat("  Error with", method, ":", conditionMessage(e), "\n")
        })
      }
      cat("\n")
    }
  }
  
  # Save results
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  filename <- paste0("benchmarks/r_classint_benchmark_", timestamp, ".csv")
  
  # Create benchmarks directory if it doesn't exist
  if (!dir.exists("benchmarks")) {
    dir.create("benchmarks")
  }
  
  write.csv(results, filename, row.names = FALSE)
  cat("📊 Results saved to:", filename, "\n\n")
  
  # Print summary
  print_benchmark_summary(results)
  
  return(results)
}

#' Print benchmark summary
#' @param results Data frame with benchmark results
print_benchmark_summary <- function(results) {
  cat("📈 BENCHMARK SUMMARY\n")
  cat("===================\n\n")
  
  # Performance by size
  cat("Performance by dataset size (median time):\n")
  for (size in sort(unique(results$Size))) {
    size_results <- results[results$Size == size, ]
    avg_time <- mean(size_results$MedianTime_ms)
    cat(sprintf("  Size %-8d: %.2f ms (average across all methods)\n", size, avg_time))
  }
  cat("\n")
  
  # Performance by method
  cat("Performance by method (median time across all sizes):\n")
  for (method in unique(results$Method)) {
    method_results <- results[results$Method == method, ]
    avg_time <- mean(method_results$MedianTime_ms)
    cat(sprintf("  %-10s: %.2f ms (average)\n", method, avg_time))
  }
  cat("\n")
  
  # Fastest method for each size
  cat("Fastest method by dataset size:\n")
  for (size in sort(unique(results$Size))) {
    size_results <- results[results$Size == size, ]
    
    for (dist in unique(size_results$Distribution)) {
      dist_results <- size_results[size_results$Distribution == dist, ]
      if (nrow(dist_results) > 0) {
        fastest <- dist_results[which.min(dist_results$MedianTime_ms), ]
        cat(sprintf("  Size %-8d, %-10s: %s (%.2f ms)\n", 
                   size, paste0(dist, ":"), fastest$Method, fastest$MedianTime_ms))
      }
    }
  }
  cat("\n")
  
  # R Session info
  cat("R Session Info:\n")
  cat("  R version:", paste(R.Version()[c("major", "minor")], collapse = "."), "\n")
  cat("  classInt version:", as.character(packageVersion("classInt")), "\n")
  cat("  Platform:", R.Version()$platform, "\n")
}

#' Generate sample break points for comparison with Julia
#' This creates data that can be used to validate that Julia results match R
generate_comparison_data <- function() {
  cat("🔍 GENERATING COMPARISON DATA FOR JULIA\n")
  cat("========================================\n\n")
  
  # Generate standard test datasets
  datasets <- list(
    small_normal = generate_test_data(1000, "normal"),
    medium_uniform = generate_test_data(10000, "uniform"), 
    large_skewed = generate_test_data(50000, "skewed")
  )
  
  comparison_results <- list()
  
  for (dataset_name in names(datasets)) {
    cat("Dataset:", dataset_name, "\n")
    data <- datasets[[dataset_name]]
    
    dataset_results <- list()
    for (method in c("fisher", "kmeans", "quantile", "equal")) {
      tryCatch({
        result <- classIntervals(data, n = 7, style = method)
        breaks <- result$brks
        dataset_results[[method]] <- breaks
        cat(sprintf("  %-10s: [%.2f, %.2f, ..., %.2f, %.2f] (%d breaks)\n", 
                   method, breaks[1], breaks[2], breaks[length(breaks)-1], 
                   breaks[length(breaks)], length(breaks)))
      }, error = function(e) {
        cat("  ", method, ": ERROR -", conditionMessage(e), "\n")
      })
    }
    comparison_results[[dataset_name]] <- dataset_results
    cat("\n")
  }
  
  # Save comparison data
  saveRDS(comparison_results, "benchmarks/r_comparison_data.rds")
  cat("💾 Comparison data saved to: benchmarks/r_comparison_data.rds\n")
  cat("   (This can be loaded in Julia for exact result validation)\n\n")
  
  return(comparison_results)
}

# Main execution
main <- function() {
  cat("R classInt Benchmarking Script\n")
  cat("==============================\n\n")
  
  # Check R version
  if (getRversion() < "3.6.0") {
    warning("This script is tested with R 3.6.0+. Your version: ", getRversion())
  }
  
  # Run benchmark
  results <- run_classint_benchmark()
  
  # Generate comparison data
  comparison_data <- generate_comparison_data()
  
  cat("✅ Benchmarking completed successfully!\n")
  cat("📁 Check the 'benchmarks/' directory for output files.\n")
  
  return(list(
    benchmark_results = results,
    comparison_data = comparison_data
  ))
}

# Run the script
if (!interactive()) {
  main()
}
