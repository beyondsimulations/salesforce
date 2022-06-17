# Neccessary packages and functions
    import Pkg
    Pkg.activate("salesforce")
    include("functions/load_packages.jl")
    print("\n\n All neccessary functions are loaded.")

# Benchmark instances
## Available options for the grid sizes are "msc2014","30","25","20","15".
## All other parameters are Float64 and can be specified as wished.
## These vectors are the foundation of the benchmark as each possible
## parameter combination will later be calculated.
    #grid_sizes           = ["msc2014","30","25","20","15"]
    grid_sizes           = ["15"]
    location_scales      = [1.0]
    #profitvar            = [10.0,20.0,30.0,40.0,50.0]
    profitvar            = [50.0]
    cost_travelhour      = [10.0,20.0,30.0,40.0,50.0]
    cost_workerhour      = [40.0,50.0,60.0,70.0,80.0]
    location_fixed_costs = [10000.0,20000.0,30000.0,40000.0,50000.0]
    time_levels          = [400.0,800.0,1600.0]            
    
# Dataframe for the results of the benchmark
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
   
# Parameters of the salesforcemodel
    mp          = 0.00::Float64      # marginal profit (mp = 0 for optimal profit)
    μ           = 1.0::Float64       # scaling parameter
    b           = 0.30::Float64      # calling time elasticity
    base_time   = 1600.0::Float64    # yearly hours per salesforce personnel
    max_drive   = 360.0::Float64     # max kilometers to drive

# State the optimisation options
    optcr   = 0.000::Float64         # allowed gap
    reslim  = 10800::Int64           # maximal duration of optimisation in seconds
    cores   = 8::Int64               # number of CPU cores
    nodlim  = 100000000000::Int64    # maximal number of nodes
    iterlim = 100000000000::Int64    # maximal number of iterations
    silent  = false::Bool            # state whether to surpress the optimisation log

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

# Number of benchmarks instances
    total = length(grid_sizes)*length(location_scales)*length(profitvar)*
            length(cost_travelhour)*length(cost_workerhour)*length(location_fixed_costs)
    
# Start the benchmark loop
    current = 1 
    for hexsize in grid_sizes
        for pot_ratio in location_scales
            for α in profitvar
                for h in cost_travelhour
                    for g in cost_workerhour
                        for fix in location_fixed_costs

                            GC.gc()
                            
                            print("\n\nIteration ",current," of ",total,".")
                            global current += 1
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
                            #display(plot_area)

                            for max_time in time_levels
                                sales_agents = sales_output(alloc,max_time,fix)

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
            
                            # save the results to the benchmark output file
                                push!(benchmark, (grid = hexsize, SCUs = length(weight), 
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
                                CSV.write("results/benchmark_full_15_fin.csv", benchmark)
                                GC.gc()
                            end
                        end
                    end
                end
            end
        end
    end
    print("\n Results were prepared and exported.")