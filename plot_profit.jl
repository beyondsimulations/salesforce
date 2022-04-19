using Plots
using LaTeXStrings

p(t,pr,co,el) = pr * t^el - co * t

plot(t -> p(t,1,0,0.3),0,1500,  labels= "b = 0.30, no costs", legend = :bottomleft, theme = :wong, xlabel= "selling time t", ylabel="profit contribution")
plot!(t -> p(t,1,0.01,0.3),0,1500,  labels= "b = 0.30, costs included")
plot!(t -> p(t,1,0,0.4),0,1500,  labels= "b = 0.40, no costs")
plot!(t -> p(t,1,0.01,0.4),0,1500,  labels= "b = 0.40, costs included")

