# This file contains interchangeable functions that can be set in the 
# EVRPSettings object.

module ObjectiveFunctions 
    using ..NodeTypes
    using ..DataStruct
    using ..SolutionTypes
    
    """
    Compute and save the total distance of all routes as the objective value 
    for a solution.

    """
    function objective_function_distance!(
            solution::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP
        )::Float64

        obj_value = 0.0
        for route in solution.routes
            obj_value += calculate_total_route_distance(route, evrp_data)
        end
        solution.objective_value = obj_value
        return obj_value
    end

    """
    Compute the total distance of one route.

    """
    function calculate_total_route_distance(
            route::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP
        )::Float64

        if length(route) == 0
            return 0.0
        end
        total_dist = sum(evrp_data.distances[node.node_index, 
            route[i+1].node_index] for (i, node) in enumerate(route[1:end - 1]))
        return total_dist
    end

    # If you add more objective functions, it is a good idea to test that it 
    # works as inteded with all functions that use EVRPSettings :)
end

module RechargingFunctions
    using ..DataStruct
    using ..ErrorTypes

    """
    Compute the recharging time at a charging station given the assumption that 
    the charging is linear.

    Is by default set to cause battery infeasibility errors, but it can be 
    turned off using the key_word argument `throw_error::Bool`.

    """
    function calculate_recharging_time_linear(
            battery_arrival::Float64, 
            battery_departure::Float64, 
            evrp_data::DataStruct.DataEVRP;
            throw_error::Bool = true
        )::Float64

        if throw_error && (battery_arrival < 0 || battery_departure < 0 || 
                battery_arrival > evrp_data.battery_capacity || 
                battery_departure > evrp_data.battery_capacity)
            throw(ErrorTypes.InfeasibleSolutionError(
                "Something is wrong with your battery?"))
        end

        if battery_arrival < 0 
            # Solution not feasible, it will be corrected at a later stage
            # so the exact value is of no importance here.
            return 0.0
        end

        if battery_arrival > battery_departure
            println(string("Warning: Vehicle stopped at charging station ",
                "without charging."))
            return 0.0
        end

        return evrp_data.recharging_rate * (battery_departure - battery_arrival)
    end
end

module EnergyConsumptionFunctions
    using ..DataStruct
    """
    Compute the energy consumption between two nodes assuming the consumption 
    is linear and dependent only on the distance between the nodes.

    """
    function distance_dependent_energy_consumption(
            node_i::Int, 
            prev_node_i::Int, 
            weight::Float64,
            evrp_data::DataStruct.DataEVRP
        )::Float64

        return evrp_data.energy_consumption_rate * 
            evrp_data.distances[prev_node_i, node_i]
    end

    """
    Compute the energy consumption between two nodes assuming the consumption 
    is linear and dependent on the weight of the vehicle as well as the travel 
    times between nodes.

    """
    function load_dependent_energy_consumption(
            node_i::Int,
            prev_node_i::Int,
            weight_departure_prev_node::Float64,
            evrp_data::DataStruct.DataEVRP
        )::Float64

        phi1, phi2 = evrp_data.energy_consumption_parameters
        M = evrp_data.truck_weight
        return (phi1 + phi2 * (weight_departure_prev_node + M)) * 
            evrp_data.travel_times[prev_node_i, node_i]
    end
end

