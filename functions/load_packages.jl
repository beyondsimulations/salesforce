# Load the neccessary packages
using CSV
using DataFrames
using DelimitedFiles
using JuMP
using GAMS
using Random
using Shapefile
using Plots
using Statistics
using Gurobi
using Suppressor

# include all neccessary functions
include("preparation_functions.jl")
include("profit_functions.jl")
include("plot_functions.jl")
include("prepare_output.jl")
include("district_optimisation.jl")
include("heuristic_exchange.jl")