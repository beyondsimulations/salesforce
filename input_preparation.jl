using CSV
using DataFrames
using DelimitedFiles
using JuMP
using GAMS
using Random
using Shapefile
using Plots

# Choose the size of the hexagons: 20, 30, 40, 50, 60
hexsize = 60

# Choose the parameters of the salesforcemodel
h = 1 # cost per travel time unit
α = 10 # per unit profit contribution of sales
μ = 1 # scaling parameter
b = 0.4 # calling time elasticity
fix = 1000 # fixed costs for one location
max_time = 1600 # number of hours per salesforce personnel
max_drive = 360 # max kilometers to drive
number_pot_locations = 50 # number of potential locations

# Load the distance matrix and the number of people
people = DataFrame(CSV.File("data/people/people_$hexsize.csv"))
distance = readdlm("data/distance//distance_$hexsize.csv", ',', Float64)
shape =  Shapefile.Table("data/geometry/grid_$hexsize.shp")

# Sort and prepare the number of people
people = people[sortperm(people[:,1]),:]
people = people[:,2]
people = ceil.(people./10000, digits = 0)

# Sort and prepare the distance matrix 
distance = transpose(distance)
distance = distance[sortperm(distance[:,1]),:]
distance = distance[2:end,2:end]
distance = round.(distance./1000, digits = 2)

# Check if preparation was successful
size(people,1) == size(distance,1) == size(distance,2) ? N = size(people,1) : error("Preparation failed: sizes are different")

# Create the neccessary functions for the salesforcemodel
## beta
function beta(distance,i,j)
    0.1 + min(0.9,2*distance[i,j]/800)
end

# profit
function profit_plus(α,μ,people,β,b)
    α * μ * people * (1-β)^b # * t^b
end

function profit_minus(β,h)
    h * β # * t
end

## 1 derivation of profit
function profit_der(α,μ,people,β,b)
    α * μ * people * (1-β)^(b) * b # * t^(b-1)
end

# Potential locations

potloc = Array{Int64,1}(undef,N) .= 0
while sum(potloc) < number_pot_locations
    potloc[rand(1:N)] = 1
end

# Calculate beta, profit_plus, profit_minus and derivation of profit
β = Array{Float64,2}(undef,N,N)  .= 0
pp = Array{Float64,2}(undef,N,N) .= 0
pm = Array{Float64,2}(undef,N,N) .= 0
pd = Array{Float64,2}(undef,N,N) .= 0
for i = 1:N
    for j = 1:N
        if distance[i,j] < max_drive && potloc[i] == 1
            β[i,j]  = beta(distance,i,j)
            pp[i,j] = profit_plus(α,μ,people[j],β[i,j],b)
            pm[i,j] = profit_minus(β[i,j],h)
            pd[i,j] = profit_der(α,μ,people[j],β[i,j],b)
        end
    end
end


# Create the optimisation model
sf1 = Model(GAMS.Optimizer)

set_optimizer_attribute(sf1, GAMS.ModelType(), "NLP")
set_optimizer_attribute(sf1, "Solver", "BONMIN")
set_optimizer_attribute(sf1, "OptCR", 0.0001)
set_optimizer_attribute(sf1, "ResLim", 10800)
set_optimizer_attribute(sf1, "Threads", 8)
set_optimizer_attribute(sf1, "NodLim", 10000000000)
set_optimizer_attribute(sf1, "Iterlim", 1000000)

@variable(sf1, W[1:N,1:N], Bin)
@variable(sf1, T[1:N], Int)

@NLobjective(sf1, Max, sum((pp[i,j]*(T[j]^b) - pm[i,j] * T[j]) * W[i,j] for i = 1:N, j = 1:N if distance[i,j] < max_drive) - sum(fix * W[i,i] for i = 1:N))
@constraint(sf1, timeconstraint[i in 1:N; potloc[i]==1], sum(T[j] * W[i,j] for j = 1:N if distance[i,j] < max_drive && potloc[i]==1) <= max_time)
#@NLconstraint(sf1, gradientconstraint[i = 1:N, j = 1:N; distance[i,j] <= max_drive && potloc[i]==1], W[i,j] * (pd[i,i] * (1/(T[i])^(1-b) - pm[i,i])) - W[i,j] * (pd[i,j] * (1/(T[j])^(1-b) - pm[i,i])) == 0)
@constraint(sf1, oneallocation[j = 1:N], sum(W[i,j] for i = 1:N if distance[i,j]<max_drive && potloc[i]==1) <= 1)
@constraint(sf1, realised[i = 1:N, j = 1:N; distance[i,j] < max_drive && potloc[i]==1], W[i,j] - W[i,i] <= 0)
#@constraint(sf1, mintime[i = 1:N, j = 1:N; distance[i,j] < max_drive && potloc[i]==1], T[j] <= W[i,j] * max_time)

JuMP.optimize!(sf1)

gap = abs(objective_bound(sf1)-objective_value(sf1))/abs(objective_value(sf1)+0.00000000001)
objval = objective_value(sf1)
alloc = Array{Float64,2}(undef,N,3) .= 0
alloc = DataFrame(alloc, [:index, :area, :time])
for i = 1:size(alloc,1)
    alloc[i,1] = i
    alloc[i,3] = value.(T[i])
    for j = 1:size(alloc,1)
        if value.(W[i,j]) > 0
            alloc[j,2] = i
        end
    end
end
print(alloc)

# Export the CSV
CSV.write("results/allocation_$hexsize.csv", alloc)

normalize(vec) = [(x - minimum(vec))/(maximum(vec) - minimum(vec)) for x in vec]
# Plot the results
if length(unique(alloc.area)) > 1
    alloc.shape = Shapefile.shapes(shape)

    normalized_values_time = normalize(alloc.time)
    normalized_values_area = normalize(alloc.area)

    colors_time = Array([cgrad(:matter, 10, categorical = true, scale = :exp, rev = true)[value] for value in normalized_values_time])
    colors_area = Array([cgrad(:tab20, length(unique(alloc.area)), categorical = true)[value] for value in normalized_values_area])

    plot_time = plot(size=(500, 600), axis=false, ticks=false)
    for x = 1:nrow(alloc)
        plot!(plot_time, alloc[x, :shape], color=colors_time[x])
    end

    plot_area = plot(size=(500, 600), axis=false, ticks=false)
    for x = 1:nrow(alloc)
        if alloc[x, :area] == 1
            plot!(plot_area, alloc[x, :shape], color=colors_area[x])
        end
    end

end
gui(plot_time)
gui(plot_area)