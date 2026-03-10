# RHSParams は GKSL 方程式の右辺を作るための入力をまとめる。
# k 点、TB ハミルトニアン、パルス、Lindblad キャッシュ、散逸率 γ を
# ひとまとまりにして rhs! へ渡す。
Base.@kwdef struct RHSParams
    kgrid::Vector{Vec2}
    tb::TBParams
    pulse::PulseParams
    lindblad::LindbladCache
    γ::Float64 = 0.1
end

# 密度行列の時間微分や RK4 の作業配列を初期化するために、
# k 点ごとの 2x2 複素行列を 0 で埋めたベクトルを返す。
function zero_state(nk::Integer)
    nk > 0 || throw(ArgumentError("nk must be positive"))
    return [CMat2(0.0 + 0.0im, 0.0 + 0.0im, 0.0 + 0.0im, 0.0 + 0.0im) for _ in 1:nk]
end

# ハミルトニアン由来の時間発展 -i [H, ρ] を dρ に書き込む。
# 量子力学的な可逆時間発展の部分だけを切り出した関数である。
function commutator!(
    dρ::AbstractMatrix{<:Complex},
    Hk::AbstractMatrix{<:Complex},
    ρk::AbstractMatrix{<:Complex},
)::Nothing
    dρ .= -im .* (Hk * ρk - ρk * Hk)
    return nothing
end

# GKSL の散逸項 γ(LρL^† - 1/2 {L^†L, ρ}) を dρ に加える。
# commutator! の結果に足し込む実装にしているので、
# ここでは .= ではなく .+= を使っている。
function dissipator!(
    dρ::AbstractMatrix{<:Complex},
    ρk::AbstractMatrix{<:Complex},
    Lk::AbstractMatrix{<:Complex},
    LdLk::AbstractMatrix{<:Complex},
    γ,
)::Nothing
    dρ .+= γ .* (Lk * ρk * adjoint(Lk) .- 0.5 .* (LdLk * ρk + ρk * LdLk))
    return nothing
end

# 各 k 点について GKSL 方程式の右辺 dρ/dt をまとめて計算する。
# パルスで決まる A(t) に応じて k を k + eA(t) にずらし、
# その時刻の H(k + eA) で可換子項を作ってから散逸項を加える。
function rhs!(
    dρ::AbstractVector{<:AbstractMatrix{<:Complex}},
    ρ::AbstractVector{<:AbstractMatrix{<:Complex}},
    p::RHSParams,
    t::Float64,
)::Nothing
    length(dρ) == length(ρ) || throw(ArgumentError("dρ and ρ must have same length"))
    length(ρ) == length(p.kgrid) || throw(ArgumentError("state and kgrid length mismatch"))

    At = A(t, p.pulse)

    @inbounds for i in eachindex(ρ)
        # Peierls 置換に従って、その時刻のベクトルポテンシャル分だけ
        # 運動量を平行移動したハミルトニアンを使う。
        kshift = p.kgrid[i] + At
        Hk = H(kshift, p.tb)
        commutator!(dρ[i], Hk, ρ[i])
        dissipator!(dρ[i], ρ[i], p.lindblad.L[i], p.lindblad.LdL[i], p.γ)
    end

    return nothing
end
