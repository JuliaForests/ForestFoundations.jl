# ForestFoundations

ForestFoundations.jl provides the shared, package-independent foundations used across the
JuliaForests ecosystem (ForestMensuration.jl, ForestInventory.jl, ForestModeling.jl, and
future packages). It has no forestry-domain assumptions of its own — only unit-safe
geometry, DataFrame unit round-tripping, and plot-to-population scaling — so every
downstream package can rely on a single, consistent implementation instead of
duplicating it.

[![Build Status](https://github.com/JuliaForests/ForestFoundations.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaForests/ForestFoundations.jl/actions/workflows/CI.yml?query=branch%3Amaster)

## Installation

Install the package via Julia's package manager:

```julia-repl
using Pkg
Pkg.add("ForestFoundations")
```

## Overview

ForestFoundations.jl is built on top of [Unitful.jl](https://github.com/PainterQubits/Unitful.jl)
and re-exports the pieces every forestry calculation needs (`@u_str`, `unit`, `ustrip`,
`uconvert`, and the `Length`/`Area`/`Volume`/`Mass` quantity types), plus:

- **Metric/imperial detection (`ImperialUnits`):**
  A trait-like `Union` of imperial length units (`inch`, `ft`, `yd`, `mi`) used
  throughout the ecosystem to automatically pick the right output unit or standard
  (square meters vs. square feet, hectares vs. acres) from the unit of the input alone.

- **Basal area (`basalarea`):**
  The cross-sectional area of a tree stem at breast height — the single most-used
  primitive in forest mensuration, computed once here and reused everywhere.

- **Reference area and expansion factor (`referencearea`, `expansionfactor`):**
  Pure unit-conversion arithmetic for scaling a per-plot count or sum (trees, basal
  area, ...) to a per-unit-area rate (trees/ha, m²/ha, trees/ac, ft²/ac, ...),
  automatically choosing hectares or acres from the measurement system.

- **DataFrame unit round-trip (`stripunits`, `parseunits`):**
  Converts a `DataFrame` of `Unitful` quantities into plain numeric columns (with the
  unit recorded in the column name) for export to CSV/Excel, and reads the units declared
  in the headers of any table (raw field data or exported results) back into quantities.

## Units are always explicit

Every quantity carries its unit. Functions take `Unitful` quantities, never plain numbers
with an assumed unit: `basalarea(30u"cm")` works, `basalarea(30)` is a `MethodError`.
Tabular data declares one unit per column in the header, as `name (unit)` written the
way Unitful parses it (`DAP (cm)`, `h (m)`, `g (m^2)`, `area (ha)`), and `parseunits`
attaches it when the table is read.

## Example Usage

### Basal Area

```julia-repl
using ForestFoundations

# metric diameter in cm -> basal area in m^2
julia> basalarea(30u"cm")
0.07068583470577035 m^2

# imperial diameter in inches -> basal area in ft^2
julia> basalarea(11.8u"inch")
0.7594363907740328 ft^2
```

### Reference Area and Expansion Factor

```julia-repl
using ForestFoundations

julia> referencearea(u"cm")
ha

julia> referencearea(u"inch")
ac

# a 500 m^2 plot expands to 20 trees/ha for every tree counted
julia> expansionfactor(500.0u"m^2")
20.0 ha^-1

# a 0.1 ac plot expands to 10 trees/ac for every tree counted
julia> expansionfactor(0.1u"ac")
10.0 ac^-1
```

### DataFrame Unit Round-Trip

```julia-repl
using ForestFoundations, DataFrames

julia> data = DataFrame(id=[1, 2], d=[30.0, 25.0]u"cm", v=[0.5, 0.3]u"m^3")
2×3 DataFrame
 Row │ id     d          v
     │ Int64  Quantity…  Quantity…
─────┼─────────────────────────────
   1 │     1    30.0 cm    0.5 m^3
   2 │     2    25.0 cm    0.3 m^3

# ready for CSV export: units moved into the column names
julia> clean = stripunits(data)
2×3 DataFrame
 Row │ id     d (cm)   v (m^3)
     │ Int64  Float64  Float64
─────┼─────────────────────────
   1 │     1     30.0      0.5
   2 │     2     25.0      0.3

# and back to Unitful quantities, e.g. after loading a CSV
julia> parseunits(clean)
2×3 DataFrame
 Row │ id     d          v
     │ Int64  Quantity…  Quantity…
─────┼─────────────────────────────
   1 │     1    30.0 cm    0.5 m^3
   2 │     2    25.0 cm    0.3 m^3
```

Saving and reading a CSV:

```julia
using CSV
CSV.write("results.csv", stripunits(df))              # d (cm) | 30.0, 25.0
df = parseunits(CSV.read("results.csv", DataFrame))   # d | 30.0 cm, 25.0 cm
```

`removeunits` and `restoreunits`, the former names of these functions, still work but are
deprecated.

## Keywords

Forest mensuration, dendrometry, forest inventory, units of measurement, basal area,
Unitful.

## License

This project is licensed under the MIT License.
