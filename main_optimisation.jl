# Load all neccessary packages and functions
import Pkg
Pkg.activate("salesforce")
include("functions/load_packages.jl")
print("\n\n All neccessary functions are loaded.")

# Choose the marginal profit (mp = 0 for optimal profit)
    mp          = 0.00::Float64

# Choose the parameters of the salesforcemodel
    hexsize     = "msc2014"::String          # size of the hexagons (30, 40, 50, 60)
    h           = 30.0::Float64      # cost per hour of travel time
    g           = 50.0::Float64      # cost per worker per hour
    α           = 5.0::Float64      # per unit profit contribution of sales
    μ           = 1.0::Float64       # scaling parameter
    b           = 0.30::Float64      # calling time elasticity
    fix         = 50000.0::Float64   # fixed costs for one location
    max_time    = 1600.0::Float64     # number of hours per salesforce personnel
    base_time   = 1600.0::Float64    # max. fraction of salesforce personnel
    max_drive   = 360.0::Float64     # max kilometers to drive
    pot_ratio   = 1.00::Float64      # ratio of potential locations to all BAs

# state the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 8::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations
    silent  = false::Bool             # state whether to surpress the optimisation log

# state whether to use CPLEX via GAMS or Gurobi
    const GRB_ENV = Gurobi.Env()
    gurobi = true

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C0"     

# load and prepare the input data
# Load the distance matrix and the number of weight
    weight   = vec(readdlm("data/weight/weight_$hexsize.csv", Float64))
    distance = readdlm("data/distance/distance_$hexsize.csv", Float64)
    shape    = Shapefile.Table("data/geometry/grid_$hexsize.shp")

# Create an adjacency matrix
    adj = adjacency_matrix(distance)

# Check if preparation was successful
    size(weight,1) == size(distance,1) == size(distance,2) ? hexnum = size(weight,1) : error("Preparation failed: sizes are different")

# Create random potential locations
    potloc = random_locations(pot_ratio,hexnum)

# Calculate the sets for contiguity and compactness constraints
    N,M,card_n,card_m = sets_m_n(distance,adj,hexnum)

# Calculate Model Parameters
    β,pp,ts = model_params(hexnum,distance,max_drive,α,μ,weight,b,h,g,mp)
    print("\n The input data was prepared successfully.")

# Optimise the problem formulation
    X,gap,objval,dur = districting_model(optcr::Float64,
                                                        reslim::Int64,
                                                        cores::Int64,
                                                        nodlim::Int64,
                                                        iterlim::Int64,
                                                        hexnum::Int64,
                                                        potloc::Vector{Int64},
                                                        max_drive::Float64,
                                                        fix::Float64,
                                                        distance::Array{Float64,2},
                                                        pp::Array{Float64,2},
                                                        adj::Array{Bool,2},
                                                        compactness::String,
                                                        N::Array{Bool,3},
                                                        M::Array{Bool,3}, 
                                                        card_n::Array{Int64,2},
                                                        card_m::Array{Int64,2},
                                                        gurobi::Bool,
                                                        silent::Bool)
    print("\n The optimisation took ",round(dur)," seconds.")
    print("\n The objective value is ",round(objval),".")

# Clean up the results
    alloc = clean_output(X,hexnum,ts,pp,distance)
    sales_agents = sales_output(alloc,max_time,fix)
    plot_time, plot_area = plot_generation(alloc,shape)

# Prepare results for part-time workers or full workers
    sales_agents_heur = sales_output_full(alloc::DataFrame,
                                    sales_agents::DataFrame,
                                    weight::Vector{Float64},
                                    β::Array{Float64,2},
                                    α::Float64,
                                    μ::Float64,
                                    b::Float64,
                                    h::Float64,
                                    g::Float64,
                                    max_time::Float64,
                                    fix::Float64)

   # Start the reallocation heuristic to improve the results
   XI = exchange_heuristic(X,distance,ts,sales_agents,sales_agents_heur)
   allocI = clean_output(XI,hexnum,ts,pp,distance)
   plot_timeI, plot_areaI = plot_generation(allocI,shape)
   display(plot_area)
   display(plot_areaI)

   sales_agentsI = sales_output(allocI,max_time,fix)
   sales_agents_heurI = sales_output_full(allocI::DataFrame,
                                       sales_agentsI::DataFrame,
                                       weight::Vector{Float64},
                                       β::Array{Float64,2},
                                       α::Float64,
                                       μ::Float64,
                                       b::Float64,
                                       h::Float64,
                                       g::Float64,
                                       max_time::Float64,
                                       fix::Float64)

    show(sales_agents)
    show(sales_agentsI)

# Export the CSV
    CSV.write("results/allocation_$hexsize.csv", alloc)
    CSV.write("results/salesforce_$hexsize.csv", sales_agents)
    CSV.write("results/salesforce_part_$hexsize.csv", sales_agents_heur)
    print("\n Results were prepared and exported.")

    print("\nGap between both results: ",
          round((1-sum(sales_agents_heur.profit)/sum(sales_agents.profit))*100,digits = 4),"%")
    print("\nGap between both results: ",
          round((1-sum(sales_agents_heurI.profit)/sum(sales_agents.profit))*100,digits = 4),"%")