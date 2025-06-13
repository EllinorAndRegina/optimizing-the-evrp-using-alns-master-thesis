module TestSolutionUtils
    using ..DataStruct
    using ..SolutionUtilities
    using ..ParsingFunctions
    using ..ErrorTypes

    function test_weight_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        @assert SolutionUtilities.check_weight_constraint(route, evrp_data)
    end

    function test_check_weight_infeasible_no_error()
        file_name = "./Testing/DataForTesting/Feasibility/WeightInfeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        @assert !SolutionUtilities.check_weight_constraint(route, evrp_data, throw_error = false)
    end

    function test_check_weight_infeasible_error()
        file_name = "./Testing/DataForTesting/Feasibility/WeightInfeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]

        recreated_error = false
        try 
            SolutionUtilities.check_weight_constraint(route, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error
    end

    function test_arrival_time_to_next_node_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        recharging_time = 0.0
        prev_node = evrp_data.nodes[7]
        node = evrp_data.nodes[10]
        arrival_prev = 340.58

        feasible, arrival_time = SolutionUtilities.calculate_arrival_time_to_node(
            node, prev_node, arrival_prev, recharging_time, evrp_data)
        @assert feasible
        @assert arrival_time > 454.62 && arrival_time < 454.63
    end

    function test_arrival_time_to_node_from_cs_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        recharging_time = 181.26
        prev_node = evrp_data.nodes[6]
        node = evrp_data.nodes[13]
        arrival_prev = 559.49

        feasible, arrival_time = SolutionUtilities.calculate_arrival_time_to_node(
            node, prev_node, arrival_prev, recharging_time, evrp_data)
        @assert feasible
        @assert arrival_time > 758.47 && arrival_time < 758.48
    end

    function test_arrival_time_to_next_node_infeasible_no_error()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        recharging_time = 159.09
        prev_node = evrp_data.nodes[5]
        node = evrp_data.nodes[7]
        arrival_prev = 167.93

        feasible, arrival_time = SolutionUtilities.calculate_arrival_time_to_node(
            node, prev_node, arrival_prev, recharging_time, evrp_data,
            throw_error = false)
        @assert !feasible
    end

    function test_arrival_time_to_next_node_infeasible_error()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        recharging_times = 159.09
        prev_node = evrp_data.nodes[5]
        node = evrp_data.nodes[7]
        arrival_prev = 167.93

        recreated_error = false
        try 
            SolutionUtilities.calculate_arrival_time_to_node(
                node, prev_node, arrival_prev, recharging_times, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error
    end

    function test_arrival_time_to_node_too_early()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        recharging_times = 159.09
        prev_node = evrp_data.nodes[5]
        node = evrp_data.nodes[7]
        arrival_prev = 160.93

        feasible, arrival_time = SolutionUtilities.calculate_arrival_time_to_node(
            node, prev_node, arrival_prev, recharging_times, evrp_data)

        @assert feasible
        @assert arrival_time == 340.0
    end

    function test_check_time_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/FullChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 0.0, 159.09, 0.0, 0.0, 181.26, 0.0, 0.0, 0.0, 0.0]
        is_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(route, recharging_times, evrp_data)
        @assert is_feasible
    end

    function test_check_time_infeasible_no_error()
        file_name = "./Testing/DataForTesting/Feasibility/TimeInfeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, 
            ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 0.0, 159.09, 0.0, 0.0, 181.26, 0.0, 0.0, 0.0, 0.0]
        is_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(
            route, recharging_times, evrp_data, throw_error = false)
        @assert !is_feasible
    end

    function test_check_time_infeasible_error()
        file_name = "./Testing/DataForTesting/Feasibility/TimeInfeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, 
            ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 0.0, 159.09, 0.0, 0.0, 181.26, 0.0, 0.0, 0.0, 0.0]

        recreated_error = false
        try 
            SolutionUtilities.calculate_arrival_times_for_route(
                route, recharging_times, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error
    end

    function test_check_time_with_waiting_time()
        file_name = "./Testing/DataForTesting/Feasibility/WaitingTime.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, 
            ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 0.0, 159.09, 0.0, 0.0, 181.26, 0.0, 0.0, 0.0, 0.0]
        is_feasible, arrival_times = SolutionUtilities.calculate_arrival_times_for_route(
            route, recharging_times, evrp_data)
        @assert is_feasible
        @assert arrival_times[end] > 1094.0 && arrival_times[end] < 1095.0
    end

    function test_check_time_multiple_and_consecutive_visits_to_cs()
        file_name = "./Testing/DataForTesting/Feasibility/MultipleConsecutiveCSFeasibleFullCharging.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 2, 3, 6, 5, 3, 4, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 38.65, 64.31, 0.0, 0.0, 184.48, 0.0, 0.0]
        is_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(route, recharging_times, evrp_data)
        @assert is_feasible
    end

    function test_check_time_partial_feasible()
        file_name = "./Testing/DataForTesting/Feasibility/PartialChargingFeasible.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 0.0, 70.21, 0.0, 0.0, 242.89, 0.0, 0.0, 0.0, 0.0]
        is_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(route, recharging_times, evrp_data)
        @assert is_feasible
    end

    function test_check_time_partial_multiple_and_consecutive_visits_to_cs()
        file_name = "./Testing/DataForTesting/Feasibility/MultipleConsecutiveCSFeasiblePartialCharging.txt" 
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        route_i = [1, 2, 3, 6, 5, 3, 4, 1]
        route = evrp_data.nodes[route_i]
        recharging_times = [0.0, 0.0, 17.29, 0.0, 0.0, 98.89, 0.0, 0.0]
        is_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(route, recharging_times, evrp_data)
        @assert is_feasible
    end
