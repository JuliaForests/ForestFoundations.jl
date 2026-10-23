"""
    basalarea(D::Length)
    basalarea(D1::Length, D2::Length)

Calculates the cross-sectional area (``g``) of a tree stem from its diameter (``D``).
Measured at breast height, this is the tree basal area.

# Arguments
- `D`: Diameter as a unitful quantity, e.g. `10u"cm"` or `12u"inch"`. A diameter tape
  reading already is a diameter (the tape is graduated in ``\\pi`` units), so it can be
  passed as is; a raw circumference ``C`` must be converted first with ``D = C / \\pi``.
- `D1`, `D2`: Long and short diameters (axes) of an elliptical cross section, taken with
  calipers. They may be given in different length units; `D2` is converted to the unit of `D1`.

All diameters must be non-negative values.

# Returns
- `Quantity`: Area in square feet (`ft^2`) if the input is imperial, or square meters (`m^2`) otherwise.

# Mathematical basis
For a circular cross section the area follows from the diameter:
```math
g = \\frac{\\pi D^2}{4}
```
For an elliptical cross section with long and short diameters ``D_1`` and ``D_2``, the
exact area is obtained with the geometric mean diameter ``\\sqrt{D_1 D_2}``, which gives:
```math
g = \\frac{\\pi D_1 D_2}{4}
```
The one-argument method is the case ``D_1 = D_2 = D``.

# Accuracy note
Most stems are not perfectly circular. A diameter tape slightly overestimates the true
area, because the circle is the geometric figure with the smallest perimeter for a given
area. With calipers, the geometric mean of the long and short diameters is the best
practice for elliptical sections; the arithmetic mean overestimates the area (about 4% at
a 3:2 axis ratio and 13% at 2:1), so it is not offered here.

# Examples

```julia-repl
julia> basalarea(30u"cm")
0.07068583470577035 m^2

julia> basalarea(11.8u"inch")
0.7594363907740328 ft^2

julia> basalarea(36u"cm", 25u"cm")
0.07068583470577035 m^2
```

# References
Kershaw Jr., Ducey, Beers & Hush (2020). *Forest Mensuration*, 5th ed., Section 5.2.3.
"""
function basalarea(D1::Length, D2::Length)
    (ustrip(D1) < 0 || ustrip(D2) < 0) &&
        throw(DomainError((D1, D2), "The diameter must be a non-negative value, observed values are $D1 and $D2"))

    g = quartπ * D1 * uconvert(unit(D1), D2)

    if unit(D1) isa ImperialUnits
        return uconvert(u"ft^2", g)
    else
        return uconvert(u"m^2", g)
    end
end

basalarea(D::Length) = basalarea(D, D)

# A plain number carries no unit, so there is no `basalarea(::Real)`: assuming a unit
# (e.g. centimeters) would silently give wrong results for data recorded in other units.
# Attach the unit explicitly (`basalarea(30u"cm")`) or read it from the column header
# with `parseunits`.

"""
    stripunits(data::AbstractDataFrame; renamecols::Bool=true)

Converts a DataFrame containing Unitful quantities into a plain numeric DataFrame,
moving each column's unit into its header (`D` with values in `cm` becomes `D (cm)`).
This is the format for saving results to CSV/Excel; [`parseunits`](@ref) is the inverse.
Safely ignores dimensionless data (NoUnits) preventing empty parentheses.

# Header convention
`name (unit)`, with the unit written as Unitful parses it (`m^2`, `m^3`, `ha`, `inch`).
Column names follow the symbology of Silva et al. (2022): `D` for the diameter at 1.30 m,
`H` for the total height, `g` for the basal area and `v` for the volume of the tree.
Each column must hold a single unit: convert mixed-unit columns first, e.g.
`df.D = uconvert.(u"cm", df.D)`.

# Arguments
- `data::AbstractDataFrame`: The input DataFrame containing columns with physical units.
- `renamecols::Bool`: If `true` (default), appends the unit symbol to the column header.

# Returns
- `DataFrame`: A new DataFrame with plain numeric types, ready for export.

# Examples
```julia-repl
julia> data = DataFrame(D=[30.0, 25.0, 18.5]u"cm", H=[22.4, 20.1, 16.8]u"m",
                       v=[0.7012, 0.4825, 0.2194]u"m^3");

julia> stripunits(data)
3×3 DataFrame
 Row │ D (cm)   H (m)    v (m^3)
     │ Float64  Float64  Float64
─────┼───────────────────────────
   1 │    30.0     22.4   0.7012
   2 │    25.0     20.1   0.4825
   3 │    18.5     16.8   0.2194
```
"""
function stripunits(data::AbstractDataFrame; renamecols::Bool=true)
    dataClean = copy(data)

    for colname in names(dataClean)
        col = dataClean[!, colname]
        T = nonmissingtype(eltype(col))

        if T <: Quantity
            u = unit(T)
            # Skip renaming if the column is dimensionless (NoUnits)
            if renamecols && u != NoUnits
                newname = "$(colname) ($(u))"
                rename!(dataClean, colname => newname)
                dataClean[!, newname] = ustrip.(col)
            else
                dataClean[!, colname] = ustrip.(col)
            end
        end
    end

    return dataClean
