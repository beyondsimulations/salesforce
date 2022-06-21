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