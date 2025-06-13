

include("../Types.jl")

# Include function files
include("../Functions/DataParsing.jl")
include("../Functions/EVRPFunctions.jl")
include("../Functions/Utilities.jl")
include("../Functions/ALNSFunctions.jl")
include("../Functions/RemoveOperators.jl")
include("../Functions/InsertOperators.jl")
include("../Functions/InitialSolution.jl")

include("../Functions/ALNS.jl")

include("../Plotting/PlotFunctions.jl")
include("ModelUtilities.jl")
include("ModelFunctions.jl")

using .SettingTypes
using .DataStruct
using .ParsingFunctions
using .ProblemSpecifierTypes

using .BatteryCalculationFunctions
using .EnergyConsumptionFunctions
using .ObjectiveFunctions
using .RechargingFunctions

using .InitialSolution
using .RemoveOperators
using .InsertOperators
using JuMP
ENV["GRB_NO_REVOKE"] = "1"
using Gurobi
using HiGHS
using GLPK


"""
Setup and run the solver on the model. 

# Input arguments

- `datafile::String`: the path to the datafile.
- `problem_specifier::ProblemSpecifierTypes.EVRPType``: specifies which one of 
    the implemented EVRP formulations to solve
- `n_cs_copies::Int`: number of copies of the charging stations.
- `time_limit::Int``: sets the time limit for the run.
- `plotting::Bool`: detemening if wanting to plot the routes from the found solution or not.
- `printing::Bool`: is a bool determining if wanting to print intomation and messages regaring the run.
- `initial_solution_bool::Bool`: determining if wanting to give the solver an initial solution or not.

# Output arguments

- `model_solution`: the solution obtained by the solver.
- `gurobi_results`: the results saved when generating the data. 
- `translated_model_solution`: the solution of the model after post-processing to be comparable to the ALNS results.

"""
function run_model(
        datafile::String,
        n_cs_copies::Int;
        solver::Module = Gurobi,
        problem_specifier::ProblemSpecifierTypes.EVRPType = ProblemSpecifierTypes.full_charging,
        time_limit::Int = -1,
        plotting::Bool = false,
        printing::Bool = false,
        initial_solution_bool::Bool = true
    )

    load_dependent_params = (1.03809 * 0.072338, 0.0012248 * 0.41667) 
    truck_weight = 1579.0
    insert_k_full = 3
    insert_k_partial = 5
    insert_k_load = 4
    insert_score_full = (0.6, 0.6, 0.6)
    insert_score_partial = (1.2, 1.0, 0.2)
    insert_score_load = (0.6, 0.6, 0.8)
    obj_func = ObjectiveFunctions.objective_function_distance!
    obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
    recharging_func = RechargingFunctions.calculate_recharging_time_linear

    energy_consump_func = EnergyConsumptionFunctions.distance_dependent_energy_consumption
    energy_consump_func_load_dependent = EnergyConsumptionFunctions.load_dependent_energy_consumption

    battery_func_full = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
    battery_func_partial = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging

    evrp_data = DataStruct.DataEVRP(
        datafile, 
        ParsingFunctions.parsing_EVRPTW_Schneider, 
        load_dependent_params = load_dependent_params, 
        truck_weight = truck_weight)
    initial_solution = nothing
    if problem_specifier == ProblemSpecifierTypes.full_charging
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func_full)
        if initial_solution_bool
            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings, insert_score_full, insert_k_full)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end
        end
    elseif problem_specifier == ProblemSpecifierTypes.partial_charging
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func_partial)
        if initial_solution_bool
            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings, insert_score_partial, insert_k_partial)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end
        end
    elseif problem_specifier == ProblemSpecifierTypes.load_dependent
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func_load_dependent, recharging_func, battery_func_full)
        if initial_solution_bool
            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings, insert_score_load, insert_k_load)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end
        end
    else
        error("Problem variation not supported")
    end

    if solver == Gurobi
        model_solution, gurobi_results = Models.run_models(evrp_data, evrp_settings, 
            Gurobi, problem_specifier, n_cs_copies = n_cs_copies, printing = printing, 
            time_limit = time_limit, initial_solution = initial_solution)
            
        translated_model_solution = SolutionUtilities.create_solution_from_routes(gurobi_results.best_routes, 
        evrp_data, evrp_settings, throw_infeasible_time_errors = false,           
        throw_infeasible_battery_errors = false)

        if plotting
            PlotFunctions.plot_routes_single(translated_model_solution, evrp_data, "Gurobi solution for $datafile")
        end

        return model_solution, gurobi_results, translated_model_solution
    end

    model_solution = Models.run_models(evrp_data, evrp_settings, 
        Gurobi, problem_specifier, n_cs_copies = n_cs_copies, printing = printing, 
        time_limit = time_limit, initial_solution = initial_solution)

    translated_model_solution = SolutionUtilities.create_solution_from_routes(model_solution[1].routes, 
    evrp_data, evrp_settings, throw_infeasible_time_errors = false,           
    throw_infeasible_battery_errors = false)

    if plotting
        PlotFunctions.plot_routes_single(translated_model_solution, evrp_data, "$solver solution for $datafile")
    end

    return model_solution[1], translated_model_solution

end

