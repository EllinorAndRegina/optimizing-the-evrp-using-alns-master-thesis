module TestMaxIterations
    using ..TerminationCriteria
    using ..ALNSSetupFunctions

    function test_max_iterations_accepting()
        max_iter = 5
        curr_iter = 6

        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(max_iterations = max_iter)
        status = TerminationCriteria.number_of_iterations(curr_iter, alns_settings)
        @assert status "Termination criteria max iterations - test accept"
    end

    function test_max_iterations_rejecting()
        max_iter = 5
        curr_iter = 4
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(max_iterations = max_iter)
        status = TerminationCriteria.number_of_iterations(curr_iter, alns_settings)
        @assert !status "Termination criteria max iterations - test reject"
    end

    function test_max_iterations_iteration_max_iter()
        max_iter = 5
        curr_iter = 5
        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(max_iterations = max_iter)
        status = TerminationCriteria.number_of_iterations(curr_iter, alns_settings)
        @assert !status "Termination criteria max iterations - test reject"
    end

    function test_max_iterations_zero()
        max_iter = 5
        curr_iter = 0

        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(max_iterations = max_iter)

        try
            status = TerminationCriteria.number_of_iterations(curr_iter, alns_settings)
            global recreated_error = false
        catch err
            if isa(err,DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Termination criteria max iterations - not feasable"
    end

    function test_max_iterations_negative()
        max_iter = 5
        curr_iter = -1

        alns_settings = ALNSSetupFunctions.setup_alns_full_standard(max_iterations = max_iter)

        try
            status = TerminationCriteria.number_of_iterations(curr_iter, alns_settings)
            global recreated_error = false
        catch err
            if isa(err,DomainError)
                global recreated_error = true
            else
                rethrow(err)
            end
        end

        @assert recreated_error "Termination criteria max iterations - not feasable"
    end
end
