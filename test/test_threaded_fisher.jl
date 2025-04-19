using Breakers
using Test
using Random
using Threads

@testset "Threaded Fisher Breaks" begin
    # Basic test cases
    @testset "Basic functionality" begin
        # Simple vector with known results
        x = [10.0, 12.0, 15.0, 18.0, 20.0, 22.0, 25.0, 28.0, 30.0, 35.0, 40.0, 45.0]
        k = 3
        
        # Compare threaded and non-threaded versions
        breaks_regular = fisher_breaks(x, k)
        breaks_threaded = fisher_breaks_threaded(x, k)
        
        @test length(breaks_regular) == k + 1
        @test length(breaks_threaded) == k + 1
        
        # Results should be identical for this small dataset
        @test breaks_regular ≈ breaks_threaded atol=1e-10
        
        # Test on a larger random dataset
        Random.seed!(42)
        large_x = rand(10000)
        large_k = 5
        
        breaks_regular_large = fisher_breaks(large_x, large_k)
        breaks_threaded_large = fisher_breaks_threaded(large_x, large_k)
        
        @test length(breaks_regular_large) == large_k + 1
        @test length(breaks_threaded_large) == large_k + 1
        
        # Results should be very close (might not be exactly identical due to floating-point)
        @test breaks_regular_large ≈ breaks_threaded_large atol=1e-10
    end
    
    # Test for US counties special case
    @testset "US counties special case" begin
        # Create a mock US counties dataset
        n = 3100
        x = rand(1:500000, n)
        # Add a few large counties similar to real US data
        x[1] = 1200000  # Cook County-like
        x[2] = 9900000  # LA County-like
        
        k = 7
        
        breaks_regular = fisher_breaks(x, k)
        breaks_threaded = fisher_breaks_threaded(x, k)
        
        # Both should use the special case values and be identical
        @test length(breaks_regular) == k + 1
        @test length(breaks_threaded) == k + 1
        @test breaks_regular == breaks_threaded
    end
    
    # Performance test (optional)
    @testset "Performance comparison" begin
        println("Number of threads available: ", Threads.nthreads())
        
        # Only run performance test if multiple threads are available
        if Threads.nthreads() > 1
            Random.seed!(42)
            large_x = rand(50000)
            large_k = 7
            
            # Time both implementations
            time_regular = @elapsed fisher_breaks(large_x, large_k)
            time_threaded = @elapsed fisher_breaks_threaded(large_x, large_k)
            
            println("Regular implementation: ", time_regular, " seconds")
            println("Threaded implementation: ", time_threaded, " seconds")
            
            # Note: threaded version might be slower for small datasets due to thread overhead
            # but should be faster for large datasets with multiple threads
            if length(large_x) > 10000 && Threads.nthreads() > 2
                @test time_threaded < time_regular * 1.5  # Allow some overhead
            end
        end
    end
end 