end

"""
    parseunits(data::AbstractDataFrame)

Reads the units declared in the column headers (`name (unit)`) and attaches them to the
values, returning a DataFrame of Unitful quantities with the plain names (`D (cm)` becomes
`D` with values in `cm`). Use it on any tabular input — raw field data or a table saved
with [`stripunits`](@ref), of which it is the inverse.
Safely evaluates mathematical expressions (e.g., m^3) inside the Unitful module scope.

# Header convention
`name (unit)`, with the unit written as Unitful parses it (`m^2`, `m^3`, `ha`, `inch`).
Headers whose unit cannot be parsed (e.g. `m²`) are left unchanged with a warning.

# Arguments
- `data::AbstractDataFrame`: The input DataFrame, typically loaded from a CSV or Excel file.

# Returns
- `DataFrame`: A DataFrame with Unitful quantities in the columns that declare a unit.

# Examples
```julia-repl
julia> field = DataFrame("D (cm)" => [30.0, 25.0, 18.5], "H (m)" => [22.4, 20.1, 16.8],
                         "v (m^3)" => [0.7012, 0.4825, 0.2194]);

julia> parseunits(field)
3×3 DataFrame
 Row │ D          H          v
     │ Quantity…  Quantity…  Quantity…
─────┼──────────────────────────────────
   1 │   30.0 cm     22.4 m  0.7012 m^3
   2 │   25.0 cm     20.1 m  0.4825 m^3
   3 │   18.5 cm     16.8 m  0.2194 m^3
```
"""
function parseunits(data::AbstractDataFrame)
    dataRestored = copy(data)

    # Regular expression to capture the base name and the unit inside parentheses
    regex = r"^(.*?)\s*\((.*?)\)$"

    for colname in names(dataRestored)
        m = match(regex, colname)

        if m !== nothing
            basename = strip(m.captures[1])
            unitstr = strip(m.captures[2])

            # Handle cases where the parentheses were inadvertently empty
            if unitstr == ""
                rename!(dataRestored, colname => basename)
                continue
            end

            try
                # uparse can return an expression (e.g., for "m^3").
                # Core.eval evaluates this expression safely inside the Unitful context.
                u = Core.eval(Unitful, Unitful.uparse(unitstr))

                rename!(dataRestored, colname => basename)
                dataRestored[!, basename] = dataRestored[!, basename] .* u
            catch e
                # Formats the warning outside the macro to prevent scope interpolation bugs
                msg = "Could not parse unit '$(unitstr)' in column '$(colname)'. Error: $e"
                @warn msg
            end
        end
    end

    return dataRestored
end

"""
    referencearea(u::Units)

Returns the natural reference area used to extrapolate per-plot data to a population
density estimate: hectares (`ha`) for the metric system, acres (`ac`) for the imperial
system, detected from a length unit `u` (e.g., the unit of a diameter or height).

# Arguments
- `u::Units`: A length unit, such as `unit(30u"cm")` or `unit(12u"inch")`.

# Returns
- `Units`: `u"ha"` if `u` is a metric length unit, `u"ac"` if it is an imperial one.

# Examples

```julia-repl
julia> referencearea(u"cm")
ha

julia> referencearea(u"inch")
ac
```
"""
referencearea(u::Units) = u isa ImperialUnits ? u"ac" : u"ha"

