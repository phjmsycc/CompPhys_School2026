using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CairoMakie
using GrapheneHHG

outdir = joinpath(@__DIR__, "out")
mkpath(outdir)

# 与えた Δ について、時間発展から HHG スペクトルまでを一気に計算する。
# Δ = 0 と Δ ≠ 0 を同じ手順で比較できるように、
# パラメータ以外の流れを 1 つの関数にまとめてある。
function run_spectrum(Δ; Nk = 20, γ = 0.1, A0 = 0.5, ω0 = 0.7, dt = 0.02)
    result = simulate_currents(TBParams(t = 1.0, Δ = Δ); Nk = Nk, γ = γ, A0 = A0, ω0 = ω0, dt = dt)
    return hhg_spectra(result.currents, result.dt, result.pulse.ω0)
end

# Δ = 0 と Δ = 0.2 のスペクトルを同じ軸に重ね、
# 偶数次高調波の現れ方の違いを見やすくする。
function plot_selection_rule(sp0, spΔ)
    imax_x = min(findlast(<=(20.0), sp0.x.n), findlast(<=(20.0), spΔ.x.n))
    imax_y = min(findlast(<=(20.0), sp0.y.n), findlast(<=(20.0), spΔ.y.n))

    fig = Figure(size = (1100, 760))
    ax_x = Axis(fig[1, 1], title = "Selection rule from Jx", xlabel = "n = ω/ω0", ylabel = "log10 Power")
    lines!(ax_x, sp0.x.n[1:imax_x], log10.(sp0.x.power[1:imax_x] .+ 1e-20); linewidth = 2, label = "Δ=0.0")
    lines!(ax_x, spΔ.x.n[1:imax_x], log10.(spΔ.x.power[1:imax_x] .+ 1e-20); linewidth = 2, label = "Δ=0.2")
    axislegend(ax_x; position = :rt)

    ax_y = Axis(fig[2, 1], title = "Selection rule from Jy", xlabel = "n = ω/ω0", ylabel = "log10 Power")
    lines!(ax_y, sp0.y.n[1:imax_y], log10.(sp0.y.power[1:imax_y] .+ 1e-20); linewidth = 2, label = "Δ=0.0")
    lines!(ax_y, spΔ.y.n[1:imax_y], log10.(spΔ.y.power[1:imax_y] .+ 1e-20); linewidth = 2, label = "Δ=0.2")
    axislegend(ax_y; position = :rt)
    return fig
end

# 反転対称な場合と破った場合を比較して、選択則の違いを見る。
sp0 = run_spectrum(0.0)
spΔ = run_spectrum(0.2)

fig = plot_selection_rule(sp0, spΔ)

# 比較図をそのまま保存して講義資料で使える形にする。
outfile = joinpath(outdir, "04_selection_rule.png")
save(outfile, fig)
println("saved: $outfile")
