# This file contains interchangeable functions that can be set in the ALNSSettings object 

module SelectionFunctions
    using Random
    using ..SettingTypes

    """
    Simulate roulette wheel selection and return the index of the selected item.

    """
    function roulette_wheel_selection(
            probabilities::Vector{Float64}, 
            alns_settings::SettingTypes.ALNSSettings
        )::Int
        
        if length(probabilities) == 0
            throw(DomainError(probabilities, string("ERROR: The probabilities ",
                "given to the roulette wheel selection is an empty list")))
        elseif any(x -> x < 0, probabilities)
            throw(DomainError(probabilities, string("ERROR: At least one of ",
                "the operator probabilities given to the roulette wheel ",
                "selection is negative")))
        elseif sum(probabilities) < 0.99 || sum(probabilities) > 1.01
            throw(DomainError(probabilities, string("ERROR: The sum of the ",
                "operator probabilities given to the roulette wheel selection ",
                "does not add up to 1")))
        end
        
        cummulative_prob = 0
        r = rand(alns_settings.rng, Float32)
        for i in eachindex(probabilities)
            cummulative_prob += probabilities[i]
            if r < cummulative_prob
                return i
            end
        end
        throw(ErrorException(string("ERROR: No operator chosen in the roulette ",
            "wheel selection... reason unknown")))
    end
end

module AcceptanceCriteria
    using ..SolutionTypes
    using ..SettingTypes

    """
    Decide whether to accept or decline a new solution using the greedy policy.
    
    True is returned if it is accepted, otherwise false. 

    """
    function greedy(
            S_new::SolutionTypes.EVRPSolution, 
            S_old::SolutionTypes.EVRPSolution, 
            S_best::SolutionTypes.EVRPSolution, 
            T::Float64, 
            alns_settings::SettingTypes.ALNSSettings
        )::Bool

        if S_new.objective_value < S_old.objective_value
            return true
        end
        return false
    end

    """
    Decide whether to accept or decline a new solution using the metropolis 
    policy.
    
    True is returned if it is accepted, otherwise false. 

    """
    function metropolis(
            S::SolutionTypes.EVRPSolution, 
            S_old::SolutionTypes.EVRPSolution, 
            S_best::SolutionTypes.EVRPSolution, 
            T::Float64, 
            alns_settings::SettingTypes.ALNSSettings
        )::Bool

        if greedy(S, S_old, S_best, T, alns_settings)
            return true
        elseif rand(alns_settings.rng, Float32) < exp(-(S.objective_value - 
                S_old.objective_value)/T)
            return true
        end
        return false
    end
end

module TerminationCriteria
    using ..SettingTypes
    
    """
    Decide whether to terminate using a maximum number of iterations.
    
    True is returned if the algorithm should teminate, otherwise false. 

    """
    function number_of_iterations(
            curr_iter::Int, 
            alns_settings::SettingTypes.ALNSSettings
        )::Bool

        if curr_iter <= 0
            throw(DomainError(curr_iter, "ERROR: iterations cannot be negative or 0"))
        end
        if curr_iter > alns_settings.max_iterations
            return true
        end
        return false
    end

    """
    Decide whether to terminate using a maximum time limit.
    
    True is returned if the algorithm should teminate, otherwise false. 

    """
    function time_termination(
            curr_iter::Int, 
            alns_settings::SettingTypes.ALNSSettings
        )::Bool
        return false
    end
end