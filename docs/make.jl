using GrapheneHHG
using Documenter

DocMeta.setdocmeta!(GrapheneHHG, :DocTestSetup, :(using GrapheneHHG); recursive=true)

makedocs(;
    modules=[GrapheneHHG],
    authors="Minoru Kanega <xxxx.xxxxx@gmail.com>",
    sitename="GrapheneHHG.jl",
    format=Documenter.HTML(;
        canonical="https://xxxxxxxx.github.io/GrapheneHHG.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/xxxxxxxx/GrapheneHHG.jl", devbranch="main")
