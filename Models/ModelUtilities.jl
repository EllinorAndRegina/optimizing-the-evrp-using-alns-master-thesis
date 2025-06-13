module DataHandeling
    using ..NodeTypes
    using ..DataStruct
    

    """
    The function gets the indicies for the copied charging stations.

    The row index is the node index of the charging station. The first column is the
    indicies for the charging stations in the input data.

    """
    function getting_indicies_for_copies(
        evrp_data::DataStruct.DataEVRP,
        n_cs_copies::Int)::Matrix{Int}
    
        indicies_copies = zeros(Int, evrp_data.n_charging_stations, n_cs_copies)

        indicies_charging_stations = findall(x -> x.node_type == 
            NodeTypes.charging_station, evrp_data.nodes)


        for (i, index_charging_stations) in enumerate(indicies_charging_stations)          
            indicies_copies[i,:] = [index_charging_stations + 
                n * evrp_data.n_charging_stations for n in 0:(n_cs_copies - 1)]
        end
    
        return indicies_copies
    end


    """
    The function sorts the data and copies the charging stations   
    according to the number of copies. This in necessary as it is
    expected for the model that the data is sorted with the depot first, 
    then the charging stations and its copies and last the customers. 

    """
    function sorting_and_copying_data(
            parameter::VecOrMat{Float64}, 
            evrp_data::Any, 
            n_cs_copies::Int
        )::VecOrMat{Float64}

        indicies_depot = findall(x -> x.node_type == 
            NodeTypes.depot, evrp_data.nodes)

        indicies_charging_stations = findall(x -> x.node_type == 
            NodeTypes.charging_station, evrp_data.nodes)

        indicies_customers = findall(x -> x.node_type == 
            NodeTypes.customer, evrp_data.nodes)

        expected_length = size(parameter, 1) + (n_cs_copies - 1) * 
            length(indicies_charging_stations) + 1

        if ndims(parameter) == 1
            depot = parameter[indicies_depot]
            charging_stations = parameter[indicies_charging_stations]
            customers = parameter[indicies_customers]

            updated_parameter = vcat(depot, repeat(charging_stations, 
                n_cs_copies), customers, depot)

            if length(updated_parameter) != expected_length
            
                throw(DomainError(
                    "The dimension of updated parameter is not correct"))
            end

        elseif ndims(parameter) == 2
            depot_vcat = parameter[indicies_depot, :]
            charging_stations_vcat = parameter[indicies_charging_stations, :]
            customers_vcat = parameter[indicies_customers, :]

            updated_parameter_tmp = vcat(depot_vcat, 
                repeat(charging_stations_vcat, n_cs_copies, 1), customers_vcat,
                depot_vcat)

            depot_hcat = updated_parameter_tmp[:, indicies_depot]
            charging_stations_hcat = updated_parameter_tmp[:, 
                indicies_charging_stations]
            customers_hcat = updated_parameter_tmp[:, indicies_customers]
            
            updated_parameter = hcat(depot_hcat, repeat(charging_stations_hcat, 
                1, n_cs_copies), customers_hcat, depot_hcat)
           
            if size(updated_parameter) != (expected_length, expected_length)
                
                throw(DomainError(
                    "The dimension of updated parameter is not correct"))
            end

        else
            throw(ArgumentError("Non feasable dimension on data")) 
        end
        return updated_parameter
    end


    """
    The function transforms the input data from the file into a format that is 
    suitable for the models. It sorts the data and copies the charging stations
    according to the number of copies specified.
    The output is a tuple containing the following:
    
    - n_nodes: The total number of nodes in the problem, including depots, 
      charging stations, and customers.
    - i_cs_start: The index of the first charging station in the sorted data.
    - i_cs_end: The index of the last charging station in the sorted data.
    - i_customers_start: The index of the first customer in the sorted data.
    - i_customers_end: The index of the last customer in the sorted data.
    - distances: A matrix containing the distances between all nodes, with 
      charging stations copied according to the number of copies specified.
    - travel_times: A matrix containing the travel times between all nodes,
        calculated from the distances and the speed of the vehicles.
    - demand: A vector containing the demand of each node, sorted and copied
      according to the number of copies specified.
    - service_times: A vector containing the service times of each node, sorted
        and copied according to the number of copies specified.
    - time_window_start: A vector containing the start of the time window for
      each node, sorted and copied according to the number of copies specified.
    - time_window_end: A vector containing the end of the time window for each
        node, sorted and copied according to the number of copies specified.

    """
    function get_data_for_models(
            evrp_data::DataStruct.DataEVRP,
            n_cs_copies::Int64
        )

        ####### Constants #######
        speed = evrp_data.speed

        ####### 1D data #######
        demand_unsorted = [node.demand for node in evrp_data.nodes]
        demand = DataHandeling.sorting_and_copying_data(demand_unsorted, 
            evrp_data, n_cs_copies)
        
        service_times_unsorted = [node.service_time for node in evrp_data.nodes]
        service_times = DataHandeling.sorting_and_copying_data(
            service_times_unsorted, evrp_data, n_cs_copies)
        
        time_window_start_unsorted = [node.time_window_start for node in 
            evrp_data.nodes]
        time_window_start = DataHandeling.sorting_and_copying_data(
            time_window_start_unsorted, evrp_data, n_cs_copies)

        time_window_end_unsorted = [node.time_window_end for node in 
            evrp_data.nodes]
        time_window_end = DataHandeling.sorting_and_copying_data(
            time_window_end_unsorted, evrp_data, n_cs_copies)

        distances_with_inf = DataHandeling.sorting_and_copying_data(
            evrp_data.distances, evrp_data, n_cs_copies)
        distances = replace(distances_with_inf, Inf => 100000)

        travel_times = DataStruct.calculate_travel_times(distances, speed)

        ####### Indicies #######
        n_depots = evrp_data.n_depots

        i_cs_start = n_depots + 1
        i_cs_end = i_cs_start + evrp_data.n_charging_stations * n_cs_copies - 1 
        i_customers_start = i_cs_end + 1
        i_customers_end = i_customers_start + evrp_data.n_customers - 1   
        n_nodes = i_customers_end + 1 


        ####### Checking if the data is correct #######
        indicies_copies = getting_indicies_for_copies(evrp_data, n_cs_copies)
        
        for i in i_cs_start:i_cs_end
            if minimum(indicies_copies) <= i <= maximum(indicies_copies)
                index_cs_in_matrix = findfirst(x -> x == i, indicies_copies)[1]
                node_index_in_data = indicies_copies[index_cs_in_matrix, 1]
                if evrp_data.nodes[node_index_in_data].node_type != 
                        NodeTypes.charging_station
                    println("Error: The node is not a charging station")
                end 
            else
                node_index_in_data = next_node_index - 
                    evrp_data.n_charging_stations * (n_cs_copies - 1)
                if evrp_data.nodes[node_index_in_data].node_type != 
                        NodeTypes.customer
                    println("Error: The node is not a customer")
                end
            end
        end
        return (
            n_nodes::Int64,
            i_cs_start::Int64,
            i_cs_end::Int64,
            i_customers_start::Int64,
            i_customers_end::Int64,
            distances::Matrix{Float64},
            travel_times::Matrix{Float64},
            demand::Vector{Float64},
            service_times::Vector{Float64},
            time_window_start::Vector{Float64},
            time_window_end::Vector{Float64}
        )
    end  
