function optimisation_salesforce1(N,pp,distance,max_drive,fix,potloc)
    # Location Model
    salesforce = Model(GAMS.Optimizer)
    set_silent(salesforce)

    set_optimizer_attribute(salesforce, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(salesforce, "Solver", "CPLEX")
    set_optimizer_attribute(salesforce, "OptCR",   0.000)
    set_optimizer_attribute(salesforce, "ResLim",  10800)
    set_optimizer_attribute(salesforce, "Threads", 8)
    set_optimizer_attribute(salesforce, "NodLim",  1000000)
    set_optimizer_attribute(salesforce, "Iterlim", 1000000)

    @variable(salesforce, X[1:N,1:N], Bin, container=Array)

    @objective(salesforce,
            Max,
            sum(pp[i,j] * X[i,j] for i = 1:N, j = 1:N if distance[i,j] < max_drive && potloc[i] == 1) - sum(fix * X[i,i] for i = 1:N if potloc[i]==1)
    )

    @constraints(salesforce,
                begin
                tic[j = 1:N], 
                    sum(X[i,j] for i = 1:N if potloc[i]==1) <= 1;

                cut[i = 1:N, j = 1:N; distance[i,j] < max_drive && potloc[i]==1], 
                    X[i,j] - X[i,i] <= 0;

                rmv[i = 1:N; potloc[i] == 1],
                    X[i,i] <= potloc[i];

                end
    )

    print("\n JuMP model sucessfully build. Starting optimisation.")

## Start the optimisation
    JuMP.optimize!(salesforce)

    print("\n Optimisation finished.")

## Check whether a solution was found
    if termination_status(salesforce) == MOI.OPTIMAL
        print("\n Solution is optimal.")
    elseif termination_status(salesforce) == MOI.TIME_LIMIT && has_values(salesforce)
        print("\n Solution is suboptimal due to a time limit, but a primal solution is available.")
    else
        error("\n The model was not solved correctly.")
    end

    gap = abs(objective_bound(salesforce)-objective_value(salesforce))/abs(objective_value(salesforce)+0.00000000001)
    objval = objective_value(salesforce)

    X_opt = Array{Int64,2}(undef,hexnum,hexnum) .= 0
    for i = 1:hexnum
        for j = 1:hexnum
            if value(X[i,j]) == 1
                X_opt[i,j] = 1
            end
        end
    end
    
    return X,gap,objval
end