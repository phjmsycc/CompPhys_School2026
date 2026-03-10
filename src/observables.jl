# 1 つの k 点での電流成分 Re tr(ρ dH/dk) を計算する。
# 2 バンド模型では 2x2 行列のトレースを取ればよい。
_current_component(
    ρk::AbstractMatrix{<:Complex}, dHdk::AbstractMatrix{<:Complex}
)::Float64 = real(tr(ρk * dHdk))

# k 点ごとの状態配列と dH/dk 配列の長さがそろっているか確認する。
# 観測量の平均は同じ k メッシュ上でしか意味を持たないので、
# 長さ不一致は早めに例外にする。
function _validate_current_inputs(
    ρ::AbstractVector{<:AbstractMatrix{<:Complex}},
    dHdkx::AbstractVector{<:AbstractMatrix{<:Complex}},
    dHdky::AbstractVector{<:AbstractMatrix{<:Complex}},
)::Nothing
    length(ρ) == length(dHdkx) || throw(ArgumentError("ρ and dHdkx length mismatch"))
    length(ρ) == length(dHdky) || throw(ArgumentError("ρ and dHdky length mismatch"))
    return nothing
end

# k 点ごとの電流を足し合わせ、BZ 平均した Jx, Jy を返す。
# dHdk は NamedTuple(x=..., y=...) として受け取り、
# 呼び出し側で成分を取り違えにくい形にしている。
function current_traces(
    ρ::AbstractVector{<:AbstractMatrix{<:Complex}}, dHdk::NamedTuple{(:x, :y)}
)
    _validate_current_inputs(ρ, dHdk.x, dHdk.y)

    total_x = 0.0
    total_y = 0.0
    @inbounds for i in eachindex(ρ)
        total_x += _current_component(ρ[i], dHdk.x[i])
        total_y += _current_component(ρ[i], dHdk.y[i])
    end

    scale = inv(length(ρ))
    return (x=total_x * scale, y=total_y * scale)
end

# 各 k 点で dH/dk_x, dH/dk_y をまとめて前計算する。
# 観測量は時刻ごとに何度も使うので、
# Peierls シフト後の k + A をここで一括処理すると見通しがよい。
function dHdk_all(kgrid, tb::TBParams, Avec::Vec2=Vec2(0.0, 0.0))
    out_x = Vector{CMat2S}(undef, length(kgrid))
    out_y = Vector{CMat2S}(undef, length(kgrid))
    @inbounds for i in eachindex(kgrid)
        dHdkx, dHdky = dHdk(kgrid[i] + Avec, tb)
        out_x[i] = dHdkx
        out_y[i] = dHdky
    end
    return (x=out_x, y=out_y)
end
