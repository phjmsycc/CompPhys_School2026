# 各 k 点で使う Lindblad 演算子 L_k と L_k^† L_k を保持する。
# 時間発展のたびに固有分解を繰り返さずに済むよう、
# 事前計算した結果をまとめてキャッシュする。
struct LindbladCache{T<:AbstractVector{<:AbstractMatrix{<:Complex}}}
    L::T
    LdL::T
end

# A = 0 のハミルトニアンから価電子帯 |v_k> と伝導帯 |c_k> を取り、
# L_k = |v_k><c_k| を各 k 点で前計算する。
function precompute_lindblad(kgrid, p::TBParams)::LindbladCache
    Ls = Vector{CMat2S}(undef, length(kgrid))
    LdLs = Vector{CMat2S}(undef, length(kgrid))

    for (i, k) in pairs(kgrid)
        decomp = eigen(Hermitian(Matrix(H(k, p))))
        evals = decomp.values
        evecs = decomp.vectors
        iv = argmin(evals)
        ic = argmax(evals)

        vket = @view evecs[:, iv]
        cket = @view evecs[:, ic]
        Lmat = vket * cket'
        Ls[i] = CMat2S(Lmat)
        LdLs[i] = Ls[i]' * Ls[i]
    end

    return LindbladCache(Ls, LdLs)
end

# 各 k 点の基底状態密度行列 ρ_k(0) = |v_k><v_k| を作る。
# 時間発展はこの初期条件から始め、
# パルスと散逸でどのように変化するかを追う。
function ground_state_density(kgrid, p::TBParams)
    ρ = [
        CMat2(0.0 + 0.0im, 0.0 + 0.0im, 0.0 + 0.0im, 0.0 + 0.0im) for _ in eachindex(kgrid)
    ]

    for (i, k) in pairs(kgrid)
        decomp = eigen(Hermitian(Matrix(H(k, p))))
        evals = decomp.values
        evecs = decomp.vectors
        iv = argmin(evals)
        vket = @view evecs[:, iv]
        proj = vket * vket'
        ρ[i] .= proj
    end

    return ρ
end
