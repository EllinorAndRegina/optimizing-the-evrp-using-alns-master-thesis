module RemoveOperators 
    using Random  
    using StatsBase

    using ..NodeTypes
    using ..DataStruct
    using ..SolutionUtilities
    using ..SettingTypes
    using ..SolutionTypes
    using ..RemoveUtilities

    """
    Randomly remove customers or charging stations from a feasible solution and 
    return a (most likely) non-feasible solution and the removed nodes.

    """
    function random_removal(
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}

        routes = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes)
        n_nodes_in_route = sum(length, routes) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        elseif n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        possible_removals = Vector{Tuple{Int, Int}}(undef, 0)
        for (ri, route) in enumerate(routes)
            removals_per_route = map(x -> (ri, x), 2:length(route) - 1)
            append!(possible_removals, removals_per_route)
        end

        to_remove = sample(alns_settings.rng, possible_removals, 
            n_nodes_to_remove, replace = false)
        # Sort route index in ascending order and the position in descending order
        sort!(to_remove, lt = (x, y) -> (x[1] < y[1]) || (x[1] == y[1] && 
            x[2] > y[2]))

        # Remove nodes
        removed_items = NodeTypes.Node[]
        for (ri, pos) in to_remove
            push!(removed_items, routes[ri][pos])
            deleteat!(routes[ri], pos)
        end

        for (ind, route) in enumerate(routes)
            if length(route) < 3
                routes[ind] = []
                continue
            end

            # Avoid having two charging stations in a row
            prev_node = route[2]
            to_delete = Int[]
            for (i, node) in enumerate(route[3:end])
                if prev_node == node 
                    push!(to_delete, i + 2)
                end
                prev_node = node
            end
            deleteat!(route, to_delete)
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            removed_items)

        S_new = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        if printing
            println("Number of routes", length(routes))
            println("Number of route 1", length(routes[1]))
        end

        return S_new, customer_list
    end

    """
    Randomly remove customers or charging stations from a feasible solution and 
    return a (most likely) non-feasible solution and the removed nodes. The 
    distribution is skewed so that the probability of a node in routes with 
    fewer nodes being removed is larger than the probability for nodes in 
    routes with many nodes.

    """
    function random_removal_non_uniform(
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}

        routes = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes)
        n_nodes_in_route = sum(length, routes) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        elseif n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        removed_items = Vector{NodeTypes.Node}(undef, n_nodes_to_remove)   
        for i in 1:n_nodes_to_remove
            indicies_of_routes_to_choose_from_i = []
            for (ind, route) in enumerate(routes)
                if length(route) > 2
                    push!(indicies_of_routes_to_choose_from_i, ind)
                end
            end

            random_route_index = rand(alns_settings.rng, 
                indicies_of_routes_to_choose_from_i)
            length_route = length(routes[random_route_index])
            random_element_index = rand(alns_settings.rng, 2:(length_route - 1))
            removed_items[i] = routes[random_route_index][random_element_index]
            deleteat!(routes[random_route_index], random_element_index)

            # Avoid having two charging stations in a row (might delete depot 
            # from empty route as well which is fine!)
            if routes[random_route_index][random_element_index - 1] == 
                    routes[random_route_index][random_element_index]
                deleteat!(routes[random_route_index], random_element_index)
            end
        end

        for (ind, route) in enumerate(routes)
            if length(route) < 3
                routes[ind] = []
            end
        end
        
        # Check that the correct number of nodes have been removed
        if length(findall(x -> x === nothing, removed_items)) != 0 
            throw(DomainError(removed_items, 
                "ERROR: wrong number of elements removed"))
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            removed_items)

        S_new = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        if printing
            println("Number of routes", length(routes))
            println("Number of route 1", length(routes[1]))
        end

        return S_new, customer_list
    end


    """
    Randomly remove routes from a feasible solution and return a (most likely) 
    non-feasible solution and the removed nodes. 
    
    Routes are removed until the remove proportion is fulfilled, so it is 
    possible to remove more than the requested amount. 

    """
    function random_routes_removal( 
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}

        if length(S.routes) == 0
            throw(DomainError(S, "You forgot to purchase the trucks..."))
        end

        routes_tmp = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes_tmp)
        n_nodes_in_route = sum(length, routes_tmp) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        elseif n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        routes_to_choose_from_i = findall(x -> !isempty(x), routes_tmp)
        removed = NodeTypes.Node[]
        while length(removed) < n_nodes_to_remove
            ri = rand(alns_settings.rng, routes_to_choose_from_i)
            append!(removed, routes_tmp[ri][2:end-1])
            filter!(x -> x != ri, routes_to_choose_from_i)
            routes_tmp[ri] = NodeTypes.Node[]
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, removed)
        S_new = SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        if length(routes_to_choose_from_i) == 0
            if printing
                println("Warning: All routes removed in random route remove ",
                    "operator. This could be an indication that your remove ",
                    "proportion is too high or you are working on a smaller ",
                    "dataset.")
            end
        end
        
        return S_new, customer_list
    end

    """
    Remove the routes that has the highest costs (with regards to the objective 
    function) from a feasible solution and return a (most likely) non-feasible 
    solution and the removed nodes. 
    
    Routes are removed until the remove proportion is fulfilled, so it is 
    possible to remove more than the requested amount. 

    """
    function worst_cost_routes_removal(
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}
        
        if length(S.routes) == 0
            throw(DomainError(S, "You forgot to purchase the trucks..."))
        end

        routes_tmp = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes_tmp)
        n_nodes_in_route = sum(length, routes_tmp) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        elseif n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        costs_per_route = zeros(length(routes_tmp))
        for (i, route) in enumerate(routes_tmp)
            costs_per_route[i] = evrp_settings.objective_func_per_route(
                route, evrp_data)
        end

        removed = NodeTypes.Node[]
        while length(removed) < n_nodes_to_remove
            ri = argmax(costs_per_route)
            if costs_per_route[ri] < 0
                throw(DomainError(costs_per_route, string("The cost/objective ",
                    "value for a single route should not be negative")))
            end
            
            append!(removed, routes_tmp[ri][2:end - 1])
            costs_per_route[ri] = -1
            routes_tmp[ri] = NodeTypes.Node[]
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, removed)
        S_new = SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        if all(x -> x < 0, costs_per_route)
            if printing
                println("Warning: All routes removed in worst route remove ",
                    "operator. This could be an indication that your remove ",
                    "proportion is too high or you are working on a smaller ",
                    "dataset.")
            end
        end
        
        return S_new, customer_list
    end

    """
    Remove the routes that includes the least amount of nodes from a feasible 
    solution and return a (most likely) non-feasible solution and the removed 
    nodes. 
    
    Routes are removed until the remove proportion is fulfilled, so it is 
    possible to remove more than the requested amount. 

    """
    function shortest_routes_removal(
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}

        if length(S.routes) == 0
            throw(DomainError(S, "You forgot to purchase the trucks..."))
        end

        routes_tmp = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes_tmp)
        n_nodes_in_route = sum(length, routes_tmp) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        elseif n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        length_per_route = map(route -> length(route), routes_tmp)

        removed = NodeTypes.Node[]
        while length(removed) < n_nodes_to_remove
            ri = argmin(length_per_route)
            if length_per_route[ri] > 1000 * evrp_data.n_nodes
                throw(DomainError(length_per_route, string("The length ",
                    "of a route should not be negative, something is wrong with ",
                    "the logic here.")))
            end
            
            append!(removed, routes_tmp[ri][2:end - 1])
            length_per_route[ri] = 1000 * evrp_data.n_nodes + 1
            routes_tmp[ri] = NodeTypes.Node[]
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, removed)
        S_new = SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        if all(x -> x > 1000 * evrp_data.n_nodes, length_per_route)
            if printing
                println("Warning: All routes removed in shortest route remove ",
                    "operator. This could be an indication that your remove ",
                    "proportion is too high or you are working on a smaller ",
                    "dataset.")
            end
        end
        
        return S_new, customer_list
    end

    """
    Remove the customers or charging stations that impact the objective value 
    the most from a feasible solution and return a (most likely) non-feasible 
    solution and the removed nodes.

    """
    function worst_cost_removal(
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings;
            printing::Bool = false
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}
        
        routes_tmp = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes_tmp)
        n_nodes_in_route = sum(length, routes_tmp) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            n_nodes_in_route)

        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        end

        if n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        # Calculate costs. The costs will be negative since costs here are the 
        # differences in objective value when comparing the route with and 
        # without the removed node. The cost is a tuple consisting of the 
        # route index, position index in route, the change in objective value 
        # and a bool describing if a charging station needs to be removed to 
        # avoid repeats of the same charging station in a row.
        costs = Vector{Tuple{Int, Int, Float64, Bool}}(undef, 0)
        for (ri, route) in enumerate(routes_tmp) 
            costs_for_route = RemoveUtilities.calculate_remove_costs_for_route(
                route, ri, evrp_data, evrp_settings)
            append!(costs, costs_for_route)
        end

        # Remove nodes
        removed = []
        for i in 1:n_nodes_to_remove
            if length(costs) == 0
                break
            end
            
            min_idx = argmin(x[3] for x in costs)
            route_i, pos, _, cs_remove_required = costs[min_idx]
            push!(removed, routes_tmp[route_i][pos])
            deleteat!(routes_tmp[route_i], pos)
            
            # Avoid multiple cs in a row
            if cs_remove_required
                deleteat!(routes_tmp[route_i], pos)
            end
            filter!(x -> x[1] != route_i, costs)
            
            # Recalculate costs
            new_costs = RemoveUtilities.calculate_remove_costs_for_route(
                routes_tmp[route_i], route_i, evrp_data, evrp_settings)
            append!(costs, new_costs)
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, removed)

        S = SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        return S, customer_list
    end

    """
    In Shaw removal, what nods that are removed from the solution are determained by
    the distance to a seed node. The seed node is chosen randomly and the nodes
    that are removed are the ones that are closest to the seed node. The number of
    nodes to remove is determined by the remove proportion.

    """
    function shaw_removal_distance(        
            S::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings,
            alns_settings::SettingTypes.ALNSSettings
        )::Tuple{SolutionTypes.EVRPSolution, Vector{NodeTypes.Node}}
    
        routes_tmp = [copy(route) for route in S.routes]
        n_non_empty_routes = count(x -> !isempty(x), routes_tmp)
        n_nodes_in_route = sum(length, routes_tmp) - n_non_empty_routes * 2

        n_nodes_to_remove = ceil(Int, alns_settings.remove_proportion * 
            (evrp_data.n_nodes - 1))
        if n_nodes_to_remove < 1
            throw(DomainError(n_nodes_to_remove, 
                "Trying to remove less then 1 node: Should remove atleast 1"))
        end

        if n_nodes_to_remove > n_nodes_in_route
            throw(DomainError(n_nodes_to_remove, string(
                "Number of nodes to remove are more then number of nodes ",
                "in the routes: not possible!")))
        end

        # Find random seed node
        seed_node = rand(alns_settings.rng, evrp_data.nodes[2:end])

        # Find which nodes to remove
        removed_nodes = Vector{NodeTypes.Node}(undef, 0)

        if n_nodes_to_remove > 1
            possible_removals = collect(enumerate(evrp_data.distances[
                seed_node.node_index, 2:end]))
            partialsort!(possible_removals, n_nodes_to_remove - 1, 
                by = x -> x[2])
            removed_nodes = map(x -> evrp_data.nodes[x[1] + 1], 
                possible_removals[1:n_nodes_to_remove - 1])
        end

        push!(removed_nodes, seed_node)

        # Remove nodes
        for (ri, route) in enumerate(routes_tmp)
            to_remove_in_route = Int[]
            for (i, node) in enumerate(route[2:end-1])
                if node in removed_nodes
                    push!(to_remove_in_route, i + 1)
                end
            end
            deleteat!(route, to_remove_in_route)
            if length(route) < 3
                routes_tmp[ri] = NodeTypes.Node[]
                continue
            end

            # Avoid having two charging stations in a row
            prev_node = route[2]
            to_delete = Int[]
            for (i, node) in enumerate(route[3:end])
                if prev_node == node 
                    push!(to_delete, i + 2)
                end
                prev_node = node
            end
            deleteat!(route, to_delete)
        end

        customer_list = filter(x -> x.node_type == NodeTypes.customer, 
            removed_nodes)

        S = SolutionUtilities.create_solution_from_routes(routes_tmp, 
            evrp_data, evrp_settings, throw_infeasible_time_errors = false)

        return S, customer_list
    end
end

