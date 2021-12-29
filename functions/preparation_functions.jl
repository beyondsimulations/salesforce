function random_locations(ratio_potloc::Float64, hexsize::Int64)
    potloc = Array{Int64,1}(undef,hexsize) .= 0
    while sum(potloc) < ratio_potloc * hexsize
        potloc[rand(1:hexnum)] = 1
    end
    return potloc
end

function model_params(hexnum::Int64,
                      distance::Array{Float64,2},
                      max_drive::Float64,
                      α::Float64,
                      μ::Float64,
                      people::Vector{Float64},
                      b::Float64,
                      h::Float64)
    β   = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    pp  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    ts  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    dr  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    for i = 1:hexnum
        for j = 1:hexnum
            if distance[i,j] < max_drive
                β[i,j]  = beta(distance,i,j)
                ts[i,j] = profit_time(α,μ,people[j],β[i,j],b,h,g)
                pp[i,j] = profit_potential(α,μ,people[j],β[i,j],b,h,g,ts[i,j])
                dr[i,j] = profit_potential_der(α,μ,people[j],β[i,j],b,h,g,ts[i,j])
            end
        end
    end
    if -1 < sum(dr) < 1
        print("\n Check: Profit Potential correct.")
    else
        error("\n Error in Profit Potential calculation: ",sum(dr),".")
    end
    return β,pp,ts
end