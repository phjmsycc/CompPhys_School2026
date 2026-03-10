"""
パルスの振幅・角振動数・中心時刻・包絡幅をまとめる。

# フィールド
- `A0`: ベクトルポテンシャルの振幅
- `ω0`: キャリア角振動数
- `t0`: パルス中心時刻
- `σ`: ガウシアン包絡の幅

# 補足
ここでの `A(t)` は x 軸方向の直線偏光に固定している。
"""
Base.@kwdef struct PulseParams{T<:Real}
    A0::T = 0.125
    ω0::T = 0.4
    t0::T = 0.0
    σ::T = 1.0
end

"""
授業で使う既定のガウシアンパルスを作る。

# キーワード引数
- `A0`: ベクトルポテンシャルの振幅
- `ω0`: キャリア角振動数
- `t0`: パルス中心時刻
- `fwhm_cycles`: パルス幅を基本周期 `T0 = 2π / ω0` の何倍かで与える

# 戻り値
- `PulseParams`: `FWHM -> σ` 変換後のパラメータ

# 補足
講義では `fwhm_cycles = 5.0` を既定値にし、ガウシアン包絡つきパルスを標準設定として使う。
"""
function default_pulse(; A0::Real=0.5, ω0::Real=0.7, t0::Real=0.0, fwhm_cycles::Real=5.0)
    T0 = 2 * pi / ω0
    σ = fwhm_cycles * T0 / (2 * sqrt(2 * log(2)))
    return PulseParams(A0, ω0, t0, σ)
end

"""
ベクトルポテンシャル `A(t)` を返す。

# 引数
- `t`: 評価時刻
- `p`: パルス形状を表す `PulseParams`

# 戻り値
- `Vec2`: `(A_x(t), A_y(t))`

# 補足
x 成分には cos キャリアつきガウシアン包絡を入れ、`A_y(t) = 0` とする。
"""
function A(t::T, p::PulseParams)::Vec2 where {T<:Real}
    τ = t - p.t0
    env = exp(-(τ^2) / (2 * p.σ^2))
    ax = p.A0 * cos(p.ω0 * τ) * env
    return Vec2(ax, zero(T))
end
