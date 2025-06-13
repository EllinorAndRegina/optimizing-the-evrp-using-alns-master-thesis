# This file includes all helper functions. They are divided into modules 
# depending on which type of helper function it is.

module SolutionUtilities
    using ..NodeTypes
    using ..DataStruct
    using ..ErrorTypes
    using ..SolutionTypes
    using ..SettingTypes

    """
    Create an EVRPSolution object and check that the solution is feasible.

    The solution is allowed to be infeasible with regards to battery constraints 
    by default but not with regards to weight or time. This can be adjusted 
    using the keyword arguments `throw_infeasible_time_errors::Bool`,
    `throw_infeasible_weight_errors::Bool` and 
    `throw_infeasible_battery_errors::Bool`.

    """
    function create_solution_from_routes(
            routes::Vector{Vector{NodeTypes.Node}}, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings;
            throw_infeasible_time_errors::Bool = true, 
            throw_infeasible_weight_errors::Bool = true, 
            throw_infeasible_battery_errors::Bool = false
        )::SolutionTypes.EVRPSolution

        times_of_arrival = Vector{Vector{Float64}}(undef, length(routes))
        battery_arrival = Vector{Vector{Float64}}(undef, length(routes))
        battery_departure = Vector{Vector{Float64}}(undef, length(routes))
        
        feasible_solution = true

        for (ir, route) in enumerate(routes)
            # Check weight constraint for route
            weight_feasible = check_weight_constraint(route, evrp_data; 
                printing = false, throw_error = throw_infeasible_weight_errors)
            feasible_solution *= weight_feasible
            
            # Check battery constraint
            battery_feasible, battery_arrival[ir], 
                battery_departure[ir], recharging_times = 
                evrp_settings.calculate_battery_func(route, evrp_data, 
                evrp_settings, throw_error = throw_infeasible_battery_errors)
            feasible_solution *= battery_feasible
            
            # Check time window constraints and calculate time of arrival
            time_feasible, times_of_arrival[ir] = 
                calculate_arrival_times_for_route(route, recharging_times, 
                evrp_data, throw_error = throw_infeasible_time_errors)
            feasible_solution *= time_feasible
        end

        return SolutionTypes.EVRPSolution(routes, times_of_arrival, 
            battery_arrival, battery_departure, nothing, feasible_solution)
    end

    """
    Compute arrival times to the nodes in a route. 

    By default an error is thrown if the route is not fulfilling the time 
    constraints. This can be adjusted using the keyword argument 
    `throw_error::Bool`.

    # Returns
    - Bool, it is true if the route is feasible with regards to the time 
        constraints, otherwise false.
    - Vector{Float64}, the arrival times. The size of the vector is the 
        same as the length of the route and the i:th arrival time 
        corresponds to the i:th node in the route. 

    """
    function calculate_arrival_times_for_route(
            route::Vector{NodeTypes.Node},
            recharging_times::Vector{Float64},
            evrp_data::DataStruct.DataEVRP;
            throw_error::Bool = true
        )::Tuple{Bool, Vector{Float64}}
 
        times_of_arrival = Vector{Float64}(undef, length(route))

        is_route_feasible = true
        for (i, node) in enumerate(route)
            if i == 1 # The first node is a depot and the arrival time is 0
                times_of_arrival[i] = 0.0
                continue
            end

            prev_node = route[i - 1]
            arrival_prev_node = times_of_arrival[i - 1]
            is_node_feasible, arrival_time = calculate_arrival_time_to_node(node, 
                prev_node, arrival_prev_node, recharging_times[i-1], evrp_data, 
                throw_error = throw_error)
            times_of_arrival[i] = arrival_time

            is_route_feasible *= is_node_feasible
        end
        return is_route_feasible, times_of_arrival
    end


    

    """
    Compute arrival time to the node. 

    By default an error is thrown if the vehicle arrives after the end of the 
    time window. This can be adjusted using the keyword argument 
    `throw_error::Bool`. If the vehicle arrives too early it is assumed that it 
    waits for the start of the time window.  

    # Returns
    - Bool, it is true if the vehicle arrived before the end of the time window, 
        otherwise false.
    - Float64, the arrival time. 

    """
    function calculate_arrival_time_to_node(
            node::NodeTypes.Node, 
            prev_node::NodeTypes.Node, 
            arrival_to_prev_node::Float64,
            recharging_time_prev::Float64,
            evrp_data::DataStruct.DataEVRP;
            throw_error::Bool = true
        )::Tuple{Bool, Float64}

        arrival_time = arrival_to_prev_node + prev_node.service_time +
            evrp_data.travel_times[prev_node.node_index, node.node_index] +
            recharging_time_prev

        if recharging_time_prev > 0.0 && prev_node.node_type != 
                NodeTypes.charging_station
            println("WARNING: You are recharging at a node that is not a ", 
                "charging station... Is this intentional?")
        end

        is_feasible = true
        if arrival_time < node.time_window_start
            arrival_time = node.time_window_start
        elseif arrival_time > node.time_window_end
            is_feasible = false
            if throw_error
                throw(ErrorTypes.InfeasibleSolutionError(
                    "Arrived too late to node $(node.node_index)"))
            end
        end
        return is_feasible, arrival_time
    end

    """
    Compute if the route is feasible with regards to the weight constraint.

    Returns true if it feasible, otherwise false.

    """
    function check_weight_constraint(
            route::Vector{NodeTypes.Node},
            evrp_data::DataStruct.DataEVRP;
            printing::Bool = false,
            throw_error::Bool = true
        )::Bool

        if length(route) == 0
            return true
        end
        
        is_feasible = false
        if sum(node.demand for node in route) <= evrp_data.vehicle_capacity
            is_feasible = true
            if printing
                println("Weight constraint are fullfilled")
            end
        else
            if printing
                println("Infeasibility warning, load too heavy")
            end
            if throw_error
                throw(ErrorTypes.InfeasibleSolutionError(
                    "The truck is too heavy, remove some packages"))
            end
        end
        return is_feasible
    end
