using Documenter
using MaterialDocs
using Breakers

# Set up DocMeta
DocMeta.setdocmeta!(Breakers, :DocTestSetup, :(using Breakers); recursive=true)

# Generate documentation
makedocs(
    sitename = "Breakers.jl",
    format = Material3(
        theme = :ocean_depth,
        dark_mode = :toggle,
        prettyurls = get(ENV, "CI", nothing) == "true",
        edit_link = "main",
    ),
    modules = [Breakers],
    authors = "Richard Careaga and contributors",
    warnonly = [:missing_docs],
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/getting_started.md",
            "Binning Methods" => "manual/binning_methods.md",
            "R classInt Compatibility" => "manual/r_classint_compatibility.md",
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
