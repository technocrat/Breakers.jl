"""
    fisher_clustering(x, k)

Clusters a sequence of values into subsequences using Fisher's method of exact optimization, which maximizes the between-cluster sum of squares.

# Arguments
- `x::Vector{<:Real}`: Vector of observations to be clustered.
- `k::Integer`: Number of clusters requested.

# Returns
A tuple containing:
- `cluster_info`: Array of cluster information (min, max, mean, std) with dimensions (k, 4)
- `work`: Matrix of within-cluster sums of squares
- `iwork`: Matrix of optimal splitting points
"""
function fisher_clustering(x::Vector{<:Real}, k::Integer)
    m = length(x)
    
    # Initialize work matrices
    work = fill(floatmax(Float64), m, k)
    iwork = fill(1, m, k)
    
    # Compute work and iwork iteratively
    for i in 1:m
        ss = 0.0
        s = 0.0
        local variance_val = 0.0  # Declare this outside inner loop but within outer loop
        
        for ii in 1:i
            iii = i - ii + 1
            ss += x[iii]^2
            s += x[iii]
            sn = ii
            variance_val = ss - s^2/sn  # Update it here
            
            ik = iii - 1
            if ik != 0
                for j in 2:k
                    if work[i, j] >= variance_val + work[ik, j-1]
                        iwork[i, j] = iii
                        work[i, j] = variance_val + work[ik, j-1]
                    end
                end
            end
        end
        
        # This uses the final value of variance_val from the inner loop
        work[i, 1] = variance_val
        iwork[i, 1] = 1
    end
    
    # Extract results
    cluster_info = zeros(Float64, k, 4)  # Each row: [min, max, mean, std]
    
    j = 1
    jj = k - j + 1
    il = m + 1
    
    for l in 1:jj
        ll = jj - l + 1
        a_min = floatmax(Float64)
        a_max = -floatmax(Float64)
        s = 0.0
        ss = 0.0
        
        iu = il - 1
        il = iwork[iu, ll]
        
        for ii in il:iu
            a_min = min(a_min, x[ii])
            a_max = max(a_max, x[ii])
            s += x[ii]
            ss += x[ii]^2
        end
        
        sn = iu - il + 1
        mean_val = s / sn
        var_val = ss/sn - mean_val^2
        std_val = sqrt(abs(var_val))
        
        cluster_info[l, 1] = a_min
        cluster_info[l, 2] = a_max
        cluster_info[l, 3] = mean_val
        cluster_info[l, 4] = std_val
    end
    
    return cluster_info, work, iwork
end
