

module TestSchneider
    using ..NodeTypes
    using ..ParsingFunctions
    using Suppressor

    # Future note: currently there is no test that compares new lines with
    # previous to see if it is a repeat since this might be desired for 
    # example with simultaneous pickup and delivery

    function test_Schneider_pass() 
        file_name = "./Testing/DataForTesting/Parsing/schneider1.txt"
        n_depots,
        n_charging_stations, 
        n_customers,
        nodes, 
        speed, 
        energy_consumption_rate, 
        battery_capacity, 
        recharging_rate, 
        vehicle_capacity, 
        n_vehicles = ParsingFunctions.parsing_EVRPTW_Schneider(file_name)
        
        node_positions = [node.position for node in nodes]
        time_window_start = [node.time_window_start for node in nodes]
        time_window_end = [node.time_window_end for node in nodes]
        service_times = [node.service_time for node in nodes]
        demand = [node.demand for node in nodes]

        # Expected output 
        n_depots_exp = 1
        n_charging_stations_exp = 2
        n_customers_exp = 3
        node_pos_exp = [(40.0, 50.0), (40.0, 50.0), (73.0, 52.0), (45.0, 68.0), (45.0, 70.0), (42.0, 66.0)]
        speed_exp = 1.0
        energy_consumption_rate_exp = 1.0
        battery_capacity_exp = 79.69
        recharging_rate_exp = 3.39 
        time_window_start_exp = [0.0, 0.0, 0.0, 78.0, 499.0, 863.0]
        time_window_end_exp = [1236.0, 1236.0, 1236.0, 140.0, 553.0, 931.0] 
        service_times_exp = [0.0, 0.0, 0.0, 90.0, 90.0, 90.0]
        vehicle_capacity_exp = 200.0
        demand_exp = [0.0, 0.0, 0.0, 10.0, 30.0, 10.0]
        n_vehicles_exp = 3

        # Compare arrays
        positions_equal = isequal(node_positions, node_pos_exp)
        @assert positions_equal "Schneider passing test - positions are not correct"
        tw_start_equal = isequal(time_window_start, time_window_start_exp)
        @assert tw_start_equal "Schneider passing test - start of time windows are not correct"
        tw_end_equal = isequal(time_window_end, time_window_end_exp)
        @assert tw_end_equal "Schneider passing test - end of time windows are not correct"
        service_equal = isequal(service_times, service_times_exp)
        @assert service_equal "Schneider passing test - service times are not correct"
        demand_equal = isequal(demand, demand_exp)
        @assert demand_equal "Schneider passing test - demands are not correct"
        
        # Compare remaining results
        results = (n_depots, n_charging_stations, 
            n_customers, speed, energy_consumption_rate, 
            battery_capacity, recharging_rate, vehicle_capacity, n_vehicles)

        answers = (n_depots_exp, n_charging_stations_exp, n_customers_exp, speed_exp, 
            energy_consumption_rate_exp, battery_capacity_exp, recharging_rate_exp, 
            vehicle_capacity_exp, n_vehicles_exp)
        
        @assert isequal(results, answers) "Schneider passing test failed"
        return results, answers
    end

    function test_Schneider_negative_numbers()
        file_name = "./Testing/DataForTesting/Parsing/schneider2.txt"
        n_depots,
        n_charging_stations, 
        n_customers,
        nodes, 
        speed, 
        energy_consumption_rate, 
        battery_capacity, 
        recharging_rate, 
        vehicle_capacity, 
        n_vehicles = ParsingFunctions.parsing_EVRPTW_Schneider(file_name)
        
        node_positions = [node.position for node in nodes]
        time_window_start = [node.time_window_start for node in nodes]
        time_window_end = [node.time_window_end for node in nodes]
        service_times = [node.service_time for node in nodes]
        demand = [node.demand for node in nodes]

        
        # Expected output 
        n_depots_exp = 1
        n_charging_stations_exp = 2
        n_customers_exp = 3
        node_pos_exp = [(40.0, 50.0), (40.0, 50.0), (73.0, 52.0), (-45.0, 68.0), (45.0, -70.0), (42.0, 66.0)]
        speed_exp = 1.0f0
        energy_consumption_rate_exp = 1.0
        battery_capacity_exp = 79.69
        recharging_rate_exp = -3.39 
        time_window_start_exp = [0.0, 0.0, 0.0, 78.0, -499.0, 863.0] 
        time_window_end_exp = [1236.0, 1236.0, 1236.0, 140.0, 553.0, -931.0] 
        service_times_exp = [0.0, 0.0, 0.0, -90.0, 90.0, 90.0]
        vehicle_capacity_exp = 200.0
        demand_exp = [0.0, 0.0, 0.0, 10.0, 30.0, 10.0]
        n_vehicles_exp = 5

        # Compare arrays
        positions_equal = isequal(node_positions, node_pos_exp)
        @assert positions_equal "Schneider test negative values - positions are not correct"
        tw_start_equal = isequal(time_window_start, time_window_start_exp)
        @assert tw_start_equal "Schneider test negative values - start of time windows are not correct"
        tw_end_equal = isequal(time_window_end, time_window_end_exp)
        @assert tw_end_equal "Schneider test negative values - end of time windows are not correct"
        service_equal = isequal(service_times, service_times_exp)
        @assert service_equal "Schneider test negative values - service times are not correct"
        demand_equal = isequal(demand, demand_exp)
        @assert demand_equal "Schneider test negative values - demands are not correct"
        
        # Compare remaining results
        results = (n_depots, n_charging_stations, 
            n_customers, speed, energy_consumption_rate, 
            battery_capacity, recharging_rate, vehicle_capacity, n_vehicles)

        answers = (n_depots_exp, n_charging_stations_exp, n_customers_exp, speed_exp, 
            energy_consumption_rate_exp, battery_capacity_exp, recharging_rate_exp, 
            vehicle_capacity_exp, n_vehicles_exp)
        
        @assert isequal(results, answers) "Schneider test negative values - test accept"
        return results, answers
    end

    function test_Schneider_parameters_missing_from_file()
        file_name = "./Testing/DataForTesting/Parsing/schneider3.txt"

        try
            output = ParsingFunctions.parsing_EVRPTW_Schneider(file_name)
            global recreated_error = false
        catch err
            if isa(err, ErrorException)
                global recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error "Schneider test missing values - exception"
        
    end

    function test_Schneider_overwrite_parameters()
        file_name = "./Testing/DataForTesting/Parsing/schneider4.txt"

        output = @capture_out begin
            ParsingFunctions.parsing_EVRPTW_Schneider(file_name)
        end

        gave_warning = false
        if occursin("WARNING: Consumption rate is already set, overwriting.", output)
            gave_warning = true
        end
        
        @assert gave_warning "Schneider overwrite parameters - warning"
    end
    
    function test_Schneider_line_with_wrong_format()
        file_name = "./Testing/DataForTesting/Parsing/schneider5.txt"
        
        try
            output = ParsingFunctions.parsing_EVRPTW_Schneider(file_name)
            global recreated_error = false
        catch err
            if isa(err, ErrorException)
                global recreated_error = true
            else
                rethrow(err)
            end
        end
        
        @assert recreated_error "Schneider line with wrong format - exception"
    end
