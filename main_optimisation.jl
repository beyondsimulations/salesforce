# Neccessary packages and functions
    import Pkg
    Pkg.activate("salesforce")
    include("functions/load_packages.jl")
    print("\n\n All neccessary functions are loaded.")
   
# Choose the parameters of the salesforcemodel
    mp          = 0.00::Float64       # Choose the marginal profit (mp = 0 for optimal profit)
    hexsize     = "15"::String        # size of the hexagons ("msc2014","30","25","20","15")
    h           = 20.0::Float64       # cost per hour of travel time
    g           = 50.0::Float64       # cost per worker per hour
    α           = 20.0::Float64       # per unit profit contribution of sales
    μ           = 1.0::Float64        # scaling parameter
    b           = 0.30::Float64       # calling time elasticity
    fix         = 40000.0::Float64    # fixed costs for one location
    max_time    = 1600.0::Float64     # number of hours per salesforce personnel
    max_drive   = 360.0::Float64      # max kilometers to drive
    pot_ratio   = 1.00::Float64       # ratio of potential locations to all BAs

# state the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 8::Int64               # number of CPU cores
    nodlim  = 1000000::Int64         # maximal number of nodes
    iterlim = 1000000::Int64         # maximal number of iterations
    silent  = false::Bool             # state whether to surpress the optimisation log

# Create Gurobi environment variable
    const GRB_ENV = Gurobi.Env()

# State the strength of the compactness and contiguity constraints
## C0 = no contiguity constraints (no compactness)
## C1 = solely contiguity constrains (no compactness)
## C2 = contiguity and normal ompactness constraints
## C3 = contiguity and strong compactness constraints
## For more details take a look at the article "Police Service Districting Planning" by
## Vlcek, Haase, Fliedner and Cors
    compactness = "C0"        

# Load distance matrix and weights
    weight   = vec(readdlm("data/weight/weight_$hexsize.csv", Float64))
    distance = readdlm("data/distance/distance_$hexsize.csv", Float64)
    shape    = Shapefile.Table("data/geometry/grid_$hexsize.shp")

# Create adjacency matrix
    adj = adjacency_matrix(distance)

# Create random potential locations
    potloc = random_locations(pot_ratio,length(weight))

# Calculate the sets for contiguity and compactness constraints
    N,M,card_n,card_m = sets_m_n(distance,adj,length(weight))

# Calculate Model Parameters
    β,pp,ts = model_params(length(weight),distance,max_drive,α,μ,weight,b,h,g,mp)

# Optimise the problem instance
    X,gap,objval,dur = districting_model(optcr,reslim,cores,nodlim,iterlim,
                                         length(weight),potloc,max_drive,fix,distance,
                                         pp,adj,compactness,N,M, card_n,card_m,silent)
    print("\n The optimisation took ",round(dur,digits = 2)," seconds.")
    print("\n The objective value is ",round(objval),".")

# Clean the resulting layouts
    alloc = clean_output(X,length(weight),ts,pp,distance)
    plot_area = plot_generation_area(alloc,shape)
    sales_agents = sales_output(alloc,max_time,fix)

# Plot the results
    #display(plot_area)

# Prepare results for part-time workers or full workers
    sales_agents_heur = sales_output_full(alloc,sales_agents,weight,
                                            β,α,μ,b,h,g,max_time,fix)

# Display results
    gap_heur = round((1-(sum(sales_agents_heur.profit)-
                         sum(sales_agents_heur.fix_costs))/
                        (sum(sales_agents.profit)-
                         sum(sales_agents.fix_costs)))*100,digits = 6)
    print("\n Time per representative: ",max_time,
        ". Average sales time: ", round(sum(sales_agents_heur.hours)/
        nrow(sales_agents_heur),digits = 2),
        ". Gap between both results: ",gap_heur,"%")
    GC.gc()