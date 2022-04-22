# Load all neccessary packages and functions
import Pkg
Pkg.activate("salesforce")
include("functions/load_packages.jl")
print("\n\n All neccessary functions are loaded.")

# specify benchmark instances
    grid_sizes           = ["msc2014","30","25","20","15"]
    location_scales      = [1.0]
    profitvar            = [10.0,20.0,30.0,40.0,50.0]
    cost_travelhour      = [10.0,20.0,30.0,40.0,50.0]
    cost_workerhour      = [50.0]
    location_fixed_costs = [10000.0,20000.0,30000.0,40000.0,50000.0]
    time_levels          = [400.0,800.0,1600.0]            
    
# create a Dataframe for the results of the benchmark
    benchmark = DataFrame(grid = String[], SCUs = Int64[], scaleIJ = Float64[], 
                          profitsale = Float64[], cost_travel = Float64[],
                          cost_worker = Float64[], fix_costs = Float64[],
                          workertime = Float64[], 
                          duration = Float64[], objective_opt = Float64[],
                          objective_sales = Float64[],
                          objective_heur = Float64[], locations = Int64[],
                          heur_gap = Float64[], 
                          agents_opt = Float64[], agents_heur = Float64[], 
                          agent_profit_dev_opt = Float64[], 
                          agent_profit_dev_heur = Float64[])

# Choose the marginal profit (mp = 0 for optimal profit)
    mp          = 0.00::Float64

# Choose the parameters of the salesforcemodel
    #hexsize     = 30::Int64         # size of the hexagons (30, 40, 50, 60)
    #h           = 20.0::Float64     # cost per hour of travel time
    #g           = 30.0::Float64     # cost per worker per hour
    #α           = 10.0::Float64      # per unit profit contribution of sales
    μ           = 1.0::Float64      # scaling parameter
    b           = 0.30::Float64      # calling time elasticity
    #fix         = 20000.0::Float64  # fixed costs for one location
    #max_time    = 1600.0::Float64   # min hours per salesforce personnel in district (incl. part-time)
    base_time   = 1600.0::Float64    # yearly hours per salesforce personnel
    parttime    = 1.0::Float64       # max. fraction of salesforce personnel
    max_drive   = 360.0::Float64     # max kilometers to drive
    #pot_ratio   = 1.00::Float64     # ratio of potential locations to all BAs

# state the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 4::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations
    silent  = true::Bool             # state whether to surpress the optimisation log

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

# number of total benchmarks
    total = length(grid_sizes)*length(location_scales)*length(profitvar)*
            length(cost_travelhour)*length(cost_workerhour)*length(location_fixed_costs)
    current = 1
# start the benchmark loop
    for hexsize in grid_sizes
        for pot_ratio in location_scales
            for α in profitvar
                for h in cost_travelhour
                    for g in cost_workerhour
                        for fix in location_fixed_costs
    print("\n\nIteration ",current," of ",total,".")
    global current += 1

# load benchmark instances
    

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
    print("\n The optimisation took ",round(dur,digits = 2)," seconds.")
    print("\n The objective value is ",round(objval),".")

    # Clean up the results
    alloc = clean_output(X,hexnum,ts,pp,distance)
    plot_area = plot_generation_area(alloc,shape)
    display(plot_area)

    for max_time in time_levels
    sales_agents = sales_output(alloc,max_time,fix)

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
    #XI = exchange_heuristic(X,distance,ts,sales_agents,sales_agents_heur)
    #allocI = clean_output(XI,hexnum,ts,pp,distance)
    #plot_timeI, plot_areaI = plot_generation(allocI,shape)
    #display(plot_areaI)

    #sales_agentsI = sales_output(alloc,max_time,fix)
    #sales_agents_heurI = sales_output_full(allocI::DataFrame,
    #                                    sales_agentsI::DataFrame,
    #                                    weight::Vector{Float64},
    #                                    β::Array{Float64,2},
    #                                    α::Float64,
    #                                    μ::Float64,
    #                                    b::Float64,
    #                                    h::Float64,
    #                                    g::Float64,
    #                                    max_time::Float64,
    #                                    fix::Float64)

    # Display the results
    gap_heur = round((1-(sum(sales_agents_heur.profit)-sum(sales_agents_heur.fix_costs))/
                        (sum(sales_agents.profit)-sum(sales_agents.fix_costs)))*100,digits = 6)

    #gap_heurI = round((1-(sum(sales_agents_heurI.profit)-sum(sales_agents_heurI.fix_costs))/
    #                   (sum(sales_agentsI.profit)-sum(sales_agentsI.fix_costs)))*100,digits = 6)

    print("\n Time per representative: ",max_time,
          ". Average sales time: ", round(sum(sales_agents_heur.hours)/nrow(sales_agents_heur),digits = 2),
          ". Gap between both results: ",gap_heur,"%")
    #print("\n Time per representative: ",max_time,". Gap between both results after exchange: ",gap_heurI,"%")
        
# save the results to the benchmark output file
    push!(benchmark, (grid = hexsize, SCUs = hexnum, 
        scaleIJ = pot_ratio, 
        profitsale = α, cost_travel = h,
        cost_worker = g, fix_costs = fix,
        workertime = max_time,
        duration              = round(dur, digits = 2), 
        objective_opt         = round(objval, digits = 2),
        objective_sales       = round(sum(sales_agents.profit).-sum(sales_agents.fix_costs),digits = 2), 
        objective_heur        = round(sum(sales_agents_heur.profit).-sum(sales_agents.fix_costs),digits = 2),
        heur_gap              = gap_heur, 
        locations             = nrow(sales_agents), 
        agents_opt            = sum(sales_agents.agents), 
        agents_heur           = sum(sales_agents_heur.agents), 
        agent_profit_dev_opt  = round(std(sales_agents.agent_profit),digits = 2), 
        agent_profit_dev_heur = round(std(sales_agents_heur.agent_profit),digits = 2)))
    CSV.write("results/benchmark_full_new2.csv", benchmark)
                            end
                        end
                    end
                end
            end
        end
    end
    # Export the CSV
    print("\n Results were prepared and exported.")