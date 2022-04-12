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
    sales_agents[:,:agent_profit] = floor.(Int64, sales_agents[:,:profit]./sales_agents[:,:agents])
    sales_agents[:,:profit] = round.(Int64, sales_agents[:,:profit])
    sales_agents[:,:hours] = round.(Int64, sales_agents[:,:hours])
    return sales_agents
end

function sales_output_full(alloc::DataFrame,
                           sales_agents::DataFrame,
                           people::Vector{Float64},
                           β::Array{Float64,2},
                           α::Float64,
                           μ::Float64,
                           b::Float64,
                           h::Float64,
                           g::Float64)
    sales = copy(sales_agents)
    sales[:,:factor_lo] = floor.(sales[:,:hours]/(max_time/parttime)) * (max_time/parttime) ./ sales[:,:hours]
    sales[:,:factor_up] = ceil.(sales[:,:hours]/(max_time/parttime))  * (max_time/parttime) ./ sales[:,:hours]
    alloc[:,:profit_lo] .= 0.0
    alloc[:,:profit_up] .= 0.0
    alloc[:,:profit_be] .= 0.0
    alloc[:,:time_be]   .= 0.0
    area_dict = Dict(sales[i,:area] => i for i = 1:nrow(sales))
    for j = 1:nrow(alloc)
        alloc[j,:profit_lo] = profit_potential(α,μ,people[j],β[round(Int64,alloc[j,:area]),j],b,h,g,(alloc[j,:time] * sales[area_dict[alloc[j,:area]],:factor_lo]))
        alloc[j,:profit_up] = profit_potential(α,μ,people[j],β[round(Int64,alloc[j,:area]),j],b,h,g,(alloc[j,:time] * sales[area_dict[alloc[j,:area]],:factor_up]))
        alloc[j,:profit_be] = max(alloc[j,:profit_lo],alloc[j,:profit_up])
        if alloc[j,:profit_lo] >= alloc[j,:profit_up]
            alloc[j,:profit_be] = alloc[j,:profit_lo]
            alloc[j,:time_be] = alloc[j,:time] * sales[area_dict[alloc[j,:area]],:factor_lo]
        else
            alloc[j,:profit_be] = alloc[j,:profit_up]
            alloc[j,:time_be] = alloc[j,:time] * sales[area_dict[alloc[j,:area]],:factor_up]
        end
    end
    sales_agents_be = combine(groupby(alloc, :area), :time_be => sum => :hours_be, :profit_be => sum => :profit_be, nrow => :nr_kge)
    sales_agents_be[:,:agents_be] = round.(sales_agents_be[:,:hours_be]./max_time,digits = 2)
    sales_agents_be[:,:agent_profit_be] = floor.(Int64, sales_agents_be[:,:profit_be]./sales_agents_be[:,:agents_be])
    sales_agents_be[:,:profit_be] = round.(Int64, sales_agents_be[:,:profit_be])
    sales_agents_be[:,:hours_be] = round.(Int64, sales_agents_be[:,:hours_be])
    return sales_agents_be
end

