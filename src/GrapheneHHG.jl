module GrapheneHHG

using FFTW
using LinearAlgebra
using StaticArrays
using Statistics

# 講義で扱うベクトルや 2x2 複素行列を、毎回同じ形で使えるように
# 型エイリアスとして先にまとめておく。
const Vec2 = SVector{2,Float64}
const CMat2 = MMatrix{2,2,ComplexF64,4}
const CMat2S = SMatrix{2,2,ComplexF64,4}

# このモジュールでは、格子の定義から始めて
# パルス・ハミルトニアン・散逸・時間積分・観測量・FFT の順に
# 受講者が流れを追えるようにファイルを読み込む。
include("lattice.jl")
include("pulse.jl")
include("tb.jl")
include("lindblad.jl")
include("rhs.jl")
include("integrators.jl")
include("observables.jl")
include("fft.jl")
include("workflows.jl")

export d1, d2, d3, b1, b2, NN_VECTORS
export kgrid_rhombus, hex_vertices

export PulseParams, default_pulse, A, E

export TBParams, f, dfdk, H, dHdk

export LindbladCache, precompute_lindblad, ground_state_density

export RHSParams, zero_state, commutator!, dissipator!, rhs!
export RK4Work, rk4_step!

export current_traces, dHdk_all

export hhg_spectrum
export simulate_currents, hhg_spectra

end
