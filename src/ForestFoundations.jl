module ForestFoundations

using DataFrames, IrrationalConstants, Unitful

import Unitful: Length, Area, Volume, Mass, Units, Quantity, NoUnits

# Imperial units, used to detect the measurement system of an input
const ImperialUnits = Union{
  # lengths
  typeof(u"inch"), typeof(u"ft"), typeof(u"yd"), typeof(u"mi"),
  # areas
  typeof(u"inch^2"), typeof(u"ft^2"), typeof(u"yd^2"), typeof(u"mi^2"), typeof(u"ac"),
  # volumes
  typeof(u"inch^3"), typeof(u"ft^3"), typeof(u"yd^3"), typeof(u"mi^3"),
}

export quartπ, @u_str, unit, ustrip, uconvert, Length, Area, Volume, Mass, Units, Quantity, NoUnits, ImperialUnits

include("utils.jl")

export sectionalarea, checklengths, stripunits, parseunits, longtable, referencearea, referencevolume, inreferencevolume, expansionfactor

# `basalarea` was renamed `sectionalarea`; the old name still works with a deprecation warning
Base.@deprecate basalarea(d::Length) sectionalarea(d)

end
