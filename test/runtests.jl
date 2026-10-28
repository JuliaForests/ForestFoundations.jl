using ForestFoundations
using DataFrames
using Test

@testset "ForestFoundations.jl" begin
  @testset "Sectional Area Tests" begin
    dStandard = 30.0u"cm"
    expectedBasalArea = 0.07068583470577035
    @test sectionalarea(dStandard) |> ustrip ≈ expectedBasalArea atol = 1e-6
    @test unit(sectionalarea(dStandard)) == u"m^2"
    @test sectionalarea(0.0u"cm") == 0.0u"m^2"
    @test_throws DomainError sectionalarea(-dStandard)

    # plain numbers carry no unit, so they are rejected instead of assumed to be cm
    @test_throws MethodError sectionalarea(30)

    @test unit(sectionalarea(12u"inch")) == u"ft^2"
  end

  @testset "Length Check Tests" begin
    h = [0.3, 1.3, 2.3]u"m"
    @test checklengths(:h => h, :d => [30.0, 27.5, 25.1]u"cm") === nothing
    @test_throws DimensionMismatch("h and d must have the same length (got 3 and 2).") checklengths(:h => h, :d => [30.0, 27.5]u"cm")
    @test_throws DimensionMismatch("id, h and d must have the same length (got 3, 3 and 4).") checklengths(:id => 1:3, :h => h, :d => [1.0, 2, 3, 4]u"cm")
    # an optional vector not given (`nothing`) is skipped
    @test checklengths(:h => h, :E => nothing) === nothing
  end

  @testset "Unit Conversion Tests" begin
    data = DataFrame(id=[1, 2], d=[30.0, 25.0]u"cm", v=[0.5, 0.3]u"m^3", note=["a", "b"])

    clean = stripunits(data)
    @test names(clean) == ["id", "d (cm)", "v (m^3)", "note"]
    @test clean[!, "d (cm)"] == [30.0, 25.0]
    @test clean[!, "v (m^3)"] == [0.5, 0.3]

    cleanNoRename = stripunits(data; renamecols=false)
    @test names(cleanNoRename) == names(data)
    @test cleanNoRename.d == [30.0, 25.0]

    restored = parseunits(clean)
    @test restored.d == data.d
    @test restored.v == data.v
    @test names(restored) == ["id", "d", "v", "note"]

    # raw field data with units declared only in the headers
    field = DataFrame("tree" => [1, 2], "dbh (cm)" => [30.0, 25.0], "h (m)" => [22.5, 20.1])
    parsed = parseunits(field)
    @test names(parsed) == ["tree", "dbh", "h"]
    @test parsed.dbh == [30.0, 25.0]u"cm"
    @test sectionalarea.(parsed.dbh) ≈ [sectionalarea(30.0u"cm"), sectionalarea(25.0u"cm")]

    # a column whose values cannot carry the unit keeps its original header
    textcol = @test_logs (:warn,) parseunits(DataFrame("sp (ha)" => ["a", "b"]))
    @test names(textcol) == ["sp (ha)"]
    @test textcol[!, "sp (ha)"] == ["a", "b"]

    # compound units written by stripunits (`cm m^2`, `m^3 ha^-1`) are read back
    compound = DataFrame(v=[21.2]u"cm*m^2", xha=[150.0]u"m^3/ha")
    @test parseunits(stripunits(compound)) == compound
  end

  @testset "Long Table Tests" begin
    data = DataFrame(area=["A", "B"], xm=[21.8, 19.6]u"m^3", cv=[39.58, 45.64], n=[70, 20], pop=["finite", "infinite"])

    # one row: a value column, the unit apart from the value
    one = longtable(data[1:1, Not(:area)])
    @test names(one) == ["variable", "unit", "value"]
    @test one.variable == ["xm", "cv", "n", "pop"]
    @test one.unit == ["m^3", "", "", ""]
    @test one.value == [21.8, 39.58, 70, "finite"]

    # many rows: a value column per row, named by the given column, which is not a variable
    many = longtable(data, :area)
    @test names(many) == ["variable", "unit", "A", "B"]
    @test many.B == [19.6, 45.64, 20, "infinite"]
    @test names(longtable(data[:, Not(:area)])) == ["variable", "unit", "value1", "value2"]

    # the unit is written as in the headers of stripunits, so parseunits reads it back
    @test only(longtable(DataFrame(xha=[150.0]u"m^3/ha")).unit) == "m^3 ha^-1"
  end

  @testset "Reference Area and Expansion Factor Tests" begin
    # metric vs imperial reference area
    @test referencearea(u"cm") == u"ha"
    @test referencearea(u"m") == u"ha"
    @test referencearea(u"inch") == u"ac"
    @test referencearea(u"ft") == u"ac"

    # metric expansion factor: 500 m^2 plot -> 20 ha^-1 (10000 m^2 / 500 m^2)
    @test ustrip(uconvert(u"ha^-1", expansionfactor(500.0u"m^2"))) ≈ 20.0 atol = 1e-6
    @test unit(expansionfactor(500.0u"m^2")) == u"ha^-1"

    # imperial expansion factor: 0.1 ac plot -> 10 ac^-1
    @test ustrip(uconvert(u"ac^-1", expansionfactor(0.1u"ac"))) ≈ 10.0 atol = 1e-6
    @test unit(expansionfactor(0.1u"ac")) == u"ac^-1"

    # always floating point: an integer area must not leak a Rational (20//1 ha^-1)
    @test expansionfactor(500u"m^2") === 20.0u"ha^-1"
    @test expansionfactor(500u"m^2") === expansionfactor(500.0u"m^2")
    @test expansionfactor(2000u"m^2") === 5.0u"ha^-1"
    @test expansionfactor(1u"ha") === 1.0u"ha^-1"
    @test expansionfactor(2u"ac") === 0.5u"ac^-1"
    @test expansionfactor(1//2 * u"ha") === 2.0u"ha^-1"
    @test ustrip(expansionfactor(5000u"ft^2")) isa AbstractFloat

    # manual cross-check against a plain 1/area computation in the matching system
    area = 0.05u"ha"
    @test expansionfactor(area) == inv(area)
    areaImperial = 0.2u"ac"
    @test expansionfactor(areaImperial) == inv(areaImperial)

    # referencearea also accepts an Area quantity directly, not just a length unit
    @test referencearea(1000.0u"m^2") == u"ha"
    @test referencearea(0.1u"ha") == u"ha"
    @test referencearea(0.1u"ac") == u"ac"

    # any imperial area, not only acres, selects the acre
    @test referencearea(u"ft^2") == u"ac"
    @test referencearea(5000u"ft^2") == u"ac"
    @test unit(expansionfactor(5000u"ft^2")) == u"ac^-1"
    @test expansionfactor(43560u"ft^2") ≈ 1.0u"ac^-1"
  end

  @testset "Reference Volume Tests" begin
    @test referencevolume(u"cm") == u"m^3"
    @test referencevolume(u"m") == u"m^3"
    @test referencevolume(u"inch") == u"ft^3"
    @test referencevolume(u"ft") == u"ft^3"
  end

  @testset "In Reference Volume Tests" begin
    a = sectionalarea(30.0u"cm")

    # the raw product keeps a mixed unit; the conversion makes it coherent
    @test unit(a * 300.0u"cm") != u"m^3"
    @test unit(inreferencevolume(a * 300.0u"cm", 30.0u"cm")) == u"m^3"
    @test ustrip(inreferencevolume(a * 300.0u"cm", 30.0u"cm")) ≈ 0.07068583470577035 * 3 atol = 1e-12

    # squared diameter times height
    v = (π / 4) * abs2(30.0u"cm") * 0.15u"m"
    @test unit(inreferencevolume(v, u"cm")) == u"m^3"
    @test ustrip(inreferencevolume(v, u"cm")) ≈ 0.010602875205865558 atol = 1e-12

    # imperial system
    vimp = (π / 4) * abs2(12.0u"inch") * 0.5u"ft"
    @test unit(inreferencevolume(vimp, u"inch")) == u"ft^3"
    @test ustrip(inreferencevolume(vimp, u"inch")) ≈ 0.39269908169872414 atol = 1e-12

    # the length unit decides the system, whatever the units of the other factors
    vmixed = sectionalarea(30.0u"cm") * 10.0u"ft"
    @test unit(inreferencevolume(vmixed, 30.0u"cm")) == u"m^3"
    @test ustrip(inreferencevolume(vmixed, 30.0u"cm")) ≈ 0.07068583470577035 * 3.048 atol = 1e-12
    @test unit(inreferencevolume(vmixed, 12.0u"inch")) == u"ft^3"

    # the Length method only reads the unit of d, never its value
    @test inreferencevolume(v, 1.0u"cm") == inreferencevolume(v, 99.0u"cm")

    # an already coherent volume is unchanged, and a plain number is rejected
    @test inreferencevolume(2.0u"m^3", u"cm") == 2.0u"m^3"
    @test_throws MethodError inreferencevolume(2.0, u"cm")
  end
end
