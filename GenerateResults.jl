include("Main.jl")
include("Models/ModelUtilities.jl")
include("Models/ModelFunctions.jl")

using .ObjectiveFunctions
using .RechargingFunctions
using .EnergyConsumptionFunctions
using .BatteryCalculationFunctions
using .SettingTypes
using .DataStruct
using .ResultsTypes
using .ParsingFunctions

using .Models
ENV["GRB_NO_REVOKE"] = "1"
using Gurobi
using JuMP

using JLD2

###############################################################################
#                          Customize result gathering                         #
###############################################################################

small_datasets = [
    "Data/SchneiderEVRPTW/c103C5.txt",      # m = 2
    "Data/SchneiderEVRPTW/c206C5.txt",      # m = 2
    "Data/SchneiderEVRPTW/c208C5.txt",      # m = 2
    "Data/SchneiderEVRPTW/r104C5.txt",      # m = 3
    "Data/SchneiderEVRPTW/r105C5.txt",      # m = 3
    "Data/SchneiderEVRPTW/r202C5.txt",      # m = 2
    "Data/SchneiderEVRPTW/rc105C5.txt",     # m = 3
    "Data/SchneiderEVRPTW/rc108C5.txt",     # m = 3
    "Data/SchneiderEVRPTW/rc208C5.txt"      # m = 2
]
small_seeds = [13, 7, 51, 99, 83, 666, 1999, 10, 29]

medium_datasets = [
    "Data/SchneiderEVRPTW/c103C15.txt",     # m = 5
    "Data/SchneiderEVRPTW/c202C15.txt",     # m = 4
    "Data/SchneiderEVRPTW/c208C15.txt",     # m = 4
    "Data/SchneiderEVRPTW/r102C15.txt",     # m = 8
    "Data/SchneiderEVRPTW/r209C15.txt",     # m = 3
    "Data/SchneiderEVRPTW/r202C15.txt",     # m = 4
    "Data/SchneiderEVRPTW/rc103C15.txt",    # m = 7
    "Data/SchneiderEVRPTW/rc108C15.txt",    # m = 5
    "Data/SchneiderEVRPTW/rc202C15.txt"     # m = 4
]
medium_seeds = [13, 7, 51, 99, 83, 666, 1999, 10, 29]

large_datasets = [
    "Data/SchneiderEVRPTW/c201_21.txt",     # m = 8
    "Data/SchneiderEVRPTW/c102_21.txt",     # m = 16
    "Data/SchneiderEVRPTW/c107_21.txt",     # m = 16
    "Data/SchneiderEVRPTW/r102_21.txt",     # m = 25
    "Data/SchneiderEVRPTW/r201_21.txt",     # m = 5
    "Data/SchneiderEVRPTW/r106_21.txt",     # m = 20
    "Data/SchneiderEVRPTW/rc108_21.txt",    # m = 17
    "Data/SchneiderEVRPTW/rc103_21.txt",    # m = 20
    "Data/SchneiderEVRPTW/rc203_21.txt"     # m = 5
]
large_seeds = [13, 7, 51, 99, 83, 666, 1999, 10, 29]

extra_long_datasets = [
    "Data/SchneiderEVRPTW/c201_21.txt",
    "Data/SchneiderEVRPTW/r102_21.txt",
    "Data/SchneiderEVRPTW/rc203_21.txt"
]

include_small_datasets = false
include_medium_datasets = false
include_large_datasets = false
include_extra_long_runs = true

include_full = true
include_partial = true
include_load_dependent = true

n_repetitions = 3
max_time_warmup = 150 # (2.5 min)
max_time_small = 60
max_time_medium = 300
max_time_large = 600
max_time_extra_long = 30*60

filenames_for_saving = [
    "Results/result_full_small.jld2",
    "Results/result_full_medium.jld2",
    "Results/result_full_large.jld2",
    "Results/result_partial_small.jld2",
    "Results/result_partial_medium.jld2",
    "Results/result_partial_large.jld2",
    "Results/result_load_dependent_small.jld2",
    "Results/result_load_dependent_medium.jld2",
    "Results/result_load_dependent_large.jld2",
    "Results/result_extra_long_runs.jld2"
]

