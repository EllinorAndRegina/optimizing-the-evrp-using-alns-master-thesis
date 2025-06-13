
"""
All parsing functions in this module should return a tuple containing the 
following:
- `n_depots::Int`: the number of depots.
- `n_charging_stations::Int`: the number of charging stations.
- `n_customers::Int`: the number of customers. 
- `nodes::Vector{Nodetypes.Node}`: a list of all nodes, that is all depots, 
    customers and charging stations
- `speed::Float64`: velocity of the vehicle. 
- `consumption_rate::Float64`: fuel consumption rate. 
- `battery_capacity::Float64`: battery capacity. 
- `recharging_rate::Float64`: the refueling rate (actually inverse recharging rate). 
- `vehicle_capacity::Float64`: weight capacity of vehicle.
- `n_vehicles::Int`: the number of available vehicles. 
    
"""
module ParsingFunctions
    using ..NodeTypes

    """
    Parse EVRPTW from a modified version of the datafiles introduced in:
        "Schneider, Michael and Stenger, Andreas and Goeke, Dominik: The 
        Electric Vehicle-Routing Problem with Time Windows and Recharging 
        Stations, Transportation Science, 48(4), 500-520, 2014." 
    The modification done was adding the number of vehicles available. 

    # Returns a tuple containing 
    - n_depots::Int,
    - n_charging_stations::Int, 
    - n_customers::Int,
    - nodes::Vector{Nodetypes.Node},
    - speed::Float64, 
    - consumption_rate::Float64, 
    - battery_capacity::Float64, 
    - recharging_rate::Float64 (actually inverse recharging rate), 
    - vehicle_capacity::Float64, 
    - n_vehicles::Int, 
    
    """
    function parsing_EVRPTW_Schneider(file_path::String)
        # Initialize data
        n_depots = 0
        n_charging_stations = 0
        n_customers = 0
        nodes = Vector{NodeTypes.Node}(undef, 0)
        speed = nothing
        consumption_rate = nothing
        battery_capacity = nothing
        recharging_rate = nothing
        vehicle_capacity = nothing
        n_vehicles = nothing

        regex_node_data = r"^([DSC]\d+)\s+([dfc])\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+
            (-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)\s+(-?\d+.\d+)"x
        regex_Q = r"^Q Vehicle fuel tank capacity \/(-?\d+.\d+)\/"
        regex_C = r"^C Vehicle load capacity \/(-?\d+.\d+)\/"
        regex_r = r"^r fuel consumption rate \/(-?\d+.\d+)\/"
        regex_g = r"^g inverse refueling rate \/(-?\d+.\d+)\/"
        regex_v = r"^v average Velocity \/(-?\d+.\d+)\/"
        regex_m = r"^m number of vehicles \/(\d+)\/"

        line_count = 0
        n_nodes = 0

        # Read file
        for line in eachline(file_path)
            line_count += 1

            # Match node data
            m = match(regex_node_data, line)
            
            if !isnothing(m)
                n_nodes += 1

                # Handle node type
                node_type_char = m.captures[2]
                node_type = nothing
                type_index = 0
                if node_type_char == "d"
                    n_depots += 1
                    node_type = NodeTypes.depot
                    type_index = n_depots
                elseif node_type_char == "f"
                    n_charging_stations += 1
                    node_type = NodeTypes.charging_station
                    type_index = n_charging_stations
                elseif node_type_char == "c"
                    n_customers += 1
                    node_type = NodeTypes.customer
                    type_index = n_customers
                end

                # Handle node coordinates
                x = parse(Float64, m.captures[3])
                y = parse(Float64, m.captures[4])
                position = (x, y)

                # Handle node demand 
                demand = parse(Float64, m.captures[5])

                # Handle time windows
                time_window_start = parse(Float64, m.captures[6])
                time_window_end = parse(Float64, m.captures[7])

                # Handle service times
                service_time = parse(Float64, m.captures[8])

                # Save node
                node = NodeTypes.Node(position, node_type, time_window_start, 
                    time_window_end, service_time, demand, n_nodes, type_index)
                push!(nodes, node)
                continue
            end 

            # Match parameters
            m = match(regex_Q, line)
            if !isnothing(m)
                if !isnothing(battery_capacity)
                    println("WARNING: Battery capacity is already set, overwriting. Check $file_path.")
                end
                battery_capacity = parse(Float64, m.captures[1])
                continue
            end

            m = match(regex_C, line)
            if !isnothing(m)
                if !isnothing(vehicle_capacity)
                    println("WARNING: Vehicle capacity is already set, overwriting. Check $file_path.")
                end
                vehicle_capacity = parse(Float64, m.captures[1])
                continue
            end

            m = match(regex_r, line)
            if !isnothing(m)
                if !isnothing(consumption_rate)
                    println("WARNING: Consumption rate is already set, overwriting. Check $file_path.")
                end
                consumption_rate = parse(Float64, m.captures[1])
                continue
            end

            m = match(regex_g, line)
            if !isnothing(m)
                if !isnothing(recharging_rate)
                    println("WARNING: Consumption rate is already set, overwriting. Check $file_path.")
                end
                recharging_rate = parse(Float64, m.captures[1])
                continue
            end

            m = match(regex_v, line)
            if !isnothing(m)
                if !isnothing(speed)
                    println("WARNING: Velocity is already set, overwriting. Check $file_path.")
                end
                speed = parse(Float64, m.captures[1])
                continue
            end

            m = match(regex_m, line)
            if !isnothing(m)
                if !isnothing(n_vehicles)
                    println("WARNING: The number of vehicles is already set, overwriting. Check $file_path.")
                end
                n_vehicles = parse(Int16, m.captures[1])
                continue
            end

            # If we get here, it is either the first row, an empty row or a row
            # that does not fit the format
            if line_count != 1 && !isequal(line, "")
                throw(ErrorException("The following line in your data file has not matched anything and is therefore ignored: \n\t$line"))
            end
        end

        # Throw errors if fields are missing
        missing_fields = Vector{String}(undef, 0)
        if isnothing(consumption_rate)
            push!(missing_fields, "fuel tank capacity")
        end
        if isnothing(battery_capacity)
            push!(missing_fields, "load capacity")
        end
        if isnothing(recharging_rate)
            push!(missing_fields, "fuel consumption rate")
        end
        if isnothing(speed)
            push!(missing_fields, "inverse refueling rate")
        end
        if isnothing(speed)
            push!(missing_fields, "velocity")
        end
        if isnothing(n_vehicles)
            push!(missing_fields, "number of vehicles")
        end 

        if length(missing_fields) > 0
            arr_str = join(missing_fields, ", ")
            throw(ErrorException("Some parameters were not found in data file. Missing parameters: $arr_str"))
        end

        return n_depots,
            n_charging_stations, 
            n_customers,
            nodes,
            speed, 
            consumption_rate, 
            battery_capacity, 
            recharging_rate, 
            vehicle_capacity, 
            n_vehicles
    end
end
