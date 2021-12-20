function optimisation_loc1(N,pp,distance,max_drive,fix,potloc)
    # Location Model
    loc1 = Model(GAMS.Optimizer)

    set_optimizer_attribute(loc1, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(loc1, "Solver", "CPLEX")
    set_optimizer_attribute(loc1, "OptCR",   0.000)
    set_optimizer_attribute(loc1, "ResLim",  10800)
    set_optimizer_attribute(loc1, "Threads", 8)
    set_optimizer_attribute(loc1, "NodLim",  1000000)
    set_optimizer_attribute(loc1, "Iterlim", 1000000)

    @variable(loc1, X[1:N,1:N], Bin)

    for i = 1:N
        for j = 1:N
            set_upper_bound(X[i,j], potloc[i])
        end
    end


    @objective(loc1,
            Max,
            sum(pp[i,j] * X[i,j] for i = 1:N, j = 1:N if distance[i,j] < max_drive && potloc[i] == 1) - sum(fix * X[i,i] for i = 1:N if potloc[i]==1)
    )

    @constraints(loc1,
                begin
                tic[j = 1:N], 
                    sum(X[i,j] for i = 1:N if potloc[i]==1) <= 1;

                cut[i = 1:N, j = 1:N; distance[i,j] < max_drive && potloc[i]==1], 
                    X[i,j] - X[i,i] <= 0;

                rmv[i = 1:N; potloc[i] == 1],
                    X[i,i] <= potloc[i];

                end
    )

    JuMP.optimize!(loc1)

    gap = abs(objective_bound(loc1)-objective_value(loc1))/abs(objective_value(loc1)+0.00000000001)
    objval = objective_value(loc1)
    
    return X,gap,objval
end