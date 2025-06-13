module SettingTypes
    using Random
    """
    This struct contains all customizable details for the ALNS algorithm
    
    - `acceptance_func::Function`: the function deciding if a new solution 
        should be accepted or not. 
    - `termination_func::Function`: the function deciding if the algorithm 
        should terminate. 
    - `selection_func::Function`: the function selecting remove/insert 
        operators in each iteration of ALNS. The function is called twice, 
        once for remove and once for insert operators.

    - `remove_operators::Array{Function, 1}`: the list of remove operators 
        used for destroying the solution.
    - `insert_operators::Array{Function, 1}`: the list of insert operators 
        used for repairing the solution.
    - `initial_weights_remove::Array{Float64, 1}`: the initial weights of 
        the remove operators. The weights are used to calculate the 
        probabilities with which the operators are chosen in each iteration.
    - `initial_weights_insert::Array{Float64, 1}`: the initial weights of 
        the insert operators. The weights are used to calculate the 
        probabilities with which the operators are chosen in each iteration.

    - `rng::AbstractRNG`: random generator

    - `n_iterations_until_update::Int`: the number of iterations that go by 
        before the weights are updated.
    - `cooling_rate::Float64`: the cooling rate of the temperature used in 
        the simulated annealing.
    - `T0::Float64`: the initial temperature for the simulated annealing.

    - `max_iterations::Int`: the maximum number of iterations before the 
        algorithm is terminated in the case that the termination function 
        uses max iterations.
    - `max_time::Float64`: the maximum amount of time the ALNS algotithm 
        is allowed to run. It is possible to go over, but it terminates 
        after the iteration it goes over the time limit. Data parsng and 
        plotting is not included.

    - `remove_proportion::Float64`: the proportion of nodes being removed 
        in each iteration.
    - `score_increments::Tuple{Int, Int, Int}`: the amount the scores for 
        remove/insert operators are increased in each iteration. The first 
        value in the tuple is the score when a new best solution has been 
        found, the second is the score when the new solution is better 
        than the last accepted solution, and lastly the third element is 
        for when a solution worse than the previous accepted solution is 
        accepted. 
    - `weight_update_reaction_factor::Float64`: the prameter regulating 
        how fast the weight reacts when updated.
    - `n_tries_to_insert::Int`: the number of tries to insert a customer 
        in random insert.
    - `k_regret::Int`: the number of routes/positions to consider when 
        calculating the k-regret measure.

    - `k_cs_insert::Int`: the number of steps back to check for insertions 
        in charging station k insert.
    - `cs_insert_score_parameters::Tuple{Float64, Float64, Float64}`: the 
        weights used when calculating the insertion scores in charging 
        station k insert. The first weight is for the ranking, the second 
        for the distance and the third is the infeasibility penalty for 
        battery constraints.

    """
    struct ALNSSettings 
        # Functions
        acceptance_func::Function
        termination_func::Function
        selection_func::Function

        # Operators and weights
        remove_operators::Array{Function, 1}
        insert_operators::Array{Function, 1}
        initial_weights_remove::Array{Float64, 1}
        initial_weights_insert::Array{Float64, 1}

        # Objects 
        rng::AbstractRNG

        # Parameters
        n_iterations_until_update::Int
        cooling_rate::Float64
        T0::Float64 

        max_iterations::Int
        max_time::Float64 

        remove_proportion::Float64 
        score_increments::Tuple{Int, Int, Int}
        weight_update_reaction_factor::Float64
        n_tries_to_insert::Int
        k_regret::Int

        k_cs_insert::Int
        cs_insert_score_parameters::Tuple{Float64, Float64, Float64}
    end

    struct EVRPSettings
        objective_func!::Function
        objective_func_per_route::Function
        energy_consumption_func::Function
        recharging_func::Function
        calculate_battery_func::Function 
    end
end

module NodeTypes
    @enum NodeType begin
        depot = 1
        charging_station = 2
        customer = 3
    end

    struct Node
        position::Tuple{Float64, Float64}
        node_type::NodeType
        time_window_start::Float64
        time_window_end::Float64
        service_time::Float64
        demand::Float64
        node_index::Int
        type_index::Int # Indexing among nodes of the same type, 
                        # e.g. the first charging station
    end
end

