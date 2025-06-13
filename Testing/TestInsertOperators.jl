# include("../Types.jl")

# # Include function files
# include("../Functions/DataParsing.jl")
# include("../Functions/EVRPFunctions.jl")
# include("../Functions/Utilities.jl")
# include("../Functions/InsertOperators.jl")
# include("../Functions/RemoveOperators.jl")
# include("../Functions/ALNSFunctions.jl")
# include("SetupFunctions.jl")


module TestGreedyInsertFull
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..ParsingFunctions

    using ..EVRPSetupFunctions
    using ..ALNSSetupFunctions
    using ..InsertOperators
    using ..SolutionUtilities
    using ..InsertUtilities

    using Suppressor

    function test_greedy_insert_feasible()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_greedy_insert_with_non_customer_in_customer_list() 
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 1, 8]]
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            InsertOperators.greedy_insert(broken_solution, customers_to_insert, 
                evrp_data, evrp_settings, alns_settings)
        end
        
        @assert contains(output, string("Your list of customers to insert",
            " contains at least one depot. It is being ignored.")) string(
            "There is no warning when trying to insert a depot or charging ",
            "station in insert_customers_greedy!")
    end

    function test_greedy_insert_empty_routes_no_charging()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[16, 8]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 8, 16, 1]]) "First route incorrect"
        @assert isequal(new_solution.routes[2], evrp_data.nodes[[]]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], evrp_data.nodes[[]]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], evrp_data.nodes[[]]) "Fourth route incorrect"
    end

    function test_greedy_insert_empty_routes_with_charging()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/GreedyInsertEmptyWithCSSingleVehicle.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[2, 3, 4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 3, 5, 4, 6, 2, 1]]) "Route incorrect"
    end

    function test_greedy_insert_infeasible()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [evrp_data.nodes[[1, 2, 3, 1]]]        
        customers_to_insert = evrp_data.nodes[[4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            global sol = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        @assert isnothing(sol) "This problem is not supposed to be feasible"

    end

    function test_greedy_insert_cs_insert_needed()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 1]],
            ]
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 1]],
            ]
        
        removed_customers = [evrp_data.nodes[7]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, removed_customers,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_greedy_insert_with_battery_infeasible_route_input()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BasicExampleLessBattery.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = false)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert, 
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) string(
            "First route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[2], routes_full[2]) string(
            "Second route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[3], routes_full[3]) string(
            "Third route incorrect, customer incorrectly inserted")
        @assert isequal(new_solution.routes[4], routes_full[4]) string(
            "Fourth route incorrect, cs incorrectly inserted")
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 8, 
            1]]) "Input should be unchanged, specifically route where cs has been removed"
    end

    function test_greedy_insert_infeasible_input_unchanged()
        data_file = "Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11, 19]]

        broken_solution = SolutionUtilities.create_solution_from_routes(
            broken_routes, evrp_data, evrp_settings)

        output = @capture_out begin
            global new_solution = InsertOperators.greedy_insert(broken_solution, 
                customers_to_insert, evrp_data, evrp_settings, alns_settings)
        end

        @assert isnothing(new_solution)
        @assert isequal(broken_routes[1], evrp_data.nodes[[1, 10, 15, 9, 
            1]]) "Input routes are supposed to be unchanged, first"
        @assert isequal(broken_routes[2], evrp_data.nodes[[1, 2, 17, 12, 6, 
            16, 1]]) "Input routes are supposed to be unchanged, second"
        @assert isequal(broken_routes[3], evrp_data.nodes[[1, 18, 14, 4, 
            1]]) "Input routes are supposed to be unchanged, third"
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 5, 8, 
            1]]) "Input routes are supposed to be unchanged, fourth"
    end
end


