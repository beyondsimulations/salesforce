# Initialise the solver
import Pkg
Pkg.activate("salesforce")
if Sys.iswindows()
    ENV["GUROBI_HOME"] = "C:\\gurobi912\\win64"
    Pkg.add("Gurobi")
    Pkg.build("Gurobi")
elseif  Sys.isapple()
    ENV["GUROBI_HOME"] = "/Library/gurobi950/macos_universal2/"
    Pkg.add("Gurobi")
    Pkg.build("Gurobi")
else
    "Sorry, we didn't define the code for your operating system."
end