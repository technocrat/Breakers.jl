using Documenter
using Breakers

# Set up DocMeta
DocMeta.setdocmeta!(Breakers, :DocTestSetup, :(using Breakers); recursive=true)

# Generate documentation
makedocs(
    sitename = "Breakers.jl",
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    modules = [Breakers],
    authors = "Richard Careaga and contributors",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/getting_started.md",
            "Binning Methods" => "manual/binning_methods.md",
            "R ClassInt Compatibility" => "manual/r_classint_compatibility.md",
        ],
        "API Reference" => "api.md",
    ],
)

# Deploy documentation
deploydocs(
    repo = "github.com/technocrat/Breakers.jl.git",
    devbranch = "master",
    push_preview = true,
) 