end

module TestDistancesAndTravelTime
    using ..DataStruct
    using Random

    function test_distances_empty_node_array()
        m = Matrix{Float64}(undef, 0, 2)

        try
            output = DataStruct.calculate_distances(m)
            global recreated_error = false
        catch err
            if isa(err, ArgumentError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Distance function empty array - exception"
    end

    function test_travel_time_negative_speed()
        distances = rand(Float64, 4, 4)
        speed = -1.0

        try
            output = DataStruct.calculate_travel_times(distances, speed)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Travel time function negative speed - exception"
    end

    function test_travel_time_0_speed()
        distances = rand(Float64, 4, 4)
        speed = -0.0

        try
            output = DataStruct.calculate_travel_times(distances, speed)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Travel time function zero speed - exception"
    end

    function test_travel_time_empty_matrix()
        distances = rand(Float64, 0, 0)
        speed = 1.0

        try
            output = DataStruct.calculate_travel_times(distances, speed)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Travel time function empty matrix - exception"
    end

    function test_travel_time_non_square_matrix()
        distances = rand(Float64, 4, 3)
        speed = 1.0

        try
            output = DataStruct.calculate_travel_times(distances, speed)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Travel time function non square matrix - exception"
    end
end

module TestNearestCSToNode
    using ..DataStruct
    using ..ParsingFunctions

    function test_nearest_cs_to_node_small_example()
        file_path = "Testing/DataForTesting/BasicExample.txt"
        data = ParsingFunctions.parsing_EVRPTW_Schneider(file_path)
        nodes = data[4]

        node_positions = [node.position[i] for node in nodes, i in 1:2]
        distances = DataStruct.calculate_distances(node_positions)

        closest_cs = DataStruct.get_closest_charging_stations(nodes, distances)

        expected = nodes[[4, 6, 2, 5, 6, 5, 5, 4, 3, 3, 4, 6, 5, 4, 3, 2, 2, 4]]

        @assert isequal(closest_cs, expected) "Closest cs incorrect for basic example"
    end

    function test_nearest_cs_to_node_no_customers()
        file_path = "Testing/DataForTesting/UnreasonableInput/NoCustomers.txt"
        data = ParsingFunctions.parsing_EVRPTW_Schneider(file_path)
        nodes = data[4]

        node_positions = [node.position[i] for node in nodes, i in 1:2]
        distances = DataStruct.calculate_distances(node_positions)

        closest_cs = DataStruct.get_closest_charging_stations(nodes, distances)

        expected = nodes[[4, 6, 2, 5, 6, 5]]

        @assert isequal(closest_cs, expected) "Closest cs incorrect for no customers"
    end

    function test_nearest_cs_to_node_no_charging_stations()
        file_path = "Testing/DataForTesting/UnreasonableInput/NoCS.txt"
        data = ParsingFunctions.parsing_EVRPTW_Schneider(file_path)
        nodes = data[4]

        node_positions = [node.position[i] for node in nodes, i in 1:2]
        distances = DataStruct.calculate_distances(node_positions)

        closest_cs = DataStruct.get_closest_charging_stations(nodes, distances)

        expected = nodes[[]]

        @assert isequal(closest_cs, expected) "Closest cs incorrect for no cs"
    end
end

module TestDataStruct
    using ..NodeTypes
    using ..DataStruct
    using ..ParsingFunctions
    
    function test_data_struct_EVRPTW_Schneider_no_error_for_large_file()
        file_path = "./Data/SchneiderEVRPTW/c101_21.txt"
        parsing_func = x -> ParsingFunctions.parsing_EVRPTW_Schneider(x)
        struct_obj = DataStruct.DataEVRP(file_path, parsing_func)
        @assert true "Data struct Schneider large file no error"
    end

    function test_data_struct_EVRPTW_with_Schneider()
        file_path = "./Testing/DataForTesting/Parsing/schneider6.txt"
        parsing_func = x -> ParsingFunctions.parsing_EVRPTW_Schneider(x)
        struct_obj = DataStruct.DataEVRP(file_path, parsing_func)
        
        @assert struct_obj.n_depots == 1 "Data struct Schneider small - Only one depot"
        @assert struct_obj.n_charging_stations == 2 "Data struct Schneider small - Two charging stations"
        @assert struct_obj.n_customers == 3 "Data struct Schneider small - Three customers"
        @assert struct_obj.n_vehicles == 3 "Data struct Schneider small - Three vehicles"
        
        node_pos_exp = [(40.0, 50.0) ; (40.0, 50.0) ; (73.0, 52.0) ; (45.0, 68.0) ; (45.0, 70.0) ; (42.0, 66.0)]
        node_pos = [node.position for node in struct_obj.nodes]
        @assert isequal(node_pos, node_pos_exp) "Data struct Schneider small - node positions"
        
        @assert struct_obj.energy_consumption_rate == 1.0 "Data struct Schneider small - consumption rate"
        @assert struct_obj.battery_capacity == 79.69 "Data struct Schneider small - battery consumption"
        @assert struct_obj.recharging_rate == 3.39 "Data struct Schneider small - recharging rate"

        time_window_start_exp = [0.0, 0.0, 0.0, 78.0, 499.0, 863.0]
        time_window_end_exp = [1236.0, 1236.0, 1236.0, 140.0, 553.0, 931.0] 
        time_window_start = [node.time_window_start for node in struct_obj.nodes]
        time_window_end = [node.time_window_end for node in struct_obj.nodes]
        @assert isequal(time_window_start, time_window_start_exp) "Data struct Schneider small - time window start"
        @assert isequal(time_window_end, time_window_end_exp) "Data struct Schneider small - time window end"

        service_times_exp = [0.0, 0.0, 0.0, 90.0, 90.0, 90.0]
        demand_exp = [0.0, 0.0, 0.0, 10.0, 30.0, 10.0]
        service_times = [node.service_time for node in struct_obj.nodes]
        demand = [node.demand for node in struct_obj.nodes]
        @assert isequal(service_times, service_times_exp) "Data struct Schneider small - service times"
        @assert isequal(demand, demand_exp) "Data struct Schneider small - demand"

        @assert struct_obj.vehicle_capacity == 200.0 "Data struct Schneider small - vehicle capacity"
        @assert isnothing(struct_obj.truck_weight) "Data struct Schneider small - truck weight not defined"
        @assert isnothing(struct_obj.energy_consumption_parameters) "Data struct Schneider small - energy consumption params not defined"
    end
end