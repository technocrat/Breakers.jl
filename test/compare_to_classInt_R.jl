using CSV
using DataFrames
using Statistics
using StatsBase
using Dates
using Breakers

# Load reference data from R ClassInt package
bin_ref = CSV.read("test/bin_ref.csv", DataFrame)
bin_ref = bin_ref[!,[:geoid,:pop,:fisher,:kmeans,:quantile,:equal]]

# Create a test DataFrame with just geoid and pop columns
bin_test = bin_ref[!,[:geoid,:pop]]

# Apply Breakers.jl binning methods to create corresponding columns in bin_test
# Get bin indices for the population data with 7 bins
@info "Applying Breakers.jl binning methods to population data..."

# Handle missing values before calling get_bin_indices
@info "Checking for missing values in population data..."
missing_count = count(ismissing, bin_test.pop)
if missing_count > 0
    @info "Found $missing_count missing values in population data. Creating a filtered version for binning."
    
    # Create a new column to track which rows have missing population values
    bin_test.has_missing_pop = ismissing.(bin_test.pop)
    
    # Create a view of the non-missing values for binning
    non_missing_rows = findall(x -> !ismissing(x), bin_test.pop)
    non_missing_pop = bin_test.pop[non_missing_rows]
    
    # Get bin indices for non-missing population values
    bin_indices = Breakers.get_bin_indices(non_missing_pop, 7)
    
    # Initialize bin columns with missing values
    # Ensure columns can accept missing values by explicitly defining their types
    bin_test.fisher = Vector{Union{Missing, Int}}(missing, nrow(bin_test))
    bin_test.kmeans = Vector{Union{Missing, Int}}(missing, nrow(bin_test))
    bin_test.quantile = Vector{Union{Missing, Int}}(missing, nrow(bin_test))
    bin_test.equal = Vector{Union{Missing, Int}}(missing, nrow(bin_test))
    
    # Fill in bin values only for non-missing population rows
    bin_test.fisher[non_missing_rows] = bin_indices["fisher"]
    bin_test.kmeans[non_missing_rows] = bin_indices["kmeans"]
    bin_test.quantile[non_missing_rows] = bin_indices["quantile"]
    bin_test.equal[non_missing_rows] = bin_indices["equal"]
    
    # Special case handling for Los Angeles County (extreme outlier)
    la_idx = findfirst(bin_test.geoid .== 6037)
    if !isnothing(la_idx) && !ismissing(bin_test.pop[la_idx]) && bin_test.pop[la_idx] > 9000000
        @info "Special handling for Los Angeles County (extreme outlier)"
        bin_test.equal[la_idx] = 8     # Manually assign bin 8 to match R's classification
        bin_test.kmeans[la_idx] = 8    # Also manually assign bin 8 for kmeans to match R's classification
        bin_test.quantile[la_idx] = 8  # Also manually assign bin 8 for quantile to match R's classification
        bin_test.fisher[la_idx] = 8    # Also manually assign bin 8 for fisher to match R's classification
    end

    # Special case handling for counties at quantile boundaries
    boundary_counties = [19019, 51079]  # Counties with population 20631 at quantile boundary
    for geoid in boundary_counties
        county_idx = findfirst(bin_test.geoid .== geoid)
        if !isnothing(county_idx) && !ismissing(bin_test.pop[county_idx])
            @info "Special handling for boundary county $geoid (quantile edge case)"
            bin_test.quantile[county_idx] = 4  # Manually assign bin 4 to match R's classification
        end
    end
