using Test

# examples で使う標準ワークフローが、最小設定でも整合した出力を返すか確認する。
@testset "Workflow helpers" begin
    result = simulate_currents(TBParams(t = 1.0, Δ = 0.0); Nk = 3, γ = 0.1, A0 = 0.3, ω0 = 0.7, dt = 0.5, fwhm_cycles = 2.0)

    @test length(result.ts) == length(result.currents.x)
    @test length(result.ts) == length(result.currents.y)
    @test result.dt == 0.5
    @test length(result.ts) > 1

    spectra = hhg_spectra(result.currents, result.dt, result.pulse.ω0)

    @test length(spectra.x.n) == length(spectra.x.power)
    @test length(spectra.y.n) == length(spectra.y.power)
    @test spectra.x.n[1] == 0.0
    @test spectra.y.n[1] == 0.0
    @test length(spectra.x.n) == fld(length(result.currents.x), 2) + 1
    @test length(spectra.y.n) == fld(length(result.currents.y), 2) + 1
end
