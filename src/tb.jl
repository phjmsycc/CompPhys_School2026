# TBParams は 2 バンドグラフェン模型の定数をまとめる。
# t はホッピング、Δ はスタガードポテンシャルである。
Base.@kwdef struct TBParams{T<:Real}
    t::T = 1.0
    Δ::T = 0.0
    dvecs::NTuple{3,Vec2} = NN_VECTORS
end

# ハミルトニアンの非対角要素 f(k) = Σ_j exp(i k・d_j) を計算する。
function f(k, dvecs::NTuple{3,Vec2}=NN_VECTORS)::ComplexF64
    throw(ErrorException("TODO(student): implement f(k, dvecs) in src/tb.jl"))
end

# 勾配 ∂f/∂k を計算する。
# 電流演算子や dH/dk を作るときに必要になるので、
# x, y 成分をまとめた 2 成分ベクトルで返す。
function dfdk(k, dvecs::NTuple{3,Vec2}=NN_VECTORS)::SVector{2,ComplexF64}
    throw(ErrorException("TODO(student): implement dfdk(k, dvecs) in src/tb.jl"))
end

# 2 バンド TB ハミルトニアン H(k) を組み立てる。
# 対角成分 ±Δ が副格子非対称性を表し、
# 非対角成分 -t f(k) が最近接ホッピングに対応する。
# 2x2 行列を SMatrix で返す。
function H(k, p::TBParams)::CMat2S
    throw(ErrorException("TODO(student): implement H(k, p) in src/tb.jl"))
end

# ハミルトニアンの波数微分 dH/dk_x, dH/dk_y を返す。
# 2x2 行列を SMatrix の Tuple で返す。
function dHdk(k, p::TBParams)::Tuple{CMat2S,CMat2S}
    throw(ErrorException("TODO(student): implement dHdk(k, p) in src/tb.jl"))
end