module TestGreedyInsertPartial
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..ParsingFunctions

    using ..EVRPSetupFunctions
    using ..ALNSSetupFunctions
    using ..InsertOperators
    using ..SolutionUtilities
    using ..InsertUtilities

    using Suppressor

    function test_greedy_insert_feasible_partial()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_greedy_insert_with_non_customer_in_customer_list_partial() 
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 1, 8]]
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            InsertOperators.greedy_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        
        @assert contains(output, string("Your list of customers to insert",
            " contains at least one depot. It is being ignored.")) string(
            "There is no warning when trying to insert a depot or charging ",
            "station in insert_customers_greedy!")
    end

    function test_greedy_insert_empty_routes_no_charging_partial()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[16, 8]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert, 
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 8, 16, 1]]) "First route incorrect"
        @assert isequal(new_solution.routes[2], evrp_data.nodes[[]]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], evrp_data.nodes[[]]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], evrp_data.nodes[[]]) "Fourth route incorrect"
    end

    function test_greedy_insert_empty_routes_with_charging_partial()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/GreedyInsertEmptyWithCSSingleVehicle.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[2, 3, 4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 3, 5, 4, 6, 2, 1]]) "Route incorrect"
    end

    function test_greedy_insert_infeasible_partial()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(file_name)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [evrp_data.nodes[[1, 2, 3, 1]]]        
        customers_to_insert = evrp_data.nodes[[4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            global sol = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        @assert isnothing(sol) "This problem is not supposed to be feasible"

    end

    function test_greedy_insert_cs_insert_needed_partial()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 1]],
            ]
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 1]],
            ]
        
        removed_customers = [evrp_data.nodes[7]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, removed_customers,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_greedy_insert_with_battery_infeasible_route_input_partial()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BasicExampleLessBattery.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = false)
        
        new_solution = InsertOperators.greedy_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) string(
            "First route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[2], routes_full[2]) string(
            "Second route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[3], routes_full[3]) string(
            "Third route incorrect, customer incorrectly inserted")
        @assert isequal(new_solution.routes[4], routes_full[4]) string(
            "Fourth route incorrect, cs incorrectly inserted")
    end

    function test_greedy_insert_infeasible_input_unchanged_partial()
        data_file = "Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_partial(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11, 19]]

        broken_solution = SolutionUtilities.create_solution_from_routes(
            broken_routes, evrp_data, evrp_settings)

        output = @capture_out begin
            global new_solution = InsertOperators.greedy_insert(broken_solution, 
                customers_to_insert, evrp_data, evrp_settings, alns_settings)
        end

        @assert isnothing(new_solution)
        @assert isequal(broken_routes[1], evrp_data.nodes[[1, 10, 15, 9, 
            1]]) "Input routes are supposed to be unchanged, first"
        @assert isequal(broken_routes[2], evrp_data.nodes[[1, 2, 17, 12, 6, 
            16, 1]]) "Input routes are supposed to be unchanged, second"
        @assert isequal(broken_routes[3], evrp_data.nodes[[1, 18, 14, 4, 
            1]]) "Input routes are supposed to be unchanged, third"
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 5, 8, 
            1]]) "Input routes are supposed to be unchanged, fourth"
    end
end



