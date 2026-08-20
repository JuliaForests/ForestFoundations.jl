"""
    basalarea(d::Length)

calculates the individual cross-sectional area (g) of a tree stem.

# arguments
- `d`: diameter at breast height as a unitful quantity e.g. 10u"cm" or 12u"inch". The diameter must be a positive value.

# returns
- `Quantity`: area in square feet ft2 if input is imperial or square meters m2 otherwise.

# mathematical basis
the calculation uses the standard geometric formula
```math
g = \\frac{\\pi d^2}{4}
```

# accuracy note

most stems are not perfectly circular
using a diameter tape slightly overestimates the true area because the circle
is the geometric figure with the smallest perimeter for a given area.

# examples

```julia-repl
julia> basalarea(30u"cm")
0.07068583470577035 m^2

julia> basalarea(11.8u"inch")
0.7594363907740327 ft^2
```
"""
function basalarea(d::Length)
  ustrip(d) <= 0 && throw(DomainError("The diameter must be a positive value, observed values is $d"))

  g = quartπ * abs2(d)

  if unit(d) isa ImperialUnits
    return uconvert(u"ft^2", g)
  else
    return uconvert(u"m^2", g)
  end
end

"""
    basalarea(d::Real)

Calculates the basal area (g) of a tree given its diameter in centimeters.

# Description
This function computes the basal area of a tree, which is the cross-sectional area of the tree trunk at breast height (usually measured at 1.3 meters above ground). Basal area is a critical parameter in forest mensuration, used for estimating stand density, timber volume, and assessing competition among trees in a forest stand.

# Arguments
- `d::Real`: The diameter at breast height of the tree in **centimeters**. The diameter must be a positive value.

# Returns
- `Float64`: The basal area of the tree in **square meters**.

# Example
```julia-repl
# Calculate the basal area for a tree with a diameter of 30 cm
julia> basalarea(30)
0.07068583470577035 m^2
```
"""
basalarea(d::Real) = basalarea(d * u"cm")

"""
    removeunits(data::AbstractDataFrame; renamecols::Bool=true)

Converts a DataFrame containing Unitful quantities into a plain numeric DataFrame.
Safely ignores dimensionless data (NoUnits) preventing empty parentheses.

# Arguments
- `data::AbstractDataFrame`: The input DataFrame containing columns with physical units.
- `renamecols::Bool`: If `true` (default), appends the unit symbol to the column header.

# Returns
- `DataFrame`: A new DataFrame with plain numeric types, ready for export.
"""
function removeunits(data::AbstractDataFrame; renamecols::Bool=true)
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
    restoreunits(data::AbstractDataFrame)

Restores Unitful quantities to a plain DataFrame by parsing unit strings located in the column headers.
Safely evaluates mathematical expressions (e.g., m^3) inside the Unitful module scope.

# Arguments
- `data::AbstractDataFrame`: The input DataFrame, typically loaded from a CSV file.

# Returns
- `DataFrame`: A DataFrame with restored Unitful quantities.
"""
function restoreunits(data::AbstractDataFrame)
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
    expansionfactor(u::Units, area::Area)
    expansionfactor(x::Quantity, area::Area)
    expansionfactor(x::AbstractVector{<:Quantity}, area::Area)

Calculates the expansion factor (EF) used to scale a per-plot count or sum (e.g., number
of trees, basal area) to a per-unit-area rate (trees/ha, m²/ha, trees/ac, ft²/ac, ...).
The reference area (`ha` or `ac`) is chosen automatically from the measurement system,
detected from a length unit, a length quantity, or a vector of length quantities.

# Arguments
- `u`/`x`: A length unit, a length quantity, or a vector of length quantities. Only used
  to detect whether the metric or imperial system is in use; its magnitude is ignored.
- `area::Area`: The total sampled area.

# Returns
- `Quantity`: The expansion factor, in `ha^-1` or `ac^-1`.

# Examples

```julia-repl
julia> expansionfactor(u"cm", 500u"m^2")
20.0 ha^-1

julia> expansionfactor(30u"cm", 500u"m^2")
20.0 ha^-1

julia> expansionfactor([30u"cm", 25u"cm"], 500u"m^2")
20.0 ha^-1

julia> expansionfactor(12u"inch", 0.1u"ac")
10.0 ac^-1
```
"""
expansionfactor(u::Units, area::Area) = inv(uconvert(referencearea(u), area))
expansionfactor(x::Quantity, area::Area) = expansionfactor(unit(x), area)
expansionfactor(x::AbstractVector{<:Quantity}, area::Area) = expansionfactor(unit(first(x)), area)
