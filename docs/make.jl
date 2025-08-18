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
    warnonly = [:missing_docs],
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Binning Methods" => "manual/binning_methods.md",
        ],
        "API Reference" => "api.md",
    ],
)

# Deploy documentation
deploydocs(
    repo = "github.com/technocrat/Breakers.jl.git",
    devbranch = "main",
    push_preview = true,
) 