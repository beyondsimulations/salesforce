# Collection of all profit functions
## currently used profit functions
### calculate the beta for each profit function
function beta(distance,i,j)
    0.1 + min(0.9,2*distance[i,j]/800)
end

### calculate the time that needs to be spend for the max profit
function profit_time(mp,α,μ,people,β,b,h,g)
    ((h * β + g + mp)/(α * μ * people * (1-β)^(b) * b))^(1/(b-1))
end

### calculate the max profit of each area
function profit_potential(α,μ,people,β,b,h,g,t)
    α * μ * people * (1-β)^b * t^b - (h * β + g) * t
end

## 1 derivation of profit potential
function profit_potential_der(mp,α,μ,people,β,b,h,g,t)
    α * μ * people * (1-β)^b * b * t^(b-1) - h * β - g - mp
end
