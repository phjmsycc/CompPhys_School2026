using LinearAlgebra
using Test

# GKSL 右辺と Lindblad キャッシュが、密度行列として重要な性質を
# 保つように作られているかを確認する。
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

    # GKSL 方程式はトレース保存かつ Hermitian 性保存であるべきなので、
    # dρ/dt もその条件を満たすことを確かめる。
    for i in eachindex(dρ)
        @test abs(tr(dρ[i])) ≤ 1e-10
        @test norm(dρ[i] - dρ[i]') ≤ 1e-10
    end

    # L^†L は |c_k><c_k| に対応する射影になっているはずである。
    for LdL in cache.LdL
        @test norm(LdL * LdL - LdL) ≤ 1e-10
        @test norm(LdL - LdL') ≤ 1e-10
    end
end
