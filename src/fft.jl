# 時間依存電流 J(t) から HHG スペクトルを作る。
# 全時間領域をそのまま使い、DC 成分を引いてから FFTW.jl の rfft 関数を用いて FFT し、
# 出力は 周波数 ω, 高調波次数 n = ω / ω0, FFT強度 power=amplitude^2 で返す。
function hhg_spectrum(Jt, dt, ω0)
    dt > 0 || throw(ArgumentError("dt must be positive"))
    ω0 > 0 || throw(ArgumentError("ω0 must be positive"))

    signal = Float64.(collect(Jt))
    # 平均値は 0 次成分として強く出るので、先に除いておく。
    signal .-= mean(signal)

    spectrum = fft(signal)

    npos = fld(length(signal), 2) + 1
    ω = (2 * pi / (length(signal) * dt)) .* collect(0:(npos - 1))
    n = ω ./ ω0
    amplitude = abs.(spectrum[1:npos])
    power = amplitude .^ 2

    return (n=n, power=power, ω=ω, amplitude=amplitude)
end
