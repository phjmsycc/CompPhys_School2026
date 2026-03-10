using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CairoMakie
using GrapheneHHG

outdir = joinpath(@__DIR__, "out")
mkpath(outdir)

# モデルと時間発展の標準設定から Jx(t), Jy(t) をまとめて計算する。
result = simulate_currents(TBParams(t = 1.0, Δ = 0.0); Nk = 20, γ = 0.1, A0 = 0.5, ω0 = 0.7, dt = 0.02)

# x, y 成分を上下に並べて保存し、後の FFT 例と見比べやすくする。
fig = Figure(size = (1100, 760))
ax_x = Axis(fig[1, 1], title = "Current Jx(t)", xlabel = "t", ylabel = "Jx")
lines!(ax_x, result.ts, result.currents.x; linewidth = 2)

ax_y = Axis(fig[2, 1], title = "Current Jy(t)", xlabel = "t", ylabel = "Jy")
lines!(ax_y, result.ts, result.currents.y; linewidth = 2)

outfile = joinpath(outdir, "02_timeevol_current.png")
save(outfile, fig)
println("saved: $outfile")
