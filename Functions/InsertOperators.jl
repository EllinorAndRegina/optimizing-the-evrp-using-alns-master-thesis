module InsertOperators
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..SolutionUtilities
    using ..InsertUtilities

    using Random

    """
    Create a new feasible solution by inserting the removed customers into their 
    best positions according to the greedy principle. The customer that affects 
    the objective value the least is inserted in its best position in its best 
    route.

    If no feasible solution is found, `nothing` is returned.

    """
    function greedy_insert(
            broken_solution::SolutionTypes.EVRPSolution,
            removed_customers::Vector{NodeTypes.Node},
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        return greedy(broken_solution.routes, removed_customers, 
            evrp_data, evrp_settings, 
            alns_settings.cs_insert_score_parameters, 
            alns_settings.k_cs_insert, printing = printing)
    end

    function greedy(
            routes::Vector{Vector{NodeTypes.Node}},
            removed_customers::Vector{NodeTypes.Node},
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            cs_insert_score_parameters::Tuple{Float64, Float64, Float64},
            k_cs_insert::Int;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        n_routes = length(routes)
        routes_tmp = [copy(route) for route in routes]
        customer_list = copy(removed_customers)

        # Calculate the differences in objective value when inserting the nodes
        # in each route in the best positions
        delta_objectives = Matrix{Tuple{Int, Float64, Bool}}(undef, n_routes, 
            length(customer_list))
        for (r, route) in enumerate(routes_tmp)
            for (i, node) in enumerate(customer_list)
                pos, delta, feasible = 
                    InsertUtilities.calculate_cost_of_inserting_node(node, 
                    route, evrp_data, evrp_settings)
                delta_objectives[r, i] = (pos, delta, feasible)
            end
        end
        
        # Insert customers
        while !isempty(customer_list)
            # Here node_to_insert_i is the index in the customer_list list
            node_to_insert_i, corr_route = InsertUtilities.find_min_in_cost_matrix(
                delta_objectives) 

            if isnothing(node_to_insert_i)  
                if printing
                    println("Warning: no node inserted")
                end
                return nothing
            end 

            node = customer_list[node_to_insert_i]
            if node.node_type != NodeTypes.customer
                println("WARNING: Your list of customers to insert contains at ",
                    "least one $(node.node_type). It is being ignored.")
                deleteat!(customer_list, node_to_insert_i) 
                delta_objectives = delta_objectives[:, 1:end .!= node_to_insert_i]
                continue
            end
            
            # Insert node in the best position
            pos, _, battery_feasible = delta_objectives[corr_route, 
                node_to_insert_i]
            current_route = []

            if length(routes_tmp[corr_route]) == 0
                # If route has not been initialized previously, we add the 
                # depot at the start and the end
                current_route = [evrp_data.nodes[1], node, evrp_data.nodes[1]] 
            else
                current_route = vcat(routes_tmp[corr_route][1:pos - 1], node, 
                    routes_tmp[corr_route][pos:end])
            end
            
            if !battery_feasible 
                status = InsertUtilities.charging_stations_k_insert!(
                    current_route, evrp_data, evrp_settings, 
                    cs_insert_score_parameters, 
                    k_cs_insert)
                if !status
                    delta_objectives[corr_route, node_to_insert_i] = 
                        (-1, Inf, false)
                    continue
                end
            end
            
            deleteat!(customer_list, node_to_insert_i) 
            delta_objectives = delta_objectives[:, 1:end .!= node_to_insert_i]

            # Recalculate delta_objectives for modified route
            for (i, node) in enumerate(customer_list)
                if delta_objectives[corr_route, i] != Inf
                    pos, delta, feasible = InsertUtilities.
                        calculate_cost_of_inserting_node(node, current_route, 
                            evrp_data, evrp_settings)
                        delta_objectives[corr_route, i] = (pos, delta, feasible)
                end
            end

            # Save route
            routes_tmp[corr_route] = current_route
        end

        # Postprocess routes so they fulfill charging constraints even if no 
        # customer has been added
        for route in routes_tmp
            status = InsertUtilities.charging_stations_k_insert!(route, 
                evrp_data, evrp_settings, 
                cs_insert_score_parameters, 
                k_cs_insert)
            if !status
                return nothing
            end
        end
        
        return SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = true)
    end

    """
    Create a new feasible solution by inserting the removed customers into their 
    best positions one at a time in random order. The randomly chosen customer 
    is inserted in the feasible route and position that affects the objective 
    value the least.

    If no feasible solution is found, `nothing` is returned.

    """
    function random_insert(
            broken_solution::SolutionTypes.EVRPSolution,
            removed_customers::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        routes_tmp = [copy(route) for route in broken_solution.routes]
        customer_list = copy(removed_customers)
        
        shuffle!(alns_settings.rng, customer_list)

        # Insert customers
        for customer in customer_list
            n_tries_to_insert = alns_settings.n_tries_to_insert

            if customer.node_type != NodeTypes.customer
                println("WARNING: Your list of customers to insert contains at ",
                    "least one $(customer.node_type). It is being ignored.") 
                continue
            end
    
            costs = Vector{Tuple{Int, Int, Float64, Bool}}(undef, 0)
            for (r, route) in enumerate(routes_tmp)
                k_best_per_route = 
                    InsertUtilities.calculate_k_best_costs_of_inserting_node(
                    customer, route, n_tries_to_insert, evrp_data, evrp_settings) 
                append!(costs, map(x -> (r, x[1], x[2], x[3]), k_best_per_route))
            end

            if length(costs) == 0
                if printing
                    println("Warning: no node inserted")
                end
                return nothing
            end

            n_tries_to_insert = min(length(costs), n_tries_to_insert)
            partialsort!(costs, n_tries_to_insert, by = x -> x[3])
            
            current_route = []
            for (ri, pos, _, battery_feasible) in costs[1:n_tries_to_insert]
                if length(routes_tmp[ri]) == 0
                    # If route has not been initialized previously, we add the 
                    # depot at the start and the end
                    current_route = [evrp_data.nodes[1], customer, evrp_data.nodes[1]] 
                else
                    current_route = vcat(routes_tmp[ri][1:pos - 1], customer, 
                        routes_tmp[ri][pos:end])
                end

                if !battery_feasible 
                    status = InsertUtilities.charging_stations_k_insert!(
                        current_route, evrp_data, evrp_settings, 
                        alns_settings.cs_insert_score_parameters, 
                        alns_settings.k_cs_insert)
                    if !status
                        current_route = []
                        continue
                    end
                end

                routes_tmp[ri] = current_route
                break
            end

            if length(current_route) == 0
                if printing
                    println("Warning: customer could not be inserted within ",
                        "$(alns_settings.n_tries_to_insert) tries in random insert")
                end
                return nothing
            end
        end

        # Postprocess routes so they fulfill charging constraints even if no 
        # customer has been added
        for route in routes_tmp
            status = InsertUtilities.charging_stations_k_insert!(route, 
                evrp_data, evrp_settings, 
                alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
            if !status
                return nothing
            end
        end

        return SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = true)
    end



    """
    Create a new feasible solution by inserting the removed customers into their
    best positions according to the k-regret principle. The customer that affects 
    most the objective value is inserted in its best position in its best route.

    To handle the k best costs for each route and node, a dictionary is used for 
    these calculations. The key is a tuple with the node and route index and the 
    value is a vector containing the k best insertions in the route. An insertion 
    consists of a tuple of the form (insert position in route, cost, is battery 
    feasible). If there are less than k possible insertions the vector has the 
    length of the possible number of insertions.

    """
    function highest_position_k_regret_insert(  
            broken_solution::SolutionTypes.EVRPSolution,
            removed_customers::Vector{NodeTypes.Node},
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        k = alns_settings.k_regret
        n_routes = length(broken_solution.routes)
        routes_tmp = [copy(route) for route in broken_solution.routes]
        customer_list = copy(removed_customers)

        if printing && any(x -> x.node_type != NodeTypes.customer, customer_list)
            println("WARNING: Your list of customers to insert contains ",
                "nodes that are not customers. They are ignored.")
        end
        customer_list = filter(x -> x.node_type == NodeTypes.customer, customer_list)

        costs = Dict{Tuple{Int, Int}, Vector{Tuple{Int, Float64, Bool}}}()
        for (r, route) in enumerate(routes_tmp)
            for node in customer_list
                # Calculate the k best costs of inserting each node for each route
                costs[( node.node_index, r)] = 
                    InsertUtilities.calculate_k_best_costs_of_inserting_node(
                    node, route, k, evrp_data, evrp_settings)
            end
        end

        # Insert customers
        while !isempty(customer_list)
            # Find the node to insert
            i_in_list_customer_to_insert = nothing
            max_regret_measure = -Inf
            k_best = []

            for (ci, customer) in enumerate(customer_list)
                # Calculate the k best position in the solution for the customer
                k_best_per_customer = InsertUtilities.find_k_best_per_customer(
                    costs, customer.node_index, n_routes, k) 
                if length(k_best_per_customer) == 0
                    if printing
                        println("Warning: no node inserted")
                    end
                    return nothing
                end

                # Calculate the regret measure for the customer
                regret_measure = sum(k_best_per_customer[i][3] - 
                    k_best_per_customer[1][3] for i in 
                    eachindex(k_best_per_customer))
                if regret_measure > max_regret_measure
                    i_in_list_customer_to_insert = ci
                    max_regret_measure = regret_measure
                    k_best = k_best_per_customer
                end
            end

            if isnothing(i_in_list_customer_to_insert)
                if printing
                    println("Warning: no customer to insert due to regret measure ",
                        "< -Inf")
                end
                return nothing
            end

            customer = customer_list[i_in_list_customer_to_insert]
            
            # Insert customer in its best feasible route. 
            # If none of the k best ones are feasible return nothing.
            current_route = []
            insertion_route_i = nothing
            for insertion_data in k_best
                route_i, pos, _, battery_feasible = insertion_data

                if length(routes_tmp[route_i]) == 0
                    # If route has not been initialized previously, we add the 
                    # depot at the start and the end
                    current_route = [evrp_data.nodes[1], customer, 
                        evrp_data.nodes[1]]
                else
                    current_route = vcat(routes_tmp[route_i][1:pos - 1], customer, 
                        routes_tmp[route_i][pos:end])
                end
                
                if !battery_feasible 
                    status = InsertUtilities.charging_stations_k_insert!(
                        current_route, evrp_data, evrp_settings, 
                        alns_settings.cs_insert_score_parameters, 
                        alns_settings.k_cs_insert)
                    if !status
                        continue
                    end
                end
                
                insertion_route_i = route_i
                break
            end

            if isnothing(insertion_route_i)
                if printing
                    println("Warning: customer with node index ",
                        "$(customer.node_index) could not be inserted due to ",
                        "battery constraints")
                end
                return nothing
            end
            
            # Delete customer from the list of customers to insert
            deleteat!(customer_list, i_in_list_customer_to_insert) 
               
            # Delete the costs in the dictionary for the customer that was just 
            # inserted
            for ri in 1:n_routes
                delete!(costs, (customer.node_index, ri))
            end

            # Recalculate the costs for the route where the customer was inserted
            for customer_to_insert in customer_list
                costs[(customer_to_insert.node_index, insertion_route_i)] = 
                    InsertUtilities.calculate_k_best_costs_of_inserting_node(
                    customer_to_insert, current_route, k, evrp_data, evrp_settings)
            end

            # Save route
            routes_tmp[insertion_route_i] = current_route
        end

        # Postprocess routes so they fulfill charging constraints even if no 
        # customer has been added
        for route in routes_tmp
            status = InsertUtilities.charging_stations_k_insert!(route, 
                evrp_data, evrp_settings, 
                alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
            if !status
                return nothing
            end
        end
        
        return SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = true)
    end


    """
    Create a new feasible solution by inserting the removed customers into their
    best positions according to the k-regret principle. The customer that affects
    most the objective value is inserted in its best position in its best route. 
    Here, first the best position in each route is calculated then we use the k 
    best routes to choose what costumer to insert first.

    """
    function highest_route_k_regret_insert(
            broken_solution::SolutionTypes.EVRPSolution,
            removed_customers::Vector{NodeTypes.Node}, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Union{SolutionTypes.EVRPSolution, Nothing}

        n_routes = length(broken_solution.routes)
        routes_tmp = [copy(route) for route in broken_solution.routes]
        customer_list = copy(removed_customers)

        if printing && any(x -> x.node_type != NodeTypes.customer, customer_list)
            println("WARNING: Your list of customers to insert contains ",
                "nodes that are not customers. They are ignored.")
        end
        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            customer_list)

        if customer_list == []
            if printing
                println("Warning: no customer in customer_list to insert")
            end
        end

        # Calculate the costs of insertions.
        costs = Matrix{Tuple{Int, Float64, Bool}}(undef, n_routes, 
            length(customer_list))
        for (r, route) in enumerate(routes_tmp)
            for (i, node) in enumerate(customer_list)
                costs[r, i] = 
                    InsertUtilities.calculate_cost_of_inserting_node(
                    node, route, evrp_data, evrp_settings)
            end
        end

        # Insert customers
        while !isempty(customer_list)

            # Find the node to insert
            customer_to_insert_i = -1
            max_regret_measure = -Inf
            k_best = []

            for ci in 1:length(customer_list)
                insertion_data_for_customer = [(r, x[1], x[2], x[3]) for 
                    (r, x) in enumerate(costs[:, ci])]
                filtered_insertions = filter(x -> x[3] < Inf, 
                    insertion_data_for_customer)

                if length(filtered_insertions) == 0
                    if printing
                        println("Warning: No possible positions to insert the ",
                            "customer")
                    end
                    return nothing
                end

                k_tmp = min(length(filtered_insertions), alns_settings.k_regret)
                k_best_per_customer = partialsort!(filtered_insertions, 1:k_tmp, 
                    by = x -> x[3])
                
                regret_measure = sum(k_best_per_customer[i][3] - 
                    k_best_per_customer[1][3] for i in 1:k_tmp)
                
                if regret_measure > max_regret_measure
                    max_regret_measure = regret_measure
                    customer_to_insert_i = ci
                    k_best = k_best_per_customer
                end
            end

            if customer_to_insert_i == -1
                if printing
                    println("Warning: no customer to insert due to regret measure ",
                        "< -Inf")
                end
                return nothing
            end

            customer = customer_list[customer_to_insert_i]
            
            # Insert customer in its best feasible route. 
            # If none of the k best ones are feasible return nothing.
            current_route = []
            insertion_route_i = -1
            for insertion_data in k_best
                route_i, pos, _, battery_feasible = insertion_data

                if length(routes_tmp[route_i]) == 0
                    # If route has not been initialized previously, we add the 
                    # depot at the start and the end
                    current_route = [evrp_data.nodes[1], customer, 
                        evrp_data.nodes[1]] 
                else
                    current_route = vcat(routes_tmp[route_i][1:pos - 1], customer, 
                        routes_tmp[route_i][pos:end])
                end
                
                if !battery_feasible 
                    status = InsertUtilities.charging_stations_k_insert!(
                        current_route, evrp_data, evrp_settings, 
                        alns_settings.cs_insert_score_parameters, 
                        alns_settings.k_cs_insert)
                    if !status
                        continue
                    end
                end
                
                insertion_route_i = route_i
                break
            end

            if insertion_route_i == -1
                if printing
                    println("Warning: customer with node index ",
                        "$(customer.node_index) could not be inserted due to ",
                        "battery constraints")
                end
                return nothing
            end

            deleteat!(customer_list, customer_to_insert_i) 
            costs = costs[:, 1:end .!= customer_to_insert_i]

            # Recalculate costs for modified route
            for (i, node) in enumerate(customer_list)
                pos, delta, feasible = InsertUtilities.
                    calculate_cost_of_inserting_node(node, current_route, 
                        evrp_data, evrp_settings)
                costs[insertion_route_i, i] = (pos, delta, feasible)
            end

            # Save route
            routes_tmp[insertion_route_i] = current_route
        end

        # Postprocess routes so they fulfill charging constraints even if no 
        # customer has been added
        for route in routes_tmp
            status = InsertUtilities.charging_stations_k_insert!(route, 
                evrp_data, evrp_settings, alns_settings.cs_insert_score_parameters, 
                alns_settings.k_cs_insert)
            if !status
                return nothing
            end
        end
        
        return SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = true)
    end
end
