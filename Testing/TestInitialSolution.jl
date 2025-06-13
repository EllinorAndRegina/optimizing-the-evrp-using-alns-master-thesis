module TestTimeWindowHeuristicInital
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..ParsingFunctions

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
end 

module TestGeneralFunctionsInital
    using ..NodeTypes
    using ..DataStruct
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions

    function test_check_all_customers_inserted_not_starting_in_depot()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[2, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
            @assert status "Testing error if start depot has not been inserted correctly - test failed"
        catch e 
            
        end
    end


    function test_check_all_customers_inserted_not_ending_in_depot()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 3]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
            @assert status "Testing error if end depot has not been inserted correctly - test failed"
        catch e 
            
        end

    end

    function test_check_all_customers_inserted_to_many_depot_inserted()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 1, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data)
            @assert status "Testing error if end depot has not been inserted correctly - test failed"
        catch e 
            
        end

    end

    function test_check_all_customers_inserted_not_all_customers_inserted()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 1, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
            @assert status "Testing error if end depot has not been inserted correctly - test failed"
        catch e 
            
        end

    end

    function test_check_all_customers_inserted_customer_inserted_more_then_once()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 3, 6, 1, 1]], 
            evrp_data.nodes[[1, 18, 3, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
            @assert status "Testing error if end depot has not been inserted correctly - test failed"
        catch e 
            
        end

    end

    function test_check_all_customers_inserted_two_cs_in_a_row()

        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 3, 6, 1, 1]], 
            evrp_data.nodes[[1, 18, 3, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]]
        try
            status = InitialSolutionUtilities.check_all_customers_inserted(routes, evrp_data, printing = false)
            @assert status "Testing error if two charging stations have been inserted after eachother - test failed"
        catch e 
            
        end

    end

end


module TestingFullInitialSolutionFunction

    using ..NodeTypes
    using ..DataStruct
    using ..SolutionUtilities
    using ..InitialSolutionUtilities
    using ..SettingTypes
    using ..SolutionTypes
    using ..InitialSolution
    using ..EVRPSetupFunctions
    using Suppressor

    function test_simple_example_initial_solution()
        # file_name = "Testing/DataForTesting/InitialSolution/BasicExampleIInitial.txt"
        data_file = "Data/SchneiderEVRPTW/c101_21.txt"

        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)

        output = @capture_out begin
            global sol = InitialSolution.create_initial_solution(
                evrp_data, evrp_settings, printing = false)
        end
        @assert !isnothing(sol) "This problem is supposed to be feasible"

    end


end