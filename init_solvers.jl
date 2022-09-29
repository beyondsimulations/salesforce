# This file helps to initialise the Gurobi Solver necessary for the
# optimal calculation of the resulting districts
    import Pkg
    Pkg.activate("salesforce")
    Pkg.instantiate()
    if Sys.iswindows()
        ENV["GUROBI_HOME"] = "C:\\gurobi912\\win64"
        Pkg.add("Gurobi")
        Pkg.build("Gurobi")
    elseif  Sys.isapple()
        ENV["GUROBI_HOME"] = "/Library/gurobi950/macos_universal2/"
        Pkg.add("Gurobi")
        Pkg.build("Gurobi")
    elseif Sys.islinux()
        ENV["GUROBI_HOME"] = "Documents/gurobi951/linux64"
        Pkg.add("Gurobi")
        Pkg.build("Gurobi")
    else   
        "Sorry, we didn't define the code for your operating system."
    end