module TestRandomInsert
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..ParsingFunctions

    using ..EVRPSetupFunctions
    using ..ALNSSetupFunctions
    using ..InsertOperators
    using ..SolutionUtilities
    using ..InsertUtilities

    using Suppressor

    function test_random_insert_feasible()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 12)
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[8, 10, 16, 18]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.random_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_random_insert_with_non_customer_in_customer_list() 
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 1, 8]]
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            InsertOperators.random_insert(broken_solution, customers_to_insert, 
                evrp_data, evrp_settings, alns_settings)
        end
        
        @assert contains(output, string("Your list of customers to insert",
            " contains at least one depot. It is being ignored.")) string(
            "There is no warning when trying to insert a depot or charging ",
            "station.")
    end

    function test_random_insert_empty_routes_with_charging()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 5)
        
        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles] 
        customers_to_insert = evrp_data.nodes[[16, 8, 15, 12, 18]]
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.random_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 18, 4, 12, 6, 16, 1]]) "First route incorrect"
        @assert isequal(new_solution.routes[2], evrp_data.nodes[[1, 15, 4, 8, 1]]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], evrp_data.nodes[[]]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], evrp_data.nodes[[]]) "Fourth route incorrect"
    end

    function test_random_insert_empty_routes_no_charging()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 2)

        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[10, 15, 9, 16]] 

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.random_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 10, 15, 9, 16, 1]]) "Route incorrect"
    end

    function test_random_insert_infeasible()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [evrp_data.nodes[[1, 2, 3, 1]]]        
        customers_to_insert = evrp_data.nodes[[4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            global sol = InsertOperators.random_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        @assert isnothing(sol) "This problem is not supposed to be feasible"

    end

    function test_random_insert_cs_insert_needed()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 1]],
            ]
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 1]],
            ]
        
        removed_customers = [evrp_data.nodes[7]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.random_insert(broken_solution, removed_customers,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_random_insert_with_battery_infeasible_route_input()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BasicExampleLessBattery.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = false)
        
        new_solution = InsertOperators.random_insert(broken_solution, customers_to_insert, 
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) string(
            "First route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[2], routes_full[2]) string(
            "Second route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[3], routes_full[3]) string(
            "Third route incorrect, customer incorrectly inserted")
        @assert isequal(new_solution.routes[4], routes_full[4]) string(
            "Fourth route incorrect, cs incorrectly inserted")
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 8, 
            1]]) "Input should be unchanged, specifically route where cs has been removed"
    end

    function test_random_insert_infeasible_input_unchanged()
        data_file = "Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11, 19]]

        broken_solution = SolutionUtilities.create_solution_from_routes(
            broken_routes, evrp_data, evrp_settings)

        output = @capture_out begin
            global new_solution = InsertOperators.random_insert(broken_solution, 
                customers_to_insert, evrp_data, evrp_settings, alns_settings)
        end

        @assert isnothing(new_solution)
        @assert isequal(broken_routes[1], evrp_data.nodes[[1, 10, 15, 9, 
            1]]) "Input routes are supposed to be unchanged, first"
        @assert isequal(broken_routes[2], evrp_data.nodes[[1, 2, 17, 12, 6, 
            16, 1]]) "Input routes are supposed to be unchanged, second"
        @assert isequal(broken_routes[3], evrp_data.nodes[[1, 18, 14, 4, 
            1]]) "Input routes are supposed to be unchanged, third"
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 5, 8, 
            1]]) "Input routes are supposed to be unchanged, fourth"
    end
end



module TestHighestPositionKRegretInsertFull
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..ParsingFunctions

    using ..EVRPSetupFunctions
    using ..ALNSSetupFunctions
    using ..InsertOperators
    using ..SolutionUtilities
    using ..InsertUtilities

    using Suppressor


    
    function test_highest_position_k_regret_feasible()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end


    function test_highest_position_k_regret_empty_routes_no_charging()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        routes = [NodeTypes.Node[] for _ in 1:4]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        expected_route_1 = evrp_data.nodes[[1, 8, 16, 1]]
        expected_route_2 = evrp_data.nodes[[1, 16, 8, 1]]

        num_matches_1 = count(route -> isequal(route, expected_route_1), new_solution.routes)
        num_matches_2 = count(route -> isequal(route, expected_route_2), new_solution.routes)

        all_others_empty = count(route -> isempty(route), new_solution.routes)
        
        @assert num_matches_1 + num_matches_2 == 1 "Expected route not found exactly once"
        @assert all_others_empty == 3 "One or more unexpected non-empty routes"
    end

    function test_highest_position_k_regret_empty_routes_with_charging()
        data_file = "Testing/DataForTesting/InsertOperators/KRegret/KRegretInsertEmptyWithCSSingleVehicle.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[2, 3, 4]]
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], evrp_data.nodes[[1, 2, 4, 1]]) "Route incorrect"
    end

    function test_highest_position_k_regret_infeasible()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [evrp_data.nodes[[1, 2, 3, 1]]]        
        customers_to_insert = evrp_data.nodes[[4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            global sol = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        @assert isnothing(sol) "This problem is not supposed to be feasible"

    end

    function test_highest_position_k_regret_cs_insert_needed()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 1]],
            ]
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 1]],
            ]
        
        removed_customers = [evrp_data.nodes[7]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, removed_customers,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_highest_position_k_regret_with_battery_infeasible_route_input()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BasicExampleLessBattery.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = false)
        
        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert, 
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) string(
            "First route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[2], routes_full[2]) string(
            "Second route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[3], routes_full[3]) string(
            "Third route incorrect, customer incorrectly inserted")
        @assert isequal(new_solution.routes[4], routes_full[4]) string(
            "Fourth route incorrect, cs incorrectly inserted")
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 8, 
            1]]) "Input should be unchanged, specifically route where cs has been removed"
    end

    function test_highest_position_k_regret_infeasible_input_unchanged()
        data_file = "Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11, 19]]

        broken_solution = SolutionUtilities.create_solution_from_routes(
            broken_routes, evrp_data, evrp_settings)

        output = @capture_out begin
            global new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, 
                customers_to_insert, evrp_data, evrp_settings, alns_settings)
        end

        @assert isnothing(new_solution)
        @assert isequal(broken_routes[1], evrp_data.nodes[[1, 10, 15, 9, 
            1]]) "Input routes are supposed to be unchanged, first"
        @assert isequal(broken_routes[2], evrp_data.nodes[[1, 2, 17, 12, 6, 
            16, 1]]) "Input routes are supposed to be unchanged, second"
        @assert isequal(broken_routes[3], evrp_data.nodes[[1, 18, 14, 4, 
            1]]) "Input routes are supposed to be unchanged, third"
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 5, 8, 
            1]]) "Input routes are supposed to be unchanged, fourth"
    end

    function test_highest_position_k_regret_feasable_with_k_4()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_position_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

