# TBParams は 2 バンドグラフェン模型の定数をまとめる。
# t はホッピング、Δ はスタガードポテンシャルである。
Base.@kwdef struct TBParams{T<:Real}
    t::T = 1.0
    Δ::T = 0.0
    dvecs::NTuple{3,Vec2} = NN_VECTORS
end

# ハミルトニアンの非対角要素 f(k) = Σ_j exp(i k・d_j) を計算する。
function f(k, dvecs::NTuple{3,Vec2}=NN_VECTORS)::ComplexF64
    fk = 0.0 + 0.0im
    for d in dvecs
        fk += cis(dot(k, d)) # cis(θ) = exp(iθ)
    end
    return fk
end

# 勾配 ∂f/∂k を計算する。
# 電流演算子や dH/dk を作るときに必要になるので、
# x, y 成分をまとめた 2 成分ベクトルで返す。
function dfdk(k, dvecs::NTuple{3,Vec2}=NN_VECTORS)::SVector{2,ComplexF64}
    dfdx = 0.0 + 0.0im
    dfdy = 0.0 + 0.0im
    for d in dvecs
        phase = cis(dot(k, d))
        dfdx += im * d[1] * phase
        dfdy += im * d[2] * phase
    end
    return SVector{2,ComplexF64}(dfdx, dfdy)
end

# 2 バンド TB ハミルトニアン H(k) を組み立てる。
# 対角成分 ±Δ が副格子非対称性を表し、
# 非対角成分 -t f(k) が最近接ホッピングに対応する。
# 2x2 行列を SMatrix で返す。
function H(k, p::TBParams)::CMat2S
    fk = f(k, p.dvecs)
    return @SMatrix ComplexF64[
        p.Δ -p.t*fk
        -p.t*conj(fk) -p.Δ
    ]
end

# ハミルトニアンの波数微分 dH/dk_x, dH/dk_y を返す。
# 2x2 行列を SMatrix の Tuple で返す。
function dHdk(k, p::TBParams)::Tuple{CMat2S,CMat2S}
    dfd = dfdk(k, p.dvecs)
    dHdkx = @SMatrix ComplexF64[
        0.0 -p.t*dfd[1]
        -p.t*conj(dfd[1]) 0.0
    ]
    dHdky = @SMatrix ComplexF64[
        0.0 -p.t*dfd[2]
        -p.t*conj(dfd[2]) 0.0
    ]
    return dHdkx, dHdky
end
