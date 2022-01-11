using IndexTransforms
using Documenter

DocMeta.setdocmeta!(IndexTransforms, :DocTestSetup, :(using IndexTransforms); recursive=true)

makedocs(;
    modules=[IndexTransforms],
    authors="Zachary P. Christensen <zchristensen7@gmail.com> and contributors",
    repo="https://github.com/Tokazama/IndexTransforms.jl/blob/{commit}{path}#{line}",
    sitename="IndexTransforms.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Tokazama.github.io/IndexTransforms.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Tokazama/IndexTransforms.jl",
)
