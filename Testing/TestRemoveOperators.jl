

module TestRandomRemovalUniform
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Plots

    function test_random_removal_basic() 
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        number_of_nodes_to_remove = 5 
        n_nodes_before = sum([length(route) for route in S.routes])
        
        S_relaxed, customer_list = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])
        
        n_removed_nodes = n_nodes_before - n_nodes_after
        
        @assert n_removed_nodes == number_of_nodes_to_remove string(
            "Testing if number of nodes to ",
            "remove is 5, should pass: Test failed")
        @assert all(x -> x.node_type == NodeTypes.customer, customer_list) string(
            "customer list should only contain customers")
    end

    function test_random_removal_Number_removed_zero()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Testing if number of nodes to remove is 0, should give an error: Test failed"
    end

    function test_random_removal_Number_removed_more_than_number_nodes()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Testing if number of nodes to remove is 0, should give an error: Test failed"
    end

    function test_random_removal_10000_rounds()
        S_relaxed = nothing 
        removed_items = nothing
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.05)
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                    evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                    evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                    evrp_data.nodes[[1, 17, 2, 1]]]
  
        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        all_removed_items = []
        counts = zeros(evrp_data.n_customers)
        for _ in 1:10000
            S_relaxed, removed_items = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)
            
            if !isempty(removed_items)
                node_i = removed_items[1].type_index
                push!(all_removed_items, node_i)
                counts[node_i] += 1
            end
        end

        # plt = histogram(all_removed_items, bins = 30)
        # display(plt)

        @assert all(x -> (x > 540 && x < 650), counts) "Your random remove might not be removing customers uniformly."
    end

    function test_random_remove_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end

    function test_random_removal_remove_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.95)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        S_removed, _ = RemoveOperators.random_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S_removed.routes[1], evrp_data.nodes[[]]) "First route is supposed to be empty"
        @assert isequal(S_removed.routes[3], evrp_data.nodes[[]]) "Third route is supposed to be empty"
        @assert isequal(S_removed.routes[2], evrp_data.nodes[[]]) "Second route is supposed to be empty"
        @assert isequal(S_removed.routes[4], evrp_data.nodes[[]]) "Fourth route is supposed to be empty"
    end
end

module TestRandomRemovalNonUniform
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Plots

    function test_random_removal_basic() 
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        number_of_nodes_to_remove = 5 
        n_nodes_before = sum([length(route) for route in S.routes])
        
        S_relaxed, customer_list = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])
        
        n_removed_nodes = n_nodes_before - n_nodes_after
        
        @assert n_removed_nodes == number_of_nodes_to_remove string(
            "Testing if number of nodes to ",
            "remove is 5, should pass: Test failed")
        @assert all(x -> x.node_type == NodeTypes.customer, customer_list) string(
            "customer list should only contain customers")
    end

    function test_random_removal_Number_removed_zero()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Testing if number of nodes to remove is 0, should give an error: Test failed"
    end

    function test_random_removal_Number_removed_more_than_number_nodes()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_random_removal_10000_rounds() # Just for histogram visualization
        S_relaxed = nothing 
        removed_items = nothing
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.05)
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                    evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                    evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                    evrp_data.nodes[[1, 17, 2, 1]]]
  
        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        all_removed_items = []
        counts = zeros(evrp_data.n_customers)
        for _ in 1:10000
            S_relaxed, removed_items = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)
            
            if !isempty(removed_items)
                node_i = removed_items[1].type_index
                push!(all_removed_items, node_i)
                counts[node_i] += 1
            end
        end

        plt = histogram(all_removed_items, bins = 30)
        display(plt)
    end

    function test_random_remove_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end

    function test_random_removal_remove_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.95)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        S_removed, _ = RemoveOperators.random_removal_non_uniform(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S_removed.routes[1], evrp_data.nodes[[]]) "First route is supposed to be empty"
        @assert isequal(S_removed.routes[3], evrp_data.nodes[[]]) "Third route is supposed to be empty"
        @assert isequal(S_removed.routes[2], evrp_data.nodes[[]]) "Second route is supposed to be empty"
        @assert isequal(S_removed.routes[4], evrp_data.nodes[[]]) "Fourth route is supposed to be empty"
    end
end

