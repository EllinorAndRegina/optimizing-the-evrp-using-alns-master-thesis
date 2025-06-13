
include("Types.jl")

# Include function files
include("Functions/DataParsing.jl")
include("Functions/EVRPFunctions.jl")
include("Functions/Utilities.jl")
include("Functions/ALNSFunctions.jl")
include("Functions/RemoveOperators.jl")
include("Functions/InsertOperators.jl")
include("Functions/InitialSolution.jl")
include("Functions/ALNS.jl")

include("Plotting/PlotFunctions.jl")

using .DataStruct
using .SettingTypes
using .ProblemSpecifierTypes

using .BatteryCalculationFunctions
using .EnergyConsumptionFunctions
using .ObjectiveFunctions
using .RechargingFunctions

using .InitialSolution
using .AcceptanceCriteria
using .TerminationCriteria
using .SelectionFunctions
using .RemoveOperators
using .InsertOperators

using .RunALNS

using Random
using Plots

"""
Setup and run ALNS.

# Input arguments
- `file_path::String`: the path to the data file.
- `seed::Int`: the seed for the random generator.

- `problem_specifier::ProblemSpecifierTypes.EVRPType`: specifies which one of 
    the implemented EVRP formulations to solve
- `objective::ProblemSpecifierTypes.ObjectiveType`: specifies which of the 
    implemented objective functions should be used

- `acceptance_func::Function`: the function that decides if a new solution 
    should be accepted or not. The input arguments to the function are the new 
    solution, the last accepted solution, the best solution found so far, the 
    temperature and the ALNSSettings object. The function returns a Bool.
- `termination_func::Function`: the function that decides if the ALNS algorithm 
    should terminate or not. The input arguments to the function are the current 
    iteration number and the ALNSSettings object. The function returns a Bool.
- `selection_func::Function`: the function that chooses remove/insert operator. 
    The input arguments to the function are the remove/insert operators' 
    probabilities of being chosen and the ALNSSettings object. The function 
    returns the item index.

- `remove_operators::Vector{Function}`: the remove operators.
- `insert_operators::Vector{Function}`: the insert operators.

- `max_iterations::Int`: the maximum number of iterations to run the ALNS 
    algorithm. 
- `max_time::Int`: the maximum number of seconds the algorithm should run 
    (does not include data parsing, initial solution or visualizing the 
    results).

- `n_iterations_until_update::Int`: the number of iterations between each 
    update of the weights.

- `cooling_rate::Float64`: the cooling rate of the temperature used for 
    simulated annealing.
- `initial_temperature_params::Tuple{Float64, Float64}`: parameters (p, w) 
    used for deciding the initial temperature in the simulated annealing. 
    The start temperature is decided such that the probability of accepting 
    a solution that is 100*w % worse than the initial solution is p.

- `remove_proportion::Float64`: the proportion of nodes to remove in each 
    iteration.
- `score_increments::Tuple{Int, Int, Int}`: the score increments of the 
    remove/insert operators. The first increment is for operators that 
    generate a solution better than the best solution found so far. The 
    second score is used when the new solution is better than the last 
    accepted solution, but not better than the best one so far. The last 
    score is used when the solution is accepted even though it is worse 
    than the last accepted solution.
- `weight_update_reaction_factor::Float64`: the parameter deciding how 
    drastically the weights react when updated. If the parameter is close to 0 
    then the scores of the operators are not used when updating the weights. If 
    it is 1 then the weight update is decided by the operator score.
- `n_tries_to_insert::Int`: the number of tries to insert a customer in the 
    random insert heuristic.
- `k_regret::Int`: the parameter in the k regret insert heuristics that decides how 
    many insertions to look at when calculating the maximum regret.
- `k_cs_insert::Int`: the number of steps back to check for charging stations in 
    the charging station k insert operator.
- `cs_insert_score_parameters::Tuple{Float64, Float64, Float64}`: weights used 
    when calculating the score in the charging station k insert operator. The 
    first value corresponds to the ranking, the second to the distance and the 
    third to the feasibility of the insertion.

"""
function main(
        file_path::String;

        seed::Int = 13,
        problem_specifier::ProblemSpecifierTypes.EVRPType = 
            ProblemSpecifierTypes.full_charging,
        objective::ProblemSpecifierTypes.ObjectiveType = 
            ProblemSpecifierTypes.distance_objective,

        acceptance_func::Function = AcceptanceCriteria.greedy,
        termination_func::Function = TerminationCriteria.time_termination,
        selection_func::Function = SelectionFunctions.roulette_wheel_selection,
        
        remove_operators::Vector{Function} = 
            Function[RemoveOperators.random_removal, 
            RemoveOperators.random_routes_removal,
            RemoveOperators.worst_cost_routes_removal,
            RemoveOperators.shortest_routes_removal,
            RemoveOperators.worst_cost_removal,
            RemoveOperators.shaw_removal_distance],
        insert_operators::Vector{Function} = 
            Function[InsertOperators.greedy_insert, 
                InsertOperators.random_insert, 
                InsertOperators.highest_position_k_regret_insert, 
                InsertOperators.highest_route_k_regret_insert],

        max_iterations::Int = 1000,
        max_time::Int = 60,
        n_iterations_until_update::Int = 100,
        cooling_rate::Float64 = 0.99975,
        initial_temperature_params::Tuple{Float64, Float64} = (0.5, 0.05),
        remove_proportion::Float64 = 0.25,
        score_increments::Tuple{Int, Int, Int} = (19, 13, 13), 
        weight_update_reaction_factor::Float64 = 0.3,
        n_tries_to_insert::Int = 5,
        k_regret::Int = 3,
        k_cs_insert::Int = 3,
        cs_insert_score_parameters::Tuple{Float64, Float64, Float64} = 
            (0.6, 0.6, 0.6),
        load_dependent_energy_params::Tuple{Float64, Float64} = 
            (1.03809 * 0.072338, 0.0012248 * 0.41667),
        truck_weight::Float64 = 1579.0, 

        gurobi_results::Union{ResultsTypes.GurobiResults, Nothing} = nothing,
        reference_value::Float64 = -1.0,

        plotting::Bool = true,
        printing::Bool = true,
        save_weights::Bool = true,
        benchmark_iterations::Int = 1,
        initial_solution::Union{SolutionTypes.EVRPSolution, Nothing} = nothing
    )
    
    # Handle input arguments
    if max_iterations < 0
        throw(DomainError(max_iterations, string("The number of iterations ",
            "must be a positive number.")))
    elseif max_time < 0
        throw(DomainError(max_time, string("The time limit ",
            "must be a positive number.")))
    elseif n_iterations_until_update <= 0
        throw(DomainError(n_iterations_until_update, string("The smallest ",
            "possible value of the number of iterations is 1, which means ",
            "to update in each iteration.")))
    elseif n_iterations_until_update >= max_iterations
        throw(DomainError(n_iterations_until_update, string("It is not ALNS ",
            "if the weights are never updated. Make sure that the ",
            "n_iterations_until_update < max_iterations.")))
    elseif cooling_rate >= 1 || cooling_rate <= 0
        throw(DomainError(cooling_rate, string("The cooling rate should be ",
            "between 0 and 1, very close to 1 preferably.")))
    elseif any(x -> x >= 1, initial_temperature_params) || 
            any(x -> x <= 0, initial_temperature_params)
        throw(DomainError(initial_temperature_params, string("The parameters ",
            "for initializing the temperature are not within their allowed ",
            "range (0, 1).")))
    elseif remove_proportion > 1 || remove_proportion <= 0
        throw(DomainError(remove_proportion, string("The proportion should be ",
            "between 0 and 1, but not 0 since we need to remove nodes and ",
            "insert them again for it to be ALNS.")))
    elseif any(x -> x < 0, score_increments)
        throw(DomainError(score_increments, string("The score increments work ",
            "by positive reinforcement so make sure all your score increments ",
            "are positive")))
    elseif weight_update_reaction_factor > 1 || 
            weight_update_reaction_factor < 0
        throw(DomainError(weight_update_reaction_factor, 
            "Should be between 0 and 1"))
    elseif n_tries_to_insert <= 0
        throw(DomainError(n_tries_to_insert, string("The number of insertion ",
            "tries should be a positive number larger than 0")))
    elseif k_regret < 2
        throw(DomainError(k_regret, "k_regret should be >= 2"))
    elseif k_cs_insert < 1
        throw(DomainError(k_cs_insert, string("The number of steps ",
            "back to search for cs insertions should be a positive ",
            "number larger than 0")))
    elseif truck_weight <= 0.0
        throw(DomainError(truck_weight, string("The weight of the ",
            "truck is a positive number")))
    end

    # Parse data
    evrp_data = nothing
    if problem_specifier == ProblemSpecifierTypes.load_dependent
        evrp_data = DataStruct.DataEVRP(file_path, 
            ParsingFunctions.parsing_EVRPTW_Schneider, 
            load_dependent_params = load_dependent_energy_params,
            truck_weight = truck_weight)
    else
        evrp_data = DataStruct.DataEVRP(file_path, 
            ParsingFunctions.parsing_EVRPTW_Schneider)
    end
    
    if evrp_data.n_customers == 0 || evrp_data.n_charging_stations == 0
        throw(DomainError(evrp_data, 
            "The data does not contain any customers or charging stations"))
    end

    # Setup EVRP
    battery_func = nothing
    energy_consump_func = nothing 
    if problem_specifier == ProblemSpecifierTypes.full_charging
        battery_func = BatteryCalculationFunctions.
            calculate_battery_levels_for_route_full_charging
        energy_consump_func = EnergyConsumptionFunctions.
            distance_dependent_energy_consumption

    elseif problem_specifier == ProblemSpecifierTypes.partial_charging
        battery_func = BatteryCalculationFunctions.
            calculate_battery_levels_for_route_partial_charging
        energy_consump_func = EnergyConsumptionFunctions.
            distance_dependent_energy_consumption

    elseif problem_specifier == ProblemSpecifierTypes.load_dependent
        battery_func = BatteryCalculationFunctions.
            calculate_battery_levels_for_route_full_charging
        energy_consump_func = EnergyConsumptionFunctions.
            load_dependent_energy_consumption
    end

    obj_func = nothing
    obj_func_per_route = nothing
    if objective == ProblemSpecifierTypes.distance_objective
        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
    else
        throw("Other objectives not implemented yet")
    end

    recharging_func = RechargingFunctions.calculate_recharging_time_linear
    
    evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
        energy_consump_func, recharging_func, battery_func)

    # Initial solution
    if isnothing(initial_solution)
        initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
            evrp_settings, cs_insert_score_parameters, k_cs_insert)

        if isnothing(initial_solution)
            throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
        end
    end
    obj_func(initial_solution, evrp_data)

    # Setup ALNS, here T0 is set such that a solution that is w worse than the 
    # initial solution is randomly accepted with a probability of p in the 
    # simulated annealing. Example: for p = 0.5 and w = 0.05 we accept a 
    # solution that is 5% worse with a probability of 50%.
    initial_weights_remove = ones(length(remove_operators))
    initial_weights_insert = ones(length(insert_operators))
    rng = Xoshiro(seed)

    p, w = initial_temperature_params
    T0 = - log(p) / (w * initial_solution.objective_value)

    alns_settings = SettingTypes.ALNSSettings(acceptance_func, termination_func,
        selection_func, remove_operators, insert_operators, 
        initial_weights_remove, initial_weights_insert, rng, 
        n_iterations_until_update, cooling_rate, T0, max_iterations,
        max_time, remove_proportion, score_increments,
        weight_update_reaction_factor, n_tries_to_insert, k_regret, k_cs_insert, 
        cs_insert_score_parameters)

    all_results = ResultsTypes.Result[]
    for i in 1:benchmark_iterations
        # Run ALNS
        results = RunALNS.run_ALNS(initial_solution, alns_settings, 
            evrp_data, evrp_settings, save_weights = save_weights)

        solutions = copy(results.solutions_for_plotting)
        pushfirst!(solutions, initial_solution)
        for solution in solutions
            status = InitialSolutionUtilities.check_all_customers_inserted(
                solution.routes, evrp_data)
            if !status
                println("Not all customers are inserted in the solution")
            end
        end

        push!(all_results, results)

        # Plot the results
        if plotting
            if save_weights
                PlotFunctions.plot_operator_weights(results.n_iterations, 
                    results.weights_insert, n_iterations_until_update)
                PlotFunctions.plot_operator_weights(results.n_iterations, 
                    results.weights_remove, n_iterations_until_update)
            end
            PlotFunctions.plot_objectives_iteration(
                results.objective_per_iteration, reference_value)
            PlotFunctions.plot_objectives_time(results.objective_per_iteration, 
                results.time_per_iteration, reference_value = reference_value, 
                gurobi_results = gurobi_results)
            PlotFunctions.plot_solution_list(solutions, [evrp_data, evrp_data], 
                ["Initial", "ALNS"])
        end

        if printing
            # Print results
            best_objective = results.objective_per_iteration[end]
            println("\nBest objective value ALNS: $(best_objective)")
            i_best = findfirst(x -> x == best_objective, results.objective_per_iteration)
            println("Found in iteration $(i_best - 1) at time $(results.time_per_iteration[i_best]) s")
        end
    end

    if length(all_results) == 1
        return all_results[1]
    end

    return all_results
end