end




module InitialSolutionUtilities
    using ..NodeTypes
    using ..DataStruct
    using ..SettingTypes
    using ..ErrorTypes

    """
    Check if time window constraint is fulfilled if traveling from `prev_node` 
    to `node` using departure time to previous node as input. 
    
    The arrival time to `node` is returned if the time window constraint is 
    fulfilled, otherwise nothing is returned.
    
    """
    function arrival_time_to_node( 
            node::NodeTypes.Node, 
            prev_node::NodeTypes.Node, 
            time_at_departure_prev_node::Float64, 
            printing::Bool,
            evrp_data::DataStruct.DataEVRP
        )::Union{Float64, Nothing}

        current_time = time_at_departure_prev_node + 
            evrp_data.travel_times[node.node_index, prev_node.node_index]

        if current_time < node.time_window_start
            current_time = node.time_window_start
        elseif current_time > node.time_window_end
            if printing
                println("Infeasability warning, the node $(node.node_index) ", 
                    "does not fit the timewindow")
            end
            return nothing
        end
        return current_time
    end

    """
    Assuming it is known that we need to add a charging station to reach the 
    next node, this function checks if is possible to reach the charging   
    stations closest to the previous node due time and battery constraints. 

    Expected inputs:
    - node: Previous node visited
    - battery_level_prev: Battery level at departure from previous node
    - time_departure_prev: Time when departuring from previous node

    Output:
    - charging_station: The charging station closest to prev_node if it is 
        possible to add and it generates a feasable solutio.
    - battery_level_departure: Battery level when departing from 
      charging station. It will be fully charged
    - time_departure_cs: Time when departuring from the charging station

    If not feasable to add the charging station, the function will return nothing

    """
    function insert_cs_at_previous_node(
            node::NodeTypes.Node, 
            battery_level_prev::Float64, 
            time_departure_prev::Float64, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings;
            printing::Bool = true
        )

        charging_station = evrp_data.closest_charging_station_per_node[
            node.node_index]
        battery_level_departure = battery_level_prev
        time_departure_cs = time_departure_prev

        # Check if enough time to reach charging station and within time window
        time_departure_cs  =  arrival_time_to_node(charging_station, node, 
            time_departure_cs, printing, evrp_data) 
        if isnothing(time_departure_cs)
            return nothing
        end

        # Check if battery enough to reach charging station
        battery_arrival_cs = battery_level_prev - 
            evrp_settings.energy_consumption_func(charging_station.node_index, 
            node.node_index, NaN, evrp_data) 
        if battery_arrival_cs >= 0.0
            recharging_time = evrp_settings.recharging_func(battery_arrival_cs, 
                evrp_data.battery_capacity, evrp_data)
            time_departure_cs += recharging_time
            battery_level_departure = evrp_data.battery_capacity
        else
            return nothing
        end

        return charging_station, battery_level_departure, time_departure_cs
    end

    """
        The function checks if it is feasable to visit the next node 
        (customer, charging station or depot) due time and battery constraints. 
        If necessary it also tries to add a charging station to the route between 
        this and the previous node.

        Expected inputs:
        - node: Node we want to visit.
        - prev_node: Previous node visited.
        - current_battery: Battery level at departure from previous node.
        - current_time: Time when departuring from previous node.
        - description: Description printed of what is checked with the function, 
          either a customer or depot, as it may be used in different settings. 

        Outputs:
        - battery_arrival_node: battery of arrival to the node. 
        - prev_node: last visited node in the route. If chargingstation added, 
            this will be the last visited node. 
        - charging_station: information about the charging station if added, otherwise nothing. 
        - current_time: time of arrival to node.

    """
    function check_if_battery_enough_to_visit_node_or_add_charging_station(
            node::NodeTypes.Node, 
            prev_node::NodeTypes.Node, 
            current_battery::Float64, 
            current_time::Float64, 
            type_of_node_added::String, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings, 
            printing::Bool
        )

        if printing
            println("Check if enough battery to visit the", type_of_node_added,
                " otherwise insert charging station on previous node")
        end

        # Calculate battery level at arrival to the node we want to visit
        battery_arrival_node = current_battery - 
            evrp_settings.energy_consumption_func(node.node_index, 
            prev_node.node_index, NaN, evrp_data)   
        charging_station = nothing

        # If expected battery at arrival is negative, we will try to add a charging 
        # station after the previous visited node
        if battery_arrival_node < 0.0
            satus_of_trying_to_add_cs = insert_cs_at_previous_node(prev_node, 
                current_battery, current_time, evrp_data, evrp_settings)
            
            # Check if it was possible to add the charging station closest to the 
            # previous node. If not, go to the next vechicle and try to add the 
            # customer there
            if isnothing(satus_of_trying_to_add_cs)
                if printing
                    println("Infeasability warning, not enough battery to visit ",
                        "node $(node.node_index) as charging station is to far ",
                        "away")
                end
                return nothing
            end
            charging_station, _, current_time = satus_of_trying_to_add_cs

            # Check the battery level so it is enough to travel from the 
            # charging station to the customer
            battery_arrival_node = evrp_data.battery_capacity - 
                evrp_settings.energy_consumption_func(node.node_index, 
                charging_station.node_index, NaN, evrp_data) 
            if battery_arrival_node < 0.0
                if printing
                    println("Infeasability warning, even if adding charging ",
                        "station with index $(charging_station.node_index) ",
                        "it is not enough battery to visit node ",
                        "$(node.node_index). But you tried!")
                end
                return nothing
            end

            # If needing to charge we will change the prev_node to the charging 
            # station
            prev_node = charging_station
        end
        
        return battery_arrival_node, prev_node, charging_station, current_time
    end


    """
    Check if all customers have been inserted in the routes and also that 
    the routes start and end in the depot. 

    """
    function check_all_customers_inserted(
            routes::Vector{Vector{NodeTypes.Node}}, 
            evrp_data::DataStruct.DataEVRP; 
            throw_error::Bool = false, 
            printing::Bool = true
        )::Bool

        customer_list = zeros(Int, evrp_data.n_customers)
        n_emty_routes = 0
        for route in routes

            depot_count = 0
            if length(route) == 0
                n_emty_routes += 1
                if n_emty_routes == evrp_data.n_vehicles
                    if printing
                        println("All routes are empty!")
                    end
                    return false
                end
                continue
            end

            obj_value_route = sum(evrp_data.distances[node.node_index, 
                route[i+1].node_index] for (i, node) in enumerate(route[1:end - 1]))

            if obj_value_route == Inf
                println("Warning: Objective value are inf!")
                return false
            end

            if route[1].node_type != NodeTypes.depot 
                throw(ErrorTypes.InfeasibleSolutionError(
                    "The start depot have not been inserted correctly"))
            end

            if route[end].node_type != NodeTypes.depot 
                throw(ErrorTypes.InfeasibleSolutionError(
                    "The end depot have not been inserted correctly"))
            end

            for node in route
                if node.node_type == NodeTypes.depot
                    depot_count += 1
                elseif node.node_type == NodeTypes.customer
                    customer_list[node.type_index] += 1
                end
            end

            if depot_count != 2
                throw(ErrorTypes.InfeasibleSolutionError(
                    "The depot have not been inserted correctly"))
            end

        end

        list_not_inserted_customers_type_ind = findall(x -> x == 0, customer_list)
        if length(list_not_inserted_customers_type_ind) > 0
            throw(ErrorTypes.InfeasibleSolutionError(string("Not all customers ",
                "have been inserted succesfully. The type indicies of these ",
                "customers are: $list_not_inserted_customers_type_ind")))
        end

        type_ind_not_zero_or_one = findall(x -> x > 1, customer_list)
        if length(type_ind_not_zero_or_one) > 0
            throw(ErrorTypes.InfeasibleSolutionError(string("Some customers ",
                "have been inserted more then once. The type indicies of these ",
                "customers are: $type_ind_not_zero_or_one")))
        end

        return true
    end
