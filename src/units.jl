# Shared default-unit conventions for the JuliaForests org: every package that
# accepts plain numbers alongside `Unitful` quantities (diameters, heights,
# volumes, areas) promotes them against these same constants, so unitless and
# unitful workflows agree across packages, not just within one.

const Len = Length   # Length (d, h)
const Vol = Volume   # Volume (v)

const DUNIT = u"cm"    # diameters and bark thicknesses
const HUNIT = u"m"     # heights and log lengths
const VUNIT = u"m^3"   # volumes
const AUNIT = u"ha"    # plot/stand areas

"""
    withunit(x, u::Units)

Promotes a plain number (or vector of numbers) to a quantity in unit `u`, and
leaves an already-unitful quantity (or `nothing`) untouched. Lets a function's
keyword/positional arguments accept `Real` and `Unitful.Quantity` values
interchangeably and normalize to one or the other uniformly. A vector may mix
in `missing` entries; each is passed through untouched instead of being
promoted.
"""
withunit(x::Union{Real,AbstractVector{<:Union{Missing,<:Real}}}, u::Units) = x * u
withunit(x::Union{Quantity,AbstractVector{<:Union{Missing,<:Quantity}}}, ::Units) = x
withunit(::Nothing, ::Units) = nothing
