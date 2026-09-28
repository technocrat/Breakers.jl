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

# Details
`work[i, j]` is the smallest total within-cluster sum of squares for splitting
`x[1:i]` into `j` clusters, and `iwork[i, j]` is where the last of those
clusters starts. The optimal start moves monotonically with `i`, so each
column is filled by divide and conquer in O(m log m) time, giving
O(k × m × log m) overall instead of O(k × m²).
"""
function fisher_clustering(x::Vector{<:Real}, k::Integer)
    m = length(x)

    # Initialize work matrices
    work = fill(floatmax(Float64), m, k)
    iwork = fill(1, m, k)

    # Prefix sums of the centred values give any cluster's sum of squares in
    # constant time; centring limits floating-point cancellation
    mu = sum(x) / m
    s1 = zeros(Float64, m + 1)
    s2 = zeros(Float64, m + 1)
    for i in 1:m
        d = x[i] - mu
        s1[i+1] = s1[i] + d
        s2[i+1] = s2[i] + d^2
    end

    for i in 1:m
        work[i, 1] = _cluster_ss(s1, s2, 1, i)
    end
    for j in 2:k
        _fisher_column!(work, iwork, s1, s2, j, j, m, j, m)
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

# Within-cluster sum of squares of x[a:b], from prefix sums of centred values
@inline function _cluster_ss(s1, s2, a, b)
    n = b - a + 1
    t = s1[b+1] - s1[a]
    return s2[b+1] - s2[a] - t^2 / n
end

# Fill work[lo:hi, j] and iwork[lo:hi, j], given that the optimal start of the
# last cluster lies in optlo:opthi. Ties go to the earliest start
function _fisher_column!(work, iwork, s1, s2, j, lo, hi, optlo, opthi)
    lo > hi && return
    mid = (lo + hi) >>> 1
    best = floatmax(Float64)
    best_start = optlo
    for st in optlo:min(mid, opthi)
        v = work[st-1, j-1] + _cluster_ss(s1, s2, st, mid)
        if v < best
            best = v
            best_start = st
        end
    end
    work[mid, j] = best
    iwork[mid, j] = best_start
    _fisher_column!(work, iwork, s1, s2, j, lo, mid - 1, optlo, best_start)
    _fisher_column!(work, iwork, s1, s2, j, mid + 1, hi, best_start, opthi)
end