load_dependent_params = (1.03809 * 0.072338, 0.0012248 * 0.41667) 
truck_weight = 1579.0

insert_k_full = 3
insert_k_partial = 5
insert_k_load = 4
insert_score_full = (0.6, 0.6, 0.6)
insert_score_partial = (1.2, 1.0, 0.2)
insert_score_load = (0.6, 0.6, 0.8)

###############################################################################
#                                   SETUP                                     #
###############################################################################

obj_func = ObjectiveFunctions.objective_function_distance!
obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
recharging_func = RechargingFunctions.calculate_recharging_time_linear

energy_consump_func = EnergyConsumptionFunctions.distance_dependent_energy_consumption
energy_consump_func_load_dependent = EnergyConsumptionFunctions.load_dependent_energy_consumption

battery_func_full = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
battery_func_partial = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging

evrp_settings_full = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func, recharging_func, battery_func_full)

evrp_settings_partial = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func, recharging_func, battery_func_partial)

evrp_settings_load_dependent = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
    energy_consump_func_load_dependent, recharging_func, battery_func_full)


###############################################################################
#                                  Warmup                                     #
###############################################################################

println("Performing warmup")

evrp_data = DataStruct.DataEVRP(
            "Data/SchneiderEVRPTW/c101_21.txt", 
            ParsingFunctions.parsing_EVRPTW_Schneider)
initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
    evrp_settings_full, insert_score_full, insert_k_full)

_, _ = Models.run_models(
    evrp_data, 
    evrp_settings_full, 
    Gurobi,
    ProblemSpecifierTypes.full_charging, 
    n_cs_copies = 10, 
    initial_solution = initial_solution, 
    time_limit = max_time_warmup)

_ = main("Data/SchneiderEVRPTW/c101_21.txt", 
    seed = 13, 
    max_time = max_time_warmup, 
    plotting = false, 
    printing = false,
    initial_solution = initial_solution)

println("Warmup complete")

###############################################################################
#                             small DATASETS                                  #
###############################################################################

