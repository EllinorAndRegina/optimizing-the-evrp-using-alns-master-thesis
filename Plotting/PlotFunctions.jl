module PlotFunctions 
    using Plots
    using Colors
    using FileIO
    using ..DataStruct
    using ..NodeTypes
    using ..SolutionTypes
    using ..ResultsTypes
    using ..SettingTypes

    

    

    """
    Takes a solution and its corresponding data and generates the plot 
    of the routes used in the functions plot_routes_single and plot_solution_list. 

    """
    function create_plot(
            solution::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP,  
            main_title::String,
            single_plot::Bool
        )

        custom_colorbar_ticks=(0:20:100, string.(round.(Int, (0:20:100)), "%"))

        depot = evrp_data.nodes[1]
        charging_stations = filter(x -> x.node_type == 
            NodeTypes.charging_station, evrp_data.nodes)

        # Calculating most outer coordinated to adjust the plot after these
        max_value_x = maximum(map(x -> x.position[1], evrp_data.nodes))
        min_value_x = minimum(map(x -> x.position[1], evrp_data.nodes))
        difference_distance_x = max_value_x - min_value_x

        max_value_y = maximum(map(x -> x.position[2], evrp_data.nodes))
        min_value_y = minimum(map(x -> x.position[2], evrp_data.nodes))
        difference_distance_y = max_value_y - min_value_y
        

        # Scaling factors for icons
        scaling_factor = difference_distance_x * .8 *(1-evrp_data.n_customers*.0025)
        size_customers = 8 - evrp_data.n_customers*.025
        cs_img_shrink_factor = 0.0003 * scaling_factor
        depot_img_shrink_factor = 0.0004 * scaling_factor

        # Plot depot with icon
        depot_img = FileIO.load("Plotting/Free_house.png")
        h, w = size(depot_img)[1:2]
        
        depot_lower_left_corner_x = depot.position[1] - 
            depot_img_shrink_factor * w/2
        depot_upper_right_corner_x = depot.position[1] + 
            depot_img_shrink_factor * w/2
        depot_lower_left_corner_y = depot.position[2] - 
            depot_img_shrink_factor * h/2
        depot_upper_right_corner_y = depot.position[2] + 
            depot_img_shrink_factor * h/2

        y_limits = (min_value_y - difference_distance_y*0.1, max_value_y + 
            difference_distance_y * 0.1)
        x_limits = (min_value_x - difference_distance_x * 0.1, max_value_x + 
            difference_distance_x * 0.1)

        plt = plot([depot_lower_left_corner_x, depot_upper_right_corner_x], 
            [depot_lower_left_corner_y, depot_upper_right_corner_y], 
            reverse(depot_img, dims = 1),xlabel = "Distance (km)", 
            ylabel = "Distance (km)", grid = false, ylim = y_limits, 
            xlim = x_limits ,aspect_ratio = 1, xguidefontsize = 15, yguidefontsize =15, title = main_title)

        # Plot charging stations with icons
        charging_station_img = FileIO.load("Plotting/Free_cs.png")
        h, w = size(charging_station_img)[1:2]
        
        for cs in charging_stations
            if cs.position != depot.position
                cs_lower_left_corner_x = cs.position[1] - 
                    cs_img_shrink_factor * w/2
                cs_upper_right_corner_x = cs.position[1] + 
                    cs_img_shrink_factor * w/2
                cs_lower_left_corner_y = cs.position[2] - 
                    cs_img_shrink_factor * h/2
                cs_upper_right_corner_y = cs.position[2] + 
                    cs_img_shrink_factor * h/2
                    
                Plots.plot!(plt, [cs_lower_left_corner_x, 
                    cs_upper_right_corner_x], 
                    [cs_lower_left_corner_y, 
                    cs_upper_right_corner_y], 
                    reverse(charging_station_img, dims = 1), 
                    yflip = false, 
                    aspect_ratio = 1
                )
            end
        end

        if isnothing(solution)
            node_positions = []
            customers_route = filter(x -> x.node_type == NodeTypes.customer, evrp_data.nodes)
            for customer in customers_route
                push!(node_positions, customer.position)
            end

            x_values = [position[1] for position in node_positions]
            y_values = [position[2] for position in node_positions]
            scatter!(plt , x_values, 
                        y_values, 
                        markercolor = :grey, 
                        markersize=size_customers, 
                        markerstrokewidth = 0.05, 
                        label = "", colorbar = false
                    ) 
            println("Warning: nothing as input, no solution found")
        end

        x_pos = Float64[]
        y_pos = Float64[]
        batt_levels = Float64[]

        for (k, route) in enumerate(solution.routes)
            prev_node = depot
            for (node_ind, node) in enumerate(route)
                if node_ind == 1
                    continue
                end

                # Plot connecting lines
                Plots.plot!(plt , [prev_node.position[1], node.position[1]], 
                                [prev_node.position[2], node.position[2]], 
                                linewidth = 0.5, 
                                linecolor = :grey, 
                                label = "")

                if node.node_type == NodeTypes.customer
                    battery_level_norm = solution.battery_departure[k][node_ind] / evrp_data.battery_capacity * 100
                    push!(x_pos, node.position[1])
                    push!(y_pos, node.position[2])
                    push!(batt_levels, battery_level_norm)
                end
                prev_node = node
            end
        end
        if single_plot
            scatter!(plt, x_pos, y_pos,
                zcolor = batt_levels,
                markercolor = :RdYlGn_11,
                markersize = size_customers,
                markerstrokewidth = 0.5,
                clims = (0, 100),
                colorbar_title = "Battery level departure (%)",
                colorbar_ticks = custom_colorbar_ticks,
                label = ""
            )
        else
            scatter!(plt, x_pos, y_pos,
                zcolor = batt_levels,
                markercolor = :RdYlGn_11,
                markersize = size_customers,
                markerstrokewidth = 0.5,
                colorbar = false,
                label = ""
            )
        end
        return plt
    end

    """
    Plots a single solution with the colorbar inside the same figure.

    """
    function plot_routes_single(
            solution::SolutionTypes.EVRPSolution, 
            evrp_data::DataStruct.DataEVRP,  
            main_title::String 
        ) 
        plt = create_plot(solution, evrp_data, main_title, true)
        
        display("image/png", plt)
    end

    """
    Takes a list of solutions and their corresponding data and generates plots 
    of the routes. If more then one solution is in input, it will generate 
    subplots. 

    If evrp_data_list is not the same length as solution_list, it will take
    the first element of evrp_data_list for all solutions.

    """
    function plot_solution_list(
            solution_list::Any, 
            evrp_data_list::Vector{DataStruct.DataEVRP},  
            subplot_titles::Vector{String};
        )

        if length(solution_list) != length(evrp_data_list)
            evrp_data_list = [evrp_data_list[1] for _ in 1:length(solution_list)]
        end

        n = length(solution_list)
        colorbar_ticks=(0:20:100, string.(round.(Int, (0:20:100)), "%"))

        if n == 1
            horizontal = 1
            vertical = 1
        else
            horizontal = 2
            vertical = ceil(Int, n/2)
        end

        plots = []
        for n_subplot in 1:n

            evrp_data = evrp_data_list[n_subplot]
            solution = solution_list[n_subplot]
            subplot_title = subplot_titles[n_subplot]

            plt = create_plot(solution, evrp_data, subplot_title, false) 
    
            push!(plots, plt)
        end
        if length(plots) < 1
            println("No solutions to plot")
            return -1
        end

        h2 = plot([], [], 
            zcolor = 50, 
            label = "    Customer ", 
            legend = :outertop, 
            colorbar = true, 
            cmap = :RdYlGn_11, 
            clims = (0,100), 
            colorbar_ticks = colorbar_ticks, 
            colorbar_title="Battery level departure (%)", 
            xticks = false, 
            yticks = false, 
            axis = false,
            legendfontsize=14, 
            linetype =:scatter, 
            foreground_color_legend = nothing, 
            markerstrokewidth = 0.05
        )

        l = @layout [grid(vertical, horizontal){0.88w} a{0.12w}]

        if horizontal == 1
            all_plots = plot(plots...,h2, layout = l,  
                size = (1000, 800), margin=8*Plots.mm, grid = false)
        else
            all_plots = plot(plots...,h2, layout = l,  
                size = (1500, 600 * vertical), margin=8*Plots.mm, grid = false)
        end
        
        display("image/png", all_plots)
    end


    """
    Plots the objective values as a function of time. If a reference value is 
    given, it is plotted together with the objectives.

    """
    function plot_objectives_iteration(
            objectives::Vector{Float64},
            comparison_value::Float64 = -1.0
        )

        n_iterations = length(objectives)
        plt = plot(0:n_iterations - 1, objectives, 
            xlabel = "Iteration", 
            ylabel = "Objective value \n(total distance traveled)", 
            ylimits = (0, 1.05 * objectives[1]), 
            label = "ALNS",
            line = (2, :solid),
            plot_title = string("Objective value as a function of the \n ",
                "number of iterations")
        )

        if comparison_value >= 0
            plot!(plt, 0:n_iterations - 1, fill(comparison_value, n_iterations), 
                label = "Reference",
                line = (2, :dash)
            )
        end
        display("image/png", plt)
    end

    """
    Plots the objective values as a function of time. If a reference value or 
    results from Gurobi are given, they are plotted together with the 
    objectives.
    
    The objectives and times vectors need to be of the same length.

    """
    function plot_objectives_time(
            objectives::Vector{Float64}, 
            times::Vector{Float64};
            reference_value::Float64 = -1.0,
            gurobi_results::Union{ResultsTypes.GurobiResults, Nothing} = nothing
        )

        plt = plot(times, objectives, 
            xlabel = "Time (s)", 
            ylabel = "Objective value \n(total distance traveled)", 
            ylimits = (0, 1.05 * objectives[1]), 
            label = "ALNS",
            line = (2, :solid),
            plot_title = "Objective value as a function of time",
            seriestype = :steppost,
            linecolor = "#1f78b4"
        )

        if reference_value >= 0
            plot!(plt, times, fill(reference_value, length(times)), 
                label = "Reference",
                line = (2, :dash),
                linecolor = "#e31a1c"
            )
        end

        if !isnothing(gurobi_results)
            times = gurobi_results.times
            plot!(plt, gurobi_results.times, gurobi_results.objectives, 
                label = "MILP",
                line = (2, :dashdot),
                seriestype = :steppost,
                linecolor = "#33a02c"
            )
        end
        display("image/png", plt)
    end

    """
    Plots the weights as a function of iteration. Works for both the remove and 
    insert operator weights.

    """
    function plot_operator_weights(
            n_iterations::Int,
            weights::Vector{Vector{Float64}},
            n_iterations_until_update::Int;
            slicing_factor_param::Int = 60
        )
        iterations = collect(0:n_iterations_until_update:n_iterations)

        if n_iterations % n_iterations_until_update != 0
            push!(iterations, n_iterations)
        end

        slicing_factor = ceil(Int, length(iterations)/slicing_factor_param)
        sliced_iterations = iterations[1:slicing_factor:end] 

        names = nothing
        title = ""
        if length(weights) == 6
            names = ["Random node", "Random route", "Worst cost route", 
                "Shortest route", "Worst cost node", "Shaw"]
            title = "Weights for remove operators \nas a function of iteration"
        else
            names = ["Greedy", "Random", "k-regret position", "k-regret route"]
            title = "Weights for insert operators \nas a function of iteration"
        end
        markers = [:circle, :square, :diamond, :cross, :xcross, :star5]
        colors = [ "#1f78b4", "#33a02c", "#fb9a99", "#e31a1c", "#a6cee3", 
            "#b2df8a"]

        plt = plot(xlabel = "Iteration", 
            ylabel = "Weights", 
            plot_title = title,
            legend = :outerright,
            top_margin=8Plots.mm)
        
        for i in eachindex(weights)
            sliced_weights = weights[i][1:slicing_factor:end]
            plot!(plt, sliced_iterations, sliced_weights,
                label = names[i],
                linewidth = 2, 
                linestyle = :solid,
                marker = markers[i],
                linecolor = colors[i],
                markercolor = colors[i]
            )
        end

        display("image/png", plt)
    end
end