module TestObjectiveFunctions
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..ParsingFunctions

    function test_total_route_distance()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        d = ObjectiveFunctions.calculate_total_route_distance(route, evrp_data)
        @assert d > 172.0 && d < 172.1 "Total distance of specified route incorrect"
    end

    function test_total_route_distance_empty_route()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route = NodeTypes.Node[]
        d = ObjectiveFunctions.calculate_total_route_distance(route, evrp_data)
        @assert d == 0.0 "Distance not 0 for empty route"
    end
end

module TestBatteryCalculationFunctions
    using ..DataStruct
    using ..SettingTypes
    using ..ObjectiveFunctions
    using ..RechargingFunctions
    using ..EnergyConsumptionFunctions
    using ..BatteryCalculationFunctions
    using ..EVRPSetupFunctions
    using ..ErrorTypes

    function test_full_charging_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route, evrp_data, evrp_settings)
        
        @assert is_feasible "Battery not feasible"
        
        battery_arrivals_lower = [79.69, 59.0, 47.8, 32.7, 65.1, 41.0, 26.2, 61.9, 43.9, 31.1, 8.0]
        battery_arrivals_upper = [79.69, 59.1, 47.9, 32.8, 65.2, 41.1, 26.3, 62.0, 44.0, 31.2, 8.1]

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")

        battery_departures_lower = [79.69, 59.0, 47.8, 79.69, 65.1, 41.0, 79.69, 61.9, 43.9, 31.1, 8.0]
        battery_departures_upper = [79.69, 59.1, 47.9, 79.69, 65.2, 41.1, 79.69, 62.0, 44.0, 31.2, 8.1]
        
        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")

        recharging_times_lower = [0.0, 0.0, 0.0, 159.0, 0.0, 0.0, 181.2, 0.0, 0.0, 0.0, 0.0]
        recharging_times_upper = [0.0, 0.0, 0.0, 159.1, 0.0, 0.0, 181.3, 0.0, 0.0, 0.0, 0.0]
        
        @assert all(recharging_times .>= recharging_times_lower) && 
            all(recharging_times .<= recharging_times_upper) string(
            "Recharging time not within precalculated limit")
    end

    function test_full_charging_infeasible_no_error()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, _, _, _ = evrp_settings.calculate_battery_func(route, 
            evrp_data, evrp_settings, throw_error = false)
        
        @assert !is_feasible "Battery is not suppposed to be feasible"
    end

    function test_full_charging_infeasible_error()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        recreated_error = false
        try 
            evrp_settings.calculate_battery_func(route, evrp_data, 
                evrp_settings)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error
    end

    function test_full_charging_unnecessary_charging_station()  # also tests multiple in a row 
        file_name = string("./Testing/DataForTesting/Feasibility/", 
            "MultipleConsecutiveCSFeasibleFullCharging.txt")
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 2, 3, 6, 5, 3, 4, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route, evrp_data, evrp_settings)
        
        @assert is_feasible "Battery not feasible"
        
        battery_arrivals_lower = [79.69, 68.2, 60.7, 52.5, 34.4, 25.2, 73.6, 50.5]
        battery_arrivals_upper = [79.69, 68.3, 60.8, 52.6, 34.5, 25.3, 73.7, 50.6]

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")
        
        battery_departures_lower = [79.69, 79.69, 79.69, 52.5, 34.4, 79.69, 73.6, 50.5]
        battery_departures_upper = [79.69, 79.69, 79.69, 52.6, 34.5, 79.69, 73.7, 50.6]

        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")

        recharging_times_lower = [0.0, 38.6, 64.3, 0.0, 0.0, 184.4, 0.0, 0.0]
        recharging_times_upper = [0.0, 38.7, 64.4, 0.0, 0.0, 184.5, 0.0, 0.0]

        @assert all(recharging_times .>= recharging_times_lower) && 
            all(recharging_times .<= recharging_times_upper) string(
            "Recharging times not within precalculated limit")
    end

    function test_full_charging_load_dependent()
        file_name = "./Testing/DataForTesting/Feasibility/LoadDependentFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_load_dependent_full(file_name)
                
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route, evrp_data, evrp_settings)
        
        @assert is_feasible "Battery not feasible"
        
        battery_arrivals_lower = [79.69, 59.9, 49.4, 35.2, 66.0, 43.6, 29.8, 63.2, 47.0, 35.5, 15.20]
        battery_arrivals_upper = [79.69, 60.0, 49.5, 35.3, 66.1, 43.7, 29.9, 63.3, 47.1, 35.6, 15.21]

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")

        battery_departures_lower = [79.69, 59.9, 49.4, 79.69, 66.0, 43.6, 79.69, 63.2, 47.0, 35.5, 15.20]
        battery_departures_upper = [79.69, 60.0, 49.5, 79.69, 66.1, 43.7, 79.69, 63.3, 47.1, 35.6, 15.21]
        
        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")

        recharging_times_lower = [0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 168.9, 0.0, 0.0, 0.0, 0.0]
        recharging_times_upper = [0.0, 0.0, 0.0, 151.0, 0.0, 0.0, 169.0, 0.0, 0.0, 0.0, 0.0]
        
        @assert all(recharging_times .>= recharging_times_lower) && 
            all(recharging_times .<= recharging_times_upper) string(
            "Recharging time not within precalculated limit")
    end

    function test_partial_charging_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/PartialChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route, evrp_data, evrp_settings)
        
        @assert is_feasible "Battery not feasible"
        
        battery_arrivals_lower = [79.69, 59.0, 47.8, 32.7, 38.9, 14.8, 0.0, 53.9, 35.8, 23.0, 0.0]
        battery_arrivals_upper = [79.69, 59.1, 47.9, 32.8, 39.0, 14.9, 0.0, 54.0, 36.0, 23.1, 0.0]

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")

        battery_departures_lower = [79.69, 59.0, 47.8, 53.4, 38.9, 14.8, 71.6, 53.9, 35.8, 23.0, 0.0]
        battery_departures_upper = [79.69, 59.1, 47.9, 53.5, 39.0, 14.9, 71.7, 54.0, 36.0, 23.1, 0.0]
        
        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")

        recharging_times_lower = [0.0, 0.0, 0.0, 70.1, 0.0, 0.0, 242.8, 0.0, 0.0, 0.0, 0.0]
        recharging_times_upper = [0.0, 0.0, 0.0, 70.3, 0.0, 0.0, 242.9, 0.0, 0.0, 0.0, 0.0]

        @assert all(recharging_times .>= recharging_times_lower) && 
            all(recharging_times .<= recharging_times_upper) string(
            "Recharging times not within precalculated limit")
    end

    function test_partial_charging_infeasible_no_error()
        file_name = "./Testing/DataForTesting/Feasibility/PartialChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, _, _, _ = evrp_settings.calculate_battery_func(route, 
            evrp_data, evrp_settings, throw_error = false)
        
        @assert !is_feasible "Battery is not suppposed to be feasible"
    end

    function test_partial_charging_infeasible_error()
        file_name = "./Testing/DataForTesting/Feasibility/PartialChargingFeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        
        route_i = [1, 8, 9, 5, 7, 10, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        recreated_error = false
        try 
            evrp_settings.calculate_battery_func(route, evrp_data, 
                evrp_settings)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error
    end

    function test_partial_charging_unnecessary_charging_station()
        file_name = string("./Testing/DataForTesting/Feasibility/", 
            "MultipleConsecutiveCSFeasiblePartialCharging.txt")
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(file_name)
        
        route_i = [1, 2, 3, 6, 5, 3, 4, 1]
        route = evrp_data.nodes[route_i]

        is_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route, evrp_data, evrp_settings)
        
        @assert is_feasible "Battery not feasible"
        
        battery_arrivals_lower = [79.69, 68.2, 49.3, 27.2, 9.2, 0.0, 23.0, 0.0]
        battery_arrivals_upper = [79.69, 68.3, 49.4, 27.3, 9.3, 0.0, 23.1, 0.0]

        @assert all(battery_arrivals .>= battery_arrivals_lower) && 
            all(battery_arrivals .<= battery_arrivals_upper) string("Battery", 
            " upon arrival not within precalculated limit")

        battery_departures_lower = [79.69, 68.2, 54.4, 27.2, 9.2, 29.1, 23.0, 0.0]
        battery_departures_upper = [79.69, 68.3, 54.5, 27.3, 9.3, 29.2, 23.1, 0.0]

        @assert all(battery_departures .>= battery_departures_lower) && 
            all(battery_departures .<= battery_departures_upper) string(
            "Battery upon departure not within precalculated limit")

        recharging_times_lower = [0.0, 0.0, 17.2, 0.0, 0.0, 98.8, 0.0, 0.0]
        recharging_times_upper = [0.0, 0.0, 17.3, 0.0, 0.0, 98.9, 0.0, 0.0]

        @assert all(recharging_times .>= recharging_times_lower) && 
            all(recharging_times .<= recharging_times_upper) string(
            "Recharging times not within precalculated limit")
    end

    function test_partial_charging_negative_battery()
        data_file = "Testing/DataForTesting/Feasibility/FullChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)

        route = evrp_data.nodes[[1, 8, 9, 7, 10, 6, 13, 12, 11, 1]]
        is_feasible, battery_levels_arrival, battery_levels_departure, 
            recharging_times = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging(route, evrp_data, evrp_settings, throw_error = false)

        @assert !is_feasible "Supposed to be non feasible"
        @assert battery_levels_arrival[6] < 0 "Negative battery at 6th node"
        @assert all(battery_levels_arrival[[1, 2, 3, 4, 5, 7, 8, 9, 10]] .>= 0) "Remaining nodes should have positive charge"

        route = evrp_data.nodes[[1, 8, 9, 5, 7, 10, 13, 12, 11, 1]]
        is_feasible, battery_levels_arrival, battery_levels_departure, 
            recharging_times = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging(route, evrp_data, evrp_settings, throw_error = false)
        
        @assert !is_feasible "Supposed to be non feasible"
        @assert all(battery_levels_arrival[8:10] .< 0) "Negative battery at nodes 8 to 10"
        @assert all(battery_levels_arrival[1:7] .>= 0) "Remaining nodes should have positive charge"
    end
end
