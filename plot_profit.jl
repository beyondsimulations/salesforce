# This file outputs graphs to grasp the profit contribution function and its changes
# through the explicit addition of traveling costs 

# Loading necessary packages for the plots
    using Plots
    using LaTeXStrings

# Profit contribution function
    p(t,pr,co,el) = pr * t^el - co * t

# Derivative of the profit contribution function
    pd(t,pr,co,el) = pr * el * t^(el-1) - co

# Design of the plots
    plot_font = "Computer Modern";
    default(fontfamily=plot_font,framestyle=:box, label=nothing, grid=false, tickfontsize=10)

# Plot of the profit contribution function
    plot(t -> p(t,1,0,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b",linestyle = :solid, linewidth = 1.0, legend = :bottomleft, 
    palette = :Dark2_5, xlabel= L"selling time $t$", ylabel=L"profit contribution $p(t)$")
    plot!(t -> p(t,1,0.01,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)
    plot!(t -> p(t,1,0,0.3),0,1500, size = (450,400), labels= L"b = 0.3, p(t) = t^b", linestyle = :solid, linewidth = 1.0)
    plot!(t -> p(t,1,0.01,0.3),0,1500,  labels= L"b = 0.3, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)
    savefig("profit.pdf")

# Plot of the derivative of the profit contribution function
    plot(t -> pd(t,1,0,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b",linestyle = :solid, linewidth = 1.0, legend = :topright, 
    palette = :Dark2_5, xlabel= L"selling time $t$", ylabel=L"profit contribution $p(t)$")
    plot!(t -> pd(t,1,0.01,0.4),0,1500,  labels= L"b = 0.4, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)
    plot!(t -> pd(t,1,0,0.3),0,1500, size = (450,400), labels= L"b = 0.3, p(t) = t^b", linestyle = :solid, linewidth = 1.0)
    plot!(t -> pd(t,1,0.01,0.3),0,1500,  labels= L"b = 0.3, p(t) = t^b-0.01t",linestyle = :solid, linewidth = 1.0)
    savefig("profit_der.pdf")