if include_small_datasets
    for (i, datafile) in enumerate(small_datasets)
        evrp_data = DataStruct.DataEVRP(
            datafile, 
            ParsingFunctions.parsing_EVRPTW_Schneider, 
            load_dependent_params = load_dependent_params, 
            truck_weight = truck_weight)

        println("Starting on file: ", datafile)
        
        if include_full
            println("Full charging")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_full, insert_score_full, insert_k_full)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            gurobi_results = Vector{ResultsTypes.GurobiResults}(undef, n_repetitions)
            for i in 1:n_repetitions 
                _, gurobi_results[i] = Models.run_models(
                    evrp_data, 
                    evrp_settings_full, 
                    Gurobi, 
                    ProblemSpecifierTypes.full_charging,
                    n_cs_copies = 5, 
                    initial_solution = initial_solution, 
                    time_limit = max_time_small)
            end
            
            alns_results = main(datafile, 
                seed = small_seeds[i], 
                max_time = max_time_small, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[1]) ? load(filenames_for_saving[1], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[1] results = results_dict
            println("Results saved for $(datafile) full charging")
        end

        if include_partial
            println("Partial charging")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_partial, insert_score_partial, insert_k_partial)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            gurobi_results = Vector{ResultsTypes.GurobiResults}(undef, n_repetitions)
            for i in 1:n_repetitions 
                _, gurobi_results[i] = Models.run_models(
                    evrp_data, 
                    evrp_settings_partial, 
                    Gurobi, 
                    ProblemSpecifierTypes.partial_charging,
                    n_cs_copies = 5, 
                    initial_solution = initial_solution, 
                    time_limit = max_time_small)
            end
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.partial_charging,
                seed = small_seeds[i], 
                max_time = max_time_small, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                k_cs_insert = insert_k_partial,
                cs_insert_score_parameters = insert_score_partial,
                score_increments = (31, 19, 22),
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[4]) ? load(filenames_for_saving[4], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[4] results = results_dict
            
            println("Results saved for $(datafile) partial charging")
        end

        if include_load_dependent
            println("Load dependent")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_load_dependent, insert_score_load, insert_k_load)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            gurobi_results = Vector{ResultsTypes.GurobiResults}(undef, n_repetitions)
            for i in 1:n_repetitions
                _, gurobi_results[i] = Models.run_models(
                    evrp_data, 
                    evrp_settings_load_dependent, 
                    Gurobi, 
                    ProblemSpecifierTypes.load_dependent,
                    n_cs_copies = 5, 
                    initial_solution = initial_solution, 
                    time_limit = max_time_small)
            end
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.load_dependent,
                seed = small_seeds[i], 
                max_time = max_time_small, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                remove_proportion = 0.2,
                k_cs_insert = insert_k_load,
                cs_insert_score_parameters = insert_score_load,
                k_regret = 2,
                score_increments = (22, 16, 13),
                initial_temperature_params = (0.5, 0.07),
                initial_solution = initial_solution)
            
            # Save results
            results_dict = isfile(filenames_for_saving[7]) ? load(filenames_for_saving[7], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[7] results = results_dict
            println("Results saved for $(datafile) load dependent")
        end
        println()
    end
end






###############################################################################
#                             MEDIUM DATASETS                                 #
###############################################################################

if include_medium_datasets
    for (i, datafile) in enumerate(medium_datasets)
        evrp_data = DataStruct.DataEVRP(
            datafile, 
            ParsingFunctions.parsing_EVRPTW_Schneider, 
            load_dependent_params = load_dependent_params, 
            truck_weight = truck_weight)

        println("Starting on file: ", datafile)
        
        if include_full
            println("Full charging")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_full, insert_score_full, insert_k_full)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_full, 
                Gurobi,
                ProblemSpecifierTypes.full_charging,
                n_cs_copies = 7, 
                initial_solution = initial_solution, 
                time_limit = max_time_medium)
            
            alns_results = main(datafile, 
                seed = medium_seeds[i], 
                max_time = max_time_medium, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[2]) ? load(filenames_for_saving[2], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[2] results = results_dict
            println("Results saved for $(datafile) full charging")
        end

        if include_partial
            println("Partial charging")
            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_partial, insert_score_partial, insert_k_partial)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_partial, 
                Gurobi,
                ProblemSpecifierTypes.partial_charging, 
                n_cs_copies = 7, 
                initial_solution = initial_solution, 
                time_limit = max_time_medium)
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.partial_charging,
                seed = medium_seeds[i], 
                max_time = max_time_medium, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                k_cs_insert = insert_k_partial,
                cs_insert_score_parameters = insert_score_partial,
                score_increments = (31, 19, 22),
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[5]) ? load(filenames_for_saving[5], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[5] results = results_dict
            
            println("Results saved for $(datafile) partial charging")
        end

        if include_load_dependent
            println("Load dependent")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_load_dependent, insert_score_load, insert_k_load)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_load_dependent, 
                Gurobi,
                ProblemSpecifierTypes.load_dependent,
                n_cs_copies = 7, 
                initial_solution = initial_solution, 
                time_limit = max_time_medium)
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.load_dependent,
                seed = medium_seeds[i], 
                max_time = max_time_medium, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                remove_proportion = 0.2,
                k_cs_insert = insert_k_load,
                cs_insert_score_parameters = insert_score_load,
                k_regret = 2,
                score_increments = (22, 16, 13),
                initial_temperature_params = (0.5, 0.07),
                initial_solution = initial_solution)
            
            # Save results
            results_dict = isfile(filenames_for_saving[8]) ? load(filenames_for_saving[8], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[8] results = results_dict
            println("Results saved for $(datafile) load dependent")
        end
        println()
    end
end



###############################################################################
#                             LARGE DATASETS                                  #
###############################################################################

if include_large_datasets
    for (i, datafile) in enumerate(large_datasets)
        evrp_data = DataStruct.DataEVRP(
            datafile, 
            ParsingFunctions.parsing_EVRPTW_Schneider, 
            load_dependent_params = load_dependent_params, 
            truck_weight = truck_weight)

        println("Starting on file: ", datafile)
        
        if include_full
            println("Full charging")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_full, insert_score_full, insert_k_full)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_full, 
                Gurobi,
                ProblemSpecifierTypes.full_charging, 
                n_cs_copies = 15, 
                initial_solution = initial_solution, 
                time_limit = max_time_large)
            
            alns_results = main(datafile, 
                seed = large_seeds[i], 
                max_time = max_time_large, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[3]) ? load(filenames_for_saving[3], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[3] results = results_dict
            println("Results saved for $(datafile) full charging")
        end

        if include_partial
            println("Partial charging")
            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_partial, insert_score_partial, insert_k_partial)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_partial, 
                Gurobi,
                ProblemSpecifierTypes.partial_charging, 
                n_cs_copies = 15, 
                initial_solution = initial_solution, 
                time_limit = max_time_large)
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.partial_charging,
                seed = large_seeds[i], 
                max_time = max_time_large, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                k_cs_insert = insert_k_partial,
                cs_insert_score_parameters = insert_score_partial,
                score_increments = (31, 19, 22),
                initial_solution = initial_solution)

            # Save results
            results_dict = isfile(filenames_for_saving[6]) ? load(filenames_for_saving[6], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[6] results = results_dict
            
            println("Results saved for $(datafile) partial charging")
        end

        if include_load_dependent
            println("Load dependent")

            initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
                evrp_settings_load_dependent, insert_score_load, insert_k_load)
            if isnothing(initial_solution)
                throw(ErrorTypes.InfeasibleSolutionError(
                "Initial solution failed to find a feasible solution"))
            end

            _, gurobi_results = Models.run_models(
                evrp_data, 
                evrp_settings_load_dependent, 
                Gurobi,
                ProblemSpecifierTypes.full_charging,
                n_cs_copies = 15, 
                initial_solution = initial_solution, 
                time_limit = max_time_large)
            
            alns_results = main(datafile, 
                problem_specifier = ProblemSpecifierTypes.load_dependent,
                seed = large_seeds[i], 
                max_time = max_time_large, 
                plotting = false, 
                printing = false,
                benchmark_iterations = n_repetitions,
                remove_proportion = 0.2,
                k_cs_insert = insert_k_load,
                cs_insert_score_parameters = insert_score_load,
                k_regret = 2,
                score_increments = (22, 16, 13),
                initial_temperature_params = (0.5, 0.07),
                initial_solution = initial_solution)
            
            # Save results
            results_dict = isfile(filenames_for_saving[9]) ? load(filenames_for_saving[9], "results") : Dict{String, Tuple}()
            results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
            @save filenames_for_saving[9] results = results_dict
            println("Results saved for $(datafile) load dependent")
        end
        println()
    end