module TestRandomRouteRemoval 
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Suppressor


    function test_random_route_removal_basic()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        number_of_nodes_to_remove = 5 
        n_nodes_before = sum([length(route) for route in S.routes])
        
        S_relaxed, customer_list = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])
        
        n_removed_nodes = n_nodes_before - n_nodes_after
        
        @assert n_removed_nodes >= number_of_nodes_to_remove string(
            "Testing if number of nodes to ",
            "remove is 5, should pass: Test failed")
        @assert all(x -> x.node_type == NodeTypes.customer, customer_list) string(
            "customer list should only contain customers")
    end

    function test_random_route_removal_one_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]],
            evrp_data.nodes[[]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        number_of_nodes_to_remove = 5 
        n_nodes_before = sum([length(route) for route in S.routes])
        
        S_relaxed, customer_list = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])
        
        n_removed_nodes = n_nodes_before - n_nodes_after
        
        @assert n_removed_nodes >= number_of_nodes_to_remove string(
            "Testing if number of nodes to ",
            "remove is 5, should pass: Test failed")
        @assert all(x -> x.node_type == NodeTypes.customer, customer_list) string(
            "customer list should only contain customers")
    end

    function test_random_route_removal_no_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_random_route_removal_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)

        S_relaxed, customer_list = nothing, nothing
        output = @capture_out begin
            S_relaxed, customer_list = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings, printing = true)
        end
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])

        @assert n_nodes_after == 0 string(
            "We should be able to remove all nodes, but something went wrong here")
        @assert length(customer_list) == evrp_data.n_customers string("If all customers ",
            "they should all end up in the customer list, you are missing some or added too many")
        @assert contains(output, "Warning: All routes removed in random route remove operator.")
    end

    function test_random_route_removal_more_than_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is more than n_nodes, ",
            "should give an error: Test failed")
    end

    function test_random_route_removal_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.random_routes_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end
end

module TestWorstCostRouteRemoval
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Plots
    using Suppressor

    function test_worst_cost_route_removal_basic()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.3)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]],    # distance = 63.895
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]],           # distance = 90.662
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]],          # distance = 91.300
            evrp_data.nodes[[1, 17, 2, 1]]                      # distance = 63.902
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[]]) "Second route is supposed to be removed"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[]]) "Third route is supposed to be removed"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
        @assert customer_list == evrp_data.nodes[[18, 14, 11, 8, 13, 7, 12]] "Customer list incorrect"
    end


    function test_worst_cost_route_removal_with_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]],
            evrp_data.nodes[[]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[]]) "Third route is supposed to be removed"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be removed"
        @assert isequal(S_relaxed.routes[5], evrp_data.nodes[[]]) "Fifth route is supposed to be unchanged"
        @assert customer_list == evrp_data.nodes[[18, 14, 11, 8]] "Customer list incorrect"
    end

    function test_worst_cost_route_removal_no_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_worst_cost_route_removal_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)

        S_relaxed, customer_list = nothing, nothing
        output = @capture_out begin
            S_relaxed, customer_list = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings, printing = true)
        end
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])

        @assert n_nodes_after == 0 string(
            "We should be able to remove all nodes, but something went wrong here")
        @assert length(customer_list) == evrp_data.n_customers string("If all customers ",
            "they should all end up in the customer list, you are missing some or added too many")
        @assert contains(output, "Warning: All routes removed in worst route remove operator.")
    end

    function test_worst_cost_route_removal_more_than_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is more than n_nodes, ",
            "should give an error: Test failed")
    end

    function test_worst_cost_route_removal_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.worst_cost_routes_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end
end

module TestShortestRouteRemoval
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Plots
    using Suppressor

    function test_shortest_route_removal_basic_one_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.1)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[]]) "Fourth route is supposed to be removed"
        @assert customer_list == evrp_data.nodes[[17]] "Customer list incorrect"
    end

    function test_shortest_route_removal_basic_two_routes()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[]]) "First route is supposed to be removed"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[]]) "Fourth route is supposed to be removed"
        @assert customer_list == evrp_data.nodes[[17, 10, 15, 9, 16]] "Customer list incorrect"
    end

    function test_shortest_route_removal_with_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]],
            evrp_data.nodes[[]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[]]) "First route is supposed to be removed"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[]]) "Fourth route is supposed to be removed"
        @assert isequal(S_relaxed.routes[5], evrp_data.nodes[[]]) "Fifth route is supposed to be unchanged"
        @assert customer_list == evrp_data.nodes[[17, 10, 15, 9, 16,]] "Customer list incorrect"
    end

    function test_shortest_route_removal_no_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_shortest_route_removal_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)

        S_relaxed, customer_list = nothing, nothing
        output = @capture_out begin
            S_relaxed, customer_list = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings, printing = true)
        end
        n_nodes_after = sum([length(route) for route in S_relaxed.routes])

        @assert n_nodes_after == 0 string(
            "We should be able to remove all nodes, but something went wrong here")
        @assert length(customer_list) == evrp_data.n_customers string("If all customers ",
            "they should all end up in the customer list, you are missing some or added too many")
        @assert contains(output, "Warning: All routes removed in shortest route remove operator.")
    end

    function test_shortest_route_removal_more_than_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is more than n_nodes, ",
            "should give an error: Test failed")
    end

    function test_shortest_route_removal_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.shortest_routes_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end
