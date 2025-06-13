module RunALNS
    using ..SolutionTypes
    using ..SettingTypes
    using ..DataStruct
    using ..ResultsTypes

    using Random

    """
    Run the Adaptive Large Neighbourhood Search algorithm on a given problem 
    starting with a given initial solution.

    """
    function run_ALNS(
            initial_solution::SolutionTypes.EVRPSolution, 
            alns_settings::SettingTypes.ALNSSettings, 
            evrp_data::DataStruct.DataEVRP, 
            evrp_settings::SettingTypes.EVRPSettings;
            iterations_to_save_solution::Vector{Int} = Int[],
            save_weights::Bool = true
        )::ResultsTypes.Result

        S_best = initial_solution
        S_old = initial_solution
        best_value = initial_solution.objective_value

        # Prepare results
        objective_values = Float64[initial_solution.objective_value]
        saved_solutions = SolutionTypes.EVRPSolution[]
        times = Float64[0.0]

        weights_remove_results = nothing
        weights_insert_results = nothing

        if save_weights
            weights_remove_results = [[alns_settings.initial_weights_remove[i]] 
                for i in 1:length(alns_settings.remove_operators)]
            weights_insert_results = [[alns_settings.initial_weights_insert[i]] 
                for i in 1:length(alns_settings.insert_operators)]
        end
        
        # Initialize variables
        iteration_count = 1
        T = alns_settings.T0
        
        weights_remove = copy(alns_settings.initial_weights_remove)
        weights_insert = copy(alns_settings.initial_weights_insert)
        probabilities_remove = calculate_probabilities(weights_remove)
        probabilities_insert = calculate_probabilities(weights_insert)

        remove_scores = zeros(Int, length(alns_settings.remove_operators))
        insert_scores = zeros(Int, length(alns_settings.insert_operators))
        remove_used_count = zeros(Int, length(alns_settings.remove_operators))
        insert_used_count = zeros(Int, length(alns_settings.insert_operators))

        start_time = time()
        stop_time = start_time + alns_settings.max_time

        while !alns_settings.termination_func(iteration_count, alns_settings)
            # Choose operators 
            remove_i = alns_settings.selection_func(probabilities_remove, 
                alns_settings)
            insert_i = alns_settings.selection_func(probabilities_insert, 
                alns_settings)

            remove_operator = alns_settings.remove_operators[remove_i]
            insert_operator = alns_settings.insert_operators[insert_i]
            remove_used_count[remove_i] += 1
            insert_used_count[insert_i] += 1
            
            # Compute new solution
            S_destroyed, removed_customers_list = remove_operator(S_old, 
                evrp_data, evrp_settings, alns_settings)
            S_new = insert_operator(S_destroyed, removed_customers_list, 
                evrp_data, evrp_settings, alns_settings)
            
            if !isnothing(S_new)
                evrp_settings.objective_func!(S_new, evrp_data)
            
                # Compare new solution with previous
                if S_new.objective_value < best_value
                    S_old = S_new
                    S_best = S_new
                    best_value = S_new.objective_value
                    remove_scores[remove_i] += alns_settings.score_increments[1]
                    insert_scores[insert_i] += alns_settings.score_increments[1]

                elseif alns_settings.acceptance_func(S_new, S_old, S_best, T, 
                        alns_settings)
                    S_old = S_new
                    remove_scores[remove_i] += alns_settings.score_increments[2]
                    insert_scores[insert_i] += alns_settings.score_increments[2]

                elseif rand(alns_settings.rng, Float32) < exp(-
                        (S_new.objective_value - S_old.objective_value)/T) 
                    S_old = S_new
                    remove_scores[remove_i] += alns_settings.score_increments[3]
                    insert_scores[insert_i] += alns_settings.score_increments[3]
                end
            end

            push!(times, time() - start_time)

            # Update parameters
            if iteration_count % alns_settings.n_iterations_until_update == 0
                update_weights!(weights_remove, remove_scores, remove_used_count, 
                    alns_settings)
                update_weights!(weights_insert, insert_scores, insert_used_count, 
                    alns_settings)

                if save_weights
                    for ind in eachindex(weights_remove)
                        push!(weights_remove_results[ind], weights_remove[ind])
                    end

                    for ind in eachindex(weights_insert)
                        push!(weights_insert_results[ind], weights_insert[ind])
                    end
                end

                probabilities_remove = calculate_probabilities(weights_remove)
                probabilities_insert = calculate_probabilities(weights_insert)

                # Set scores and counts to 0
                remove_scores = zeros(Int, length(alns_settings.remove_operators))
                insert_scores = zeros(Int, length(alns_settings.insert_operators))
                remove_used_count = zeros(Int, length(alns_settings.
                    remove_operators))
                insert_used_count = zeros(Int, length(alns_settings.
                    insert_operators))
            end

            if iteration_count in iterations_to_save_solution
                push!(saved_solutions, S_best)
            end

            push!(objective_values, best_value)

            iteration_count += 1
            T = alns_settings.cooling_rate * T

            if time() > stop_time
                break
            end
        end

        if save_weights
            if (iteration_count - 1) % alns_settings.n_iterations_until_update != 0
                for ind in eachindex(weights_remove)
                    push!(weights_remove_results[ind], weights_remove[ind])
                end

                for ind in eachindex(weights_insert)
                    push!(weights_insert_results[ind], weights_insert[ind])
                end
            end
        end

        push!(saved_solutions, S_best) 
        return ResultsTypes.Result(
            iteration_count - 1,
            objective_values, 
            saved_solutions, 
            times,
            weights_remove_results,
            weights_insert_results)
    end


    """
    Calculate probabilities from weights.

    """
    function calculate_probabilities(
            w::Vector{Float64}
        )::Vector{Float64}

        return w./sum(w)
    end

    """
    Update the weights using operator scores.
    
    """
    function update_weights!(
            weights::Vector{Float64}, 
            scores::Vector{Int}, 
            counts::Vector{Int}, 
            alns_settings::SettingTypes.ALNSSettings
        )

        for i in 1:length(weights)
            weights[i] = weights[i] * 
                (1 - alns_settings.weight_update_reaction_factor) 
            if counts[i] > 0
                weights[i] += alns_settings.weight_update_reaction_factor * 
                    scores[i]/counts[i]
            end
        end
    end
end








