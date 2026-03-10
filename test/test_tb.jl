using LinearAlgebra
using Test

# TB ハミルトニアンが満たす基本的な対称性を確認する。
# まず Hermitian 性を、次に Δ = 0 のときの固有値対称性を確かめる。
# あわせて K 点で gapless になることも確認する。
@testset "TB validity" begin
    tb0 = TBParams(t=1.0, Δ=0.0)
    tbΔ = TBParams(t=1.0, Δ=0.2)

    # 物理的に観測可能なハミルトニアンであるため、常に Hermitian である。
    for k in kgrid_rhombus(6)
        Hk = H(k, tbΔ)
        @test norm(Hk - Hk') ≤ 1e-12
    end

    # Δ = 0 では粒子・正孔対称性により、固有値が ±E の組になる。
    for k in kgrid_rhombus(6)
        vals = eigvals(Hermitian(Matrix(H(k, tb0))))
        @test isapprox(minimum(vals), -maximum(vals); atol=1e-12)
    end

    # Δ = 0 では K 点で gapless になり、Dirac cone が閉じる。
    K = GrapheneHHG.Vec2(2 * pi / (3 * sqrt(3)), 2 * pi / 3)
    valsK = eigvals(Hermitian(Matrix(H(K, tb0))))
    @test maximum(abs.(valsK)) ≤ 1e-12
end