end

if include_extra_long_runs
    for (i, datafile) in enumerate(extra_long_datasets)
        evrp_data = DataStruct.DataEVRP(
            datafile, 
            ParsingFunctions.parsing_EVRPTW_Schneider)

        println("Starting on file: ", datafile)

        initial_solution = InitialSolution.greedy_initial_solution(evrp_data, 
            evrp_settings_full, insert_score_full, insert_k_full)
        if isnothing(initial_solution)
            throw(ErrorTypes.InfeasibleSolutionError(
            "Initial solution failed to find a feasible solution"))
        end
        _, gurobi_results = Models.run_models(
            evrp_data, 
            evrp_settings_full, 
            Gurobi,
            ProblemSpecifierTypes.full_charging, 
            n_cs_copies = 15, 
            initial_solution = initial_solution, 
            time_limit = max_time_extra_long)
        
        alns_results = main(datafile, 
            seed = 13, 
            max_time = max_time_extra_long, 
            plotting = false, 
            printing = false,
            initial_solution = initial_solution)

        # Save results
        results_dict = isfile(filenames_for_saving[10]) ? load(filenames_for_saving[10], "results") : Dict{String, Tuple}()
        results_dict[datafile] = (initial_solution, gurobi_results, alns_results)
        @save filenames_for_saving[10] results = results_dict
        println("Results saved for $(datafile) extra long run")
    end
end