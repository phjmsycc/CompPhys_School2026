using LinearAlgebra
using Test

@testset "GKSL properties" begin
    Nk = 4
    kgrid = kgrid_rhombus(Nk)
    tb = TBParams(; t=1.0, Δ=0.1)
    pulse = default_pulse(; A0=0.3, ω0=0.7, fwhm_cycles=5.0)

    cache = precompute_lindblad(kgrid, tb)
    ρ = ground_state_density(kgrid, tb)
    dρ = zero_state(length(kgrid))

    p = RHSParams(; kgrid=kgrid, tb=tb, pulse=pulse, lindblad=cache, γ=0.1)
    rhs!(dρ, ρ, p, 0.0)

    for i in eachindex(dρ)
        # ここを実装（トレース保存・エルミート性）
        throw(ErrorException("TODO(student): add trace/Hermitian tests in test/test_gksl.jl"))
    end

    for LdL in cache.LdL
        # ここを実装（L^\dagger Lは射影演算子？）
        throw(ErrorException("TODO(student): add projector tests in test/test_gksl.jl"))
    end
end
