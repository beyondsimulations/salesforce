# Districting optimisation model
function districting_model(optcr::Float64,
                            reslim::Int64,
                            cores::Int64,
                            nodlim::Int64,
                            iterlim::Int64,
                            hex::Int64,
                            potential_locations::Vector{Int64},
                            max_drive::Float64,
                            fix::Float64,
                            drivingtime::Array{Float64,2},
                            profit::Array{Float64,2},
                            adjacent::Array{Bool,2},
                            compactness::String,
                            N::Array{Bool,3},
                            M::Array{Bool,3}, 
                            card_n::Array{Int64,2},
                            card_m::Array{Int64,2},
                            opensource::Bool,
                            silent_optimisation::Bool)

# Initialise the GAMS model instance
    if opensource == true
        salesforce = Model(Cbc.Optimizer)
        set_optimizer_attribute(salesforce, "logLevel", 1)
        set_optimizer_attribute(salesforce, "ratioGap",  optcr)
        set_optimizer_attribute(salesforce, "seconds",   reslim)
        set_optimizer_attribute(salesforce, "maxNodes",  nodlim)
    else
        salesforce = Model(GAMS.Optimizer)
        set_optimizer_attribute(salesforce, GAMS.ModelType(), "MIP")
        set_optimizer_attribute(salesforce, "Solver",    "CPLEX")
        set_optimizer_attribute(salesforce, "IterLim",   iterlim)
        set_optimizer_attribute(salesforce, "optCr",     optcr)
        set_optimizer_attribute(salesforce, "ResLim",    reslim)
        set_optimizer_attribute(salesforce, "NodLim",    nodlim)
    end
    set_optimizer_attribute(salesforce, "threads",    cores)

    if silent_optimisation == true
        set_silent(salesforce)
    end

## Initialise the decision variables Y and X
    @variable(salesforce, Y[1:hex], Bin)
    @variable(salesforce, X[1:hex,1:hex], Bin)

    for i = 1:hex
        if potential_locations[i] == 0
            set_upper_bound(Y[i], 0)
        end
        for j = 1:hex
            if drivingtime[i,j] > max_drive
                set_upper_bound(X[i,j], 0)
            end
        end
    end
    
## Define the objective function                
    @objective(salesforce, Max,
                    sum(profit[i,j] * X[i,j] for i = 1:hex, j = 1:hex if drivingtime[i,j] < max_drive && potential_locations[i] == 1) - sum(fix * Y[i] for i = 1:hex if potential_locations[i]==1))

## Define the p-median constraints
    @constraint(salesforce, allocate_one[j = 1:hex],
                    sum(X[i,j] for i = 1:hex if potential_locations[i] == 1) == 1)
    @constraint(salesforce, cut_nocenter[i = 1:hex, j = 1:hex; drivingtime[i,j] <= max_drive && potential_locations[i] == 1],
                    X[i,j] - Y[i] <= 0)

## Define the contiguity and compactness constraints
    if compactness == "C0"
        print("\n Compactness: C0")
    end
    if compactness == "C1"
        print("\n Compactness: C1")
        @constraint(salesforce, C1[i = 1:hex, j = 1:hex; drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    X[i,j] <= sum(X[i,v] for v = 1:hex if N[i,j,v] == 1))
    end
    if compactness == "C2"
        print("\n Compactness: C2")
        @constraint(salesforce, C2a[i = 1:hex, j = 1:hex; card_n[i,j] <= 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    X[i,j] <= sum(X[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(salesforce, C2b[i = 1:hex, j = 1:hex; card_n[i,j] > 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    2*X[i,j] <= sum(X[i,v] for v = 1:hex if N[i,j,v] == 1))
    end
    if compactness == "C3"
        print("\n Compactness: C3")
        @constraint(salesforce, C3a[i = 1:hex, j = 1:hex; card_n[i,j] <= 1 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    X[i,j] <= sum(X[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(salesforce, C3b[i = 1:hex, j = 1:hex; card_n[i,j] > 1 && card_m[i,j] < 5 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    2*X[i,j] <= sum(X[i,v] for v = 1:hex if N[i,j,v] == 1))
        @constraint(salesforce, C3c[i = 1:hex, j = 1:hex; card_m[i,j] == 5 && drivingtime[i,j] <= max_drive && adjacent[i,j] == 0 && i != j],
                    3*X[i,j] <= sum(X[i,v] for v = 1:hex if M[i,j,v] == 1))
    end
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

## Save the gap and the objective value
    gap = abs(objective_bound(salesforce)-objective_value(salesforce))/abs(objective_value(salesforce)+0.00000000001)
    objval = objective_value(salesforce)

## Save the arrays in the appropriate form
    X_opt = Array{Int64,2}(undef,hex,hex) .= 0
    Y_opt = Vector{Int64}(undef,hex) .= 0
    for i = 1:hex
        if value(Y[i]) > 0
            Y_opt[i] = 1
        end
        for j = 1:hex
            if value(X[i,j]) > 0
                X_opt[i,j] = 1
            end
        end
    end

    return  X_opt::Array{Int64,2},
            Y_opt::Vector{Int64},
            gap::Float64, 
            objval::Float64
end