end


module RemoveUtilities
    using ..NodeTypes
    using ..DataStruct
    using ..SettingTypes

    """
    Calculates the costs of removing each node from a given route. 
    
    The costs are either 0 or negative, and they are calculated as the difference 
    in objective value between excluding and including the node.

    """
    function calculate_remove_costs_for_route(
            route::Vector{NodeTypes.Node}, 
            route_i::Int, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings
        )::Vector{Tuple{Int, Int, Float64, Bool}}
        
        costs = Vector{Tuple{Int, Int, Float64, Bool}}(undef, 0)
        objective_value_original = evrp_settings.objective_func_per_route(
            route, evrp_data)

        for i in 2:length(route) - 1
            cs_remove_required = false
            new_route = vcat(route[1:i-1], route[i + 1:end])

            if length(new_route) == 2
                push!(costs, (route_i, i, - objective_value_original, 
                    cs_remove_required))
                continue
            end

            obj_value_delta = evrp_settings.objective_func_per_route(new_route, 
                evrp_data) - objective_value_original

            if obj_value_delta == Inf
                # Avoid two charging stations in a row
                if route[i - 1] == route[i + 1]
                    cs_remove_required = true
                    deleteat!(new_route, i)
                    obj_value_delta = evrp_settings.objective_func_per_route(
                        new_route, evrp_data) - objective_value_original
                else
                    throw(DomainError(obj_value_delta, string("The objective ",
                    "value is Inf")))
                end
            end
            
            if obj_value_delta > 0.0001
                throw(DomainError(obj_value_delta, string("The objective value ",
                    "is not supposed to increase when removing customers!")))
            end
            push!(costs, (route_i, i, obj_value_delta, cs_remove_required))
        end
        return costs
    end
