function exchange_heuristic(X,distance,ts,sales_agents,sales_agents_heur)
    X_greed = copy(X)
    districts = size(sales_agents_heur,1)
    scus      = size(X,1)
    possible  = Vector{Bool}(undef,districts) .= true
    X_goal = Vector{Float64}(undef,districts) .= 0
    X_now  = Vector{Float64}(undef,districts) .= 0
    X_diff = Vector{Float64}(undef,districts) .= 0
    for i = 1:districts
        X_goal[i]   = sales_agents_heur.hours[i]
        X_now[i]    = sales_agents.hours[i]
    end
    while any(possible .== true)
        X_diff .= 0
        for i = 1:districts
            if possible[i] == true
                X_diff[i] = X_now[i] - X_goal[i]
            end
        end
        candidate = argmax(abs.(X_diff))
        cand_loca  = round(Int64,sales_agents_heur.area[candidate])
        if X_diff[candidate] > 0
            sku = X_greed[cand_loca,:] .* distance[cand_loca,:]
            sku = argmax(sku)
            new_loca = Vector{Float64}(undef,districts)
            for i = 1:districts
                if i != candidate
                    new_loca[i] = distance[round(Int64,sales_agents_heur.area[i]),sku]
                else
                    new_loca[i] = maximum(distance)[1]
                end
            end
            new = argmin(new_loca)
            new_loca = round(Int64,sales_agents_heur.area[new])
            if abs(X_now[candidate] - X_goal[candidate] - ts[cand_loca,sku]) < abs(X_now[candidate] - X_goal[candidate]) &&
                abs(X_now[new] - X_goal[new] + ts[new_loca,sku]) < abs(X_now[new] - X_goal[new])
                X_greed[new_loca,sku] = 1
                X_greed[cand_loca,sku] = 0
                X_now[new] += ts[new_loca,sku]
                X_now[candidate] -= ts[cand_loca,sku]
                possible .= true
            else
                possible[candidate] = false
            end
        elseif X_diff[candidate] < 0
            best_candidate = Vector{Float64}(undef,scus) .= maximum(distance)[1]
            for i = 1:scus
                if X_greed[cand_loca,i] == 0
                    best_candidate[i] = distance[cand_loca,i]
                end
            end
            sku = argmin(best_candidate)
            old_loca = 0
            for i = 1:scus
                if X_greed[i,sku] == 1
                    old_loca = i
                end
            end
            old_district = 0
            for i = 1:districts
                if sales_agents_heur.area[i] == old_loca
                    old_district = i
                end
            end
            if abs(X_now[candidate] - X_goal[candidate] + ts[cand_loca,sku]) < abs(X_now[candidate] - X_goal[candidate]) &&
                abs(X_now[old_district] - X_goal[old_district] - ts[old_loca,sku]) < abs(X_now[old_district] - X_goal[old_district])
                X_greed[old_loca,sku] = 0
                X_greed[cand_loca,sku] = 1
                X_now[old_district] -= ts[old_loca,sku]
                X_now[candidate] += ts[cand_loca,sku]
                possible .= true
            else
                possible[candidate] = false
            end
        else
            possible .= false
        end
    end
    return X_greed
end