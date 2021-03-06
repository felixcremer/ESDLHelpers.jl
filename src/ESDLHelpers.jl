module ESDLHelpers

using ESDL
using YAXArrays
using Statistics
using RecurrenceAnalysis
using DataStructures
using StatsBase:skewness, kurtosis, mad
using EmpiricalModeDecomposition; const EMD=EmpiricalModeDecomposition
using LombScargle



export timestats, lombscargle, tslength

include("tsanalysis.jl")
include("shapesampling.jl")

include("gdalcubes.jl")




end # module
