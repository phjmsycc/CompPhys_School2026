"""
時間発展から `Jx(t), Jy(t)` を得る教材用の標準ワークフローをまとめる。

# 引数
- `tb`: 2 バンド TB 模型のパラメータ `TBParams`

# キーワード引数
- `Nk`: k 空間メッシュ数
- `γ`: 散逸率
- `A0`, `ω0`: パルス振幅と角振動数
- `dt`: 時間刻み
- `fwhm_cycles`: パルス幅を基本周期で与える

# 戻り値
- `NamedTuple`: `ts`, `currents`, `pulse`, `dt` を含む

# 補足
`examples/02_timeevol_current.jl` 以降ではこの関数を入口にして、手順の重複を避けている。
"""
function simulate_currents(
    tb::TBParams;
    Nk::Integer=20,
    γ::Real=0.1,
    A0::Real=0.5,
    ω0::Real=0.7,
    dt::Real=0.01,
    fwhm_cycles::Real=5.0,
)
    dtf = Float64(dt)
    pulse = default_pulse(; A0=A0, ω0=ω0, fwhm_cycles=fwhm_cycles)
    kgrid = kgrid_rhombus(Nk)
    lcache = precompute_lindblad(kgrid, tb)
    ρ = ground_state_density(kgrid, tb)
    p = RHSParams(; kgrid=kgrid, tb=tb, pulse=pulse, lindblad=lcache, γ=Float64(γ))
    work = RK4Work(length(kgrid))

    tmin = pulse.t0 - 6 * pulse.σ
    tmax = pulse.t0 + 8 * pulse.σ
    nt = Int(floor((tmax - tmin) / dtf)) + 1

    ts = Vector{Float64}(undef, nt)
    Jx = Vector{Float64}(undef, nt)
    Jy = Vector{Float64}(undef, nt)

    for n in 1:nt
        t = tmin + (n - 1) * dtf
        ts[n] = t
        dHdk = dHdk_all(kgrid, tb, A(t, pulse))
        currents = current_traces(ρ, dHdk)
        Jx[n] = currents.x
        Jy[n] = currents.y

        if n < nt
            rk4_step!(ρ, p, t, dtf, work)
        end
    end

    return (ts=ts, currents=(x=Jx, y=Jy), pulse=pulse, dt=dtf)
end

"""
x, y の時間波形を同じ設定でスペクトル化する。

# 引数
- `currents`: `simulate_currents` が返す `currents = (x=..., y=...)`
- `dt`: 時間刻み
- `ω0`: 基本角振動数

# 戻り値
- `NamedTuple`: `x`, `y` 成分それぞれの HHG スペクトル

# 補足
両成分を同じ条件で FFT し、比較しやすい形にまとめて返す。
"""
function hhg_spectra(currents::NamedTuple{(:x, :y)}, dt, ω0)
    return (x=hhg_spectrum(currents.x, dt, ω0), y=hhg_spectrum(currents.y, dt, ω0))
end
