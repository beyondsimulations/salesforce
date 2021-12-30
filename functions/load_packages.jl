# Load the neccessary packages
using CSV
using DataFrames
using DelimitedFiles
using JuMP
using GAMS
using Random
using Shapefile
using Plots

# include all neccessary functions
include("preparation_functions.jl")
include("profit_functions.jl")
include("plot_functions.jl")
include("prepare_output.jl")
include("opti_salesforce1.jl")
include("opti_salesforce2.jl")
include("district_optimisation.jl")