end


module TestHighestRouteKRegretInsertFull
    using ..NodeTypes
    using ..SettingTypes
    using ..SolutionTypes
    using ..DataStruct
    using ..ParsingFunctions

    using ..EVRPSetupFunctions
    using ..ALNSSetupFunctions
    using ..InsertOperators
    using ..SolutionUtilities
    using ..InsertUtilities

    using Suppressor


    
    function test_highest_route_k_regret_feasible()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end


    function test_highest_route_k_regret_empty_routes_no_charging()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        routes = [NodeTypes.Node[] for _ in 1:4]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        expected_route = evrp_data.nodes[[1, 8, 16, 1]]

        num_matches = count(route -> isequal(route, expected_route), new_solution.routes)

        all_others_empty = all(route -> isempty(route) || isequal(route, expected_route), new_solution.routes)
        
        @assert num_matches == 1 "Expected route not found exactly once"
        @assert all_others_empty "One or more unexpected non-empty routes"
    end

    function test_highest_route_k_regret_empty_routes_with_charging()
        data_file = "Testing/DataForTesting/InsertOperators/KRegret/KRegretInsertEmptyWithCSSingleVehicle.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [NodeTypes.Node[] for _ in 1:evrp_data.n_vehicles]
        customers_to_insert = evrp_data.nodes[[2, 3, 4]]
        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)

        expected_route = evrp_data.nodes[[1, 2, 4, 1]]

        num_matches = count(route -> isequal(route, expected_route), new_solution.routes)

        all_others_empty = all(route -> isempty(route) || isequal(route, expected_route), new_solution.routes)
        
        @assert num_matches == 1 "Expected route not found exactly once"
        @assert all_others_empty "One or more unexpected non-empty routes"
    end

    function test_highest_route_k_regret_infeasible()
        file_name = "./Testing/DataForTesting/InsertOperators/Greedy/InfeasibleTimeWindow.txt" 
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(file_name)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()

        routes = [evrp_data.nodes[[1, 2, 3, 1]]]        
        customers_to_insert = evrp_data.nodes[[4]]

        broken_solution = SolutionUtilities.create_solution_from_routes(routes, 
            evrp_data, evrp_settings)

        output = @capture_out begin
            global sol = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert,
                evrp_data, evrp_settings, alns_settings)
        end
        @assert isnothing(sol) "This problem is not supposed to be feasible"

    end

    function test_highest_route_k_regret_cs_insert_needed()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 1]],
            ]
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 11, 1]], 
            evrp_data.nodes[[1, 13, 1]],
            ]
        
        removed_customers = [evrp_data.nodes[7]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings)
        
        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, removed_customers,
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end

    function test_highest_route_k_regret_with_battery_infeasible_route_input()
        data_file = "Testing/DataForTesting/InsertOperators/Greedy/BasicExampleLessBattery.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11]]

        broken_solution = SolutionUtilities.create_solution_from_routes(broken_routes, 
            evrp_data, evrp_settings, throw_infeasible_battery_errors = false)
        
        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert, 
            evrp_data, evrp_settings, alns_settings)

        @assert isequal(new_solution.routes[1], routes_full[1]) string(
            "First route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[2], routes_full[2]) string(
            "Second route incorrect, supposed to be unchanged")
        @assert isequal(new_solution.routes[3], routes_full[3]) string(
            "Third route incorrect, customer incorrectly inserted")
        @assert isequal(new_solution.routes[4], routes_full[4]) string(
            "Fourth route incorrect, cs incorrectly inserted")
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 8, 
            1]]) "Input should be unchanged, specifically route where cs has been removed"
    end

    function test_highest_route_k_regret_infeasible_input_unchanged()
        data_file = "Testing/DataForTesting/InsertOperators/BasicInfeasibleCustomerInsert.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        
        broken_routes = [evrp_data.nodes[[1, 10, 15, 9, 1]], 
            evrp_data.nodes[[1, 2, 17, 12, 6, 16, 1]], 
            evrp_data.nodes[[1, 18, 14, 4, 1]], 
            evrp_data.nodes[[1, 13, 7, 5, 8, 1]],
            ]
        customers_to_insert = evrp_data.nodes[[11, 19]]

        broken_solution = SolutionUtilities.create_solution_from_routes(
            broken_routes, evrp_data, evrp_settings)

        output = @capture_out begin
            global new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, 
                customers_to_insert, evrp_data, evrp_settings, alns_settings)
        end

        @assert isnothing(new_solution)
        @assert isequal(broken_routes[1], evrp_data.nodes[[1, 10, 15, 9, 
            1]]) "Input routes are supposed to be unchanged, first"
        @assert isequal(broken_routes[2], evrp_data.nodes[[1, 2, 17, 12, 6, 
            16, 1]]) "Input routes are supposed to be unchanged, second"
        @assert isequal(broken_routes[3], evrp_data.nodes[[1, 18, 14, 4, 
            1]]) "Input routes are supposed to be unchanged, third"
        @assert isequal(broken_routes[4], evrp_data.nodes[[1, 13, 7, 5, 8, 
            1]]) "Input routes are supposed to be unchanged, fourth"
    end

    function test_highest_route_k_regret_feasable_with_k_4()
        data_file = "Testing/DataForTesting/BasicExample.txt"
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(data_file)
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        routes_full = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 8, 1]], 
            evrp_data.nodes[[1, 17, 2, 16, 1]]
            ]
        routes_broken = [evrp_data.nodes[[1, 10, 15, 3, 9, 1]], 
            evrp_data.nodes[[1, 13, 5, 7, 6, 12, 1]], 
            evrp_data.nodes[[1, 18, 14, 11, 4, 1]], 
            evrp_data.nodes[[1, 17, 2, 1]]
            ]
        customers_to_insert = evrp_data.nodes[[16, 8]]
    
        
        broken_solution = SolutionUtilities.create_solution_from_routes(routes_broken, 
            evrp_data, evrp_settings)

        new_solution = InsertOperators.highest_route_k_regret_insert(broken_solution, customers_to_insert,
            evrp_data, evrp_settings, alns_settings)
        
        @assert isequal(new_solution.routes[1], routes_full[1]) "First route incorrect"
        @assert isequal(new_solution.routes[2], routes_full[2]) "Second route incorrect"
        @assert isequal(new_solution.routes[3], routes_full[3]) "Third route incorrect"
        @assert isequal(new_solution.routes[4], routes_full[4]) "Fourth route incorrect"
    end
end