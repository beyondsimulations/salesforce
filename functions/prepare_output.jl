function clean_output(X,N,ts,pp,distance)
    alloc = Array{Float64,2}(undef,N,5) .= 0
    alloc = DataFrame(alloc, [:index, :area, :time, :profit, :distance])
    for i = 1:size(alloc,1)
        alloc[i,1] = i
        for j = 1:size(alloc,1)
            if X[i,j] > 0
                alloc[j, :area] = i
                alloc[j, :time] = ts[i,j]
                alloc[j, :profit] = pp[i,j]
                alloc[j, :distance] = distance[i,j]
            end
        end
    end
    return alloc
end

function sales_output(alloc::DataFrame)
    sales_agents = combine(groupby(alloc, :area), :time => sum => :hours, :profit => sum => :profit, nrow => :nr_kge)
    sales_agents[:,:agents] = round.(sales_agents[:,:hours]./max_time,digits = 2)
    sales_agents[:,:agent_profit] = round.(Int64, sales_agents[:,:profit]./sales_agents[:,:agents])
    sales_agents[:,:profit] = round.(Int64, sales_agents[:,:profit])
    sales_agents[:,:hours] = round.(Int64, sales_agents[:,:profit])
    return sales_agents
end

