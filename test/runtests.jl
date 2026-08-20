using ForestFoundations
using DataFrames
using Test

@testset "ForestFoundations.jl" begin
    @testset "Basal Area Tests" begin
      dStandard = 30.0
      expectedBasalArea = 0.07068583470577035
      @test basalarea(dStandard) |> ustrip ≈ expectedBasalArea atol = 1e-6
      dZero = 0.0
      @test_throws DomainError basalarea(dZero)
      @test_throws DomainError basalarea(-dStandard)
    end

    @testset "Unit Conversion Tests" begin
      data = DataFrame(id=[1, 2], d=[30.0, 25.0]u"cm", v=[0.5, 0.3]u"m^3", note=["a", "b"])

      clean = removeunits(data)
      @test names(clean) == ["id", "d (cm)", "v (m^3)", "note"]
      @test clean[!, "d (cm)"] == [30.0, 25.0]
      @test clean[!, "v (m^3)"] == [0.5, 0.3]

      cleanNoRename = removeunits(data; renamecols=false)
      @test names(cleanNoRename) == names(data)
      @test cleanNoRename.d == [30.0, 25.0]

      restored = restoreunits(clean)
      @test restored.d == data.d
      @test restored.v == data.v
      @test names(restored) == ["id", "d", "v", "note"]
    end

    @testset "Reference Area and Expansion Factor Tests" begin
      # metric vs imperial reference area
      @test referencearea(u"cm") == u"ha"
      @test referencearea(u"m") == u"ha"
      @test referencearea(u"inch") == u"ac"
      @test referencearea(u"ft") == u"ac"

      # metric expansion factor: 500 m^2 plot -> 20 ha^-1 (10000 m^2 / 500 m^2)
      @test ustrip(uconvert(u"ha^-1", expansionfactor(u"cm", 500.0u"m^2"))) ≈ 20.0 atol = 1e-6
      @test ustrip(uconvert(u"ha^-1", expansionfactor(30.0u"cm", 500.0u"m^2"))) ≈ 20.0 atol = 1e-6
      @test ustrip(uconvert(u"ha^-1", expansionfactor([30.0, 25.0]u"cm", 500.0u"m^2"))) ≈ 20.0 atol = 1e-6

      # imperial expansion factor: 0.1 ac plot -> 10 ac^-1
      @test ustrip(uconvert(u"ac^-1", expansionfactor(u"inch", 0.1u"ac"))) ≈ 10.0 atol = 1e-6
      @test ustrip(uconvert(u"ac^-1", expansionfactor(12.0u"inch", 0.1u"ac"))) ≈ 10.0 atol = 1e-6

      # only the unit is used to detect the system; magnitude is irrelevant
      @test expansionfactor(1.0u"cm", 500.0u"m^2") == expansionfactor(999.0u"cm", 500.0u"m^2")

      # manual cross-check against a plain 1/area computation in the matching system
      area = 0.05u"ha"
      @test expansionfactor(u"cm", area) == inv(area)
      areaImperial = 0.2u"ac"
      @test expansionfactor(u"ft", areaImperial) == inv(areaImperial)

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

    @testset "withunit Tests" begin
      @test withunit(30.0, u"cm") == 30.0u"cm"
      @test withunit(30.0u"cm", u"cm") == 30.0u"cm"
      @test withunit([30.0, 25.0], u"cm") == [30.0, 25.0]u"cm"
      @test withunit([30.0, 25.0]u"cm", u"cm") == [30.0, 25.0]u"cm"
      @test withunit(nothing, u"cm") === nothing

      # a vector may mix in `missing`; each entry is promoted individually and
      # `missing` itself passes through untouched
      promoted = withunit([30.0, missing, 25.0], u"cm")
      @test isequal(promoted, [30.0u"cm", missing, 25.0u"cm"])
      alreadyUnitful = [30.0, missing, 25.0]u"cm"
      @test withunit(alreadyUnitful, u"cm") === alreadyUnitful
    end
end
