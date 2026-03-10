# 時間依存電流 J(t) から HHG スペクトルを作る。
# 全時間領域をそのまま使い、DC 成分を引いてから FFTW.jl の rfft 関数を用いて FFT し、
# 出力は 周波数 ω, 高調波次数 n = ω / ω0, FFT強度 power=amplitude^2 で返す。
function hhg_spectrum(Jt, dt, ω0)
    throw(ErrorException("TODO(student): implement hhg_spectrum(Jt, dt, ω0) in src/fft.jl"))
end