end

module TestWorstCostRemoval
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions
    using Plots

    function test_worst_cost_removal_basic()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.worst_cost_removal(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(customer_list, evrp_data.nodes[[18, 8, 15, 9]]) "Customer list incorrect"
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 16, 1]]) "First route is incorrect"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 14, 11, 4, 1]]) "Third route is incorrect"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end

    function test_worst_cost_removal_one_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]],
            evrp_data.nodes[[]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        S_relaxed, customer_list = RemoveOperators.worst_cost_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(customer_list, evrp_data.nodes[[18, 8, 15, 9]]) "Customer list incorrect"
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 16, 1]]) "First route is incorrect"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 14, 11, 4, 1]]) "Third route is incorrect"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[5], evrp_data.nodes[[]]) "Fifth route is supposed to be unchanged"
    end

    function test_worst_cost_removal_no_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.worst_cost_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_worst_cost_removal_more_than_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.worst_cost_removal(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is more than n_nodes, ",
            "should give an error: Test failed")
    end

    function test_worst_cost_removal_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.worst_cost_removal(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end
end


module TestShawRemoval
    using ..NodeTypes
    using ..DataStruct
    using ..ObjectiveFunctions
    using ..InitialSolutionUtilities
    using ..EVRPSetupFunctions
    using ..RemoveOperators
    using ..SolutionUtilities
    using ..ALNSSetupFunctions

    function test_shaw_removal_basic()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.25)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(customer_list, evrp_data.nodes[[11, 14, 8, 18]]) "Customer list incorrect"
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[]]) "Third route is incorrect"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end

    function test_shaw_removal_one_empty_route()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]],
            evrp_data.nodes[[]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(customer_list, evrp_data.nodes[[11, 14, 8, 18, 16, 10]]) "Customer list incorrect"
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 15, 3, 9, 1]]) "First route is incorrect"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[]]) "Third route is incorrect"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[5], evrp_data.nodes[[]]) "Fifth route is supposed to be unchanged"
    end

    function test_shaw_removal_no_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.0)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is 0, ",
            "should give an error: Test failed")
    end

    function test_shaw_removal_more_than_all_nodes_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 1.1)
        
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
                evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
                evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
                evrp_data.nodes[[1, 17, 2, 1]]]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        recreated_error = false
        try 
            output = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)
        catch err
            if isa(err, DomainError)
                recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error string("Testing if number of nodes to remove is more than n_nodes, ",
            "should give an error: Test failed")
    end

    function test_shaw_removal_input_unchanged()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.4)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings) 
        
        output = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)

        @assert isequal(S.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S.routes[3], evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]]) "Third route is supposed to be unchanged"
        @assert isequal(S.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end

    function test_shaw_removal_only_one_node_removed()
        file_name = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name) 
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(remove_proportion = 0.05)

        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
        ]

        S = SolutionUtilities.create_solution_from_routes(routes, evrp_data, evrp_settings)
        
        S_relaxed, customer_list = RemoveOperators.shaw_removal_distance(S, evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(customer_list, evrp_data.nodes[[]]) "Customer list incorrect"
        @assert isequal(S_relaxed.routes[1], evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]]) "First route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[2], evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]]) "Second route is supposed to be unchanged"
        @assert isequal(S_relaxed.routes[3], evrp_data.nodes[[1, 18, 14, 11, 8, 1]]) "Third route is incorrect"
        @assert isequal(S_relaxed.routes[4], evrp_data.nodes[[1, 17, 2, 1]]) "Fourth route is supposed to be unchanged"
    end
end