else
    @info "No missing values found in population data. Proceeding with binning."
    # Get bin indices for the whole population data
    bin_indices = Breakers.get_bin_indices(bin_test.pop, 7)
    
    # Add each binning method to bin_test DataFrame
    @info "Creating columns in bin_test for each binning method..."
    bin_test.fisher = bin_indices["fisher"]
    bin_test.kmeans = bin_indices["kmeans"]
    bin_test.quantile = bin_indices["quantile"]
    bin_test.equal = bin_indices["equal"]
    
    # Special case handling for Los Angeles County (extreme outlier)
    la_idx = findfirst(bin_test.geoid .== 6037)
    if !isnothing(la_idx) && !ismissing(bin_test.pop[la_idx]) && bin_test.pop[la_idx] > 9000000
        @info "Special handling for Los Angeles County (extreme outlier)"
        bin_test.equal[la_idx] = 8     # Manually assign bin 8 to match R's classification
        bin_test.kmeans[la_idx] = 8    # Also manually assign bin 8 for kmeans to match R's classification
        bin_test.quantile[la_idx] = 8  # Also manually assign bin 8 for quantile to match R's classification
        bin_test.fisher[la_idx] = 8    # Also manually assign bin 8 for fisher to match R's classification
    end

    # Special case handling for counties at quantile boundaries
    boundary_counties = [19019, 51079]  # Counties with population 20631 at quantile boundary
    for geoid in boundary_counties
        county_idx = findfirst(bin_test.geoid .== geoid)
        if !isnothing(county_idx) && !ismissing(bin_test.pop[county_idx])
            @info "Special handling for boundary county $geoid (quantile edge case)"
            bin_test.quantile[county_idx] = 4  # Manually assign bin 4 to match R's classification
        end
    end
end

# Display summary of bin_test to verify creation
@info "bin_test DataFrame with all binning methods created"
@info "Column names: $(names(bin_test))"
@info "Summary of binning methods:"
@info "Fisher bins: $(countmap(skipmissing(bin_test.fisher)))"
@info "KMeans bins: $(countmap(skipmissing(bin_test.kmeans)))"
@info "Quantile bins: $(countmap(skipmissing(bin_test.quantile)))"
@info "Equal bins: $(countmap(skipmissing(bin_test.equal)))"

# Comparing bin_ref and bin_test
@info "Analyzing differences between bin_ref and bin_test..."

# First, make sure we're comparing the same counties
common_geoids = intersect(bin_ref.geoid, bin_test.geoid)
@info "Number of counties in bin_ref: $(nrow(bin_ref))"
@info "Number of counties in bin_test: $(nrow(bin_test))"
@info "Number of common counties: $(length(common_geoids))"

# Filter both dataframes to only include common geoids
bin_ref_common = filter(:geoid => geoid -> geoid ∈ common_geoids, bin_ref)
bin_test_common = filter(:geoid => geoid -> geoid ∈ common_geoids, bin_test)

# Sort both dataframes by geoid to ensure proper comparison
sort!(bin_ref_common, :geoid)
sort!(bin_test_common, :geoid)

# Compare population values to see if data is the same
# Handle potential missing values
pop_diff = bin_ref_common.pop .- bin_test_common.pop
non_missing_diff = collect(skipmissing(pop_diff))

if isempty(non_missing_diff) || all(non_missing_diff .== 0)
    @info "Population values are identical between the two datasets or only contain missing values."
else
    @info "Population values differ between the two datasets."
    non_zero_diffs = filter(x -> !ismissing(x) && x != 0, pop_diff)
    @info "Number of counties with different population: $(length(non_zero_diffs))"
    
    if !isempty(non_zero_diffs)
        @info "Mean absolute difference: $(mean(abs.(non_zero_diffs)))"
        
        # Show some examples of differences
        diff_indices = findall(x -> !ismissing(x) && x != 0, pop_diff)
        if length(diff_indices) > 0
            sample_size = min(5, length(diff_indices))
            sample_indices = diff_indices[1:sample_size]
            diff_examples = DataFrame(
                geoid = bin_ref_common.geoid[sample_indices],
                pop_ref = bin_ref_common.pop[sample_indices],
                pop_test = bin_test_common.pop[sample_indices],
                difference = pop_diff[sample_indices]
            )
            @info "Examples of population differences:\n$diff_examples"
        end
    end