end


module ResultHandeling
    using ..NodeTypes       
    using ..DataStruct
    using ..SolutionTypes
    using ..SettingTypes
    using ..DataHandeling
    using ..ResultsTypes
    using ..InitialSolutionUtilities
    using ..SolutionUtilities
    using ..ProblemSpecifierTypes
    using JuMP
    using Gurobi


    """
    The function translates the results from solving the model using Gurobi into a 
    solution object, including data from benchmarking. It also returns the data for plotting.

    """
    function get_model_results_gurobi(model, 
            data::Any,
            n_cs_copies::Int, 
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings,
            time_limit::Int,
            printing::Bool,
            problem_variation::ProblemSpecifierTypes.EVRPType; 
            initial_solution::Any = nothing
        )::Tuple{SolutionTypes.EVRPSolution, ResultsTypes.GurobiResults}

        partial_charging_bool = false
        if problem_variation == ProblemSpecifierTypes.partial_charging
            partial_charging_bool = true
        end

       ####### Checking if solved and feasable and saving results #######
        optimal = false
        if termination_status(model) == MOI.OPTIMAL
            optimal = true
            if printing
                println("Optimal solution found.")
            end
        elseif termination_status(model) == MOI.INFEASIBLE
            if printing
                println("Solver did not find an feasable solution.")
            end
            return initial_solution
        end

        solution = ResultHandeling.EVRPSolution(evrp_data, model, n_cs = 
            n_cs_copies, partial_charging_bool = partial_charging_bool)

        all_routes = solution.routes
        evrp_settings.objective_func!(solution, evrp_data)

        check_all_customers_inserted = 
            InitialSolutionUtilities.check_all_customers_inserted(all_routes, 
            evrp_data)
        if !check_all_customers_inserted
            throw(ErrorException("Not all customers are inserted"))
        end

        data_unique = unique(x -> x[2], data)
        data_unique = data_unique[2:end]
        time_elapsed = map(x-> x[1], data_unique)
        best_obj = map(x -> x[2], data_unique)

        if !isnothing(initial_solution)
            evrp_settings.objective_func!(initial_solution, evrp_data)
            pushfirst!(time_elapsed, 0.0)
            pushfirst!(best_obj, initial_solution.objective_value)
        end

        
        if length(best_obj) > 0
            push!(best_obj, best_obj[end])
        else
            push!(best_obj, solution.objective_value)
            if printing
                println("Solution found very quickly, added best solution ",
                    "from model")
            end
        end

        push!(time_elapsed, time_limit)

        data_for_plotting = ResultsTypes.GurobiResults(convert(Vector{Float64}, 
            best_obj), convert(Vector{Float64}, time_elapsed), all_routes, 
            optimal)

        if printing
            best_objective = best_obj[end]
            println("\nBest objective value Gurobi: $(best_objective)")
            i_best = findfirst(x -> x == best_objective, best_obj)
            println("Found at time $(time_elapsed[i_best]) s")
        end

        return solution, data_for_plotting
    end  


      """
    The function translates the results from solving the model into a 
    solution object. It also returns the data for plotting.

    """
    function get_model_results(model, 
            n_cs_copies::Int, 
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings,
            printing::Bool,
            problem_variation::ProblemSpecifierTypes.EVRPType; 
            initial_solution::Any = nothing
        )::SolutionTypes.EVRPSolution

        partial_charging_bool = false
        if problem_variation == ProblemSpecifierTypes.partial_charging
            partial_charging_bool = true
        end

       ####### Checking if solved and feasable and saving results #######
        optimal = false
        if termination_status(model) == MOI.OPTIMAL
            optimal = true
            if printing
                println("Optimal solution found.")
            end
        elseif termination_status(model) == MOI.INFEASIBLE
            if printing
                println("Solver did not find an feasable solution.")
            end
            return initial_solution
        end

        solution = ResultHandeling.EVRPSolution(evrp_data, model, n_cs = 
            n_cs_copies, partial_charging_bool = partial_charging_bool)

        all_routes = solution.routes
        evrp_settings.objective_func!(solution, evrp_data)

        check_all_customers_inserted = 
            InitialSolutionUtilities.check_all_customers_inserted(all_routes, 
            evrp_data)
        if !check_all_customers_inserted
            throw(ErrorException("Not all customers are inserted"))
        end

        return solution
    end  

    """
    The function translates the results from solving the model into a 
    solution object.

    """
    function EVRPSolution(
            evrp_data::DataStruct.DataEVRP, 
            model::Model;
            n_cs::Int = 1,
            partial_charging_bool::Bool = false
        )::SolutionTypes.EVRPSolution

        raw_data_time_arrival = value.(model[:p])
        raw_data_battery_arrival = value.(model[:y])
        raw_data_battery_departure = nothing

        if partial_charging_bool
            raw_data_battery_departure = value.(model[:Y])
        else
            raw_data_battery_departure = nothing 
        end

        routes_and_battery_data = getting_route_index_and_battery_data(
            value.(model[:x]), raw_data_time_arrival, raw_data_battery_arrival, 
            raw_data_battery_departure, evrp_data, n_cs_copies = n_cs, 
            partial_charging = partial_charging_bool)

        objective_value = JuMP.objective_value(model)

        status = JuMP.termination_status(model) 
        is_feasible = nothing
        if status == MOI.OPTIMAL || status == MOI.FEASIBLE_POINT
            is_feasible = true
        else
            is_feasible = false
        end
        
        return SolutionTypes.EVRPSolution(
            routes_and_battery_data[1],
            routes_and_battery_data[2], 
            routes_and_battery_data[3], 
            routes_and_battery_data[4], 
            objective_value, 
            is_feasible)

    end

    """
    The function translates the solution obtained by the model to route index and battery data 
    in the same format as the ALNS solution.

    As the output, it returns a tuple containing:
    - routes: A vector of vectors, where each inner vector contains the nodes in a route.
    - times_of_arrival: A vector of vectors, where each inner vector contains the time of arrival 
      at each node in a route.
    - battery_arrival: A vector of vectors, where each inner vector contains the battery level
        upon arrival at each node in a route.
    - battery_departure: A vector of vectors, where each inner vector contains the battery level
        upon departure from each node in a route.


    """
    function getting_route_index_and_battery_data(
        x_values::Array{Float64, 3}, 
        raw_data_time_arrival::Array{Float64}, 
        raw_data_battery_arrival::Matrix{Float64},
        raw_data_battery_departure::Any,
        evrp_data::DataStruct.DataEVRP;
        n_cs_copies::Int=1,
        partial_charging::Bool=false
        )

        indicies_copies = DataHandeling.getting_indicies_for_copies(evrp_data, 
            n_cs_copies)
        times_of_arrival_all_routes = Vector{Vector{Float64}}(undef, 
            evrp_data.n_vehicles)
        battery_arrival_all_routes = Vector{Vector{Float64}}(undef, 
            evrp_data.n_vehicles)
        battery_departure_all_routes = Vector{Vector{Float64}}(undef, 
            evrp_data.n_vehicles)
        routes = Vector{Vector{NodeTypes.Node}}(undef, evrp_data.n_vehicles)

        depot = evrp_data.nodes[1]

        for k in 1:evrp_data.n_vehicles
            route_k = Vector{NodeTypes.Node}(undef, 0)
            times_of_arrival_route = Vector{Float64}(undef, 0)
            battery_arrival_route = Vector{Float64}(undef, 0)
            battery_departure_route = Vector{Float64}(undef, 0)

            x_values_per_vehicle = x_values[:, :, k]

            feasable_nodes_indicies = [[i,j] for 
                i in 1:size(x_values_per_vehicle, 1), 
                j in 1:size(x_values_per_vehicle, 1) if 
                abs(x_values_per_vehicle[i,j]) == 1.0]

            if length(feasable_nodes_indicies) > 0
                i_end_depot_in_route = maximum(map(x -> maximum(x), 
                    feasable_nodes_indicies))
                prev_node = 1

                # Adding depot to start of route
                push!(route_k, depot)
                push!(times_of_arrival_route, raw_data_time_arrival[1])
                push!(battery_arrival_route, raw_data_battery_arrival[1,k])
                push!(battery_departure_route, evrp_data.battery_capacity)

                # Taking out the next node after depot
                list_index = findfirst(x -> x[1] == prev_node, 
                    feasable_nodes_indicies)
                next_node_index = feasable_nodes_indicies[list_index][2] 
                while next_node_index != i_end_depot_in_route
        
                    if minimum(indicies_copies) <= next_node_index <= 
                            maximum(indicies_copies)
                        index_cs_in_matrix = findfirst(x -> x == next_node_index, 
                            indicies_copies)[1]
                        index_to_add = indicies_copies[index_cs_in_matrix, 1] 
                    else 
                        # If being a customer, we need to consider the copies to 
                        # get the node index in the data
                        index_to_add = next_node_index - 
                            evrp_data.n_charging_stations * (n_cs_copies - 1)

                    end
                    
                    push!(route_k, evrp_data.nodes[index_to_add])
                    push!(times_of_arrival_route, 
                        raw_data_time_arrival[next_node_index])
                    push!(battery_arrival_route, 
                        raw_data_battery_arrival[next_node_index,k])
                    if partial_charging
                        push!(battery_departure_route, 
                            raw_data_battery_departure[next_node_index])
                    else
                        if evrp_data.nodes[index_to_add].node_type == 
                                NodeTypes.charging_station
                            push!(battery_departure_route, 
                                evrp_data.battery_capacity)
                        else
                            push!(battery_departure_route, 
                                raw_data_battery_arrival[next_node_index, k])
                        end
                    end
                    prev_node = next_node_index
                    list_index = findfirst(x -> x[1] == prev_node, 
                        feasable_nodes_indicies)
                    next_node_index = feasable_nodes_indicies[list_index][2] 
                    
                    if next_node_index == i_end_depot_in_route
                        break
                    end

                    if length(route_k) > length(feasable_nodes_indicies) + 2 
                        throw(DomainError(string("Warning: Number of indicies ",
                            "are out of avalable range")))
                    end
                end
                
                if length(route_k) < 2
                    throw(DomainError(string("Warning: It has only added the ",
                        "depot, even if there are more nodes")))
                end
                push!(route_k, depot)
                push!(times_of_arrival_route, 
                    raw_data_time_arrival[i_end_depot_in_route])
                push!(battery_arrival_route, 
                    raw_data_battery_arrival[i_end_depot_in_route,k])

                if partial_charging
                    push!(battery_departure_route, 
                        raw_data_battery_departure[i_end_depot_in_route])
                else
                    push!(battery_departure_route, 
                        raw_data_battery_arrival[i_end_depot_in_route])
                end

                routes[k] = route_k
                times_of_arrival_all_routes[k] = times_of_arrival_route
                battery_arrival_all_routes[k] = battery_arrival_route
                battery_departure_all_routes[k] = battery_departure_route

            else
                routes[k] = []
                times_of_arrival_all_routes[k] = []
                battery_arrival_all_routes[k] = []
                battery_departure_all_routes[k] = []
            end

        end

        return routes, times_of_arrival_all_routes, battery_arrival_all_routes, 
            battery_departure_all_routes
    end



    """
    The function translates the ALNS solution to the model solution.

    As the output, it returns a tuple containing:
    - x_values: A 3D array containing the x values for the model.
    - y_values: A 2D array containing the y values for the model.
    - Y_values: A 1D array containing the Y values for the model.
    - p_values: A 1D array containing the p values for the model.
    - u_values: A 2D array containing the u values for the model.

    """
    function translate_ALNS_solution_to_model_solution(
            solution::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP;
            n_cs_copies::Int = 1,
            printing::Bool = false
        )

        n_nodes = evrp_data.n_nodes + 1 + (n_cs_copies - 1) * 
            evrp_data.n_charging_stations
        n_vehicles = evrp_data.n_vehicles

        x_values = zeros(Float64, n_nodes, n_nodes, n_vehicles)
        y_values = zeros(Float64, n_nodes, n_vehicles)
        Y_values = zeros(Float64, n_nodes)
        p_values = zeros(Float64, n_nodes)
        u_values = zeros(Float64, n_nodes, n_vehicles)


        cs_count = zeros(Int, evrp_data.n_charging_stations)

        for (ri,route) in enumerate(solution.routes)
            if length(route) == 0
                y_values[1, ri] = evrp_data.battery_capacity
                continue
            end
            times_of_arrival = solution.times_of_arrival[ri]
            battery_arrival = solution.battery_arrival[ri]
            battery_departure = solution.battery_departure[ri]

            customers_in_route = filter(n -> n.node_type == NodeTypes.customer, 
                route)
            start_load = sum(node -> node.demand, customers_in_route)

            prev_node_i = 1

            n_nodes_route = length(route)
            for (ni, node) in enumerate(route)

                if ni == 1
                    # x_values[1, next_node_i, ri] = 1.0 
                    y_values[1, ri] = evrp_data.battery_capacity
                    Y_values[1] = battery_departure[1]
                    p_values[1] = times_of_arrival[1]
                    u_values[1, ri] = start_load
                    continue
                end

                next_node_i = node.node_index
                load_droped = 0.0
                
                if node.node_type == NodeTypes.depot
                    y_values[n_nodes, ri] = battery_arrival[n_nodes_route]
                    Y_values[n_nodes] = battery_departure[n_nodes_route]
                    p_values[n_nodes] = max(times_of_arrival[n_nodes_route], 
                        p_values[n_nodes])
                    x_values[prev_node_i, n_nodes, ri] = 1.0
                    continue #ska gå ut från rutten?? borde inte behövas
                elseif node.node_type == NodeTypes.charging_station
                    cs_count[node.type_index] += 1
                    if cs_count[node.type_index] > n_cs_copies
                        println("Warning: to few copies of charging stations")
                        return nothing
                    end
                    next_node_i += (cs_count[node.type_index] - 1)*
                        evrp_data.n_charging_stations
                    
                    if Y_values[next_node_i] != 0.0
                        if printing
                            println("Y_values[$next_node_i] != 0.0")
                        end 
                        return nothing
                    end
                    Y_values[next_node_i] = battery_departure[ni]

                elseif node.node_type == NodeTypes.customer 
                    next_node_i += evrp_data.n_charging_stations * 
                        (n_cs_copies - 1)
                    load_droped = node.demand
                end

                x_values[prev_node_i, next_node_i, ri] = 1.0

                if y_values[next_node_i, ri] != 0.0
                    if printing
                        println("Warning: y_route[ $next_node_i, $ri] != 0.0")
                    end 
                    return nothing
                end
                y_values[next_node_i, ri] = battery_arrival[ni]

                if p_values[next_node_i] != 0.0
                    if printing
                        println("p_values[$next_node_i] != 0.0")
                    end 
                    return nothing
                end
                p_values[next_node_i] = times_of_arrival[ni]


                if u_values[next_node_i, ri] != 0.0
                    if printing
                        println("u_values[$next_node_i, $ri] != 0.0")
                    end 
                    return nothing
                end
                u_values[next_node_i, ri] = u_values[prev_node_i, ri] - 
                    load_droped

                prev_node_i = next_node_i
            end
        end

        return x_values, y_values, Y_values, p_values, u_values

    end

    """
    Callback function used in Gurobi to get the objectve value over time. 
    Note that this functionallity is specific for Gurobi and can not be used
    with other solvers.

    """
    function create_callback(data, start_time)
        return function(cb_data::Gurobi.CallbackData, cb_where::Cint)
            if cb_where == GRB_CB_MIP
                objbst = Ref{Cdouble}()
                GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBST, objbst)
                objbnd = Ref{Cdouble}()
                GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBND, objbnd)
                push!(data, (time() - start_time, objbst[], objbnd[]))
            end
        end
    end
end
