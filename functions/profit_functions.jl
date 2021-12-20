# Collection of all profit functions

function beta(distance,i,j)
    0.1 + min(0.9,2*distance[i,j]/800)
end

# profit
function profit_plus(α,μ,people,β,b)
    α * μ * people * (1-β)^b # * t^b
end

# travel costs
function profit_minus(β,h,g)
    (h * β + g) # * t
end

## 1 derivation of profit
function profit_der(α,μ,people,β,b)
    α * μ * people * (1-β)^(b) * b # * t^(b-1)
end

function profit_time(α,μ,people,β,b,h,g)
    ((h * β + g)/(α * μ * people * (1-β)^(b) * b))^(1/(b-1))
end

function profit_potential(α,μ,people,β,b,h,g,t)
    α * μ * people * (1-β)^b * t^b - (h * β + g) * t
end

function profit_potential_der(α,μ,people,β,b,h,g,t)
    α * μ * people * (1-β)^b * b * t^(b-1) - (h * β + g)
end