end

module TestRemoveUtilities
    using ..NodeTypes
    using ..EVRPSetupFunctions
    using ..RemoveUtilities 
    
    function test_calculate_remove_costs_for_route_small_example()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)

        route1 = evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]
        costs1 = RemoveUtilities.calculate_remove_costs_for_route(route1, 1, evrp_data, evrp_settings)
        costs1 = map(x -> (x[1], x[2], round(x[3], digits=3)), costs1)
        expected1 = [(1, 2, -0.071), (1, 3, -3.675), (1, 4, -11.289), (1, 5, -0.659), (1, 6, -1.016)]
        @assert isequal(costs1, expected1) "Remove costs for route 1 incorrect."

        route2 = evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]
        costs2 = RemoveUtilities.calculate_remove_costs_for_route(route2, 2, evrp_data, evrp_settings)
        costs2 = map(x -> (x[1], x[2], round(x[3], digits=3)), costs2)
        expected2 = [(2, 2, -2.342), (2, 3, -2.577), (2, 4, -3.424), (2, 5, -0.030), (2, 6, -1.834)]
        @assert isequal(costs2, expected2) "Remove costs for route 2 incorrect."

        route3 = evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]
        costs3 = RemoveUtilities.calculate_remove_costs_for_route(route3, 3, evrp_data, evrp_settings)
        costs3 = map(x -> (x[1], x[2], round(x[3], digits=3)), costs3)
        expected3 = [(3, 2, -19.562), (3, 3, -0.15), (3, 4, -3.062), (3, 5, -0.998), (3, 6, -18.956)]
        @assert isequal(costs3, expected3) "Remove costs for route 3 incorrect."

        route4 = evrp_data.nodes[[1, 17, 2, 1]]
        costs4 = RemoveUtilities.calculate_remove_costs_for_route(route4, 4, evrp_data, evrp_settings)
        costs4 = map(x -> (x[1], x[2], round(x[3], digits=3)), costs4)
        expected4 = [(4, 2, -5.764), (4, 3, -4.236)]
        @assert isequal(costs4, expected4) "Remove costs for route 4 incorrect."
    end

    function test_calculate_remove_costs_for_empty_route()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)

        route = evrp_data.nodes[[]]
        costs = RemoveUtilities.calculate_remove_costs_for_route(route, 1, evrp_data, evrp_settings)
        expected = Vector{Tuple{Int, Int, Float64}}(undef, 0)
        @assert isequal(costs, expected) "Remove costs for empty route incorrect."
    end

    function test_calculate_remove_costs_for_route_with_single_customer()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)

        route = evrp_data.nodes[[1, 16, 1]]
        costs = RemoveUtilities.calculate_remove_costs_for_route(route, 1, evrp_data, evrp_settings)
        costs = map(x -> (x[1], x[2], round(x[3], digits=3)), costs)
        expected = [(1, 2, -12.649)]
        @assert isequal(costs, expected) "Remove costs for route with single customer incorrect."
    end
