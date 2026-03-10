using Test

@testset "FFT helpers" begin
    signal = [1.0, -1.0, 1.0, -1.0]
    spectrum = hhg_spectrum(signal, 0.5, pi)

    @test length(spectrum.n) == length(spectrum.power)
    @test length(spectrum.n) == length(spectrum.ω)
    @test length(spectrum.n) == length(spectrum.amplitude)
    @test length(spectrum.n) == fld(length(signal), 2) + 1
    @test spectrum.n[1] == 0.0
    @test spectrum.n[2] == 1.0

    @test_throws ArgumentError hhg_spectrum(signal, 0.0, pi)
    @test_throws ArgumentError hhg_spectrum(signal, 0.5, 0.0)
end
