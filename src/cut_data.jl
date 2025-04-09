"""
    cut_data(x::Vector{<:Union{Missing, Real}}, breaks::AbstractVector{<:Real})

Bin data values into categories defined by breaks.

# Arguments
- `x`: Vector of values (can include missing values)
- `breaks`: Vector of break points (sorted)

# Returns
- `Vector{String}`: Categories for each value
"""
function cut_data(x::Vector{T}, breaks::AbstractVector{<:Real}) where T <: Union{Missing, Real}
    # Convert breaks to a simple Float64 vector to ensure consistent processing
    # Always collect to handle SubArrays
    breaks_float = collect(Float64.(collect(breaks)))
    n = length(breaks_float)
    result = similar(x, String)
    
    if n < 2
        error("At least 2 break points are required")
    end
    
    for i in eachindex(x)
        value = x[i]
        if ismissing(value)
            result[i] = "Missing"
            continue
        end
        
        found = false
        
        # Special case for the minimum value
        if value <= breaks_float[1]
            result[i] = "≤ $(breaks_float[1])"
            found = true
        else
            for j in 1:(n-1)
                # Match values within an interval using strict inequality for upper bound
                # to match R's classInt behavior (values at break points go to higher interval)
                if value > breaks_float[j] && value < breaks_float[j+1]
                    result[i] = "$(breaks_float[j]) - $(breaks_float[j+1])"
                    found = true
                    break
                end
                
                # Special case for values exactly on break points (except minimum)
                # Assign to the higher interval
                if value == breaks_float[j+1] && j < n-1
                    result[i] = "$(breaks_float[j+1]) - $(breaks_float[j+2])"
                    found = true
                    break
                end
            end
            
            # Special case for maximum value and values beyond
            if !found && value >= breaks_float[n-1]
                result[i] = "> $(breaks_float[n-1])"
                found = true
            end
        end
        
        if !found
            result[i] = "Other"
        end
    end
    
    return result
end

"""
    cut_data(x::SubArray{T, 1}, breaks::AbstractVector{<:Real}) where T<:Union{Missing, Real}

Handle SubArray inputs by collecting them first, then forwarding to the Vector version.

# Arguments
- `x`: SubArray of values (can include missing values)
- `breaks`: Vector of break points (sorted)

# Returns
- `Vector{String}`: Categories for each value
"""
function cut_data(x::SubArray{T, 1}, breaks::AbstractVector{<:Real}) where T<:Union{Missing, Real}
    # Convert SubArray to Vector and call the Vector method
    return cut_data(collect(x), breaks)
end