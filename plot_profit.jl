using Plots
using LaTeXStrings

p(t,pr,co,el) = pr * t^el - co * t

plot_font = "Computer Modern";
default(fontfamily=plot_font,framestyle=:box, label=nothing, grid=false, tickfontsize=10)
plot(t -> p(t,1,0,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b",linestyle = :solid, linewidth = 1.0, legend = :bottomleft, 
palette = :Dark2_5, xlabel= L"selling time $t$", ylabel=L"profit contribution $p(t)$")
plot!(t -> p(t,1,0.01,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)
plot!(t -> p(t,1,0,0.3),0,1500, size = (450,400), labels= L"b = 0.3, p(t) = t^b", linestyle = :solid, linewidth = 1.0)
plot!(t -> p(t,1,0.01,0.3),0,1500,  labels= L"b = 0.3, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)

savefig("profit.pdf")

