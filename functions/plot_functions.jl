normalize(vec) = [(x - minimum(vec))/(maximum(vec) - minimum(vec)) for x in vec]

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
            
function plot_generation(alloc::DataFrame)
    plot_area = plot(size=(500, 600), axis=false, ticks=false)
    plot_time = plot(size=(500, 600), axis=false, ticks=false)
    if length(unique(alloc.area)) > 1
        alloc.shape = Shapefile.shapes(shape)

        normalized_values_time = normalize(alloc.time)
        normalized_values_area = equalize(alloc.area)

        colors_time = Array([cgrad(:matter, 10, categorical = false, rev = true)[value] for value in normalized_values_time])
        colors_area = Array([cgrad(:Pastel1_9, length(unique(alloc.area)), categorical = true)[value] for value in normalized_values_area])
        
        for x = 1:nrow(alloc)
            if alloc[x, :time] > 0
                plot!(plot_time, alloc[x, :shape], color=colors_time[x])
            else
                plot!(plot_area, alloc[x, :shape], color=nothing)
            end
        end
        
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
    return plot_time, plot_area
end