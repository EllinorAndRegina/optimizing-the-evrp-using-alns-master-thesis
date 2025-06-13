module InitialSolution
    using ..NodeTypes
    using ..DataStruct
    using ..SolutionUtilities
    using ..InitialSolutionUtilities
    using ..InsertUtilities
    using ..SettingTypes
    using ..SolutionTypes
    using ..SortByTypesInitialSolution
    using ..InsertOperators

    """
    Having the dataset and settings as an input, the functions generates 
    as inital solution. It it's generated using time window heuristics, 
    in which the customers are sorted accoring to some parameter, as the start or 
    the end of the delivery time window, or the size of the demand. The customers are added one by 
    one by iterating throught the routes and adding them to the first one 
    where they fit the time window and fullfills the rest of the 
    constraints as battery constraints, weight constraints and time 
    constraints. If not fullfilling the battery constraints it will try 
    to add a charging station to the previous node. It also checks if 
    adding the customer, can its still go back to the depot. If not being 
    able to add a customer to any route the algorithm will stop and 
    return nothing.

    Create an initial solution from the data for the full charging policy. 
    Note that it is not usable with the load dependent discharging problem.
    
    
    """
    function create_initial_solution(
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings; 
            printing::Bool = true, 
            parameter_to_sort_by::SortByTypesInitialSolution.
                InitialSolutionSortBy = SortByTypesInitialSolution.time_window_end
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        # Initilize vectors
        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        last_recorded_times_of_departure = zeros(Float64, evrp_data.n_vehicles)
        total_load_vehicles = zeros(Float32, evrp_data.n_vehicles)
        last_recorded_battery_levels_departure = ones(Float64, 
            evrp_data.n_vehicles) * evrp_data.battery_capacity

        # Check if the depot is the first node in the dataset
        depot = evrp_data.nodes[1]
        if depot.node_type != NodeTypes.depot
            println("This function assumes the first node is the depot :)")
            return nothing 
        end

        # Sort the customers according to set parameter
        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            evrp_data.nodes)
        if parameter_to_sort_by == SortByTypesInitialSolution.time_window_start
            sort!(customer_list, by=x -> x.time_window_start)
        elseif parameter_to_sort_by == SortByTypesInitialSolution.time_window_end
            sort!(customer_list, by=x -> x.time_window_end)
        elseif parameter_to_sort_by == SortByTypesInitialSolution.largest_demand
            sort!(customer_list, by=x -> x.demand, rev=true)
        elseif parameter_to_sort_by == SortByTypesInitialSolution.smallest_demand
            sort!(customer_list, by=x -> x.demand)
        end

        for customer in customer_list
            customer_inserted = false
            
            for route in 1:evrp_data.n_vehicles 
                last_node_added_to_route = nothing  

                if length(routes[route]) == 0
                    push!(routes[route], depot)
                    last_node_added_to_route = depot
                else
                    last_node_added_to_route = routes[route][end]
                end

                # Check if route fullfills weight capacity constraint with node 
                # added
                load_if_adding_customer = total_load_vehicles[route] + 
                    customer.demand
                if load_if_adding_customer > evrp_data.vehicle_capacity
                    if printing
                        println("Infeasability warning, the demand of the node ",
                            "$(customer.node_index) in route $route is too big")
                    end
                    continue
                end

                # Initializing temporary variables for the current vehicle
                inserted_cs_by_prev = nothing
                battery_level_at_departure_from_prev_node = 
                    last_recorded_battery_levels_departure[route]
                time_at_departure_from_prev_node = 
                    last_recorded_times_of_departure[route]

                # Check if enough battery to visit the node, otherwise insert 
                # charging station on previous node
                status_after_try = InitialSolutionUtilities.
                    check_if_battery_enough_to_visit_node_or_add_charging_station(
                    customer, last_node_added_to_route, 
                    battery_level_at_departure_from_prev_node, 
                    time_at_departure_from_prev_node, "customer", evrp_data, 
                    evrp_settings, printing)
                if isnothing(status_after_try)
                    continue
                end

                battery_level_at_arrival_if_adding_customer, 
                last_node_added_to_route, 
                inserted_cs_by_prev, 
                time_at_departure_from_prev_node = status_after_try

                # Check if we can reach the node within its time window. If 
                # arriving before time window start, we will wait at the node
                time_at_arrival_if_adding_customer = 
                    InitialSolutionUtilities.arrival_time_to_node(
                    customer, last_node_added_to_route, 
                    time_at_departure_from_prev_node, printing, evrp_data) 
                    
                if isnothing(time_at_arrival_if_adding_customer)
                    continue
                end

                # Now we have arrived to and are about to leave the customer
                last_node_added_to_route = customer
                time_at_departure_if_adding_customer = 
                    time_at_arrival_if_adding_customer + customer.service_time

                # Check if enough battery to visit the depot after node, 
                # otherwise insert charging station on current node. 
                # OBS! This solution do not consider the case if we need to 
                # charge more then once to reach the depot
                status_after_try_to_add_depot = InitialSolutionUtilities.
                    check_if_battery_enough_to_visit_node_or_add_charging_station(
                    depot, customer, battery_level_at_arrival_if_adding_customer, 
                    time_at_departure_if_adding_customer, "depot", evrp_data, 
                    evrp_settings, printing)
                
                if isnothing(status_after_try_to_add_depot)
                    continue
                end

                _, last_node_added_to_route, _, time_departure_from_customer_or_cs = 
                    status_after_try_to_add_depot

                # Check if we have time to reach depot after visit to node
                arrival_time_to_depot = time_departure_from_customer_or_cs + 
                    evrp_data.travel_times[last_node_added_to_route.node_index, 
                    depot.node_index]
                if arrival_time_to_depot > depot.time_window_end
                    if printing
                        println("Infeasability warning, if adding node ", 
                            "$(customer.node_index) in route $k there is not ",
                            "enough time to go back to depot")
                    end
                    continue
                end

                # Updating values for vechicle k
                last_recorded_times_of_departure[route] =  
                    time_at_departure_if_adding_customer
                total_load_vehicles[route] = load_if_adding_customer
                last_recorded_battery_levels_departure[route] = 
                    battery_level_at_arrival_if_adding_customer

                if length(routes[route]) == 0
                    push!(routes[route], depot)
                    last_node_added_to_route = depot
                else
                    last_node_added_to_route = routes[route][end]
                end

                if !isnothing(inserted_cs_by_prev)
                    push!(routes[route], inserted_cs_by_prev)
                end
                push!(routes[route], customer)
                customer_inserted = true
                break
            end  

            if !customer_inserted
                println("Could not insert node $(customer.node_index) in any route")
                return nothing
            end
        end

        for (ri, route) in enumerate(routes)
            if length(route) > 0
                last_node = route[end]
                battery_arrival_depot = 
                    last_recorded_battery_levels_departure[ri] - 
                    evrp_settings.energy_consumption_func(depot.node_index, 
                    last_node.node_index, NaN, evrp_data)  
                if battery_arrival_depot < 0.0
                    push!(route, evrp_data.closest_charging_station_per_node[
                        last_node.node_index])
                end
                push!(route, depot)
            end
        end
        
        println("We have found a solution!")
        return SolutionUtilities.create_solution_from_routes(routes, evrp_data, 
            evrp_settings, throw_infeasible_battery_errors = true)
    end

    """
    Generates an initial solution using the logic in greedy insert. This is done 
    by giving it empty routes and all the customers to insert. If no feasible 
    solution is found, nothing is returned. 

    """
    function greedy_initial_solution(
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            cs_insert_score_parameters::Tuple{Float64, Float64, Float64},
            k_cs_insert::Int;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        n_routes = evrp_data.n_vehicles
        routes = [NodeTypes.Node[] for _ in 1:n_routes]
        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            evrp_data.nodes)

        return InsertOperators.greedy(routes, customer_list, evrp_data, 
            evrp_settings, cs_insert_score_parameters, k_cs_insert, 
            printing = printing)
    end
end