module Models
    using JuMP
    ENV["GRB_NO_REVOKE"] = "1"
    using Gurobi
    using HiGHS
    using GLPK
    using ..DataStruct
    using ..DataHandeling
    using ..ResultHandeling
    using ..NodeTypes
    using ..SettingTypes
    using ..ResultsTypes
    using ..SolutionTypes
    using ..ProblemSpecifierTypes
    using Suppressor

    """
    Generate the sets used in the models.

    """
    function get_sets(
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )

        n_nodes, i_cs_start, i_cs_end, i_customers_start, i_customers_end,
            _, _,_, _,_, _ = DataHandeling.get_data_for_models(
                evrp_data, n_cs_copies)

        set_customers = i_customers_start:i_customers_end
        set_customers_and_cs = i_cs_start:i_customers_end
        set_charging_stations = i_cs_start:i_cs_end
        set_customers_cs_and_start_depot = 1:i_customers_end
        set_customers_cs_and_end_depot = i_cs_start:n_nodes
        set_all_nodes = 1:n_nodes
        set_vehicles = 1:evrp_data.n_vehicles
        set_cs_and_start_depot = 1:i_cs_end
        set_customers_and_start_depot = union(1, set_customers)

        return set_customers, set_customers_and_cs, set_charging_stations, 
            set_customers_cs_and_start_depot, set_customers_cs_and_end_depot, 
            set_all_nodes, set_vehicles, set_cs_and_start_depot, 
            set_customers_and_start_depot
    end
    
    """
    The flow constraints used in all 3 model variations.

    """
    function flow_constraints(
            model::Model, 
            x::Any, 
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )

        ####### Sets ########
        set_customers, set_customers_and_cs, set_charging_stations, 
            set_customers_cs_and_start_depot, set_customers_cs_and_end_depot, 
            _, set_vehicles, _, _ = get_sets(evrp_data, n_cs_copies)
        
        ####### Constraits ########
        for i in set_customers
            @constraint(model, sum( x[i, j, k] for j in 
                set_customers_cs_and_end_depot, k in set_vehicles if i != j) == 1)
        end

        for i in set_charging_stations
            @constraint(model, sum( x[i, j, k] for j in 
                set_customers_cs_and_end_depot, k in set_vehicles) <= 1 )
        end

        for k in set_vehicles
            @constraint(model, sum( x[1,j,k] for j in set_customers_and_cs) <= 1)
        end

        for k in set_vehicles
            for j in set_customers_and_cs
                @constraint(model, sum(x[i, j, k] for i in 
                    set_customers_cs_and_start_depot) == sum(x[j, i, k] for i 
                    in set_customers_cs_and_end_depot ) )
            end
        end
    end

    """
    Time constraits for EVRP variations using the full charging policy.

    """
    function time_constraints_full(
            model::Model, 
            p::Any, 
            x::Any, 
            y::Any, 
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )

        ####### Sets ########
        _, _, set_charging_stations, 
            _, set_customers_cs_and_end_depot, 
            set_all_nodes, set_vehicles, _, 
            set_customers_and_start_depot = 
            get_sets(evrp_data, n_cs_copies)
        

        ####### Node data ########
        _, _, _, _, _, _, travel_times,_,service_times, time_window_start, 
        time_window_end = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)


        ####### Constraints ########
        for i in set_customers_and_start_depot
            for j in set_customers_cs_and_end_depot
                @constraint(model, p[i] + (travel_times[i, j] + service_times[i]) * 
                    sum( x[i, j, k] for k in set_vehicles) <= p[j]+ time_window_end[1]*
                    (1.0 - sum(x[i, j, k] for k in set_vehicles) ) )
            end
        end

        for i in set_charging_stations
            for j in set_customers_cs_and_end_depot
                for k in set_vehicles
                    @constraint(model, p[i] + travel_times[i, j]*x[i, j, k] + 
                        evrp_data.recharging_rate*(evrp_data.battery_capacity - 
                        y[i, k]) <= p[j] + (time_window_end[1] + 
                        evrp_data.recharging_rate * evrp_data.battery_capacity) *
                        (1-x[i, j, k]))
                end
            end
        end

        for i in set_all_nodes
            @constraint(model, time_window_start[i]<= p[i])
        end  

        for i in set_all_nodes
            @constraint(model, p[i]<= time_window_end[i])
        end 
    end


    """
    Time constraits for EVRP variations using the partial charging policy.

    """
    function time_constraints_partial(
            model::Model, 
            p::Any, 
            x::Any, 
            y::Any, 
            Y::Any, 
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )
        
        ####### Sets ########
        _, _, set_charging_stations, 
            _, set_customers_cs_and_end_depot, 
            set_all_nodes, set_vehicles, _, 
            set_customers_and_start_depot = get_sets(evrp_data, n_cs_copies)

        ####### Node data ########
        _, _, _, _, _, _, travel_times,_,service_times, time_window_start, 
            time_window_end = DataHandeling.get_data_for_models(evrp_data, 
            n_cs_copies)

        ####### Constraints ########
        for i in set_customers_and_start_depot
            for j in set_customers_cs_and_end_depot
                @constraint(model, p[i] + (travel_times[i, j] + service_times[i]) * 
                    sum( x[i, j, k] for k in set_vehicles) <= p[j]+ 
                    time_window_end[1]*(1.0 - sum(x[i, j, k] for k in 
                    set_vehicles)))
            end
        end

        for i in set_charging_stations
            for j in set_customers_cs_and_end_depot
                for k in set_vehicles
                    @constraint(model, p[i] + travel_times[i, j]*x[i, j, k] + 
                        evrp_data.recharging_rate*(Y[i] - y[i, k]) <= p[j] + 
                        (time_window_end[1] + evrp_data.recharging_rate * 
                        evrp_data.battery_capacity)*(1-x[i, j, k]) )
                end
            end
        end

        for i in set_all_nodes
            @constraint(model, time_window_start[i]<= p[i])
        end  

        for i in set_all_nodes
            @constraint(model, p[i]<= time_window_end[i])
        end 
    end


    """
    Weight constraints. 

    """
    function weight_constraint(model::Model, 
            x::Any,  
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )

        ####### Sets ########
        
        sets = get_sets(evrp_data, n_cs_copies)

        set_customers, set_customers_cs_and_end_depot, set_vehicles = 
            sets[1], sets[5], sets[7]

        ####### Node data ########
        demand = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)[8]

        for k in set_vehicles
            @constraint(model, sum(demand[i] * x[i, j, k] for i in set_customers, 
                j in set_customers_cs_and_end_depot) <= evrp_data.vehicle_capacity)
        end
    end

    """
    Energy constraints for EVRP with load dependent discharging.

    """
    function energy_constraints_load_dependent(
            model::Model, 
            u::Any, 
            x::Any, 
            y::Any,  
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
    )

        ####### Constants ########
        phi_1 = evrp_data.energy_consumption_parameters[1] 
        phi_2 = evrp_data.energy_consumption_parameters[2] 
        m = evrp_data.truck_weight


        ####### Sets ########

        sets = get_sets(evrp_data, n_cs_copies)

        set_customers, set_customers_cs_and_end_depot, set_vehicles, 
            set_cs_and_start_depot= sets[1], sets[5], sets[7], sets[8]  
        
        ####### Node data ########
        travel_times = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)[7]

        for k in set_vehicles 
            @constraint(model, y[1,k] == evrp_data.battery_capacity )
        end

        for k in set_vehicles
            for i in set_customers 
                for j in set_customers_cs_and_end_depot
                    if i == j
                        continue 
                    end
                    @constraint(model, y[i, k] - y[j,k] - (phi_2 * (u[i, k] + m) + 
                        phi_1)*travel_times[i, j] >= (- evrp_data.battery_capacity - 
                        (phi_2 * (evrp_data.vehicle_capacity + m) + phi_1) *
                        travel_times[i, j]) *(1 - x[i, j, k]) )
                end
            end
        end

        for k in set_vehicles 
            for i in set_cs_and_start_depot
                for j in set_customers_cs_and_end_depot
                    if i == j
                        continue
                    end
                    @constraint(model, evrp_data.battery_capacity - y[j, k] - 
                        (phi_2 * (u[i, k] + m) + phi_1)*travel_times[i, j] >= (- 
                        evrp_data.battery_capacity - (phi_2 * 
                        (evrp_data.vehicle_capacity + m) + phi_1)*travel_times[i, j])*
                        (1 - x[i, j, k]) )
                end
            end
        end

    end

    """
    Energy constraints for EVRP with full charging policy and linear discharging.

    """
    function energy_constraints_full_charging(
            model::Model, 
            x::Any, 
            y::Any,  
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )
        ####### Sets ########

        sets = get_sets(evrp_data, n_cs_copies)

        set_customers,set_customers_cs_and_end_depot, set_vehicles, 
            set_cs_and_start_depot= sets[1], sets[5], sets[7], sets[8]

        ####### Node data ########
        distances = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)[6]

        for k in set_vehicles
            for i in set_customers
                for j in set_customers_cs_and_end_depot
                    @constraint(model, y[j, k]<=y[i, k] - 
                        evrp_data.energy_consumption_rate * distances[i, j] * 
                        x[i, j, k] + evrp_data.battery_capacity * (1-x[i, j, k]))
                end
            end
        end

        for k in set_vehicles
            for i in set_cs_and_start_depot
                for j in set_customers_cs_and_end_depot
                    @constraint(model,y[j, k] <= evrp_data.battery_capacity - 
                        evrp_data.energy_consumption_rate * distances[i, j] * 
                        x[i, j, k] )
                end
            end
        end

        for k in set_vehicles
            @constraint(model,y[1,k] == evrp_data.battery_capacity )
        end
    end


    """
    Energy constraints for EVRP with partial charging policy and linear discharging.

    """
    function energy_constraints_partial_charging(
            model::Model, 
            x::Any, 
            y::Any, 
            Y::Any, 
            evrp_data::DataStruct.DataEVRP, 
            n_cs_copies::Int64
        )
        ####### Sets ########

        sets = get_sets(evrp_data, n_cs_copies)

        set_customers,set_customers_cs_and_end_depot, set_vehicles, 
            set_cs_and_start_depot= sets[1], sets[5], sets[7], sets[8]

        ####### Node data ########
        distances = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)[6]

        ####### Constraints ########
        for k in set_vehicles
            for i in set_customers
                for j in set_customers_cs_and_end_depot
                    @constraint(model, y[j, k]<=y[i, k] - 
                        evrp_data.energy_consumption_rate * distances[i, j] * 
                        x[i, j, k] + evrp_data.battery_capacity*(1 - x[i, j, k]))
                end
            end
        end

        for i in set_cs_and_start_depot
            for j in set_customers_cs_and_end_depot
                for k in set_vehicles
                    @constraint(model,y[j, k] <= Y[i] - 
                        evrp_data.energy_consumption_rate * distances[i, j] *
                        x[i, j, k] + evrp_data.battery_capacity * (1-x[i, j, k])) 
                end
            end
        end
        
        @constraint(model,Y[1] == evrp_data.battery_capacity )
        
        for k in set_vehicles
            @constraint(model,y[1,k] == evrp_data.battery_capacity )
        end

        for i in set_cs_and_start_depot
            for k in set_vehicles
                @constraint(model, y[i,k] <= Y[i])
            end
        end
    
        for i in set_cs_and_start_depot
            @constraint(model, Y[i] <= evrp_data.battery_capacity)
        end
    end


    """ 
    This function generates a solution for different variations the Electric 
    Vehicle Routing Problem (EVRP). Which variation to be solved, is decided 
    by the problem_variation variable. It uses the JuMP package for modeling 
    and can be solved using different solvers (e.g., Gurobi, HiGHS, GLPK).
    Note that n_cs_copies is the number of copies of the charging stations in 
    the model and needs to be atleast 1.

    Note that the callback function used for the benchmarking is specific for
    Gurobi and needs to be replaced or commented out if using another solver.

    If not finding any feasible solution, it returns nothing. 

    """
    function run_models(
            evrp_data::DataStruct.DataEVRP,
            evrp_settings::SettingTypes.EVRPSettings, 
            solver::Module,
            problem_variation::ProblemSpecifierTypes.EVRPType; 
            printing::Bool = false,
            n_cs_copies::Int64 = 1,
            initial_solution::Any = nothing,
            time_limit::Int = -1
        )::Union{Tuple{SolutionTypes.EVRPSolution, ResultsTypes.GurobiResults}, Nothing}

        ####### Sets ########
        data_for_models = DataHandeling.get_data_for_models(evrp_data, n_cs_copies)
        n_nodes,distances = data_for_models[1], data_for_models[6]
        ############ Model definition ############

        model = nothing
        @capture_out begin
            model = Model(solver.Optimizer)
        end

        ########## Set time limit ################

        if time_limit > 0
            @capture_out begin
                set_optimizer_attribute(model, "TimeLimit", time_limit)
            end
        end
        set_optimizer_attribute(model, "OutputFlag", 0)

        ############ Variables ############

        @variable(model, x[1:n_nodes, 1:n_nodes, 1:evrp_data.n_vehicles], Bin) #x[i, j, k]
        @variable(model, 0 <= y[1:n_nodes, 1:evrp_data.n_vehicles] <= 
            evrp_data.battery_capacity) #y[i, k] one for each vechicle and node
        @variable(model, p[1:n_nodes] >= 0) #p[i]# time at node i

        if problem_variation == ProblemSpecifierTypes.partial_charging
            @variable(model, 0 <= Y[1:n_nodes] <= evrp_data.battery_capacity)
        elseif problem_variation == ProblemSpecifierTypes.load_dependent
            @variable(model, 0 <= u[1:n_nodes, 1:evrp_data.n_vehicles] <= 
                evrp_data.vehicle_capacity) #u[i, k]
        end

        ############ Initial solution ############

        if !isnothing(initial_solution)
            transformed_initial_solution = ResultHandeling.
                translate_ALNS_solution_to_model_solution(initial_solution, 
                evrp_data, n_cs_copies = n_cs_copies)
    
            if !isnothing(transformed_initial_solution)
                x_initial, y_initial, Y_initial , p_initial, u_initial = 
                    transformed_initial_solution

                for k in 1:evrp_data.n_vehicles
                    for i in 1:n_nodes
                        for j in 1:n_nodes
                            set_start_value(x[i, j, k], x_initial[i, j, k])
                        end
                        set_start_value(y[i, k], y_initial[i, k])
                        set_start_value(p[i], p_initial[i])
                        if problem_variation == 
                                ProblemSpecifierTypes.partial_charging
                            set_start_value(Y[i], Y_initial[i])
                        elseif problem_variation == 
                                ProblemSpecifierTypes.load_dependent
                            set_start_value(u[i, k], u_initial[i, k])
                        end
                    end
                end
            end
        end


        ######### Defining sets #################
        sets = get_sets(evrp_data, n_cs_copies)
        set_customers_cs_and_start_depot = sets[4]
        set_customers_cs_and_end_depot = sets[5]
        set_vehicles = sets[7]

        ############ Objective function ############

        @objective(model, Min, sum(distances[i, j]*x[i, j, k] for i in 
            set_customers_cs_and_start_depot , j in set_customers_cs_and_end_depot, 
            k in set_vehicles))

        ############ Flow constraints ############
    
        flow_constraints(model, x, evrp_data, n_cs_copies)

        ############ Energy constraints ############
        if problem_variation == ProblemSpecifierTypes.full_charging
            energy_constraints_full_charging(model, x, y, evrp_data, 
                n_cs_copies)
        elseif problem_variation == ProblemSpecifierTypes.partial_charging
            energy_constraints_partial_charging(model, x, y, Y, evrp_data, 
                n_cs_copies)
        elseif problem_variation == ProblemSpecifierTypes.load_dependent
            energy_constraints_load_dependent(model, u, x, y, evrp_data, 
                n_cs_copies)
        end

        ############ Weight constraint ############

        weight_constraint(model, x, evrp_data, n_cs_copies)

        ############ Time constraints ############

        if problem_variation == ProblemSpecifierTypes.partial_charging
            time_constraints_partial(model, p, x, y, Y, evrp_data, n_cs_copies)
        else
            time_constraints_full(model, p, x, y, evrp_data, n_cs_copies)
        end

        ############## Get objective value over time ##################

        if solver == Gurobi
            data = Any[]
            start_time = time()
            callback_function = ResultHandeling.create_callback(data, start_time)
            MOI.set(model, Gurobi.CallbackFunction(), callback_function)

            optimize!(model)
            
            return ResultHandeling.get_model_results_gurobi(model,data, n_cs_copies, 
                evrp_data, evrp_settings, time_limit, printing, problem_variation)
        end

        optimize!(model)
        return model_results = ResultHandeling.get_model_results(model, n_cs_copies, 
                evrp_data, evrp_settings, printing, problem_variation) 
    end
end

