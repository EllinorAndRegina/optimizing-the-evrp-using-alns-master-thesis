include("Types.jl")
include("Plotting/PlotFunctions.jl")
include("Functions/DataParsing.jl")
include("Functions/Utilities.jl")
include("Functions/EVRPFunctions.jl")

using .ParsingFunctions
using .PlotFunctions
using .DataStruct
using .SolutionUtilities

using .ObjectiveFunctions
using .RechargingFunctions
using .EnergyConsumptionFunctions
using .BatteryCalculationFunctions

using JLD2

result_file = "Results/result_extra_long_runs.jld2"
data_file = "Data/SchneiderEVRPTW/rc203_21.txt"
reference_value = 1073.98

evrp_data = DataStruct.DataEVRP(
            data_file, 
            ParsingFunctions.parsing_EVRPTW_Schneider)

results_dict = load(result_file, "results")
initial_solution, gurobi_results, alns_results = results_dict[data_file]

obj_func = ObjectiveFunctions.objective_function_distance!
obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
recharging_func = RechargingFunctions.calculate_recharging_time_linear

energy_consump_func = EnergyConsumptionFunctions.distance_dependent_energy_consumption
energy_consump_func_load_dependent = EnergyConsumptionFunctions.load_dependent_energy_consumption

battery_func_full = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
battery_func_partial = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging

evrp_settings_full = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func, recharging_func, battery_func_full)

evrp_settings_partial = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func, recharging_func, battery_func_partial)

evrp_settings_load_dependent = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func_load_dependent, recharging_func, battery_func_full)

PlotFunctions.plot_routes_single(initial_solution, evrp_data, "Initial")

average_gurobi_time = 0
average_alns_time = 0
average_gurobi_obj = 0
average_alns_obj = 0

# for i in 1:3
#     alns_res_i = alns_results[i]

    PlotFunctions.plot_routes_single(alns_results.solutions_for_plotting[1], evrp_data, "ALNS: data file $data_file")
    
    gurobi_routes = SolutionUtilities.create_solution_from_routes(gurobi_results.best_routes, 
        evrp_data, evrp_settings_full, throw_infeasible_time_errors = false,                      
        throw_infeasible_battery_errors = false)
    PlotFunctions.plot_routes_single(gurobi_routes, evrp_data, "Gurobi: data file $data_file")

    PlotFunctions.plot_operator_weights(alns_results.n_iterations, alns_results.weights_insert, 
        100)
    PlotFunctions.plot_operator_weights(alns_results.n_iterations, alns_results.weights_remove, 
        100)

    PlotFunctions.plot_objectives_time(alns_results.objective_per_iteration, 
        alns_results.time_per_iteration, gurobi_results = gurobi_results, 
        reference_value = reference_value)

    # Calculate averages
    alns_best_obj = minimum(alns_results.objective_per_iteration)
    average_alns_obj += alns_best_obj

    alns_best_t_i = findfirst(x->x == alns_best_obj, alns_results.objective_per_iteration)
    average_alns_time += alns_results.time_per_iteration[alns_best_t_i]

    gurobi_best_obj = gurobi_results.best_value
    average_gurobi_obj += gurobi_best_obj

    gurobi_best_t_i = findfirst(x->x == gurobi_best_obj, gurobi_results.objectives)  
    average_gurobi_time += gurobi_results.times[gurobi_best_t_i]

    println("Gurobi optimal? ", gurobi_results.optimal)
# end

println("ALNS obj: ", average_alns_obj)
println("ALNS time: ", average_alns_time)
println("Gurobi obj: ", average_gurobi_obj)
println("Gurobi time: ", average_gurobi_time)
println("Difference: ", (average_alns_obj/average_gurobi_obj - 1)* 100)

