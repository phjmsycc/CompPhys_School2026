using LinearAlgebra
using Test

# 観測量まわりでは、dH/dk の一括計算と
# 電流の集計関数が互いに整合していることを確認する。
@testset "Observables" begin
    tb = TBParams(; t=1.0, Δ=0.1)
    kgrid = kgrid_rhombus(4)
    ρ = ground_state_density(kgrid, tb)
    Avec = GrapheneHHG.Vec2(0.2, -0.1)

    dH_all = dHdk_all(kgrid, tb, Avec)
    dH_first = dHdk(kgrid[1] + Avec, tb)

    # dHdk_all は各 k 点で dHdk を呼んだ結果と一致するべきである。
    @test dH_all.x[1] == dH_first[1]
    @test dH_all.y[1] == dH_first[2]

    # x, y をまとめた集計が、定義式をそのまま実装した値と一致することを確認する。
    traces = current_traces(ρ, dH_all)
    expected_x = sum(real(tr(ρ[i] * dH_all.x[i])) for i in eachindex(ρ)) / length(ρ)
    expected_y = sum(real(tr(ρ[i] * dH_all.y[i])) for i in eachindex(ρ)) / length(ρ)
    @test traces.x == expected_x
    @test traces.y == expected_y

    # k 点数がそろっていない入力は、誤った平均を避けるため例外にする。
    @test_throws ArgumentError current_traces(ρ[1:(end - 1)], dH_all)
    @test_throws ArgumentError current_traces(ρ, (x=dH_all.x[1:(end - 1)], y=dH_all.y))
    @test_throws ArgumentError current_traces(ρ, (x=dH_all.x, y=dH_all.y[1:(end - 1)]))
end
