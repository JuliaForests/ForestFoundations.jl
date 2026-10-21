using ForestFoundations
using DataFrames
using Test

@testset "ForestFoundations.jl" begin
    @testset "Basal Area Tests" begin
      dStandard = 30.0u"cm"
      expectedBasalArea = 0.07068583470577035
      @test basalarea(dStandard) |> ustrip ≈ expectedBasalArea atol = 1e-6
      @test unit(basalarea(dStandard)) == u"m^2"
      @test basalarea(0.0u"cm") == 0.0u"m^2"
      @test basalarea(0.0u"cm", 25u"cm") == 0.0u"m^2"
      @test_throws DomainError basalarea(-dStandard)

      # plain numbers carry no unit, so they are rejected instead of assumed to be cm
      @test_throws MethodError basalarea(30)
      @test_throws MethodError basalarea(36, 25)

      # geometric mean of two diameters: 36 x 25 cm has the area of a 30 cm circle
      @test basalarea(36u"cm", 25u"cm") ≈ basalarea(30u"cm")
      @test basalarea(25u"cm", 36u"cm") ≈ basalarea(36u"cm", 25u"cm")
      @test basalarea(30u"cm", 30u"cm") ≈ basalarea(30u"cm")
      # mixed units: D2 is converted to the unit of D1
      @test basalarea(10u"cm", 4u"inch") ≈ basalarea(10u"cm", 4 * 2.54u"cm")
      @test unit(basalarea(12u"inch", 10u"inch")) == u"ft^2"
      @test_throws DomainError basalarea(30u"cm", -25u"cm")
      @test_throws DomainError basalarea(-30u"cm", 25u"cm")
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
      @test basalarea.(parsed.dbh) ≈ [basalarea(30.0u"cm"), basalarea(25.0u"cm")]

      # deprecated former names still work and give the same result
      @test removeunits(data) == stripunits(data)
      @test isequal(restoreunits(clean), parseunits(clean))
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

      # manual cross-check against a plain 1/area computation in the matching system
      area = 0.05u"ha"
      @test expansionfactor(area) == inv(area)
      areaImperial = 0.2u"ac"
      @test expansionfactor(areaImperial) == inv(areaImperial)

      # referencearea also accepts an Area quantity directly, not just a length unit
      @test referencearea(1000.0u"m^2") == u"ha"
      @test referencearea(0.1u"ha") == u"ha"
      @test referencearea(0.1u"ac") == u"ac"
    end

    @testset "Reference Volume Tests" begin
      @test referencevolume(u"cm") == u"m^3"
      @test referencevolume(u"m") == u"m^3"
      @test referencevolume(u"inch") == u"ft^3"
      @test referencevolume(u"ft") == u"ft^3"
    end
end
