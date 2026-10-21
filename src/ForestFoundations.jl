module ForestFoundations

using DataFrames, IrrationalConstants, Unitful

import Unitful: Length, Area, Volume, Mass, Units, Quantity, NoUnits

const ImperialUnits = Union{typeof(u"inch"), typeof(u"ft"), typeof(u"yd"), typeof(u"mi")}

export @u_str, unit, ustrip, uconvert, Length, Area, Volume, Mass, Units, Quantity, NoUnits, ImperialUnits

include("utils.jl")

export basalarea, stripunits, parseunits, referencearea, referencevolume, expansionfactor

# Former names, kept working with a deprecation warning (shown with `--depwarn=yes`).
function removeunits(data::AbstractDataFrame; kwargs...)
    Base.depwarn("`removeunits` is deprecated, use `stripunits` instead.", :removeunits)
    return stripunits(data; kwargs...)
end

function restoreunits(data::AbstractDataFrame)
    Base.depwarn("`restoreunits` is deprecated, use `parseunits` instead.", :restoreunits)
    return parseunits(data)
end

export removeunits, restoreunits

end
