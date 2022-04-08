# Load all neccessary packages and functions
import Pkg
Pkg.activate("salesforce")
include("functions/load_packages.jl")
print("\n\n All neccessary functions are loaded.")

# specify benchmark instances
    grid_sizes = [60,50,40,30]
    location_scales = [0.2,0.4,0.6,0.8,1.0]
    location_fixed_costs = [20000.0,30000.0,40000.0]

# create a Dataframe for the results of the benchmark
    benchmark = DataFrame(grid = Int64[], SCUs = Int64[], scale = Float64[], fix_costs = Float64[],
                          duration = Float64[], objective = Float64[], 
                          locations = Int64[], agents = Float64[], 
                          agent_profit = Float64[], agent_profit_dev = Float64[])

# Choose the marginal profit (mp = 0 for optimal profit)
    mp          = 0.00::Float64

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
    silent  = false::Bool             # state whether to surpress the optimisation log

# state whether to use CPLEX via GAMS or the open source solver CBC
    opensource = false

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

# load and prepare the input data
# Load the distance matrix and the number of people
    people   = DataFrame(CSV.File("data/people/people_$hexsize.csv"))
    distance = readdlm("data/distance/distance_$hexsize.csv", ',', Float64)
    shape    = Shapefile.Table("data/geometry/grid_$hexsize.shp")

# Sort and prepare the number of people
    people = people[sortperm(people[:,:index]),:]
    people = people[:,:ewz_real_sum]
    people = ceil.(people./500, digits = 0)

# Sort and prepare the distance matrix 
    distance = transpose(distance)
    distance = distance[sortperm(distance[:,1]),:]
    distance = distance[2:end,2:end]
    distance = distance./1000

# Create an adjacency matrix
    adj = adjacency_matrix(distance)

# Check if preparation was successful
    size(people,1) == size(distance,1) == size(distance,2) ? hexnum = size(people,1) : error("Preparation failed: sizes are different")

# Create random potential locations
    potloc = random_locations(pot_ratio,hexnum)

# Calculate the sets for contiguity and compactness constraints
    N,M,card_n,card_m = sets_m_n(distance,adj,hexnum)
    print("\n The input data was prepared successfully.")

# Calculate Model Parameters
    β,pp,ts = model_params(hexnum,distance,max_drive,α,μ,people,b,h,mp)
    print("\n Parameters for the optimisation model were derived.")

# Optimise the problem formulation
    dur = @elapsed X,Y,gap,objval = districting_model(optcr::Float64,
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
                                                        opensource::Bool,
                                                        silent::Bool)
    print("\n The optimisation took ",round(dur)," seconds.")
    print("\n The objective value is ",round(objval),".")

# Clean up the results
    alloc = clean_output(X,hexnum,ts,pp,distance)
    sales_agents = sales_output(alloc)
    plot_time, plot_area = plot_generation(alloc,shape)

# Display the results
    display(plot_time)
    display(plot_area)
    print("\n",sales_agents)

# save the results to the benchmark output file
    push!(benchmark, (grid = hexsize, SCUs = hexnum, scale = pot_ratio, fix_costs = fix,
            duration = round(dur, digits = 2), objective = round(objval, digits = 2), 
            locations = nrow(sales_agents), agents = sum(sales_agents[:,:agents]), 
            agent_profit = round(mean(sales_agents[:,:profit]),digits = 2), 
            agent_profit_dev = round(std(sales_agents[:,:agent_profit],digits = 2))))
    CSV.write("results/benchmark.csv", benchmark)
            end
        end
    end
    # Export the CSV
    print("\n Results were prepared and exported.")