end

module TestInsertUtilities
    using ..NodeTypes
    using ..EVRPSetupFunctions
    using ..InsertUtilities
    using ..ALNSSetupFunctions

    using Suppressor

    function test_nearest_cs_insert_feasible_one_iteration()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 13, 7, 1]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)

        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 13, 7, 5, 1]]) "Cs inserted in wrong position"
    end

    function test_nearest_cs_insert_feasible_multiple_iterations()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/MultipleCsNeededNotInRow.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 2, 3, 4, 1]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)
        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 2, 6, 3, 5, 4, 1]]) "Cs inserted in wrong positions"
    end

    function test_nearest_cs_insert_infeasible()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BatteryInfeasibleCSInsertion.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 2, 3, 4, 1]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)
        @assert !status "It should be infeasible"
        @assert isequal(route, evrp_data.nodes[[1, 2, 3, 4, 1]]) "Route should be unchanged"
    end

    function test_nearest_cs_insert_positive_charge()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 10, 15, 9, 1]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)

        @assert status
        @assert isequal(route, evrp_data.nodes[[1, 10, 15, 9, 1]]) "Battery feasible, no cs should be inserted"
    end

    function test_nearest_cs_insert_time_infeasible()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/TimeInfeasibleCSInsertion.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 2, 3, 1]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)
        @assert !status "It should be infeasible"
        @assert isequal(route, evrp_data.nodes[[1, 2, 3, 1]]) "Route should be unchanged"
    end

    function test_nearest_cs_insert_two_cs_needed()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/MultipleCSInRow.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[1, 2, 1]]
        
        output = @capture_out begin
            global status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)
        end
        @assert status "It should be feasible"
        @assert isequal(route, evrp_data.nodes[[1, 4, 3, 2, 3, 4, 1]]) "Route is incorrect"
    end

    function test_nearest_cs_insert_empty_routes()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        route = evrp_data.nodes[[]]
        
        status = InsertUtilities.nearest_charging_stations_insert!(route, evrp_data, evrp_settings)

        @assert status "Should be true for empty route"
        @assert length(route) == 0 "Route should be empty"
    end

    # to test 
    # orimliga värden på k: <= 0, > n_insertions
    # nothing closest cs
    # rankning är korrekt om någon inte går att sätta in "i mitten"
    # icke battery feasible, time feasible
    # partial
    # flera lika insertions, dvs samma cs är närmast prev, curr och arc
    # 

    # println(map(x->x.node_index, route))

    function test_charging_stations_k_insert_basic()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 2)
        route = evrp_data.nodes[[1, 13, 7, 1]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 13, 7, 5, 1]]) "Cs inserted in wrong position"
    end

    function test_charging_stations_k_insert_basic_partial()
        data_file = "Testing/DataForTesting/Feasibility/PartialChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[1, 8, 9, 7, 10, 13, 12, 11, 1]]

        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]]) "Cs inserted in wrong position"
    end

    function test_charging_stations_k_insert_closest_cs_is_nothing()
        data_file = "Testing/DataForTesting/InsertOperators/CSInsert/ClosestCSNothing.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[1, 2, 3, 4, 3, 2, 1]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert !status "It should be impossible"
        @assert isequal(route, evrp_data.nodes[[1, 2, 3, 4, 3, 2, 1]]) "Route is supposed to be unchanged"
    end

    function test_charging_stations_k_insert_illegal_values_on_k()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 1000)
        route = evrp_data.nodes[[1, 13, 7, 1]]
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)
        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 13, 7, 5, 1]]) "Cs inserted in wrong position"

        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 0)
        route = evrp_data.nodes[[1, 13, 7, 1]]
        output = @capture_out begin
            status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
                evrp_settings, alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
        end
        @assert !status "It should be impossible"
        @assert isequal(route, evrp_data.nodes[[1, 13, 7, 1]]) "Route should be unchanged"
        @assert contains(output, "WARNING: Your value on k_cs_insert is unreasonable. It should be > 0.")

        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = -1)
        route = evrp_data.nodes[[1, 13, 7, 1]]
        output = @capture_out begin
            global status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
                evrp_settings, alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
        end
        @assert !status "It should be impossible"
        @assert isequal(route, evrp_data.nodes[[1, 13, 7, 1]]) "Route should be unchanged"
        @assert contains(output, "WARNING: Your value on k_cs_insert is unreasonable. It should be > 0.")
    end

    function test_charging_stations_k_insert_only_infeasible_insertions()
        data_file = "Testing/DataForTesting/Feasibility/FullChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 2)
        route = evrp_data.nodes[[1, 8, 9, 7, 10, 13, 12, 11, 1]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert !status "It should not be able to insert with k=2"
        @assert isequal(route, evrp_data.nodes[[1, 8, 9, 7, 10, 13, 12, 11, 1]]) "Route is supposed to be unchanged"
    end

    function test_charging_stations_k_insert_many_possible_insertions()
        data_file = "Testing/DataForTesting/InsertOperators/CSInsert/ManyInsertions.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[1, 8, 9, 10]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be possible"
        @assert isequal(route, evrp_data.nodes[[1, 8, 9, 7, 10]]) "Route is supposed to be unchanged"
    end

    function test_charging_stations_k_insert_multile_cs_needed_in_row()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/MultipleCSInRow.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 2)
        route = evrp_data.nodes[[1, 2, 1]]
        
        output = @capture_out begin
            global status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
                evrp_settings, alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
        end

        @assert status "It should be feasible"
        @assert isequal(route, evrp_data.nodes[[1, 4, 3, 2, 3, 4, 1]]) "Route is incorrect"
    end

    function test_charging_stations_k_insert_multile_cs_needed_not_in_row()
        data_file = "Testing/DataForTesting/Feasibility/FullChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[1, 8, 9, 7, 10, 13, 12, 11, 1]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be a success"
        @assert isequal(route, evrp_data.nodes[[1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]]) "Cs inserted in wrong position"
    end

    function test_charging_stations_k_insert_no_cs_needed()
        data_file = "Testing/DataForTesting/Feasibility/FullChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be a success since no cs needed"
        @assert isequal(route, evrp_data.nodes[[1, 8, 9, 5, 7, 10, 6, 13, 12, 11, 1]]) "route should be unchanged"
    end

    function test_charging_stations_k_insert_on_empty_route()
        data_file = "Testing/DataForTesting/Feasibility/FullChargingFeasible.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(k_cs_insert = 3)
        route = evrp_data.nodes[[]]
        
        status = InsertUtilities.charging_stations_k_insert!(route, evrp_data, 
            evrp_settings, alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert)

        @assert status "It should be a success since route is empty"
        @assert isequal(route, evrp_data.nodes[[]]) "route should be unchanged"
    end



    function test_find_min_in_cost_matrix_single_least_value()
        costs = [(1, 3.4, false) (3, 2.3, true) (5, 7.8, false);
                (3, 6.5, true) (4, 4.4, true) (5, 5.5, false)]
        node_to_insert, corr_route = InsertUtilities.find_min_in_cost_matrix(costs)
        @assert node_to_insert == 2 "Wrong node chosen"
        @assert corr_route == 1 "Node inserted into the wrong route"
    end

    function test_find_min_in_cost_matrix_empty_matrix()
        costs = Matrix{Tuple{Int, Float64, Bool}}(undef, 0, 0)
        node_to_insert, corr_route = InsertUtilities.find_min_in_cost_matrix(costs)
        @assert isnothing(node_to_insert) "No node was supposed to be chosen"
        @assert isnothing(corr_route) "No node was supposed to be chosen"
    end

    function test_find_min_in_cost_matrix_multiple_min()
        costs = [(1, 3.4, false) (3, 2.3, true) (5, 7.8, false);
                (3, 6.5, true) (4, 2.3, true) (5, 5.5, false)]
        node_to_insert, corr_route = InsertUtilities.find_min_in_cost_matrix(costs)
        @assert node_to_insert == 2 "Wrong node chosen"
        @assert corr_route == 1 "Node inserted into the wrong route"
    end

    function test_find_min_in_cost_matrix_only_inf()
        costs = [(1, Inf, false) (3, Inf, true) (5, Inf, false);
                (3, Inf, true) (4, Inf, true) (5, Inf, false)]
        node_to_insert, corr_route = InsertUtilities.find_min_in_cost_matrix(costs)
        @assert isnothing(node_to_insert) "No node was supposed to be chosen"
        @assert isnothing(corr_route) "No node was supposed to be chosen"
    end



    function test_cost_calculation_empty_route()
        file_name = "./Testing/DataForTesting/BasicExample.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = NodeTypes.Node[]
        node = evrp_data.nodes[16]

        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == 2 "Insert in wrong position"
        @assert min_obj_delta > 12.64 && min_obj_delta < 
            12.65 "Objective not correct for empty route"
        @assert is_feasible
    end

    function test_cost_calculation_only_infeasible_insertions()
        file_name = "./Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]
        node = evrp_data.nodes[19]
        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == -1 "Insert in wrong position"
        @assert min_obj_delta == Inf "Objective not correct for empty route"
        @assert !is_feasible
    end

    function test_cost_calculation_multiple_min()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/EqualCostOfInsertion.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 3, 1]]
        node = evrp_data.nodes[2]
        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == 2 "Insert in wrong position"
        @assert is_feasible
    end

    function test_cost_calculation_single_min()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/EqualCostOfInsertion.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 2, 4, 1]]
        node = evrp_data.nodes[3]
        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == 3 "Insert in wrong position"
        @assert is_feasible
    end

    function test_cost_calculation_weight_infeasible()
        file_name = "./Testing/DataForTesting/BasicExample.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 11, 14, 16, 1]]
        node = evrp_data.nodes[7]

        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == -1 "Inserted in wrong position"
        @assert min_obj_delta == Inf "Objective not correct"
        @assert !is_feasible
    end

    function test_cost_calculation_time_infeasible()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 2, 3, 1]]
        node = evrp_data.nodes[4]

        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)
        
        @assert pos == -1 "Inserted in wrong position"
        @assert min_obj_delta == Inf "Objective not correct"
        @assert !is_feasible
    end

    function test_cost_calculation_battery_infeasible()
        file_name = "./Testing/DataForTesting/BasicExample.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = NodeTypes.Node[]
        node = evrp_data.nodes[7]

        pos, min_obj_delta, is_feasible = 
            InsertUtilities.calculate_cost_of_inserting_node(node, route, 
            evrp_data, evrp_settings)

        @assert pos == 2 "Inserted in wrong position"
        @assert min_obj_delta > 72.11 && min_obj_delta < 
            72.12 "Objective not correct"
        @assert !is_feasible
    end



    function test_find_k_best_per_customer_basic()
        k = 3
        costs = Dict{Tuple{Int, Int}, Vector{Tuple{Int, Float64, Bool}}}()

        costs[(7, 1)] = [(2, 5.5, false), (3, 3.2, true), (4, 1.5, false)]
        costs[(7, 2)] = [(2, 3.5, true), (3, 5.6, true), (4, 5.6, false), (5, 2.7, false)]
        costs[(8, 1)] = [(2, 3.9, true), (3, 8.2, false), (4, 4.3, false)]
        costs[(8, 2)] = [(2, 4.7, true), (3, 7.2, false), (4, 6.3, true), (5, 5.1, false)]

        k_best7 = InsertUtilities.find_k_best_per_customer(costs, 7, 2, k)
        @assert isequal(k_best7, [(1, 4, 1.5, false), (2, 5, 2.7, false), (1, 3, 3.2, true)])

        k_best8 = InsertUtilities.find_k_best_per_customer(costs, 8, 2, k)
        @assert isequal(k_best8, [(1, 2, 3.9, true), (1, 4, 4.3, false), (2, 2, 4.7, true)])
    end

    function test_find_k_best_per_customer_route_shorter_than_k()
        k = 4
        costs = Dict{Tuple{Int, Int}, Vector{Tuple{Int, Float64, Bool}}}()

        costs[(7, 1)] = [(2, 5.5, false), (3, 3.2, true), (4, 1.5, false)]
        costs[(7, 2)] = [(2, 3.5, true), (3, 5.6, true), (4, 5.6, false), (5, 2.7, false)]
        costs[(8, 1)] = [(2, 3.9, true), (3, 8.2, false), (4, 4.3, false)]
        costs[(8, 2)] = [(2, 4.7, true), (3, 7.2, false), (4, 6.3, true), (5, 5.1, false)]

        k_best7 = InsertUtilities.find_k_best_per_customer(costs, 7, 2, k)
        @assert isequal(k_best7, [(1, 4, 1.5, false), (2, 5, 2.7, false), (1, 3, 3.2, true), (2, 2, 3.5, true)])

        k_best8 = InsertUtilities.find_k_best_per_customer(costs, 8, 2, k)
        @assert isequal(k_best8, [(1, 2, 3.9, true), (1, 4, 4.3, false), (2, 2, 4.7, true), (2, 5, 5.1, false)])
    end

    function test_find_k_best_per_customer_n_inserts_for_customer_less_than_k()
        k = 5
        costs = Dict{Tuple{Int, Int}, Vector{Tuple{Int, Float64, Bool}}}()

        costs[(7, 1)] = [(2, 5.5, false), (3, 3.2, true)]
        costs[(7, 2)] = [(2, 3.5, true), (3, 5.6, true)]
        costs[(8, 1)] = [(2, 3.9, true), (3, 8.2, false), (4, 4.3, false)]
        costs[(8, 2)] = [(2, 4.7, true), (3, 7.2, false), (4, 6.3, true), (5, 5.1, false)]

        k_best7 = InsertUtilities.find_k_best_per_customer(costs, 7, 2, k)
        @assert isequal(k_best7, [(1, 3, 3.2, true), (2, 2, 3.5, true), (1, 2, 5.5, false), (2, 3, 5.6, true)])

        k_best8 = InsertUtilities.find_k_best_per_customer(costs, 8, 2, k)
        @assert isequal(k_best8, [(1, 2, 3.9, true), (1, 4, 4.3, false), (2, 2, 4.7, true), (2, 5, 5.1, false), (2, 4, 6.3, true)])
    end



    function test_calculate_k_best_costs_of_inserting_node_basic()
        file_name = "./Testing/DataForTesting/Utilities/SmallExampleForKRegretUtilities.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 3, 2, 5, 1]]
        node = evrp_data.nodes[4]

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 3, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, [(3, 0.030,true), (4, 0.146, true), 
            (2, 1.010, true)]) "k_best is incorrect - basic 1"

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 4, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, [(3, 0.030,true), (4, 0.146, true), (2, 1.010, true), 
            (5, 1.126, true)]) "k_best is incorrect - basic 2"
    end

    function test_calculate_k_best_costs_of_inserting_node_empty_route()
        file_name = "./Testing/DataForTesting/Utilities/SmallExampleForKRegretUtilities.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[]]
        node = evrp_data.nodes[4]

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 3, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, [(2, 2.408, true)]) "k_best is incorrect - empty route"
    end

    function test_calculate_k_best_costs_of_inserting_node_route_shorter_than_k()
        file_name = "./Testing/DataForTesting/Utilities/SmallExampleForKRegretUtilities.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 3, 2, 5, 1]]
        node = evrp_data.nodes[4]

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 6, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, [(3, 0.030,true), (4, 0.146, true), (2, 1.010, true), 
            (5, 1.126, true)]) "k_best is incorrect - short route"
    end

    function test_calculate_k_best_costs_of_inserting_node_time_infeasible_insertions()
        file_name = "./Testing/DataForTesting/Utilities/SmallExampleForKRegretUtilitiesTimeInfeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 3, 2, 5, 1]]
        node = evrp_data.nodes[4]

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 4, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, [(3, 0.030,true), (2, 1.010, true)]) "k_best is incorrect - time infeasibility"
    end

    function test_calculate_k_best_costs_of_inserting_node_weight_infeasible_insertions()
        file_name = "./Testing/DataForTesting/Utilities/SmallExampleForKRegretUtilitiesWeightInfeasible.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        route = evrp_data.nodes[[1, 3, 2, 5, 1]]
        node = evrp_data.nodes[4]

        k_best = InsertUtilities.calculate_k_best_costs_of_inserting_node(node, route, 4, evrp_data, evrp_settings)
        k_best = map(x -> (x[1], round(x[2], digits=3), x[3]), k_best)

        @assert isequal(k_best, []) "k_best is incorrect - weight infeasibility"
    end

