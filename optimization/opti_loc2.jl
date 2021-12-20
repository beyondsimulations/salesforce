function optimisation_loc2(N,pp,distance,max_drive,fix,potloc,max_time,ts)
    # Location Model
    loc2 = Model(GAMS.Optimizer)

    set_optimizer_attribute(loc2, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(loc2, "Solver", "CPLEX")
    set_optimizer_attribute(loc2, "OptCR",   0.10)
    set_optimizer_attribute(loc2, "ResLim",  10800)
    set_optimizer_attribute(loc2, "Threads", 8)
    set_optimizer_attribute(loc2, "NodLim",  1000000)
    set_optimizer_attribute(loc2, "Iterlim", 1000000)

    @variable(loc2, Y[1:N,1:N], Bin)

    @objective(loc2,
            Max,
            sum(pp[i,j] * Y[i,j] for i = 1:N, j = 1:N if distance[i,j] < max_drive) - sum(fix * Y[i,i] for i = 1:N)
    )

    @constraints(loc2,
                begin
                tic[j = 1:N], 
                    sum(Y[i,j] for i = 1:N) <= 1;

                cut[i = 1:N, j = 1:N; distance[i,j] < max_drive], 
                    Y[i,j] - Y[i,i] <= 0;

                rmv[i = 1:N],
                    Y[i,i] <= potloc[i];
                
                mxt[i = 1:N; potloc[i] == 1],
                   sum(ts[i,j] * Y[i,j] for j = 1:N) <= max_time;

                end
    )

    JuMP.optimize!(loc2)

    gap = abs(objective_bound(loc2)-objective_value(loc2))/abs(objective_value(loc2)+0.00000000001)
    objval = objective_value(loc2)
    
    return Y,gap,objval
end