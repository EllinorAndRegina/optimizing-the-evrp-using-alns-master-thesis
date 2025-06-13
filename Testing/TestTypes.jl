module TestGetChargingStationFunctions
    using Distances
    using LinearAlgebra
    using ..NodeTypes
    using ..EVRPSetupFunctions
    using ..DataStruct
    # get_closest_charging_station_to_arcs

    function test_running_get_closest_charging_station_to_arcs()
        data_file = "Testing/DataForTesting/Types/SmallEX.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        nodes = evrp_data.nodes
        distances = evrp_data.distances


        expected_cs = [
            nothing    nodes[3]  nodes[2]  nodes[3]  nodes[2]  nodes[3];
            nodes[3]   nothing   nothing   nodes[3]  nodes[3]  nodes[3];
            nodes[2]   nothing   nothing   nodes[2]  nodes[2]  nodes[2];
            nodes[3]   nodes[3]  nodes[2]  nothing   nodes[2]  nodes[3];
            nodes[2]   nodes[3]  nodes[2]  nodes[2]  nothing   nodes[2];
            nodes[3]   nodes[3]  nodes[2]  nodes[3]  nodes[2]  nothing
        ]
        

        # Call the function to test
        closest_cs_to_arcs = DataStruct.get_closest_charging_station_to_arcs(nodes, distances)

        # Check the output
        @assert closest_cs_to_arcs == expected_cs "The closest charging stations to arcs do not match the expected values."
        
    end

    function test_get_closest_charging_station_to_arcs_only_charging_stations()
        data_file = "Testing/DataForTesting/Types/SmallEX.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        nodes = evrp_data.nodes
        charging_stations = filter(x -> x.node_type == NodeTypes.charging_station, nodes)
        distances = evrp_data.distances


        expected = Matrix{Nothing}(undef, length(charging_stations), length(charging_stations))
        
        # Call the function to test
        closest_cs_to_arcs = DataStruct.get_closest_charging_station_to_arcs(charging_stations, distances)

        # Check the output
        @assert closest_cs_to_arcs == expected "The closest charging stations to arcs do not match the expected values."
    end

    function test_get_closest_charging_station_to_arcs_only_customers()
        data_file = "Testing/DataForTesting/Types/SmallEX.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        nodes = evrp_data.nodes
        charging_stations = filter(x -> x.node_type == NodeTypes.customer, nodes)
        distances = evrp_data.distances


        expected = Matrix{Nothing}(undef, length(charging_stations), length(charging_stations))
        
        # Call the function to test
        closest_cs_to_arcs = DataStruct.get_closest_charging_station_to_arcs(charging_stations, distances)

        # Check the output
        @assert closest_cs_to_arcs == expected "The closest charging stations to arcs do not match the expected values."
    end

    

end