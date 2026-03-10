# 最近接ベクトル d_j
const d1 = Vec2(0.0, 1.0)
const d2 = Vec2(sqrt(3) / 2, -0.5)
const d3 = Vec2(-sqrt(3) / 2, -0.5)
const NN_VECTORS = (d1, d2, d3)

# 逆格子ベクトル b_1, b_2 は a_i ・ b_j = 2π δ_ij を満たす。
# k 空間メッシュや六角形 BZ の頂点計算はこの 2 本から作る。
const b1 = Vec2(2 * sqrt(3) * pi / 3, 2 * pi / 3)
const b2 = Vec2(-2 * sqrt(3) * pi / 3, 2 * pi / 3)

# 逆格子のひし形上に Nk x Nk 個の k 点を並べる。
function kgrid_rhombus(Nk::Integer)::Vector{Vec2}
    Nk > 0 || throw(ArgumentError("Nk must be positive"))

    u = (0:(Nk - 1)) ./ Nk
    v = (0:(Nk - 1)) ./ Nk

    grid = Vector{Vec2}(undef, Nk * Nk)
    idx = 1

    for uu in u, vv in v
        grid[idx] = uu * b1 + vv * b2
        idx += 1
    end

    return grid
end

# 六角形 BZ の 6 頂点を K 点から組み立てて返す。
# 描画で多角形として使いやすいように、偏角で並べ替えて順序をそろえる。
function hex_vertices(b1v, b2v)::Vector{Vec2}
    K1 = (b1v - b2v) / 3
    K2 = (2 * b1v + b2v) / 3
    K3 = (b1v + 2 * b2v) / 3

    verts = Vec2[K1, K2, K3, -K1, -K2, -K3]
    order = sortperm(verts; by=v -> atan(v[2], v[1]))
    return verts[order]
end