end

module TestInitialSolutionUtilities
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..ParsingFunctions
    using ..ErrorTypes
    using Suppressor

    ################# Tests for arrival_time_to_node() #################

    function test_arrival_time_to_node_in_tw_start_current_time()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowAccepted.txt"
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        node = evrp_data.nodes[7] 
        prev_node = evrp_data.nodes[1]
        current_time = 0.0
        printing = false
        expected_time = 18.6815

        current_time = InitialSolutionUtilities.arrival_time_to_node(node, prev_node, current_time, printing, evrp_data)

        @assert expected_time - 0.1 <= current_time <= expected_time + 0.1  "Time window constraints are not accepted"
        return (current_time, expected_time)
    end 


    function test_arrival_time_to_node_before_tw_start_current_time()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        node = evrp_data.nodes[7] 
        prev_node = evrp_data.nodes[1]
        current_time = 0.0
        printing = false
        expected_time = 78.0

        current_time = InitialSolutionUtilities.arrival_time_to_node(node, prev_node, current_time, printing, evrp_data)

        @assert expected_time == current_time  "Time window constraints: arrived before and waited - test not accepted"
        return (current_time, expected_time)
    end 

    
    ################# Tests for insert_cs_at_previous_node() #################


    function test_insert_cs_at_previous_node_enough_battery_to_reach_cs_battery_level()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node = evrp_data.nodes[1] 
        battery_level_prev = 40.0
        time_departure_prev = 0.0
        expected_battery = evrp_data.battery_capacity

        _, battery_level_departure, _ = InitialSolutionUtilities.insert_cs_at_previous_node(node, battery_level_prev, time_departure_prev, evrp_data,  evrp_settings)
        @assert expected_battery == battery_level_departure  "Battery constraint: testig if can reach charging station - test not accepted"
        return (battery_level_departure, expected_battery)
    end


    function test_insert_cs_at_previous_node_not_enough_battery_to_reach_cs()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node = evrp_data.nodes[1] 
        battery_level_prev = 0.0
        time_departure_prev = 0.0
        expected_return = nothing

        output = InitialSolutionUtilities.insert_cs_at_previous_node(node, battery_level_prev, time_departure_prev, evrp_data,  evrp_settings)
        @assert expected_return == output  "Battery constraint: testing return if not able to reach cs - test not accepted"
        return ("Values:",output,"Expected", expected_return)
    end
    
    ################# Tests for check_enough_battery_to_visit_node_or_add_cs() #################

    function test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_enough_to_travel_to_customer_status()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node=evrp_data.nodes[7] 
        prev_node=evrp_data.nodes[1] 
        current_battery = evrp_data.battery_capacity
        current_time = 5.0
        description = "Test"
        printing = false
        
        output = InitialSolutionUtilities.check_if_battery_enough_to_visit_node_or_add_charging_station(node, prev_node, current_battery, current_time, description, evrp_data, evrp_settings, printing)
        
        @assert !isnothing(output) "Testing check_enough_battery_to_visit_node_or_add_cs: Charging, reaches cs, and reaches node. Should not give nothing- test not accepted"
        
        # return (output, (expected_battery, expected_prev_node_cs, expected_prev_node_cs, "Calculated time"))
    end

    function test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_enough_to_travel_to_customer_battery_arrival_node()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node=evrp_data.nodes[1] 
        prev_node=evrp_data.nodes[8] 
        current_battery = 14.0
        current_time = 5.0
        description = "Test"
        printing = false
        expected_battery = 47.0
        battery_arrival_node, _, _, _ = InitialSolutionUtilities.check_if_battery_enough_to_visit_node_or_add_charging_station(node, prev_node, current_battery, current_time, description, evrp_data, evrp_settings, printing)
        @assert expected_battery - 0.1 <= battery_arrival_node <= expected_battery + 0.1 "Testing check_enough_battery_to_visit_node_or_add_cs: Charging, reaches cs, and reaches node. Testing battery level - test not accepted"
        # return (battery_arrival_node, expected_battery)
    end



    function test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_enough_to_travel_to_customer_prev_node_and_cs()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node=evrp_data.nodes[1] 
        prev_node=evrp_data.nodes[8] 
        current_battery = 14.0
        current_time = 5.0
        description = "Test"
        printing = false
        expected_prev_node_index = evrp_data.closest_charging_station_per_node[prev_node.node_index].node_index
        _, prev_node_output, charging_station, _ = InitialSolutionUtilities.check_if_battery_enough_to_visit_node_or_add_charging_station(node, prev_node, current_battery, current_time, description, evrp_data, evrp_settings, printing)
        
        @assert expected_prev_node_index == charging_station.node_index && expected_prev_node_index == prev_node_output.node_index "Testing check_enough_battery_to_visit_node_or_add_cs: Charging, reaches cs, and reaches node. Testing if correct prev_node and charging_station- test not accepted"
        # return ("Previous node", prev_node.node_index, "Charging station", charging_station.node_index, "Expected". expected_prev_node_index)
    end



    function test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_not_enough_to_travel_to_customer()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowLowBatteryCapacity.txt" 
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node=evrp_data.nodes[1] 
        prev_node=evrp_data.nodes[8] 
        current_battery = 14.0
        current_time = 5.0
        description = "Test"
        printing = false
        output = InitialSolutionUtilities.check_if_battery_enough_to_visit_node_or_add_charging_station(node, prev_node, current_battery, current_time, description, evrp_data, evrp_settings, printing)
        
        @assert output == nothing "Testing check_enough_battery_to_visit_node_or_add_cs: Charging, reaches cs, but not reaching node. Should give nothing- test not accepted"
        return ("Values: ", output, "Expected: ", nothing)
    end 


    function test_check_enough_battery_to_visit_node_or_add_cs_dont_need_to_charge()
        file_name = "Testing/DataForTesting/InitialSolution/FullChargingInitialTimeWindowArriveBefore.txt"
        evrp_data,  evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)

        node=evrp_data.nodes[1] 
        prev_node=evrp_data.nodes[8] 
        current_battery = 14.0
        current_time = 5.0
        description = "Test"
        printing = false
    
        output = InitialSolutionUtilities.check_if_battery_enough_to_visit_node_or_add_charging_station(node, prev_node, current_battery, current_time, description, evrp_data, evrp_settings, printing)
        
        @assert !isnothing(output) "Testing check_enough_battery_to_visit_node_or_add_cs: Do not need to charge. Should not return nothing- test not accepted"
    end

    function check_all_customers_inserted_no_depot_first()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]

        recreated_error = false
        try 
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error
        
    end

    function check_all_customers_inserted_no_depot_last()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]

        recreated_error = false
        try 
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error
    end

    function check_all_customers_inserted_depot_in_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 1, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]

        recreated_error = false
        try 
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error
    end

    function check_all_customers_inserted_route_all_charging_stations() 
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[]], 
            evrp_data.nodes[[1, 2, 6, 1]], 
            evrp_data.nodes[[1, 4, 1]], 
            evrp_data.nodes[[1, 5, 1]],
            ]
        recreated_error = false
        try 
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error
    end

    function check_all_customers_inserted_dublette_customer()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 10, 5, 8, 1]],
            ]

        recreated_error = false
        try 
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                recreated_error = true
            else
                println("Unexpected error: ", err)
                println("Error type: ", typeof(err))
                rethrow(err)
            end
        end

        @assert recreated_error
    end

    function check_all_customers_inserted_missing_customer()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]

        expected_msg = "Main.ErrorTypes.InfeasibleSolutionError(\"Not all customers have been inserted succesfully. The type indicies of these customers are: [4]\")"
        error_thrown = false

        try
            InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
        catch err
            if isa(err, ErrorTypes.InfeasibleSolutionError)
                error_thrown = true
                actual_msg = string(err)
                @assert actual_msg == expected_msg "Expected error message to be:\n\"$expected_msg\"\nbut got:\n\"$actual_msg\""
            else
                rethrow(err)
            end
        end

        @assert error_thrown "Expected InfeasibleSolutionError was not thrown"
    end

    function check_all_customers_inserted_emty_routes_and_list()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes =[evrp_data.nodes[[]], 
                evrp_data.nodes[[]], 
                evrp_data.nodes[[]], 
                evrp_data.nodes[[]]]

        output = @capture_out begin
            InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = true)
        end
        @assert contains(output, "All routes are empty!") 
            "There is not print when all routes are emty"
    end


    function test_check_all_customers_inserted_two_cs_in_a_row()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2,2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]

        output = @capture_out begin
            InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = true)
        end
        @assert contains(output, "Warning: Objective value are inf!") 
            "There is not print when all routes are emty"
    end
end 