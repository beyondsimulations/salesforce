# function to assign random locations as potential locations
function random_locations(ratio_potloc::Float64, hexsize::Int64)
    potloc = Array{Int64,1}(undef,hexsize) .= 0
    while sum(potloc) < ratio_potloc * hexsize
        potloc[rand(1:hexsize)] = 1
    end
    return potloc
end

# function to calculate all necessary parameters from the response function
function model_params(hexnum::Int64,
                      distance::Array{Float64,2},
                      max_drive::Float64,
                      α::Float64,
                      μ::Float64,
                      people::Vector{Float64},
                      b::Float64,
                      h::Float64,
                      g::Float64,
                      mp::Float64)
    β   = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    pp  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    ts  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    dr  = Array{Float64,2}(undef,hexnum,hexnum) .= 0
    for i = 1:hexnum
        for j = 1:hexnum
            if distance[i,j] < max_drive
                β[i,j]  = beta(distance,i,j)
                ts[i,j] = profit_time(mp,α,μ,people[j],β[i,j],b,h,g)
                pp[i,j] = profit_potential(α,μ,people[j],β[i,j],b,h,g,ts[i,j])
                dr[i,j] = profit_potential_der(mp,α,μ,people[j],β[i,j],b,h,g,ts[i,j])
            end
        end
    end
    return β,pp,ts
end

# function to prepare the sets for contiguity and compactness constraints
function sets_m_n(airdist::Array{Float64,2}, adjacent::Array{Bool,2}, hex::Int64)
    N = Array{Bool,3}(undef,hex,hex,hex) .= 0
    M = Array{Bool,3}(undef,hex,hex,hex) .= 0
    for i = 1:hex
        for j = 1:hex
            maxdist = 0
            for v = 1:hex
                if adjacent[j,v] == 1
                    if airdist[i,v] < airdist[i,j]
                        N[i,j,v] = 1
                    end
                    maxdist = max(maxdist,airdist[i,v])
                end
            end
            for v = 1:hex
                if adjacent[j,v] == 1
                    if airdist[i,v] < maxdist
                        M[i,j,v] = 1
                    end
                end
            end
        end
    end
    card_n = sum(N, dims=3)[:,:,1]
    card_m = sum(M, dims=3)[:,:,1]
    return  N::Array{Bool,3}, 
            M::Array{Bool,3}, 
            card_n::Array{Int64,2}, 
            card_m::Array{Int64,2}
end

# function to create an adjacency matrix for the contiguity and compactness constraints
function adjacency_matrix(airdist::Array{Float64,2})
    adjacent = Array{Bool,2}(undef,size(airdist,1),size(airdist,1)) .= 0
    one_dist = minimum(airdist[airdist .> 0])
    for i = 1:size(airdist,1)
        for j = 1:size(airdist,1)
            if i != j
                if airdist[i,j] <= one_dist * 1.5
                    adjacent[i,j] = 1
                end
            end
        end
    end
    return adjacent::Array{Bool,2}
end