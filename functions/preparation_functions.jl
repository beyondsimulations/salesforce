function random_locations(number_pot_locations,N)
    potloc = Array{Int64,1}(undef,N) .= 0
    while sum(potloc) < number_pot_locations && sum(potloc) < N
        potloc[rand(1:N)] = 1
    end
    return potloc
end

function model_params(N,distance,max_drive,potloc,α,μ,people,b,h)
    β = Array{Float64,2}(undef,N,N)  .= 0
    pp = Array{Float64,2}(undef,N,N) .= 0
    ts = Array{Float64,2}(undef,N,N) .= 0
    for i = 1:N
        for j = 1:N
            if distance[i,j] < max_drive
                β[i,j]  = beta(distance,i,j)
                ts[i,j] = profit_time(α,μ,people[j],β[i,j],b,h,g)
                pp[i,j] = profit_potential(α,μ,people[j],β[i,j],b,h,g,ts[i,j])
            end
        end
    end
    return β,pp,ts
end

function new_parameters(N,distance,max_drive,potloc,α,μ,people,b,h)
    arr_deri = Array{Float64,3}(undef,N,N,2)
    arr_time = Array{Float64,3}(undef,N,N,10)
    arr_prof = Array{Float64,3}(undef,N,N,10)
    for i = 1:N
        for j = 1:N
            arr_deri
        end
    end
end