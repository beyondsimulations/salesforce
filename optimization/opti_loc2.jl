function optimisation_salesforce(hexnum,pp,distance,max_drive,fix,potloc,max_time,ts)
    # Location Model
    salesforce = Model(GAMS.Optimizer)
    set_silent(salesforce)

    set_optimizer_attribute(salesforce, GAMS.ModelType(), "MIP")
    set_optimizer_attribute(salesforce, "Solver", "CPLEX")
    set_optimizer_attribute(salesforce, "OptCR",   0.10)
    set_optimizer_attribute(salesforce, "ResLim",  10800)
    set_optimizer_attribute(salesforce, "Threads", 8)
    set_optimizer_attribute(salesforce, "NodLim",  1000000)
    set_optimizer_attribute(salesforce, "Iterlim", 1000000)

    @variable(salesforce, Y[1:hexnum,1:hexnum], Bin)

    @objective(salesforce,
            Max,
            sum(pp[i,j] * Y[i,j] for i = 1:hexnum, j = 1:hexnum if distance[i,j] < max_drive) - sum(fix * Y[i,i] for i = 1:hexnum)
    )

    @constraints(salesforce,
                begin
                tic[j = 1:hexnum], 
                    sum(Y[i,j] for i = 1:hexnum) <= 1;

                cut[i = 1:hexnum, j = 1:hexnum; distance[i,j] < max_drive], 
                    Y[i,j] - Y[i,i] <= 0;

                rmv[i = 1:hexnum],
                    Y[i,i] <= potloc[i];
                
                mxt[i = 1:hexnum; potloc[i] == 1],
                   sum(ts[i,j] * Y[i,j] for j = 1:hexnum) <= max_time;

                end
    )

    print("\n JuMP model sucessfully build. Starting optimisation.")

## Start the optimisation
    JuMP.optimize!(salesforce)

    print("\n Optimisation finished.")

## Check whether a solution was found
    if termination_status(districting) == MOI.OPTIMAL
        print("\n Solution is optimal.")
    elseif termination_status(districting) == MOI.TIME_LIMIT && has_values(districting)
        print("\n Solution is suboptimal due to a time limit, but a primal solution is available.")
    else
        error("\n The model was not solved correctly.")
    end

    gap = abs(objective_bound(salesforce)-objective_value(salesforce))/abs(objective_value(salesforce)+0.00000000001)
    objval = objective_value(salesforce)
    
    return Y,gap,objval
end