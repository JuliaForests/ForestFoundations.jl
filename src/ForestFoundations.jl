module ForestFoundations

using DataFrames, IrrationalConstants, Unitful

import Unitful: Length, Area, Volume, Mass, Units, Quantity, NoUnits

const ImperialUnits = Union{typeof(u"inch"),typeof(u"ft"),typeof(u"yd"),typeof(u"mi")}

export @u_str, unit, ustrip, uconvert, Length, Area, Volume, Mass, Units, Quantity, NoUnits, ImperialUnits

include("utils.jl")

export basalarea, stripunits, parseunits, referencearea, referencevolume, expansionfactor

end
