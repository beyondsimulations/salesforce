# This is the optimisation model used to derive the optimal districts
function districting_model(optcr::Float64,
                            reslim::Int64,
                            cores::Int64,
                            nodlim::Int64,
                            iterlim::Int64,
                            card_BAs::Int64,
                            max_drive::Float64,
                            fix::Float64,
                            drivingtime::Array{Float64,2},
                            profit::Array{Float64,2},
                            silent_optimisation::Bool)

# Initialise the Gurobi model instance
    salesforce = Model(() -> Gurobi.Optimizer(GRB_ENV))
    @suppress begin  
        set_optimizer_attribute(salesforce, "MIPGap",          optcr)
        set_optimizer_attribute(salesforce, "TimeLimit",       reslim)
        set_optimizer_attribute(salesforce, "NodeLimit",       nodlim)
        set_optimizer_attribute(salesforce, "IterationLimit",  iterlim)
        MOI.set(salesforce, MOI.NumberOfThreads(), cores)
    end

    if silent_optimisation == true
        set_silent(salesforce)
    end

    potential_locations = zeros(Bool, size(profit,1)) .= 1

## Initialise the decision variable X
    @variable(salesforce, X[1:card_BAs,1:card_BAs], Bin)
    for i = 1:card_BAs
        if potential_locations[i] == 0
            set_upper_bound(X[i,i], 0)
        end
        for j = 1:card_BAs
            if drivingtime[i,j] > max_drive
                set_upper_bound(X[i,j], 0)
            end
        end
    end
    
## Define the objective function                
    @objective(salesforce, Max,
                    sum(profit[i,j] * X[i,j] for i = 1:card_BAs, j = 1:card_BAs if drivingtime[i,j] < max_drive && potential_locations[i] == 1) - sum(fix * X[i,i] for i = 1:card_BAs if potential_locations[i]==1))

## Define the p-median constraints
    @constraint(salesforce, allocate_one[j = 1:card_BAs],
                    sum(X[i,j] for i = 1:card_BAs if potential_locations[i] == 1) == 1)
    @constraint(salesforce, cut_nocenter[i = 1:card_BAs, j = 1:card_BAs; drivingtime[i,j] <= max_drive && potential_locations[i] == 1],
                    X[i,j] - X[i,i] <= 0)

## Start the optimisation
    if silent_optimisation == true
        @suppress begin
            dur = @elapsed JuMP.optimize!(salesforce)
        end
    else
        dur = @elapsed JuMP.optimize!(salesforce)
    end

## Check whether a solution was found
    if termination_status(salesforce) == MOI.OPTIMAL
        print("\n Optimisation finished, solution is optimal.")
        gap = 0.0
    elseif termination_status(salesforce) == MOI.TIME_LIMIT && has_values(salesforce)
        print("\n Optimisation finished, solution is suboptimal due to a time limit, but a primal solution is available.")
        gap = abs(objective_bound(salesforce)-objective_value(salesforce))/abs(objective_value(salesforce)+0.00000000001)
    else
        error("\n Optimisation finished. The model was not solved correctly.")
    end

## Save the gap and the objective value
    objval = objective_value(salesforce)

## Save the arrays in the appropriate form
    X_opt = round.(Int64,value.(X))

    return  X_opt::Array{Int64,2},
            gap::Float64, 
            objval::Float64,
            dur::Float64
end