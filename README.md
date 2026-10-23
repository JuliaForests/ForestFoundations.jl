# ForestFoundations

ForestFoundations.jl provides the shared, package-independent foundations used across the
JuliaForests ecosystem (ForestMensuration.jl, ForestInventory.jl, ForestModeling.jl, and
future packages). It has no forestry-domain assumptions of its own — only unit-safe
geometry, DataFrame unit round-tripping, and plot-to-population scaling — so every
downstream package can rely on a single, consistent implementation instead of
duplicating it.

Its documentation follows the standardized forest mensuration symbology of
Silva et al. (2022), and every function works in both measurement systems: the SI is the
default, imperial inputs give imperial outputs.

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
way Unitful parses it (`D (cm)`, `H (m)`, `g (m^2)`, `v (m^3)`), and `parseunits`
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

Column names follow the symbology of Silva et al. (2022): `D` diameter at 1.30 m, `H` total
height, `v` tree volume.

```julia-repl
julia> using ForestFoundations, DataFrames

# field data as read from a CSV: the unit of each column is declared in its header
julia> field = DataFrame("D (cm)" => [30.0, 25.0, 18.5], "H (m)" => [22.4, 20.1, 16.8],
                         "v (m^3)" => [0.7012, 0.4825, 0.2194]);

# attach the units, so the columns go straight into the functions
julia> data = parseunits(field)
3×3 DataFrame
 Row │ D          H          v
     │ Quantity…  Quantity…  Quantity…
─────┼──────────────────────────────────
   1 │   30.0 cm     22.4 m  0.7012 m^3
   2 │   25.0 cm     20.1 m  0.4825 m^3
   3 │   18.5 cm     16.8 m  0.2194 m^3

julia> basalarea.(data.D)
3-element Vector{Quantity{Float64, 𝐋^2, Unitful.FreeUnits{(m^2,), 𝐋^2, nothing}}}:
 0.07068583470577035 m^2
 0.049087385212340524 m^2
 0.02688025214227767 m^2

# ready for CSV export: units moved back into the column names
julia> stripunits(data)
3×3 DataFrame
 Row │ D (cm)   H (m)    v (m^3)
     │ Float64  Float64  Float64
─────┼───────────────────────────
   1 │    30.0     22.4   0.7012
   2 │    25.0     20.1   0.4825
   3 │    18.5     16.8   0.2194
```

Reading and saving a CSV:

```julia
using CSV
data = parseunits(CSV.read("field.csv", DataFrame))   # header: D (cm), H (m), v (m^3)
CSV.write("results.csv", stripunits(data))            # same headers, plain numbers
```

## Conventions and References

- **Symbology:** standardized symbols of the Brazilian Forest Mensuration Association
  (Silva et al., 2022): one letter per variable, lowercase for the tree and uppercase for
  the stand (`g`/`G`, `v`/`V`).
- **Units:** SI by default (Silva et al., 2022), imperial supported throughout via
  Unitful; the input unit defines the output unit. No intermediate rounding.
- **Formulas:** taken mainly from Kershaw Jr. et al. (2017) and Burkhart, Avery & Bullock
  (2019), whose worked examples serve as reference values for the tests.

References:

- Burkhart, H. E., Avery, T. E., & Bullock, B. P. (2019). *Forest Measurements* (6th ed.).
  Long Grove: Waveland Press.
- Kershaw Jr., J. A., Ducey, M. J., Beers, T. W., & Husch, B. (2017). *Forest Mensuration*
  (5th ed.). Chichester: Wiley.
- Silva, G. F. et al. (2022). *Padronização da simbologia em mensuração e manejo
  florestal*. Alegre.

See the documentation home page for the full conventions and the complete list of
references.

## Academic Context

ForestFoundations.jl is part of the master's dissertation *ForestMensuration.jl:
quantificação de recursos florestais em Julia*, by Marcos Daniel da Silva, in the Graduate
Program in Agronomy: Agriculture and Environment at the Federal University of Santa Maria,
Frederico Westphalen campus (UFSM), supervised by Prof. Dr. Emanuel Araújo da Silva and
co-supervised by Prof. Dr. Rafaelo Balbinot.

## Keywords

Forest mensuration, dendrometry, forest inventory, units of measurement, basal area,
Unitful.

## License

This project is licensed under the MIT License.
