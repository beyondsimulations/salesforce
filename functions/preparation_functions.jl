# Function to assign random locations as potential locations
    function random_locations(ratio_potloc::Float64, card_BAs::Int64)
        potloc = Array{Int64,1}(undef,card_BAs) .= 0
        while sum(potloc) < ratio_potloc * card_BAs
            potloc[rand(1:card_BAs)] = 1
        end
        return potloc
    end

# Function to calculate all necessary parameters from the response function
    function model_params(card_BAs::Int64,
                        distance::Array{Float64,2},
                        max_drive::Float64,
                        α::Float64,
                        μ::Float64,
                        people::Vector{Float64},
                        b::Float64,
                        h::Float64,
                        g::Float64,
                        mp::Float64)
        β   = zeros(Float64,card_BAs,card_BAs)
        pp  = zeros(Float64,card_BAs,card_BAs)
        ts  = zeros(Float64,card_BAs,card_BAs)
        dr  = zeros(Float64,card_BAs,card_BAs)
        for i = 1:card_BAs
            for j = 1:card_BAs
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

# Function to prepare the sets for contiguity and compactness constraints
    function sets_m_n(airdist::Array{Float64,2}, adjacent::Array{Bool,2}, card_BAs::Int64)
        N = zeros(Bool,card_BAs,card_BAs,card_BAs)
        M = zeros(Bool,card_BAs,card_BAs,card_BAs)
        maxdist = 0
        for i = 1:card_BAs
            for j = 1:card_BAs
                maxdist = 0
                for v = 1:card_BAs
                    if adjacent[j,v] == 1
                        if airdist[i,v] < airdist[i,j]
                            N[i,j,v] = 1
                        end
                        maxdist = max(maxdist,airdist[i,v])
                    end
                end
                for v = 1:card_BAs
                    if adjacent[j,v] == 1
                        if airdist[i,v] < maxdist
                            M[i,j,v] = 1
                        end
                    end
                end
            end
        end
        card_n::Matrix{Int64} = sum(N, dims=3)[:,:,1]
        card_m::Matrix{Int64} = sum(M, dims=3)[:,:,1]
        return  N::Array{Bool,3}, 
                M::Array{Bool,3}, 
                card_n::Matrix{Int64}, 
                card_m::Matrix{Int64}
    end

# Function to create an adjacency matrix for the contiguity and compactness constraints
    function adjacency_matrix(airdist::Array{Float64,2})
        adjacent = zeros(Bool,size(airdist,1),size(airdist,1))
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
        return adjacent::Matrix{Bool}
    end