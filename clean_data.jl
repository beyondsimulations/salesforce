version = "30"
people  = DataFrame(CSV.File("data/weight/weight_$version.csv"))
people_out = Vector(people[:,:weight])
writedlm("data/weight/weight_$version.csv", people_out)

distance = readdlm("data/distance/distance_$version.csv", ',', Float64)
distance = transpose(distance)
distance = distance[sortperm(distance[:,1]),:]
distance = distance[2:end,2:end]
distance = round.(distance./1000, digits = 1)
writedlm("data/distance/distance_$(version).csv",distance)