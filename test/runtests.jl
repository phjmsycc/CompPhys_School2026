using Test
using GrapheneHHG

# 講義で扱う主要な機能を、TB・GKSL・観測量の順に検証する。
include("test_tb.jl")
include("test_gksl.jl")
include("test_observables.jl")
# include("test_fft.jl")
# include("test_workflows.jl")
