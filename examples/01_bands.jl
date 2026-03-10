using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CairoMakie
using GrapheneHHG
using LinearAlgebra

# 六角形 BZ を埋める曲面座標を作る。
# 極座標に近い形で中心から外へ広げることで、
# 3D surface 描画でも六角形の輪郭を保ちやすくする。
function hex_surface_coordinates(x0::Real; n::Int=6, radial_steps::Int=15, F::Int=200)
    resolution = n * radial_steps
    theta = range(0, 2 * pi, length=resolution + 1)
    r = range(0.0, x0, length=resolution + 1)

    C = [1 + n * f for f in (-F÷2):(F÷2)]
    R = [sum((1 / c^2) * cis(c * th) for c in C) for th in theta]
    ratio = sum(1 / c^2 for c in C)

    kx = [rr * real(RR) / ratio for rr in r, RR in R]
    ky = [rr * imag(RR) / ratio for rr in r, RR in R]

    return kx, ky
end

# 各 (kx, ky) で 2 バンドハミルトニアンの固有値を取り、
# 価電子帯と伝導帯のエネルギー面を返す。
# 可視化では 2 本のバンドを別々の surface として描く。
function band_surfaces(kx::AbstractMatrix{<:Real}, ky::AbstractMatrix{<:Real}, tb::TBParams)
    size(kx) == size(ky) || throw(ArgumentError("kx and ky must have the same size"))

    ev = Matrix{Float64}(undef, size(kx)...)
    ec = similar(ev)

    for I in CartesianIndices(kx)
        vals = eigvals(Hermitian(Matrix(H(Point2f(kx[I], ky[I]), tb))))
        ev[I] = minimum(vals)
        ec[I] = maximum(vals)
    end

    return ev, ec
end

outdir = joinpath(@__DIR__, "out")
mkpath(outdir)

# モデルと BZ 形状の設定を先に作る。
tb = TBParams(t=1.0, Δ=0.0)

verts = hex_vertices(b1, b2)
x0 = maximum(norm(v) for v in verts)
kx, ky = hex_surface_coordinates(x0)
ev, ec = band_surfaces(kx, ky, tb)
ground = zeros(size(ec))

# 基準面、伝導帯、価電子帯を重ねて描く。
fig = Figure(size=(1200, 800))
ax = Axis3(
    fig[1, 1],
    viewmode=:fitzoom,
    azimuth=15 * pi / 180,
    elevation=13 * pi / 180,
    aspect=(1, 1, 1),
)
# hidedecorations!(ax)
# hidespines!(ax)

surface!(ax, kx, ky, ev; shininess=Float32(5.0), colormap=Reverse(:Blues))
surface!(ax, kx, ky, ground; shininess=Float32(5.0), colormap=(:Greys, 0.3))
surface!(ax, kx, ky, ec; shininess=Float32(5.0), colormap=(:Oranges, 1.0))

# 生成した図は教材用の出力ディレクトリへ保存する。
outfile = joinpath(outdir, "01_bands.png")
save(outfile, fig)
println("saved: $outfile")
