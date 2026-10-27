# ForestFoundations.jl

```@meta
CurrentModule = ForestFoundations
```

**ForestFoundations.jl** gathers the shared units, conventions and elementary calculations
of the [JuliaForests](https://github.com/JuliaForests) ecosystem. It makes no assumptions
about any specific forestry topic. It holds the rules that every other package must apply
in the same way: which symbols name each variable, which unit system is the default, and
how a measurement in one system is carried through a calculation without being silently
converted or rounded.

Concentrating these rules in one package keeps each definition in a single place
(Wilson et al., 2014). [ForestMensuration.jl](https://github.com/JuliaForests/ForestMensuration.jl),
[ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl),
[ForestModeling.jl](https://github.com/JuliaForests/ForestModeling.jl) and
[ForestEcology.jl](https://github.com/JuliaForests/ForestEcology.jl) all build on it and
extend its functions through Julia's multiple dispatch, without modifying it.

## Key features

- **Basal area** ([`basalarea`](@ref)): the cross-sectional area of the stem, which,
  measured at breast height, is the basal area of the tree (Kershaw Jr. et al., 2017,
  p. 104).
- **Expansion factor** ([`expansionfactor`](@ref)): the ratio between the unit of area and
  the area of the sampling unit. It converts per-plot counts and sums to per-hectare or
  per-acre values (Kershaw Jr. et al., 2017, p. 274).
- **Reference units** ([`referencearea`](@ref), [`referencevolume`](@ref)): the natural
  area (`ha` or `ac`) and volume (`m^3` or `ft^3`) of the measurement system that a
  length unit belongs to.
- **Coherent volumes** ([`inreferencevolume`](@ref)): expresses a volume obtained as a
  product of areas and lengths (`cm m^2`, `ft inch^2`, ...) in the reference volume of
  the system of a length unit, so that volumes can be summed and compared.
- **Measurement-system detection** (`ImperialUnits`): a `Union` of the imperial length
  units (`inch`, `ft`, `yd`, `mi`), used across the ecosystem to pick the output unit from
  the input unit alone.
- **Tables with units** ([`stripunits`](@ref), [`parseunits`](@ref)): moves the unit of
  each `DataFrame` column into its header for CSV/Excel export, and reads it back from
  the header when field data or results are loaded.
- **Unitful re-exports**: `@u_str`, `unit`, `ustrip`, `uconvert` and the `Length`, `Area`,
  `Volume` and `Mass` quantity types, so `using ForestFoundations` is enough to write
  quantities.

## Conventions

### Symbology

The documentation of every JuliaForests function follows the standardized symbology
proposed by the Brazilian Forest Mensuration Association (Silva et al., 2022). Each
variable is a single letter, with subscripts when needed, and lowercase and uppercase
letters separate the tree from the stand: ``g`` is the basal area of a tree and ``G`` that
of the stand, ``v`` and ``V`` the tree and stand volumes. Under this convention, the basal
area formerly written as ``AS = \pi DAP^2 / 40000`` becomes ``g = \pi D^2 / 40000``, with
``D`` in centimeters and ``g`` in square meters (Silva et al., 2022).

JuliaForests extends this definition by dropping the constant 40000, which only converts
centimeters to meters and ties the formula to a single pair of units. The basal area is
written in its geometric form

```math
g = \frac{\pi D^2}{4}
```

and the unit conversion is done automatically: the result is given in square meters in
the SI and in square feet in the imperial system, whatever length unit ``D`` is measured
in. In the code, the symbols are written as plain text, since typographic italics do not
apply to a programming language.

### Units in both measurement systems

The International System of Units (SI) is the default, as the system established as the
international standard by the International Organization for Standardization (Silva et
al., 2022, p. 21). Even so, the imperial system remains the basis of many forest
measurements in the United States (Burkhart; Avery; Bullock, 2019), and the reference
works present their examples in both systems (Kershaw Jr. et al., 2017). For this reason,
every function accepts metric or imperial values through
[Unitful.jl](https://github.com/JuliaPhysics/Unitful.jl), and **the input unit defines the
output unit**:

| Input                          | `basalarea` | `expansionfactor` | `referencearea` | `referencevolume` |
| :----------------------------- | :---------- | :---------------- | :-------------- | :---------------- |
| metric (`cm`, `m`, `m^2`, ...) | `m^2`       | `ha^-1`           | `ha`            | `m^3`             |
| imperial (`inch`, `ft`, `ac`)  | `ft^2`      | `ac^-1`           | `ac`            | `ft^3`            |

In the imperial system, ``g = \pi D^2 / 4`` with ``D`` in inches and ``g`` in square feet
reduces to the familiar constant ``g = 0.005454 D^2``, against ``\pi / 40000`` for
centimeters and square meters (Burkhart; Avery; Bullock, 2019). Both constants are just
unit conversions applied to ``g = \pi D^2 / 4``, which Unitful performs automatically.

### Units are always explicit

Every quantity carries its unit. Functions take `Unitful` quantities, never plain numbers
with an assumed unit: `basalarea(30u"cm")` works, `basalarea(30)` is a `MethodError`.
Assuming a unit (centimeters, for instance) would give silently wrong results for data
recorded in another one. Tabular data declares one unit per column in the header, as
`name (unit)` written the way Unitful parses it (`D (cm)`, `H (m)`, `g (m^2)`,
`v (m^3)`), and [`parseunits`](@ref) attaches it when the table is read. Column names follow
the same symbology: `D` for the diameter at breast height, `H` for the total height, `g` and `v`
for the basal area and volume of the tree.

### No intermediate rounding

No value is rounded in intermediate calculations, following the recommendation of Silva
et al. (2022, p. 33) to avoid rounding in successive calculations. Rounding is left to the
user when the final results are reported.

## Installation

```julia
using Pkg
Pkg.add("ForestFoundations")
```

## Quick example

```julia-repl
julia> using ForestFoundations

julia> basalarea(30u"cm")              # metric diameter -> m^2
0.07068583470577035 m^2

julia> basalarea(11.8u"inch")          # imperial diameter -> ft^2
0.7594363907740328 ft^2

julia> v = basalarea(30u"cm") * 300.0u"cm"   # area times length keeps a mixed unit
21.205750411731103 cm m^2

julia> inreferencevolume(v, u"cm")     # metric system -> m^3
0.21205750411731103 m^3

julia> inreferencevolume(basalarea(12.0u"inch") * 6.0u"inch", u"inch")   # imperial -> ft^3
0.39269908169872414 ft^3

julia> expansionfactor(500u"m^2")      # each tree in a 500 m^2 plot represents 20 trees/ha
20.0 ha^-1

julia> expansionfactor(0.1u"ac")       # each tree in a 0.1 ac plot represents 10 trees/ac
10.0 ac^-1
```

### Tables with units

Field data and results are exchanged as plain tables, with the unit of each column
declared in its header. [`parseunits`](@ref) reads those headers and attaches the units,
so the columns can go straight into the functions:

```julia-repl
julia> using ForestFoundations, DataFrames

julia> field = DataFrame("D (cm)" => [30.0, 25.0, 18.5], "H (m)" => [22.4, 20.1, 16.8],
                         "v (m^3)" => [0.7012, 0.4825, 0.2194]);

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
```

[`stripunits`](@ref) does the reverse: it moves each unit back into the header and leaves
plain numbers, ready to be saved:

```julia-repl
julia> stripunits(data)
3×3 DataFrame
 Row │ D (cm)   H (m)    v (m^3)
     │ Float64  Float64  Float64
─────┼───────────────────────────
   1 │    30.0     22.4   0.7012
   2 │    25.0     20.1   0.4825
   3 │    18.5     16.8   0.2194
```

With CSV.jl, the full round trip is:

```julia
using CSV
data = parseunits(CSV.read("field.csv", DataFrame))   # header: D (cm), H (m), v (m^3)
CSV.write("results.csv", stripunits(data))            # same headers, plain numbers
```

See the [API](api.md) page for every documented function.

## The JuliaForests ecosystem

The functions are split into thematic packages, so users install only what they need.
They follow the three operations of forest resource quantification: measuring,
predicting and estimating (Batista; Couto; Silva Filho, 2014).

| Package | Scope |
| :------ | :---- |
| **ForestFoundations.jl** | Units, symbology and elementary calculations shared by all packages |
| [ForestMensuration.jl](https://github.com/JuliaForests/ForestMensuration.jl) | Measurement of the tree and the stand: cubage, form factors, stand averages, diameter distributions, site index |
| [ForestInventory.jl](https://github.com/JuliaForests/ForestInventory.jl) | Estimation by sampling: sampling designs, sampling error, confidence limits, sampling intensity |
| [ForestModeling.jl](https://github.com/JuliaForests/ForestModeling.jl) | Prediction by regression: volume, biomass and hypsometric equations, model selection |
| [ForestEcology.jl](https://github.com/JuliaForests/ForestEcology.jl) | Species composition and diversity: importance value, diversity indices, richness estimators |

## References

The equations and procedures are taken mainly from two reference works in forest
mensuration, *Forest Mensuration* (Kershaw Jr. et al., 2017) and *Forest Measurements*
(Burkhart; Avery; Bullock, 2019). Both are recent, revised editions, present measurements
and examples in the SI and imperial systems, and include worked numerical examples that
serve as reference values for the tests. The symbology follows Silva et al. (2022). Other
sources are cited in the documentation of the function that uses them.

- BATISTA, J. L. F.; COUTO, H. T. Z.; SILVA FILHO, D. F. **Quantificação de recursos
  florestais**: árvores, arvoredos e florestas. São Paulo: Oficina de Textos, 2014. 384 p.
- BEZANSON, J. et al. Julia: a fresh approach to numerical computing. **SIAM Review**,
  v. 59, n. 1, p. 65-98, 2017. DOI: [10.1137/141000671](https://doi.org/10.1137/141000671).
- BURKHART, H. E.; AVERY, T. E.; BULLOCK, B. P. **Forest measurements**. 6. ed. Long
  Grove: Waveland Press, 2019. 434 p.
- KELLER, A. **Unitful.jl**: a Julia package for physical units. Available at:
  <https://github.com/JuliaPhysics/Unitful.jl>.
- KERSHAW JR., J. A.; DUCEY, M. J.; BEERS, T. W.; HUSCH, B. **Forest mensuration**. 5. ed.
  Chichester: Wiley, 2017. 613 p.
- SILVA, G. F. et al. **Padronização da simbologia em mensuração e manejo florestal**.
  Alegre: [s. n.], 2022. 63 p.
- WILSON, G. et al. Best practices for scientific computing. **PLOS Biology**, v. 12, n. 1,
  e1001745, 2014. DOI: [10.1371/journal.pbio.1001745](https://doi.org/10.1371/journal.pbio.1001745).

## About the author

I am Marcos Daniel da Silva, a Forest Engineer. ForestFoundations.jl and the other
JuliaForests packages are being developed as part of my master's dissertation,
*ForestMensuration.jl: quantificação de recursos florestais em Julia*, in the Graduate
Program in Agronomy: Agriculture and Environment (Programa de Pós-Graduação em
Agronomia: Agricultura e Ambiente) at the Federal University of Santa Maria, Frederico
Westphalen campus (UFSM), under the supervision of Prof. Dr. Emanuel Araújo da Silva
(UFSM) and the co-supervision of Prof. Dr. Rafaelo Balbinot (UFSM).

The dissertation continues the work started in my undergraduate final project, which
created ForestMensuration.jl:
[Forestmensuration.jl: uma introdução à aplicações em Julia](https://repositorio.ufsm.br/handle/1/31917?show=full).

For more details, connect with me on
[LinkedIn](https://www.linkedin.com/in/marcosdanieldasilva/?locale=en_US) or by e-mail:
[marcosdasilva@5a.tec.br](mailto:marcosdasilva@5a.tec.br).