module DataStruct
    using Distances
    using LinearAlgebra
    using ..NodeTypes

    """
    A struct for storing all the EVRP data. Its constructor takes the 
    path to a data file (as a string) and a parsing function. The parsing
    function should take only one argument, the path to the data file. 

    The energy consumption parameters are used to calculate the energy 
    consumption for the load dependent variant of the EVRP. For more 
    info, see readme.

    """
    struct DataEVRP
        n_depots::Int
        n_charging_stations::Int
        n_customers::Int
        n_nodes::Int
        n_vehicles::Int
        
        nodes::Vector{NodeTypes.Node}
        closest_charging_station_per_node::Vector{Union{Nothing, NodeTypes.Node}}
        closest_charging_station_per_arc::Matrix{Union{Nothing, NodeTypes.Node}}
        
        # Edge weights
        distances::Array{Float64, 2}
        travel_times::Array{Float64, 2}
        
        # Battery
        energy_consumption_rate::Float64
        battery_capacity::Float64
        recharging_rate::Float64
        
        # Vehicle capacity
        vehicle_capacity::Float64

        # For load dependent EVRPTW
        truck_weight::Union{Float64, Nothing}
        energy_consumption_parameters::Union{Tuple{Float64, Float64}, Nothing}

        speed::Float64

        # Constructor
        function DataEVRP(
                file_path::String, 
                parsing_func::Function; 
                load_dependent_params::Union{Tuple{Float64, Float64}, 
                    Nothing} = nothing, 
                truck_weight::Union{Float64, Nothing} = nothing
            )

            # Read data from file
            n_depots,
            n_charging_stations,
            n_customers,
            nodes, 
            speed, 
            energy_consumption_rate, 
            battery_capacity, 
            recharging_rate,  
            vehicle_capacity, 
            n_vehicles = parsing_func(file_path)

            # Calculate total number of nodes
            n_nodes = n_depots + n_charging_stations + n_customers
            
            # Calculate distances and travel_times
            node_positions = [node.position[i] for node in nodes, i in 1:2]
            distances = calculate_distances(node_positions)
            travel_times = calculate_travel_times(distances, speed)

            # Closest charging station for each node
            closest_charging_station_per_node = get_closest_charging_stations(nodes, distances)
            closest_charging_station_per_arc = get_closest_charging_station_to_arcs(nodes, distances)
            
            return new(
                n_depots,
                n_charging_stations,
                n_customers,
                n_nodes,
                n_vehicles,
                nodes,
                closest_charging_station_per_node,
                closest_charging_station_per_arc,
                distances, 
                travel_times,
                energy_consumption_rate,
                battery_capacity,
                recharging_rate,
                vehicle_capacity,
                truck_weight,
                load_dependent_params,
                speed
            )
        end
    end

    """
    Calculate pairwise distances for a matrix containing node positions, one 
    node per row in the matrix. It is intended for 2D points but is 
    general enough for n dimensional points.
    
    The distance from a node to itself is set to infinity.

    """
    function calculate_distances(
            node_positions::Matrix{Float64}
        )::Matrix{Float64}

        if size(node_positions, 1) < 2
            throw(ArgumentError("Not enough nodes to calculate distances, 
                you need at least 2"))
        end
        x = node_positions'
        x_copy = copy(x)
        d = pairwise(Euclidean(), x, x_copy);
        d[diagind(d)] .= Inf
        return d
    end

    """
    Calculate the travel times between nodes from a distance matrix assuming 
    constant speed.

    """
    function calculate_travel_times(
            distances::Matrix{Float64}, 
            speed::Float64
        )::Matrix{Float64}

        if speed <= 0.0
            throw(DomainError(speed, string("Your trucks are not moving as they", 
                " should, you need speed > 0")))
        end
        if size(distances, 1) != size(distances, 2)
            throw(DomainError(distances, string("The distance matrix should be",
                " squared, or are you doing something funny? In that case ",
                "remove this error.")))
        end
        if size(distances, 1) == 0
            throw(DomainError(distances, "The distance matrix is empty"))
        end
        return distances/speed
    end

    """
    Compute the closest charging station to each node in a vector.

    """
    function get_closest_charging_stations(
            nodes::Vector{NodeTypes.Node}, 
            distances::Matrix{Float64}
        )::Vector{Union{Nothing, NodeTypes.Node}}
        
        closest_cs = Vector{Union{Nothing, NodeTypes.Node}}(undef, length(nodes))
        charging_stations_i = findall(x -> x.node_type == 
            NodeTypes.charging_station, nodes)
        
        if length(charging_stations_i) == 0
            return NodeTypes.Node[]
        end

        for i in 1:length(nodes)
            closest_cs_i = charging_stations_i[argmin(distances[i, 
                charging_stations_i])]
            closest_cs[i] = nodes[closest_cs_i]
        end

        if length(charging_stations_i) == 1
            closest_cs[charging_stations_i[1]] = nothing
        end

        return closest_cs
    end


    """
    Compute the closest charging station to each arc in a matrix of nodes.
    For arcs between the same node or if it cant find any other charging 
    station that is not part of the arc, the function returns nothing.

    """
    function get_closest_charging_station_to_arcs(
            nodes::Vector{NodeTypes.Node}, 
            distances::Matrix{Float64}
        )::Matrix{Union{Nothing, NodeTypes.Node}}
    
        charging_stations = filter(x -> x.node_type == NodeTypes.charging_station, nodes)
    
        closest_cs_to_arcs = Matrix{Union{Nothing, NodeTypes.Node}}(nothing, length(nodes), length(nodes))
    
        for (i, from_node) in enumerate(nodes)
            for (j, to_node) in enumerate(nodes)
                if to_node != from_node
                    distances_to_charging_stations = Vector{Tuple{Float64, Int}}() #distance, node_index_cs
                    for charging_station in charging_stations
                        if charging_station == from_node 
                            continue 
                        elseif charging_station == to_node
                            continue 
                        end
                        extra_distance_to_cs = distances[from_node.node_index, charging_station.node_index] + 
                            distances[charging_station.node_index, to_node.node_index] - 
                            distances[from_node.node_index, to_node.node_index]
                        push!(distances_to_charging_stations, (extra_distance_to_cs, charging_station.type_index))
                    end
                    if length(distances_to_charging_stations) == 0
                        closest_cs_to_arcs[i, j] = nothing
                    else
                        sort!(distances_to_charging_stations, by = x -> x[1])
                        closest_cs_i = distances_to_charging_stations[1][2]
                        closest_cs_to_arcs[i, j] = charging_stations[closest_cs_i] 
                    end
                else 
                    closest_cs_to_arcs[i, j] = nothing
                end
            end
        end
    
        return closest_cs_to_arcs
    end
    
end

module SolutionTypes
    using ..NodeTypes

    """
    Struct for solution objects. 
        
    A solution consists of routes as well as arrival times, battery levels when 
    arriving and departuring from nodes, the objective value of the solution 
    and if the solution is feasible. The arrival times and battery levels are 
    saved as vectors of vectors and all of them have the same sizes as the 
    routes variable. See the readme file for an example. 

    """
    mutable struct EVRPSolution
        routes::Vector{Vector{NodeTypes.Node}}
        times_of_arrival::Vector{Vector{Float64}}
        battery_arrival::Vector{Vector{Float64}}
        battery_departure::Vector{Vector{Float64}}
        objective_value::Union{Nothing, Float64}
        is_feasible::Bool
    end
end

module ErrorTypes
    struct InfeasibleSolutionError <: Exception
        message::String
    end
end

module ProblemSpecifierTypes
    @enum EVRPType begin
        full_charging = 1
        partial_charging = 2
        load_dependent = 3
    end

    @enum ObjectiveType begin
        distance_objective = 1
    end
end

module ResultsTypes
    using ..SolutionTypes
    using ..NodeTypes

    struct Result
        n_iterations::Int
        objective_per_iteration::Vector{Float64}
        solutions_for_plotting::Vector{SolutionTypes.EVRPSolution}
        time_per_iteration::Vector{Float64}
        weights_remove::Union{Vector{Vector{Float64}}, Nothing}
        weights_insert::Union{Vector{Vector{Float64}}, Nothing}
    end

    struct GurobiResults
        objectives::Vector{Float64}
        times::Vector{Float64}
        best_value::Float64
        best_routes::Vector{Vector{NodeTypes.Node}}
        optimal::Bool
    end

    function GurobiResults(
            objectives::Vector{Float64}, 
            times::Vector{Float64},
            best_routes::Vector{Vector{NodeTypes.Node}},
            optimal::Bool
        )::GurobiResults
        best_value = minimum(objectives)

        return GurobiResults(objectives, times, best_value, best_routes, optimal)
    end
end

module SortByTypesInitialSolution
    @enum InitialSolutionSortBy begin
        time_window_start = 1
        time_window_end = 2
        largest_demand = 3
        smallest_demand = 4
    end
end