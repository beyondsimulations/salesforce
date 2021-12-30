# Prepare the model input Data
# Load the distance matrix and the number of people
people   = DataFrame(CSV.File("data/people/people_$hexsize.csv"))
distance = readdlm("data/distance/distance_$hexsize.csv", ',', Float64)
shape    = Shapefile.Table("data/geometry/grid_$hexsize.shp")

# Sort and prepare the number of people
people = people[sortperm(people[:,:index]),:]
people = people[:,:ewz_real_sum]
people = ceil.(people./10000, digits = 0)

# Sort and prepare the distance matrix 
distance = transpose(distance)
distance = distance[sortperm(distance[:,1]),:]
distance = distance[2:end,2:end]
distance = round.(distance./1000, digits = 2)

# Create an adjacency matrix
adj = adjacency_matrix(distance)

# Check if preparation was successful
size(people,1) == size(distance,1) == size(distance,2) ? hexnum = size(people,1) : error("Preparation failed: sizes are different")

# Create random potential locations
potloc = random_locations(pot_ratio,hexnum)

# Calculate the sets for contiguity and compactness constraints
N,M,card_n,card_m = sets_m_n(distance,adj,hexnum)