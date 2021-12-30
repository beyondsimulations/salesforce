# include all neccessary functions
include("functions/load_packages.jl")
include("functions/preparation_functions.jl")
include("functions/profit_functions.jl")
include("functions/plot_functions.jl")
include("functions/prepare_output.jl")
include("optimization/opti_loc1.jl")
include("optimization/opti_loc2.jl")
print("\n\n All neccessary functions are loaded.")

# Choose the parameters of the salesforcemodel
hexsize     = 30      # size of the hexagons (30, 40, 50, 60)
h           = 15.0    # cost per hour of travel time
g           = 50.0    # cost per worker per hour
α           = 75.0    # per unit profit contribution of sales
μ           = 1.0     # scaling parameter
b           = 0.4     # calling time elasticity
fix         = 12000.0  # fixed costs for one location
max_time    = 1600.0  # number of hours per salesforce personnel
max_drive   = 360.0   # max kilometers to drive
pot_ratio   = 0.9     # ratio of potential locations to all BAs

# load and prepare the input data
include("model_input.jl")
print("\n The input data was prepared successfully.")
 
# Calculate Model Parameters
β,pp,ts = model_params(hexnum,distance,max_drive,α,μ,people,b,h)
print("\n Parameters for the optimisation model were derived.")

# Optimise the problem formulation
dur = @elapsed X1,gap1,objval1 = optimisation_loc1(hexnum,pp,distance,max_drive,fix,potloc)
print("\n The optimsation took ",dur,"seconds.")

# Clean up the results
alloc = clean_output(X1,hexnum,ts,pp,distance)
sales_agents = sales_output(alloc)
plot_time, plot_area = plot_generation(alloc)

# Export the CSV
CSV.write("results/allocation_$hexsize.csv", alloc)
CSV.write("results/salesforce_$hexsize.csv", sales_agents)
print("\n Results were prepared and exported.")

# Display the results
display(plot_time)
display(plot_area)
print("\n",sales_agents)