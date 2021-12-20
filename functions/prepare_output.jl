function clean_output(X,N,ts,pp,distance)
    alloc = Array{Float64,2}(undef,N,5) .= 0
    alloc = DataFrame(alloc, [:index, :area, :time, :profit, :distance])
    for i = 1:size(alloc,1)
        alloc[i,1] = i
        for j = 1:size(alloc,1)
            if value.(X[i,j]) > 0
                alloc[j, :area] = i
                alloc[j, :time] = ts[i,j]
                alloc[j, :profit] = pp[i,j]
                alloc[j, :distance] = distance[i,j]
            end
        end
    end
    return alloc
end

function sales_output(alloc)
    sales_agents = combine(groupby(alloc, :area), :time => sum => :hours, :profit => sum => :profit, nrow => :nr_kge)
    sales_agents[:,:agents] = sales_agents[:,:hours]./max_time
    sales_agents[:,:agent_profit] = sales_agents[:,:profit]./sales_agents[:,:nr_kge]
    sales_agents = round.(sales_agents, digits = 3)
    return sales_agents
end

