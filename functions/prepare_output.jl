# Function to reduce the output matrix of the decision variable to a Table
# with all important data
    function clean_output(X,N,ts,pp,distance)
        alloc = Array{Float64,2}(undef,N,5) .= 0
        alloc = DataFrame(alloc, [:index, :area, :time, :profit, :distance])
        for i = 1:size(alloc,1)
            alloc[i,1] = i
            for j = 1:size(alloc,1)
                if X[i,j] == 1
                    alloc[j, :area] = i
                    alloc[j, :time] = ts[i,j]
                    alloc[j, :profit] = pp[i,j]
                    alloc[j, :distance] = distance[i,j]
                end
            end
        end
        return alloc
    end

# Function to create a table with the data for each district
function sales_output(alloc::DataFrame,max_time::Float64,fix::Float64)
    sales_agents = combine(groupby(alloc, :area), :time => sum => :hours, :profit => sum => :profit, nrow => :nr_kge)
    sales_agents[:,:agents] = round.(sales_agents[:,:hours]./max_time,digits = 2)
    sales_agents[:,:agent_profit] = round.(sales_agents[:,:profit]./sales_agents[:,:agents],digits=2)
    sales_agents[:,:profit] = round.(sales_agents[:,:profit],digits=2)
    sales_agents[:,:fix_costs] .= fix
    sales_agents[:,:hours] = round.(sales_agents[:,:hours],digits=2)
    return sales_agents
end

# Function to apply our rounding heuristic to create a table with the data for each district.
# The heuristic is so far not described in the paper but might be published later.
function sales_output_full(alloc::DataFrame,
                           sales_agents::DataFrame,
                           people::Vector{Float64},
                           β::Array{Float64,2},
                           α::Float64,
                           μ::Float64,
                           b::Float64,
                           h::Float64,
                           g::Float64,
                           max_time::Float64,
                           fix::Float64)
    sales = copy(sales_agents)
    sales[:,:factor_lo] = ceil.(sales[:,:hours]/(max_time)) * max_time ./ sales[:,:hours]
    sales[:,:factor_up] = floor.(sales[:,:hours]/(max_time))  * max_time ./ sales[:,:hours]
    alloc[:,:profit_lo] .= 0.0
    alloc[:,:profit_up] .= 0.0
    alloc[:,:profit_be] .= 0.0
    alloc[:,:time_be]   .= 0.0
    area_dict = Dict(sales[i,:area] => i for i = 1:nrow(sales))
    for j = 1:nrow(alloc)
        if alloc[j,:area] > 0
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
    end
    sales_agents_heur = combine(groupby(alloc, :area), :time_be => sum => :hours, :profit_be => sum => :profit, nrow => :nr_kge)
    sales_agents_heur[:,:agents] = round.(sales_agents_heur[:,:hours]./max_time,digits = 2)
    sales_agents_heur[:,:agent_profit] = round.(sales_agents_heur[:,:profit]./sales_agents_heur[:,:agents],digits=2)
    sales_agents_heur[:,:profit] = round.(sales_agents_heur[:,:profit],digits=2)
    sales_agents_heur[:,:fix_costs] .= fix
    sales_agents_heur[:,:hours] = round.(sales_agents_heur[:,:hours],digits=2)
    return sales_agents_heur
end

