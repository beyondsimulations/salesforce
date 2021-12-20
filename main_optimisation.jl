include("functions/load_packages.jl")
include("functions/preparation_functions.jl")
include("functions/profit_functions.jl")
include("functions/plot_functions.jl")
include("functions/prepare_output.jl")

include("optimization/opti_loc1.jl")
include("optimization/opti_loc2.jl")

## Choose the parameters of the salesforcemodel
hexsize = 30
h = 10 # cost per travel time unit
g = 10 # money per worker per hour
α = 25 # per unit profit contribution of sales
μ = 1 # scaling parameter
b = 0.4 # calling time elasticity
fix = 20000 # fixed costs for one location
max_time = 1600 # number of hours per salesforce personnel
max_drive = 360 # max kilometers to drive
number_pot_locations = 100 # number of potential locations

include("functions/model_input.jl")

# Create random potential locations
potloc = random_locations(number_pot_locations,N)
 
# Calculate Model Parameters
β,pp,ts = model_params(N,distance,max_drive,potloc,α,μ,people,b,h)

# Optimise the problem formulation

X1,gap1,objval1 = optimisation_loc1(N,pp,distance,max_drive,fix,potloc)

alloc = clean_output(X1,N,ts,pp,distance)
sales_agents = sales_output(alloc)
plot_time, plot_area = plot_generation(alloc)

# Export the CSV
CSV.write("results/allocation_$hexsize.csv", alloc)
CSV.write("results/salesforce_$hexsize.csv", sales_agents)

# Display the results
display(plot_time)
display(plot_area)
print("\n",sales_agents)
print("\n Number of Locations: ",length(unique(alloc.area))-1,"\n")