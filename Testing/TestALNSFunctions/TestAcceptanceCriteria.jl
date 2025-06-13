module TestGreedy
    using ..AcceptanceCriteria
    using ..SettingTypes
    using ..ALNSSetupFunctions
    using ..EVRPSetupFunctions
    using ..SolutionTypes

    function test_greedy_accepting()
        filename = "Testing/DataForTesting/BasicExample.txt"
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(filename)

        times_of_arrival = [Float64[] for _ in 1:4]
        battery_arrival = [Float64[] for _ in 1:4]

        routes_S_old = [evrp_data.nodes[[1, 10, 15, 1]], 
            evrp_data.nodes[[1, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]
        
        routes_S_best = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        routes_S = [evrp_data.nodes[[1, 10, 15, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        S = SolutionTypes.EVRPSolution(routes_S, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S, evrp_data)

        S_old = SolutionTypes.EVRPSolution(routes_S_old, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_old, evrp_data)

        S_best = SolutionTypes.EVRPSolution(routes_S_best, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_best, evrp_data)

        status = AcceptanceCriteria.greedy(S, S_old, S_best, 0.0, alns_settings)
        
        @assert status "Acceptance criteria greedy - test accept"
    end

    function test_greedy_rejecting()
        filename = "Testing/DataForTesting/BasicExample.txt"
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(filename)

        times_of_arrival = [Float64[] for _ in 1:4]
        battery_arrival = [Float64[] for _ in 1:4]

        routes_S = [evrp_data.nodes[[1, 10, 15, 1]], 
            evrp_data.nodes[[1, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]
        
        routes_S_old = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        routes_S_best = [evrp_data.nodes[[1, 10, 15, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        S = SolutionTypes.EVRPSolution(routes_S, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S, evrp_data)

        S_old = SolutionTypes.EVRPSolution(routes_S_old, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_old, evrp_data)

        S_best = SolutionTypes.EVRPSolution(routes_S_best, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_best, evrp_data)
        
        status =  AcceptanceCriteria.greedy(S, S_old, S_best, 0.0, alns_settings)
        @assert !status "Acceptance criteria greedy - test reject"
    end
end

module TestMetropolis
    using Random
    using ..ALNSSetupFunctions
    using ..EVRPSetupFunctions
    using ..AcceptanceCriteria
    using ..ALNSSetupFunctions
    using ..SolutionTypes

    function test_metropolis_with_greedy_fulfilled()
        filename = "Testing/DataForTesting/BasicExample.txt"
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard()
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(filename)

        times_of_arrival = [Float64[] for _ in 1:4]
        battery_arrival = [Float64[] for _ in 1:4]

        routes_S_old = [evrp_data.nodes[[1, 10, 15, 1]], 
            evrp_data.nodes[[1, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]
        
        routes_S_best = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        routes_S = [evrp_data.nodes[[1, 10, 15, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        S = SolutionTypes.EVRPSolution(routes_S, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S, evrp_data)

        S_old = SolutionTypes.EVRPSolution(routes_S_old, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_old, evrp_data)

        S_best = SolutionTypes.EVRPSolution(routes_S_best, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_best, evrp_data)

        status = AcceptanceCriteria.metropolis(S, S_old, S_best, 0.0, alns_settings)
        @assert status "Acceptance criteria metropolis - greedy accept"
        return (status, true)
    end

    function test_metropolis_random_pass()
        filename = "Testing/DataForTesting/BasicExample.txt"
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(filename)

        times_of_arrival = [Float64[] for _ in 1:4]
        battery_arrival = [Float64[] for _ in 1:4]

        routes_S = [evrp_data.nodes[[1, 10, 15, 1]], 
            evrp_data.nodes[[1, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]
        
        routes_S_old = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        routes_S_best = [evrp_data.nodes[[1, 10, 15, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        S = SolutionTypes.EVRPSolution(routes_S, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S, evrp_data)

        S_old = SolutionTypes.EVRPSolution(routes_S_old, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_old, evrp_data)

        S_best = SolutionTypes.EVRPSolution(routes_S_best, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_best, evrp_data)

        T = 8.0
        # The seed given to alns_settings gives rand(rng, Float32) = 0.15142488f0
        status = AcceptanceCriteria.metropolis(S, S_old, S_best, T, alns_settings)
        @assert status "Acceptance criteria metropolis - random accept"
        return (status, true)
    end

    function test_metropolis_random_non_pass()
        filename = "Testing/DataForTesting/BasicExample.txt"
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        evrp_data, evrp_settings = EVRPSetupFunctions.setup_evrp_standard_full(filename)

        times_of_arrival = [Float64[] for _ in 1:4]
        battery_arrival = [Float64[] for _ in 1:4]

        routes_S = [evrp_data.nodes[[1, 10, 15, 1]], 
            evrp_data.nodes[[1, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]
        
        routes_S_old = [evrp_data.nodes[[1, 10, 15, 3, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        routes_S_best = [evrp_data.nodes[[1, 10, 15, 9, 16, 1]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]], 
            evrp_data.nodes[[]],
            ]

        S = SolutionTypes.EVRPSolution(routes_S, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S, evrp_data)

        S_old = SolutionTypes.EVRPSolution(routes_S_old, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_old, evrp_data)

        S_best = SolutionTypes.EVRPSolution(routes_S_best, times_of_arrival, battery_arrival, 
            battery_arrival, nothing, true)
        evrp_settings.objective_func!(S_best, evrp_data)

        T = 6.0
        # The seed given to alns_settings gives rand(rng, Float32) = 0.15142488f0
        status = AcceptanceCriteria.metropolis(S, S_old, S_best, T, alns_settings)
        @assert !status "Acceptance criteria metropolis - random reject"
        return (status, false)
    end
end