"""
    referencearea(a::Area)

The `Area`-quantity counterpart of [`referencearea(::Units)`](@ref): returns `u"ac"` if
`a` is itself already given in acres, `u"ha"` otherwise (covering `ha` as well as any
other metric area unit, e.g. `m^2`, `km^2`).

# Examples

```julia-repl
julia> referencearea(0.1u"ac")
ac

julia> referencearea(1000u"m^2")
ha
```
"""
referencearea(a::Area) = unit(a) == u"ac" ? u"ac" : u"ha"

"""
    referencevolume(u::Units)

Returns the natural reference volume unit for the measurement system a length unit `u`
belongs to: cubic meters (`m^3`) for the metric system, cubic feet (`ft^3`) for the
imperial system — the volume-quantity analogue of [`referencearea`](@ref).

# Arguments
- `u::Units`: A length unit, such as `unit(30u"cm")` or `unit(12u"inch")`.

# Returns
- `Units`: `u"m^3"` if `u` is a metric length unit, `u"ft^3"` if it is an imperial one.

# Examples

```julia-repl
julia> referencevolume(u"cm")
m^3

julia> referencevolume(u"inch")
ft^3
```
"""
referencevolume(u::Units) = u isa ImperialUnits ? u"ft^3" : u"m^3"

"""
    inreferencevolume(v::Volume, u::Units)
    inreferencevolume(v::Volume, d::Length)

Expresses a volume `v` in the reference volume unit of the measurement system given by a
length unit `u` (or by the unit of a length `d`): cubic meters (`m^3`) for the metric
system, cubic feet (`ft^3`) for the imperial system. See [`referencevolume`](@ref).

Unitful does not simplify units when quantities are multiplied, so a volume computed as an
area times a length, or from a squared diameter times a height, keeps whatever mix of units
its operands had (`cm m^2`, `cm^2 m`, `ft inch^2`, ...). Such a value is dimensionally a
volume but is not a coherent one, and it cannot be summed or compared with other volumes
without a conversion. This function performs that conversion.

# Arguments
- `v`: A volume, typically the raw product of areas and lengths.
- `u`: A length unit, such as `unit(30u"cm")` or `u"inch"`. Its system defines the output
  unit.
- `d`: A length quantity. Only its unit is used, never its value, so the system is decided
  by `d` regardless of the units of the other factors in `v` (e.g. a metric diameter with a
  length in feet yields `m^3`).

# Returns
- `Quantity`: `v` in `ft^3` if the length unit is imperial, or in `m^3` otherwise.

# Examples

```julia-repl
julia> a = basalarea(30u"cm")
0.07068583470577035 m^2

julia> a * 300.0u"cm"
21.205750411731103 cm m^2

julia> inreferencevolume(a * 300.0u"cm", 30u"cm")
0.21205750411731103 m^3

julia> inreferencevolume((π / 4) * abs2(12.0u"inch") * 0.5u"ft", u"inch")
0.39269908169872414 ft^3
```
"""
inreferencevolume(v::Volume, u::Units) = uconvert(referencevolume(u), v)

inreferencevolume(v::Volume, d::Length) = inreferencevolume(v, unit(d))

"""
    expansionfactor(area::Area)

Calculates the expansion factor (EF) used to scale a per-plot count or sum (e.g., number
of trees, basal area) to a per-unit-area rate (trees/ha, m²/ha, trees/ac, ft²/ac, ...):
the inverse of the sampled area expressed in its reference area.

The reference area follows [`referencearea(::Area)`](@ref): acres (`ac`) when `area` is
given in acres, hectares (`ha`) otherwise (any other metric area unit, e.g. `m^2`, is
converted to hectares).

# Arguments
- `area::Area`: The sampled area (e.g., the plot area).

# Returns
- `Quantity`: The expansion factor, in `ha^-1` or `ac^-1`.

# Examples

```julia-repl
julia> expansionfactor(500u"m^2")
20.0 ha^-1

julia> expansionfactor(0.1u"ac")
10.0 ac^-1
```
"""
expansionfactor(area::Area) = inv(uconvert(referencearea(area), area))