module BatteryCalculationFunctions
    using ..DataStruct
    using ..SettingTypes
    using ..NodeTypes
    using ..ErrorTypes

    """
    Given a route, this function calculates the battery levels when 
    arriving to and departing from each node in the route as well as the 
    recharging times at the charging stations using the full charging policy. 
    
    If `throw_error::Bool` is true then an error will be thrown if the 
    battery level at any node is negative.
    
    # Returns: 
    - Bool, it is true if the solution is feasible with regards to the battery
        constraint, false otherwise
    - Vector{Float64}, the battery levels upon arrival for the 
        vehicle in charge of the given route. The size of the vector is the 
        same as the size of the route.
    - Vector{Vector{Float64}}, the battery level upon departure for the 
        vehicle in charge of the given route. The size of the vector is the 
        same as the size of the route.
    - Vector{Vector{Float64}}, the recharging times at all the nodes in the 
        route. The recharging time at a customer is 0.0. The size of the vector
        is the same as the size of the route.

    """
    function calculate_battery_levels_for_route_full_charging(
            route::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings;
            throw_error::Bool = true
        )

        battery_levels_arrival = Vector{Float64}(undef, length(route))
        battery_levels_departure = Vector{Float64}(undef, length(route))
        recharging_times = zeros(Float64, length(route))

        prev_node = nothing
        is_feasible = true
        
        current_weight = 0.0
        if length(route) > 0
            current_weight = sum(node.demand for node in route)
        end

        for (i, node) in enumerate(route)
            if i == 1 # skip start depot
                prev_node = node 
                battery_levels_arrival[i] = evrp_data.battery_capacity
                battery_levels_departure[i] = evrp_data.battery_capacity
                continue
            end

            # Initialize battery level to battery at departure from previous node
            battery_level = battery_levels_departure[i - 1]

            # Remove enery needed to get from previous node to current and save 
            # result
            battery_level -= evrp_settings.energy_consumption_func(node.node_index,
                prev_node.node_index, current_weight, evrp_data)
            battery_levels_arrival[i] = battery_level

            # Calculate recharging times if node is a charging station and 
            # save battery when departing
            if node.node_type == NodeTypes.charging_station
                recharging_time = evrp_settings.recharging_func( 
                    battery_level, evrp_data.battery_capacity, evrp_data, 
                    throw_error = throw_error)
                recharging_times[i] = recharging_time

                battery_levels_departure[i] = evrp_data.battery_capacity
            else
                battery_levels_departure[i] = battery_level
            end 
            
            # Check feasibility
            if battery_level < 0.0
                is_feasible = false
                if throw_error
                    throw(ErrorTypes.InfeasibleSolutionError(
                        "Too little battery at node $(node.node_index)"))
                end
            end

            current_weight -= node.demand
            prev_node = node
        end

        return is_feasible, battery_levels_arrival, battery_levels_departure, 
            recharging_times
    end

    """
    Given a route, this function calculates the battery levels when 
    arriving to and departing from each node in the route as well as the 
    recharging times at the charging stations using the partial charging policy. 
    Assumes that the vehicle arrives with 0 battery to charging stations and the 
    end depot efter the inital battery at the depot has been depleted.
    
    If `throw_error::Bool` is true then an error will be thrown if the 
    battery level at any node is negative.
    
    # Returns: 
    - Bool, it is true if the solution is feasible with regards to the battery
        constraint, false otherwise
    - Vector{Float64}, the battery levels upon arrival for the 
        vehicle in charge of the given route. The size of the vector is the 
        same as the size of the route.
    - Vector{Vector{Float64}}, the battery level upon departure for the 
        vehicle in charge of the given route. The size of the vector is the 
        same as the size of the route.
    - Vector{Vector{Float64}}, the recharging times at all the nodes in the 
        route. The recharging time at a customer is 0.0. The size of the vector
        is the same as the size of the route.

    """
    function calculate_battery_levels_for_route_partial_charging(
            route::Vector{NodeTypes.Node},
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings;
            throw_error::Bool = true
        )
        
        battery_levels_arrival = Vector{Float64}(undef, length(route))
        battery_levels_departure = Vector{Float64}(undef, length(route))
        recharging_times = zeros(Float64, length(route))

        # Looping in reverse order (from end depot to start depot) to check 
        # the required battery level in each node
        battery_arrival_tmp_reverse = Vector{Float64}(undef, length(route))
        battery_departure_cs_tmp_reverse = Float64[]

        prev_node = nothing
        current_weight = 0.0
        for (i, node) in enumerate(reverse(route))
            if node.node_type == NodeTypes.customer
                # If we are at a customer, we require enough battery to travel 
                # to all customers between node the end depot or the next 
                # charging station in route
                battery_needed = battery_arrival_tmp_reverse[i - 1] + 
                    evrp_settings.energy_consumption_func(node.node_index, 
                    prev_node.node_index, current_weight, evrp_data)
                battery_arrival_tmp_reverse[i] = battery_needed

            elseif node.node_type == NodeTypes.charging_station
                # If we are at a charging station it is ok if we used up all the 
                # battery to reach it. The battery required at departure is 
                # just enough to reach the end depot or the next charging station
                battery_arrival_tmp_reverse[i] = 0.0 # Just enough to reach node
                battery_departure = battery_arrival_tmp_reverse[i - 1] + 
                    evrp_settings.energy_consumption_func(node.node_index, 
                    prev_node.node_index, current_weight, evrp_data)
                battery_departure = battery_departure
                push!(battery_departure_cs_tmp_reverse, battery_departure)

            else # it must be a depot
                if i == 1 # end depot
                    # The least amount of battery at end node is 0
                    battery_arrival_tmp_reverse[i] = 0.0    
                else # start depot
                    battery_needed = battery_arrival_tmp_reverse[i - 1] + 
                        evrp_settings.energy_consumption_func(node.node_index, 
                        prev_node.node_index, current_weight, evrp_data)
                    battery_arrival_tmp_reverse[i] = battery_needed
                end
            end
            current_weight += node.demand
            prev_node = node
        end

        # Looping in correct order to make sure that each vehicle start with a 
        # full battery and that the charging is consistent. We also calculate 
        # the recharging times and update the arrays which store all battery 
        # values.

        extra_battery = 0.0
        battery_level = nothing
        is_feasible = true
        battery_arrival_tmp = reverse(battery_arrival_tmp_reverse)

        for (i, node) in enumerate(route)
            if node.node_type == NodeTypes.customer
                battery_level = battery_arrival_tmp[i] + extra_battery
                battery_levels_arrival[i] = battery_level
                battery_levels_departure[i] = battery_level

            elseif node.node_type == NodeTypes.charging_station
                battery_level = battery_arrival_tmp[i] + extra_battery
                battery_levels_arrival[i] = battery_level
                battery_departure = pop!(battery_departure_cs_tmp_reverse)

                if battery_departure > evrp_data.battery_capacity
                    # Trying to charge more than battery capacity
                    extra_battery = -(battery_departure - evrp_data.battery_capacity)
                    battery_departure = evrp_data.battery_capacity
                    recharging_time = evrp_settings.recharging_func(
                        battery_level, battery_departure, evrp_data, 
                        throw_error = throw_error)
                    recharging_times[i] = recharging_time
                    battery_levels_departure[i] = battery_departure

                elseif battery_level > battery_departure
                    # No charging needed     
                    battery_levels_departure[i] = battery_level
                    extra_battery -= (battery_departure - battery_arrival_tmp[i])
                else
                    recharging_time = evrp_settings.recharging_func(
                        battery_level, battery_departure, evrp_data, 
                        throw_error = throw_error)
                    recharging_times[i] = recharging_time
                    battery_levels_departure[i] = battery_departure
                    extra_battery = 0.0
                end

            else # it must be a depot
                if i == 1 # start depot
                    battery_levels_arrival[i] = evrp_data.battery_capacity
                    battery_levels_departure[i] = evrp_data.battery_capacity
                    extra_battery = evrp_data.battery_capacity - 
                        battery_arrival_tmp[i]
                    continue
                else # end depot
                    battery_level = battery_arrival_tmp[i] + extra_battery
                    battery_levels_arrival[i] = battery_level
                    battery_levels_departure[i] = battery_level
                end
            end
            
            if battery_level < 0.0 
                is_feasible = false
            end
        end

        return is_feasible, battery_levels_arrival, battery_levels_departure, 
            recharging_times
    end
end