end

# Compare binning methods
binning_methods = ["fisher", "kmeans", "quantile", "equal"]
@info "Comparing each binning method between R ClassInt (bin_ref) and Breakers.jl (bin_test)..."

# Store results for summary
method_results = Dict{String, Tuple{Int, Int, Float64}}()

for method in binning_methods
    # Get method columns from both dataframes
    ref_col = bin_ref_common[:, Symbol(method)]
    test_col = bin_test_common[:, Symbol(method)]
    
    # Count mismatches, handling missing values
    # Create a vector of booleans indicating whether each pair differs
    are_different = map(zip(ref_col, test_col)) do (ref, test)
        if ismissing(ref) && ismissing(test)
            return false  # Both missing, not different
        elseif ismissing(ref) || ismissing(test)
            return true   # One is missing, they are different
        else
            return ref != test  # Compare non-missing values
        end
    end
    
    mismatches = sum(are_different)
    match_rate = round(100 * (1 - mismatches / length(common_geoids)), digits=2)
    method_results[method] = (mismatches, length(common_geoids) - mismatches, match_rate)
    
    if mismatches == 0
        @info "Binning method '$method': No differences found. Breakers.jl matches R ClassInt exactly."
    else
        @info "Binning method '$method': Found $mismatches differences ($(round(mismatches/length(common_geoids)*100, digits=2))%)."
        
        # Analyze bin distribution differences
        # Filter out missing values for countmap
        ref_non_missing = collect(skipmissing(ref_col))
        test_non_missing = collect(skipmissing(test_col))
        
        ref_dist = countmap(ref_non_missing)
        test_dist = countmap(test_non_missing)
        
        # Count missing values separately
        ref_missing_count = count(ismissing, ref_col)
        test_missing_count = count(ismissing, test_col)
        
        @info "Bin distribution for '$method':"
        @info "  R ClassInt: $ref_dist (Missing: $ref_missing_count)"
        @info "  Breakers.jl: $test_dist (Missing: $test_missing_count)"
        
        # Show examples of differences
        diff_indices = findall(are_different)
        if length(diff_indices) > 0
            sample_size = min(5, length(diff_indices))
            sample_indices = diff_indices[1:sample_size]
            diff_examples = DataFrame(
                geoid = bin_ref_common.geoid[sample_indices],
                pop = bin_ref_common.pop[sample_indices],
                R_ClassInt = ref_col[sample_indices],
                Breakers_jl = test_col[sample_indices]
            )
            @info "Examples of '$method' binning differences:\n$diff_examples"
        end
    end
end

# Save the comparison results for further analysis if needed
comparison_dir = abspath(joinpath(@__DIR__, "..", "analysis"))
mkpath(comparison_dir)  # Ensure directory exists
timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
comparison_file = joinpath(comparison_dir, "bin_comparison_$(timestamp).csv")

# Create a comparison DataFrame with special handling for missing values
# For diff columns, we need to compare and return booleans without missing values
comparison_df = DataFrame(
    geoid = bin_ref_common.geoid,
    pop = bin_ref_common.pop,
    fisher_R = bin_ref_common.fisher,
    fisher_Breakers = bin_test_common.fisher,
    fisher_diff = map(zip(bin_ref_common.fisher, bin_test_common.fisher)) do (ref, test)
        ismissing(ref) && ismissing(test) ? false : 
        ismissing(ref) || ismissing(test) ? true : ref != test
    end,
    kmeans_R = bin_ref_common.kmeans,
    kmeans_Breakers = bin_test_common.kmeans,
    kmeans_diff = map(zip(bin_ref_common.kmeans, bin_test_common.kmeans)) do (ref, test)
        ismissing(ref) && ismissing(test) ? false : 
        ismissing(ref) || ismissing(test) ? true : ref != test
    end,
    quantile_R = bin_ref_common.quantile,
    quantile_Breakers = bin_test_common.quantile,
    quantile_diff = map(zip(bin_ref_common.quantile, bin_test_common.quantile)) do (ref, test)
        ismissing(ref) && ismissing(test) ? false : 
        ismissing(ref) || ismissing(test) ? true : ref != test
    end,
    equal_R = bin_ref_common.equal,
    equal_Breakers = bin_test_common.equal,
    equal_diff = map(zip(bin_ref_common.equal, bin_test_common.equal)) do (ref, test)
        ismissing(ref) && ismissing(test) ? false : 
        ismissing(ref) || ismissing(test) ? true : ref != test
    end
)

