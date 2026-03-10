using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CairoMakie
using GrapheneHHG

outdir = joinpath(@__DIR__, "out")
mkpath(outdir)

# まず Δ = 0 のグラフェンについて時間波形を作り、その後 FFT する。
result = simulate_currents(TBParams(t = 1.0, Δ = 0.0); Nk = 20, γ = 0.1, A0 = 0.5, ω0 = 0.7, dt = 0.02)
spectra = hhg_spectra(result.currents, result.dt, result.pulse.ω0)

imax_x = findlast(<=(12.0), spectra.x.n)
imax_y = findlast(<=(12.0), spectra.y.n)
xpower = log10.(spectra.x.power[1:imax_x] .+ 1e-20)
ypower = log10.(spectra.y.power[1:imax_y] .+ 1e-20)

# x, y 成分のスペクトルを上下に並べて保存する。
fig = Figure(size = (1100, 760))
ax_x = Axis(
    fig[1, 1],
    title = "HHG Spectrum from Jx",
    xlabel = "n = ω/ω0",
    ylabel = "log10 Power",
    xticks = 0:1:12,
)
lines!(ax_x, spectra.x.n[1:imax_x], xpower; linewidth = 2)
xlims!(ax_x, 0, 12)
ylims!(ax_x, -10, max(maximum(xpower), -10))

ax_y = Axis(
    fig[2, 1],
    title = "HHG Spectrum from Jy",
    xlabel = "n = ω/ω0",
    ylabel = "log10 Power",
    xticks = 0:1:12,
)
lines!(ax_y, spectra.y.n[1:imax_y], ypower; linewidth = 2)
xlims!(ax_y, 0, 12)

outfile = joinpath(outdir, "03_hhg_fft.png")
save(outfile, fig)
println("saved: $outfile")
