module EVRPSetupFunctions
    using ..DataStruct
    using ..SettingTypes
    using ..ParsingFunctions

    using ..ObjectiveFunctions
    using ..RechargingFunctions
    using ..EnergyConsumptionFunctions
    using ..BatteryCalculationFunctions

    """
    Setup the evrp for a given Schneider data file with the standard functions
    and the full charging policy.
    """
    function setup_evrp_standard_full(file_name::String)::Tuple{
            DataStruct.DataEVRP, SettingTypes.EVRPSettings}
        
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        
        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
        recharging_func = RechargingFunctions.calculate_recharging_time_linear
        energy_consump_func = EnergyConsumptionFunctions.distance_dependent_energy_consumption
        battery_func = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
        
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func)
        
        return evrp_data, evrp_settings
    end

    """
    Setup the evrp for a given Schneider data file with the standard functions
    and the partial charging policy.
    """
    function setup_evrp_standard_partial(file_name::String)
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        
        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
        recharging_func = RechargingFunctions.calculate_recharging_time_linear
        energy_consump_func = EnergyConsumptionFunctions.distance_dependent_energy_consumption
        battery_func = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging
        
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func)
        
        return evrp_data, evrp_settings
    end

    function setup_evrp_load_dependent_full(file_name::String)::Tuple{
            DataStruct.DataEVRP, SettingTypes.EVRPSettings}
        
        evrp_data = DataStruct.DataEVRP(file_name, 
            ParsingFunctions.parsing_EVRPTW_Schneider, 
            load_dependent_params = (1.03809 * 0.072338, 0.0012248 * 0.41667), 
            truck_weight = 1579.0)
        
        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
        recharging_func = RechargingFunctions.calculate_recharging_time_linear
        energy_consump_func = EnergyConsumptionFunctions.load_dependent_energy_consumption
        battery_func = BatteryCalculationFunctions.calculate_battery_levels_for_route_full_charging
        
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func)
        
        return evrp_data, evrp_settings
    end

    function setup_evrp_load_dependeny_partial(file_name::String)
        evrp_data = DataStruct.DataEVRP(file_name, ParsingFunctions.parsing_EVRPTW_Schneider)
        
        obj_func = ObjectiveFunctions.objective_function_distance!
        obj_func_per_route = ObjectiveFunctions.calculate_total_route_distance
        recharging_func = RechargingFunctions.calculate_recharging_time_linear
        energy_consump_func = EnergyConsumptionFunctions.load_dependent_energy_consumption
        battery_func = BatteryCalculationFunctions.calculate_battery_levels_for_route_partial_charging
        
        evrp_settings = SettingTypes.EVRPSettings(obj_func, obj_func_per_route, 
            energy_consump_func, recharging_func, battery_func)
        
        return evrp_data, evrp_settings
    end
end

module ALNSSetupFunctions
    using Random 

    using ..AcceptanceCriteria
    using ..TerminationCriteria
    using ..SelectionFunctions
    using ..RemoveOperators
    using ..InsertOperators
    using ..SettingTypes
    """
    Setup alns with the standard functions, operators and parameters.
    
    """
    function setup_alns_full_standard(;seed::Int = 13, max_iterations::Int = 10, 
            max_time::Int = 500, remove_proportion::Float64 = 0.1, k_cs_insert::Int = 3)
        # Functions
        acceptance_func = AcceptanceCriteria.greedy
        termination_func = TerminationCriteria.number_of_iterations
        selection_func = SelectionFunctions.roulette_wheel_selection

        # Operators and weights
        remove_operators = [RemoveOperators.random_removal]
        insert_operators = [InsertOperators.greedy_insert]
        initial_weights_remove = ones(length(remove_operators))
        initial_weights_insert = ones(length(insert_operators))

        # Objects 
        rng = Xoshiro(seed)

        # Parameters
        n_iterations_until_update = 5
        cooling_rate = 0.9995
        T0 = 10.0

        score_increments = (5, 2, 3)
        weight_update_reaction_factor = 0.1
        n_tries_to_insert = 5
        k_regret = 2

        cs_insert_score_parameters = (1, 1, 1)

        return SettingTypes.ALNSSettings(
            acceptance_func,
            termination_func,
            selection_func,
            remove_operators,
            insert_operators,
            initial_weights_remove, 
            initial_weights_insert,
            rng, 
            n_iterations_until_update,
            cooling_rate,
            T0,
            max_iterations,
            max_time,
            remove_proportion,
            score_increments,
            weight_update_reaction_factor,
            n_tries_to_insert,
            k_regret,
            k_cs_insert,
            cs_insert_score_parameters
        )
    end
end