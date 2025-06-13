module TestSelectionFunctions
    using Random
    using ..SelectionFunctions
    using ..ALNSSetupFunctions

    function test_roulette_wheel_pass_first_index()
        prob = [0.25, 0.25, 0.25, 0.25]
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        
        #The seed given to alns_settings gives first rand(rng, Float32) = 0.15142488f0
        index =  SelectionFunctions.roulette_wheel_selection(prob, alns_settings)
        @assert index == 1 "Roulette wheel selection, select first index - test accept"
        return (index, 1)
    end

    function test_roulette_wheel_pass_last_index()
        prob = [0.25, 0.25, 0.25, 0.25]
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        
        #The seed given to alns_settings gives second rand(rng, Float32) = 0.88185525f0
        rand(alns_settings.rng, Float32)
        index = SelectionFunctions.roulette_wheel_selection(prob, alns_settings)
        @assert index == 4 "Roulette wheel selection, select last index - test accept"
        return (index, 4)
    end

    function test_roulette_wheel_empty_list_exception()
        prob = Float64[]
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        try
            index = SelectionFunctions.roulette_wheel_selection(prob, alns_settings)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error "Roulette wheel selection, empty list - exception"
    end

    function test_roulette_wheel_negative_probability_error()
        prob = [0.25, 0.25, 0.25, -0.25, 0.5]
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13) 
        try
            index = SelectionFunctions.roulette_wheel_selection(prob, alns_settings)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error "Roulette wheel selection, negative probability - exception"
    end

    function test_roulette_wheel_probabilities_not_adding_to_1_exception()
        prob = [0.25, 0.25, 0.25, 0.05]
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(seed = 13)
        try
            index = SelectionFunctions.roulette_wheel_selection(prob, alns_settings)
            global recreated_error = false
        catch err
            if isa(err, DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end
        @assert recreated_error "Roulette wheel selection, probabilities not adding to one - exception"
    end
end