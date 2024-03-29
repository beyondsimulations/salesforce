# Load all neccessary packages and functions
import Pkg
Pkg.activate("salesforce")
include("functions/load_packages.jl")
print("\n\n All neccessary functions are loaded.")

# specify benchmark instances
    grid_sizes = [60]
    location_scales = [1.0]
    location_fixed_costs = [40000.0]
    marginal_profits = Vector{Float64}(undef,10) .= 0
    for i = 1:length(marginal_profits)
        marginal_profits[i] = 30 - i
    end

# create a Dataframe for the results of the benchmark
    benchmark = DataFrame(grid = Int64[], SCUs = Int64[], scale = Float64[], fix_costs = Float64[],
                          margp = Float64[], duration = Float64[], objective = Float64[], locations = Int64[], 
                          agents = Float64[], agent_profit = Float64[], agent_profit_dev = Float64[])

# Choose the marginal profit (mp = 0 for optimal profit)
    #mp          = 0.00::Float64

# Choose the parameters of the salesforcemodel
    #hexsize     = 40::Int64         # size of the hexagons (30, 40, 50, 60)
    h           = 20.0::Float64      # cost per hour of travel time
    g           = 30.0::Float64      # cost per worker per hour
    α           = 10.0::Float64      # per unit profit contribution of sales
    μ           = 1.0::Float64       # scaling parameter
    b           = 0.30::Float64      # calling time elasticity
    #fix         = 20000.0::Float64  # fixed costs for one location
    max_time    = 1600.0::Float64    # number of hours per salesforce personnel
    max_drive   = 360.0::Float64     # max kilometers to drive
    #pot_ratio   = 1.00::Float64     # ratio of potential locations to all BAs

# state the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 8::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations
    silent  = true::Bool             # state whether to surpress the optimisation log

# state whether to use CPLEX via GAMS or Gurobi
    const GRB_ENV = Gurobi.Env()
    gurobi = false

# state the strength of the compactness and contiguity constraints
# C0 = no contiguity constraints (no compactness)
# C1 = solely contiguity constrains (no compactness)
# C2 = contiguity and normal ompactness constraints
# C3 = contiguity and strong compactness constraints
# For more details take a look at the article this program is based on
    compactness = "C0"     

# start the benchmark loop
    for hexsize in grid_sizes
        for pot_ratio in location_scales
            for fix in location_fixed_costs
                for mp in marginal_profits

            # Load the distance matrix and the weights of each basic area
                weight   = vec(readdlm("data/weight/weight_$hexsize.csv", Float64))
                distance = readdlm("data/distance/distance_$hexsize.csv", Float64)
                shape    = Shapefile.Table("data/geometry/grid_$hexsize.shp")

            # Create the adjacency matrix
                adj = adjacency_matrix(distance)

            # Create random potential locations
                potloc = random_locations(pot_ratio,hexnum)

            # Calculate the sets for the contiguity and compactness constraints
                N,M,card_n,card_m = sets_m_n(distance,adj,hexnum)

            # Calculate the parameters of the specific instance
                β,pp,ts = model_params(hexnum,distance,max_drive,α,μ,weight,b,h,g,mp)

            # Optimise the problem instance
                X,Y,gap,objval,dur = districting_model(optcr,reslim,cores,nodlim,iterlim,hexnum,potloc,
                                                        max_drive,fix,distance,pp,adj,compactness,N,
                                                        M, card_n,card_m,gurobi,silent)
                print("\n The optimisation took ",round(dur)," seconds.")
                print("\n The objective value is ",round(objval),".")

            # Clean and format the results 
                alloc = clean_output(X,hexnum,ts,pp,distance)
                sales_agents = sales_output(alloc,fix)
                plot_time, plot_area = plot_generation(alloc,shape)

            # Plots the resulting districts on a map
                display(plot_area)
                print("\n",sales_agents)

            # saves the new results to the benchmark output file after each iteration
                push!(benchmark, (grid = hexsize, SCUs = hexnum, scale = pot_ratio, fix_costs = fix,
                        margp = mp, duration = round(dur, digits = 2), objective = round(objval, digits = 2), 
                        locations = nrow(sales_agents), agents = sum(sales_agents[:,:agents]), 
                        agent_profit = round(mean(sales_agents[:,:profit]),digits = 2), 
                        agent_profit_dev = round(std(sales_agents[:,:agent_profit]),digits = 2)))
                CSV.write("results/benchmark_marginals.csv", benchmark)
                end
            end
        end
    end
    print("\n Benchmark is finished.")