using Documenter, ForestFoundations

makedocs(
  sitename="ForestFoundations.jl",
  modules=[ForestFoundations],
  pages=["Home" => "index.md", "API" => "api.md"],
  checkdocs=:none,
)