end


module InsertUtilities
    using ..NodeTypes
    using ..SettingTypes
    using ..DataStruct
    using ..SolutionUtilities

    """
    Iteratively insert closest charging station to the node previous to the 
    first one with negative battery until the route is feasible.

    # Returns
    - Bool, it is true if the insertions were successful, otherwise false.

    """
    function nearest_charging_stations_insert!(
            route::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings
        )::Bool
        
        if length(route) == 0
            return true
        end

        is_feasible = false
        iteration_count = 0
        insertions = Vector{Tuple{NodeTypes.Node, Int}}(undef, 0)
        route_tmp = copy(route)

        battery_feasible, battery_arrivals, battery_departures, _ = 
            evrp_settings.calculate_battery_func(route_tmp, evrp_data, 
            evrp_settings, throw_error = false)

        if battery_feasible
            is_feasible = true
        end

        while !is_feasible
            iteration_count += 1
            first_negative_node_i = findfirst(battery_arrivals .< 0.0)
            first_negative_node = route_tmp[first_negative_node_i]

            current_weight = 0.0
            if first_negative_node.node_type != NodeTypes.depot
                current_weight = sum(node.demand for node in route_tmp[
                    first_negative_node_i:end])
            end

            if first_negative_node_i == 1
                println("Warning: your route starts with negative battery")
                return false
            end

            prev_node = route_tmp[first_negative_node_i - 1]
            charging_station = evrp_data.closest_charging_station_per_node[
                prev_node.node_index]

            # Check if we have enough battery to visit the nearest charging 
            # station to the previous node before going to current node
            if battery_departures[first_negative_node_i - 1] <
                    evrp_settings.energy_consumption_func(prev_node.node_index, 
                    charging_station.node_index, current_weight, evrp_data)
                return false
            end

            insert!(route_tmp, first_negative_node_i, charging_station)
            battery_feasible, battery_arrivals, battery_departures, 
                recharging_times = evrp_settings.calculate_battery_func(
                route_tmp, evrp_data, evrp_settings, throw_error = false)

            time_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(
                route_tmp, recharging_times, evrp_data, throw_error = false)

            if !time_feasible
                return false
            end

            if battery_feasible
                is_feasible = true
            end

            push!(insertions, (charging_station, first_negative_node_i))

            if iteration_count > evrp_data.n_charging_stations
                println(string("WARNING: nearest_charging_stations_insert! has",
                    " been running for $iteration_count iterations which is ",
                    "more than the number of charging stations. That is ",
                    "probably not normal, so maybe look for a bug?"))
            end

        end

        for (node, pos) in insertions
            insert!(route, pos, node)
        end

        return true
    end

    """
    Iteratively insert the best charging station considering the closest 
    charging stations when traversing k steps back from the
    first node with negative battery. Terminate when the route is feasible.
    
    In each step back the charging station closest to the arc, and the two 
    closest to the connecting nodes are considered for insertion.

    # Returns
    - Bool, it is true if the insertions were successful, otherwise false. 

    """
    function charging_stations_k_insert!(
            route::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            cs_insert_score_parameters::Tuple{Float64, Float64, Float64},
            k_cs_insert::Int;
            printing::Bool = false
        )::Bool

        if length(route) == 0
            return true
        end

        is_feasible = false
        iteration_count = 0
        insertions = Vector{Tuple{NodeTypes.Node, Int}}(undef, 0)
        route_tmp = copy(route)

        if k_cs_insert < 1
            println("WARNING: Your value on k_cs_insert is unreasonable. ",
                "It should be > 0.")
        end

        battery_feasible, battery_arrivals, battery_departures, recharging_times = 
            evrp_settings.calculate_battery_func(route_tmp, evrp_data, 
            evrp_settings, throw_error = false)
        
        time_feasible, arrival_times = 
            SolutionUtilities.calculate_arrival_times_for_route(route_tmp, 
            recharging_times, evrp_data, throw_error = false)

        if battery_feasible
            if !time_feasible
                return false
            else
                return true
            end
        end

        while !is_feasible
            iteration_count += 1
            first_negative_node_i = findfirst(battery_arrivals .< 0.0)

            # Find and sort insertions
            cs_insertions = find_cs_insertions(first_negative_node_i, route_tmp, 
                k_cs_insert, cs_insert_score_parameters, battery_departures, 
                evrp_data, evrp_settings)
            sort!(cs_insertions, by = x -> x[3])

            # Go through each insertion
            found_insertion = false
            for cs_insertion in cs_insertions
                cs_i, pos, _ = cs_insertion
                charging_station = evrp_data.nodes[cs_i]
                new_route = vcat(route_tmp[1:pos-1], charging_station, 
                    route_tmp[pos:end])
                
                battery_feasible, battery_arrivals, battery_departures, 
                    recharging_times = evrp_settings.calculate_battery_func(
                    new_route, evrp_data, evrp_settings, throw_error = false)

                time_feasible, arrival_times = 
                    SolutionUtilities.calculate_arrival_times_for_route(
                    new_route, recharging_times, evrp_data, throw_error = false)

                if !time_feasible
                    continue
                end

                if battery_feasible
                    is_feasible = true
                end

                route_tmp = new_route
                push!(insertions, (charging_station, pos))
                found_insertion = true
                break
            end

            if !found_insertion
                return false
            end

            if iteration_count > evrp_data.n_charging_stations
                if printing
                    println(string("WARNING: k cs insert has",
                        " been running for $iteration_count iterations which is ",
                        "more than the number of charging stations. That is ",
                        "probably not normal, so maybe look for a bug?"))
                end
            end

        end

        # Important! They should not be sorted here since the position of the 
        # second insertion assumes the first insertion has taken place and so on.
        for (node, pos) in insertions
            insert!(route, pos, node)
        end

        return true
    end

    """
    Finds the charging stations and corresponing positions to consider in 
    the charging station k insert operator. It also calculates a score 
    corresponding to each insertion. A lower score means that the insertion 
    is more favorable.

    Returns a vector of tuples of the form (node index of charging station, 
    position in route, score)

    """
    function find_cs_insertions(
            first_negative_node_i::Int,
            route::Vector{NodeTypes.Node},
            k_cs_insert::Int,
            cs_insert_score_parameters::Tuple{Float64, Float64, Float64},
            battery_departures::Vector{Float64},
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings
        )::Vector{Tuple{Int, Int, Float64}}

        w_ranking, w_dist, w_feasibility = cs_insert_score_parameters
        max_distance = maximum(filter(!isinf, evrp_data.distances))

        first_negative_node = route[first_negative_node_i]
        if first_negative_node_i == 1
            println("Warning: your route starts with negative battery")
            return false
        end

        cs_insertions = Vector{Tuple{Int, Int, Float64}}(undef, 0)
        current_node = first_negative_node
        ranking = 1    # Higher ranking for cs close to the negative node
        
        current_weight = 0.0
        if first_negative_node.node_type != NodeTypes.depot
            current_weight = sum(node.demand for node in route[
                first_negative_node_i:end])
        end

        # Traverse back k steps to look for charging station insertions
        for i in 1:k_cs_insert
            prev_node_i = first_negative_node_i - i
            prev_node = route[prev_node_i]

            # Find the three cs to be considered for this step
            cs1 = evrp_data.
                closest_charging_station_per_node[current_node.node_index]
            cs2 = evrp_data.closest_charging_station_per_arc[
                prev_node.node_index, current_node.node_index]
            cs3 = evrp_data.
                closest_charging_station_per_node[prev_node.node_index]

            # Remove duplicates
            cs_list = filter(!isnothing, [cs1, cs2, cs3])
            cs_list = unique(cs_list)

            for cs in cs_list
                skip = false
                if cs == prev_node || cs == current_node
                    # We never want to go to the same charging station twice 
                    # in a row
                    skip = true
                elseif prev_node.node_type == NodeTypes.charging_station && 
                        cs == route[prev_node_i - 1]
                    # Avoid loops where the vehicle go back and forth between 
                    # two cs. There should be no instances where we go fram one 
                    # cs to another one and then back again to the previous cs. 
                    # This does not protect from similar cases with multiple cs in 
                    # a row, but it is a special case and should not occur often. 
                    # If it does happen, the time windows will make sure it 
                    # terminates since they are not inf.
                    skip = true
                end

                if !skip
                    cs_feasible, negative_node_battery_feasible = 
                        check_feasibility_for_cs_insertion(route, 
                        prev_node_i, first_negative_node_i, 
                        cs, battery_departures, current_weight, 
                        evrp_settings, evrp_data)

                    if cs_feasible # Skip cs we cannot reach with current battery
                        diff_dist = evrp_data.distances[prev_node.node_index, 
                            cs.node_index] + evrp_data.distances[cs.node_index, 
                            current_node.node_index] - 
                            evrp_data.distances[prev_node.node_index, 
                            current_node.node_index]
    
                        score = w_ranking * ranking + 
                            w_dist * diff_dist / max_distance + 
                            w_feasibility * (1 - negative_node_battery_feasible)
    
                        push!(cs_insertions, (cs.node_index, 
                            prev_node_i + 1, score))
                        ranking += 1
                    end
                end
            end

            current_node = prev_node
            current_weight += prev_node.demand

            if prev_node.node_type == NodeTypes.depot || 
                    prev_node.node_type == NodeTypes.charging_station
                break 
            end
        end
        
        return cs_insertions
    end

    """
    Checks if a charging station insertion is feasible by checking time and 
    battery constraints. 

    To be more precise, the function checks if the vehicle has enough battery to 
    reach the charging station that is to be inserted, if the time windows at 
    the charging station is met and if the battery constraints at the 
    first negative node is fulfilled. 

    # Returns
    - Bool, if vehicle has enough battery to reach the charging station and if 
        the time window constraints are fulfilled for the charging station.
    - Bool, if the insertion solves the battery issue at the negative node.

    """
    function check_feasibility_for_cs_insertion(
            route::Vector{NodeTypes.Node},
            prev_node_i_in_route::Int,
            negative_node_i_in_route::Int, 
            cs_to_insert::NodeTypes.Node,
            battery_departures::Vector{Float64},
            current_weight::Float64,
            evrp_settings::SettingTypes.EVRPSettings,
            evrp_data::DataStruct.DataEVRP
        )::Tuple{Bool, Bool} 

        prev_node = route[prev_node_i_in_route]
        
        # Check enough battery to cs
        if battery_departures[prev_node_i_in_route] <
                evrp_settings.energy_consumption_func(prev_node.node_index, 
                cs_to_insert.node_index, current_weight, evrp_data)
            return false, false
        end

        # Check if we have enough battery to reach the negative node 
        # from the inserted charging station
        current_battery = evrp_data.battery_capacity
        node = cs_to_insert
        for i in prev_node_i_in_route + 1:negative_node_i_in_route
            next_node = route[i]
            current_battery -= evrp_settings.energy_consumption_func(
                node.node_index, next_node.node_index, current_weight, evrp_data)
            node = next_node
            current_weight -= next_node.demand
        end

        if current_battery < 0
            return true, false
        end

        return true, true
    end


    """
    Find the minimum element in a cost matrix and return its corresponding 
    column and row in the matrix. If no element with cost less than infinity 
    is found, the returned indices are `nothing`.

    # Returns
    - Int or Nothing, column index
    - Int or Nothing, row index

    """
    function find_min_in_cost_matrix(
            costs::Matrix{Tuple{Int, Float64, Bool}}
        )::Tuple{Union{Int, Nothing}, Union{Int, Nothing}}

        n_rows, n_cols = size(costs)
        min_cost = Inf
        node_to_insert = nothing
        corr_route = nothing   # The route in which the node should be inserted

        for ri in 1:n_rows
            for ni in 1:n_cols
                _, cost, _ = costs[ri, ni]
                if cost < min_cost
                    min_cost = cost
                    node_to_insert = ni
                    corr_route = ri
                end
            end
        end
        return node_to_insert, corr_route
    end

    """
    Calculate the cost of inserting `node` in `route`.

    # Returns
    - Int, position where node should be inserted in route
    - Float64, the change in objective value upon insertion
    - Bool, if the battery would be feasible after the insertion

    """
    function calculate_cost_of_inserting_node(node::NodeTypes.Node,
            route::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings
        )::Tuple{Int, Float64, Bool}

        objective_value_original = evrp_settings.objective_func_per_route(
            route, evrp_data)

        if length(route) < 2 # Route needs to be initialized
            route = [evrp_data.nodes[1], evrp_data.nodes[1]]
        end

        min_obj_delta = Inf
        best_pos = -1
        is_feasible = false

        for i in 2:length(route)
            new_route = vcat(route[1:i-1], node, route[i:end])
            
            if !SolutionUtilities.check_weight_constraint(new_route, evrp_data, 
                    throw_error = false)
                continue
            end
            
            battery_feasible, _, _, recharging_times = 
                evrp_settings.calculate_battery_func(new_route, evrp_data, 
                evrp_settings, throw_error = false)

            time_feasible, _ = 
                SolutionUtilities.calculate_arrival_times_for_route(
                new_route, recharging_times, evrp_data, throw_error = false)
            
            if !time_feasible
                continue
            end

            # Saving best insert position, delta objective value and if the 
            # route is feasible
            obj_value_delta = evrp_settings.objective_func_per_route(new_route, 
                evrp_data) - objective_value_original
            
            if obj_value_delta < min_obj_delta
                best_pos = i
                min_obj_delta = obj_value_delta
                is_feasible = battery_feasible
            end
        end
        return best_pos, min_obj_delta, is_feasible
    end

    """
    Find the k best insertions for all routes from a cost dict. If there are 
    less than k available insertions, only those are returned. Therefore the 
    length of the returned vector could be less than k. 
        
    The keys in the cost dict are of the form (customer index, route index). 
    The values are vectors containing tuples of the form (insert position, cost, 
    is battery feasible). The customer index is in our use case the index in 
    the list of removed customers.

    The returned vector contains tuples of the form (route index, insert 
    position in route, cost, is battery feasible).

    """
    function find_k_best_per_customer(
            costs::Dict{Tuple{Int, Int}, Vector{Tuple{Int, Float64, Bool}}},
            customer_index::Int,
            n_routes::Int,
            k::Int
        )::Vector{Tuple{Int, Int, Float64, Bool}}

        sorted_k_insertions = Vector{Tuple{Int, Int, Float64, 
            Bool}}(undef, 0)
        for ri in 1:n_routes
            insertions = costs[(customer_index, ri)]
            for item in insertions
                if item[2] == Inf
                    continue
                end

                if length(sorted_k_insertions) < k
                    push!(sorted_k_insertions, (ri, item[1], item[2], item[3]))

                    if length(sorted_k_insertions) == k
                        sort!(sorted_k_insertions, by = x -> x[3])
                    end
                    continue
                end

                if item[2] > sorted_k_insertions[end][3]
                    continue
                end

                item_with_route = (ri, item[1], item[2], item[3])
                i = searchsortedfirst(sorted_k_insertions, item_with_route, 
                    by = x -> x[3])
                insert!(sorted_k_insertions, i, item_with_route)
                pop!(sorted_k_insertions)
            end
        end

        if length(sorted_k_insertions) < k
            sort!(sorted_k_insertions, by = x -> x[3])
        end

        return sorted_k_insertions
    end

    """
    Compute the k best insertions of a given node into a given route. If there 
    are less than k possible insertions, those are returned. So the length of 
    the returned vector may be less than k.

    The returned vector contains tuples on the form (insert position in route, 
    cost, is battery feasible)

    """
    function calculate_k_best_costs_of_inserting_node(
            node::NodeTypes.Node, 
            route::Vector{NodeTypes.Node}, 
            k::Int,
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings
        )::Vector{Tuple{Int, Float64, Bool}}
        
        objective_value_original = evrp_settings.objective_func_per_route(
            route, evrp_data)

        if length(route) == 0 # Route needs to be initialized
            route = [evrp_data.nodes[1], evrp_data.nodes[1]]
        end

        k_best_insertions = Vector{Tuple{Int, Float64, Bool}}(undef, 0)

        for i in 2:length(route) 
            new_route = vcat(route[1:i-1], node, route[i:end])
            
            if !SolutionUtilities.check_weight_constraint(new_route, evrp_data, 
                    throw_error = false)
                break
            end
            
            battery_feasible, _, _, recharging_times = 
                evrp_settings.calculate_battery_func(new_route, evrp_data, 
                evrp_settings, throw_error = false)

            time_feasible, _ = SolutionUtilities.calculate_arrival_times_for_route(
                new_route, recharging_times, evrp_data, throw_error = false)

            if !time_feasible
                continue
            end

            # Saving best insert position, delta objective value and if the 
            # route is feasible
            obj_value_delta = evrp_settings.objective_func_per_route(new_route, 
                evrp_data) - objective_value_original
            
            insertion = (i, obj_value_delta, battery_feasible)

            if length(k_best_insertions) < k
                push!(k_best_insertions, insertion)

                if length(k_best_insertions) == k
                    sort!(k_best_insertions, by = x -> x[2])
                end
                continue
            end

            if obj_value_delta > k_best_insertions[end][2]
                continue
            end

            i = searchsortedfirst(k_best_insertions, insertion, by = x -> x[2])
            insert!(k_best_insertions, i, insertion)
            pop!(k_best_insertions)
        end

        if length(k_best_insertions) < k
            sort!(k_best_insertions, by = x -> x[2])
        end

        return k_best_insertions
    end
end
 