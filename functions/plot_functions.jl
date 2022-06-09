# Function to normalize the values to colour the districts
    normalize(vec) = [(x - minimum(vec))/(maximum(vec) - minimum(vec)) for x in vec]

# Function to equalize the values to colour the districts
    function equalize(vec)
        map = Array{Int64,2}(undef, length(unique(vec)),2) .= 0
        vec = round.(Int64, vec)
        map[:,1] = unique(vec)
        for i = 1:size(map,1)
            map[i,2] = i
        end
        for i = 1:size(vec,1)
            for j = 1:size(map,1)
                if vec[i] == map[j,1]
                    vec[i] = map[j,2]
                end
            end
        end
        normalize(vec)
        return vec
    end

# Function to plot the districts in different colours        
    function plot_generation_area(alloc::DataFrame,shape::Shapefile.Table)
        if length(unique(alloc.area)) > 1
            plot_area = plot(axis=false, ticks=false)
            alloc.shape = Shapefile.shapes(shape)
            normalized_values_area = equalize(alloc.area)
            colors_area = Array([cgrad(:Pastel1_9, length(unique(alloc.area)), categorical = true)[value] for value in normalized_values_area])
            for x = 1:nrow(alloc)
                if alloc[x, :area] == alloc[x, :index]
                    plot!(plot_area, alloc[x, :shape], color=RGB(0/255,0/255,0/255))
                elseif alloc[x, :area] > 0
                    plot!(plot_area, alloc[x, :shape], color=colors_area[x])
                else
                    plot!(plot_area, alloc[x, :shape], color=nothing)
                end
            end
        end
        return plot_area
    end

# Function to plot the districts according to the salestime spend there
    function plot_generation_time(sales_agents::DataFrame, alloc::DataFrame, shape::Shapefile.Table)
        if length(unique(alloc.area)) > 1
            plot_time = plot(axis=false, ticks=false)
            alloc.time .= 0.0
            dicti = Dict(round(Int64,sales_agents.area[i]) => i for i = 1:nrow(sales_agents))
            for i = 1:nrow(alloc)
                alloc.time[i] = sales_agents.hours[dicti[alloc.area[i]]]
            end
            alloc.shape = Shapefile.shapes(shape)
            normalized_values_time = normalize(alloc.time)
            colors_time = Array([cgrad(:matter, length(unique(alloc.area)), categorical = true)[value] for value in normalized_values_time])
            for x = 1:nrow(alloc)
                if alloc[x, :area] == alloc[x, :index]
                    plot!(plot_time, alloc[x, :shape], color=RGB(0/255,0/255,0/255))
                elseif alloc[x, :time] > 0
                    plot!(plot_time, alloc[x, :shape], color=colors_time[x])
                else
                    plot!(plot_time, alloc[x, :shape], color=nothing)
                end
            end
        end
        return plot_time
    end