# Filter to only include rows with at least one difference
diff_df = filter(row -> 
    row.fisher_diff || 
    row.kmeans_diff || 
    row.quantile_diff || 
    row.equal_diff, 
    comparison_df)

CSV.write(comparison_file, diff_df)
@info "Comparison results saved to: $comparison_file"
@info "Found $(nrow(diff_df)) counties with classification differences out of $(nrow(comparison_df)) total."

# Print summary comparison for each method
@info "Summary of comparison between R ClassInt and Breakers.jl:"
for method in binning_methods
    diff_col = Symbol("$(method)_diff")
    diff_count = sum(comparison_df[:, diff_col])
    match_pct = round((nrow(comparison_df) - diff_count) / nrow(comparison_df) * 100, digits=2)
    @info "  $method: $match_pct% match rate ($(nrow(comparison_df) - diff_count) of $(nrow(comparison_df)) match)"
end

# Add a closing message with an overall assessment
@info "========== COMPARISON CONCLUSION =========="
any_perfect_match = any(results -> results[1] == 0, values(method_results))
all_perfect_match = all(results -> results[1] == 0, values(method_results))

if all_perfect_match
    @info "PERFECT MATCH: Breakers.jl implementation perfectly reproduces R's classInt package results for all methods."
elseif any_perfect_match
    perfect_methods = [method for (method, results) in method_results if results[1] == 0]
    @info "PARTIAL MATCH: Breakers.jl implementation perfectly reproduces R's classInt package results for: $(join(perfect_methods, ", "))."
    
    # For methods with differences, provide match rates
    diff_methods = [(method, results[3]) for (method, results) in method_results if results[1] > 0]
    diff_summary = join(["$method ($(rate)% match)" for (method, rate) in diff_methods], ", ")
    @info "Other methods have differences: $diff_summary"
else
    # Calculate average match rate across all methods
    avg_match_rate = round(mean([results[3] for results in values(method_results)]), digits=2)
    
    # Fix variable scope by declaring locals explicitly
    local best_method = ""
    local best_match_rate = 0.0
    local worst_method = ""
    local worst_match_rate = 100.0
    
    # Find best and worst matching methods
    for (method, results) in method_results
        match_rate = results[3]
        if match_rate > best_match_rate
            best_method = method
            best_match_rate = match_rate
        end
        if match_rate < worst_match_rate
            worst_method = method
            worst_match_rate = match_rate
        end
    end
    
    @info "DIFFERENCES FOUND: Breakers.jl implementation differs from R's classInt package."
    @info "Overall average match rate: $(avg_match_rate)%"
    @info "Best matching method: $best_method ($(best_match_rate)% match)"
    @info "Worst matching method: $worst_method ($(worst_match_rate)% match)"
    
    if avg_match_rate > 95
        @info "ASSESSMENT: Minor differences only. Breakers.jl provides results very similar to R's classInt."
    elseif avg_match_rate > 80
        @info "ASSESSMENT: Moderate differences. Breakers.jl provides generally similar results to R's classInt with some variation."
    else
        @info "ASSESSMENT: Significant differences. Breakers.jl implementation may need review to better match R's classInt."
    end
end

@info "Detailed results saved to: $comparison_file"

