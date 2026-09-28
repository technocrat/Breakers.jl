#!/usr/bin/env julia
# SPDX-License-Identifier: MIT

# Compare Breakers.jl breaks with R classInt results stored in bin_ref.csv
using Test
using Breakers
using CSV

@testset "R classInt reference (bin_ref.csv)" begin
    ref = CSV.read(joinpath(@__DIR__, "bin_ref.csv"), NamedTuple;
                   select=[:pop, :fisher, :quantile, :equal])
    keep = .!ismissing.(ref.pop)
    x = Float64.(ref.pop[keep])

    # The reference was produced with 7 classes and R's findInterval, which
    # places a value on a break in the higher bin (the maximum gets bin n+1)
    raw = Breakers.get_breaks_raw(x, 7)
    findinterval(v, brks) = searchsortedlast(brks, v)

    # The fisher reference was computed on the full data (largeN = Inf), since
    # classInt otherwise samples above 3000 observations. k-means is omitted
    # because R's result depends on its random starting centers
    for method in ["fisher", "quantile", "equal"]
        expected = collect(skipmissing(getproperty(ref, Symbol(method))[keep]))
        @test length(expected) == length(x)
        @test findinterval.(x, Ref(raw[method])) == expected
    end
end
