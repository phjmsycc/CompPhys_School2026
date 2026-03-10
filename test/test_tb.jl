using LinearAlgebra
using Test

@testset "TB validity" begin
    tb0 = TBParams(t=1.0, Δ=0.0)
    tbΔ = TBParams(t=1.0, Δ=0.2)

    for k in kgrid_rhombus(6)
        Hk = H(k, tbΔ)
        # ここを実装
        throw(ErrorException("TODO(student): add Hermitian test in test/test_tb.jl"))
    end

    for k in kgrid_rhombus(6)
        vals = eigvals(Hermitian(Matrix(H(k, tb0))))
        # ここを実装
        throw(ErrorException("TODO(student): add ±E symmetry test in test/test_tb.jl"))
    end

    K = GrapheneHHG.Vec2(2 * pi / (3 * sqrt(3)), 2 * pi / 3)
    valsK = eigvals(Hermitian(Matrix(H(K, tb0))))
    # ここを実装
    throw(ErrorException("TODO(student): add K-point gapless test in test/test_tb.jl"))
end
