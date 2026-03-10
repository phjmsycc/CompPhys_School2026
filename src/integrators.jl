# RK4Work は 4 次の Runge-Kutta 法で使う中間傾き
# k1, k2, k3, k4 と、一時的な状態 tmp を保持する。
# 配列を使い回すことで、各ステップの確保を減らしている。
struct RK4Work
    k1::Vector{CMat2}
    k2::Vector{CMat2}
    k3::Vector{CMat2}
    k4::Vector{CMat2}
    tmp::Vector{CMat2}
end

# k 点数だけ分かっていれば、RK4 の作業配列を一式用意できる。
RK4Work(nk::Integer) = RK4Work(zero_state(nk), zero_state(nk), zero_state(nk), zero_state(nk), zero_state(nk))

# 既存の状態ベクトル ρ と同じ長さから作業配列を作る簡略版である。
RK4Work(ρ::AbstractVector) = RK4Work(length(ρ))

# 1 ステップぶんの 4 次 Runge-Kutta 積分を行う。
# 各 k_i は右辺 rhs! を異なる中間時刻・中間状態で評価したもので、
# 最後に (k1 + 2k2 + 2k3 + k4) / 6 を足して ρ を更新する。
function rk4_step!(ρ::AbstractVector{<:AbstractMatrix{<:Complex}}, p::RHSParams, t, dt, work::RK4Work)::Nothing
    rhs!(work.k1, ρ, p, Float64(t))

    @inbounds for i in eachindex(ρ)
        # ρ(t + dt/2) を k1 から予測して 2 本目の傾きを作る。
        work.tmp[i] .= ρ[i] .+ (0.5 * dt) .* work.k1[i]
    end
    rhs!(work.k2, work.tmp, p, Float64(t + 0.5 * dt))

    @inbounds for i in eachindex(ρ)
        # 今度は k2 を使って、同じ中間時刻の別近似を作る。
        work.tmp[i] .= ρ[i] .+ (0.5 * dt) .* work.k2[i]
    end
    rhs!(work.k3, work.tmp, p, Float64(t + 0.5 * dt))

    @inbounds for i in eachindex(ρ)
        # k3 から終点 t + dt の予測状態を作る。
        work.tmp[i] .= ρ[i] .+ dt .* work.k3[i]
    end
    rhs!(work.k4, work.tmp, p, Float64(t + dt))

    c = dt / 6
    @inbounds for i in eachindex(ρ)
        ρ[i] .+= c .* (work.k1[i] .+ 2 .* work.k2[i] .+ 2 .* work.k3[i] .+ work.k4[i])
    end

    return nothing
end
