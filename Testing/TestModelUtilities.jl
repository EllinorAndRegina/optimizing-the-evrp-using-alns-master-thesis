module TestModelUtilities
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..ResultHandeling
    using ..EVRPSetupFunctions
    using ..ParsingFunctions
    using ..ErrorTypes
    using ..SolutionUtilities
    using ..Models
    using ..RechargingFunctions
    using ..EnergyConsumptionFunctions
    using ..BatteryCalculationFunctions
    using ..SettingTypes
    using ..ProblemSpecifierTypes
    using Suppressor
    using Gurobi
    using JuMP

    function test_translate_ALNS_solution_to_model_solution() 
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        
        solution = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)

        model_solution = ResultHandeling.translate_ALNS_solution_to_model_solution(solution, evrp_data, printing = true)

        x_values, y_values, Y_values, p_values = model_solution
        back_to_routes = ResultHandeling.getting_route_index_and_battery_data(x_values, p_values, y_values, Y_values, evrp_data)

        @assert back_to_routes[1] == routes "Warning: something is translated wrong in the x_values"

    end


    function test_translate_ALNS_solution_to_model_solution_emty_routes()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        
        solution = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        # println("solution: ", solution)

         model_solution = ResultHandeling.translate_ALNS_solution_to_model_solution(solution, evrp_data, printing = true)

        x_values, y_values, Y_values, p_values = model_solution


         back_to_routes = ResultHandeling.getting_route_index_and_battery_data(x_values, p_values, y_values, Y_values, evrp_data)

         @assert back_to_routes[1] == routes "Warning: something is translated wrong"

    end


    function test_load_dependent_model()
        file_name = "./Testing/DataForTesting/Feasibility/LoadDependentFeasibleModel.txt" 
        # evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_load_dependent_full(file_name)

        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
        recharging_func = RechargingFunctions.calculate_recharging_time_linear
        
        energy_consump_func_load_dependent = EnergyConsumptionFunctions.load_dependent_energy_consumption
        
        battery_func_full = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
        
        evrp_settings_load_dependent = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func_load_dependent, recharging_func, battery_func_full)
        
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider,
            load_dependent_params = (1.03809 * 0.072338, 0.0012248 * 0.41667),
            truck_weight = 1579.0)

        solution, gurobi_results = Models.run_models(evrp_data, evrp_settings_load_dependent, Gurobi, ProblemSpecifierTypes.load_dependent,n_cs_copies = 1, printing = false)
        
        gurobi_routes = SolutionUtilities.create_solution_from_routes(gurobi_results.best_routes, 
        evrp_data, evrp_settings_load_dependent, throw_infeasible_time_errors = false,                
        throw_infeasible_battery_errors = false)

        battery_arrivals = gurobi_routes.battery_arrival[1]
        battery_departures = gurobi_routes.battery_departure[1]
        times_of_arrival = gurobi_routes.times_of_arrival[1]
        
        @assert !isnothing(solution) "Battery not feasible"
        
        battery_arrivals_lower = [79.0, 59.0, 49.0, 35.0, 66.0, 43.0, 29.0, 63.0, 47.0, 35.0, 15.0]
        battery_arrivals_upper = [80.0, 60.0, 50.0, 36.0, 67.0, 44.0, 30.0, 64.0, 48.0, 36.0, 16.0]
        

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")
 
        battery_departures_lower = [79.69, 59.9, 49.4, 79.69, 66.0, 43.6, 79.69, 63.2, 47.0, 35.5, 15.20]
        battery_departures_upper = [79.69, 60.0, 49.5, 79.69, 66.1, 43.7, 79.69, 63.3, 47.1, 35.6, 15.21]
        
        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")


        times_of_arrival_lower = [0.0, 20.0, 101.0, 166.0, 332.0, 446.0, 551.0, 737.0, 845.0, 948.0, 1071.0]
        times_of_arrival_upper = [0.0, 21.0, 102.0, 167.0, 333.0, 447.0, 552.0, 738.0, 846.0, 949.0, 1072.0]
        
        @assert all(times_of_arrival .>= times_of_arrival_lower) && 
            all(times_of_arrival .<= times_of_arrival_upper) string(
            "Times of arrival not within precalculated limit")
        
        
    end

end