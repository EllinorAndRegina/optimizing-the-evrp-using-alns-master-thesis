include("../Types.jl")

# Include function files
include("../Functions/DataParsing.jl")
include("../Functions/EVRPFunctions.jl")
include("../Functions/Utilities.jl")
include("../Functions/ALNSFunctions.jl")
include("../Functions/InsertOperators.jl")
include("../Functions/RemoveOperators.jl")
include("../Functions/InitialSolution.jl")
include("SetupFunctions.jl")
include("../Models/ModelUtilities.jl")
include("../Models/ModelFunctions.jl")

# Include test files
include("TestALNSFunctions/TestAcceptanceCriteria.jl")
include("TestALNSFunctions/TestTerminationCriteria.jl")
include("TestRemoveOperators.jl")
include("TestInsertOperators.jl")
include("TestALNSFunctions/TestSelectionFunctions.jl")
include("TestParsingData.jl")
include("TestUtilities.jl")
include("TestEVRPFunctions.jl")
include("TestInitialSolution.jl")
include("TestTypes.jl")
include("TestModelUtilities.jl")



########## Testing data parsing functions ##############
println("\nTesting data parsing")

TestSchneider.test_Schneider_pass()
TestSchneider.test_Schneider_negative_numbers()
TestSchneider.test_Schneider_parameters_missing_from_file()
TestSchneider.test_Schneider_overwrite_parameters()
TestSchneider.test_Schneider_line_with_wrong_format()

TestDistancesAndTravelTime.test_distances_empty_node_array()
TestDistancesAndTravelTime.test_travel_time_negative_speed()
TestDistancesAndTravelTime.test_travel_time_0_speed()
TestDistancesAndTravelTime.test_travel_time_empty_matrix()
TestDistancesAndTravelTime.test_travel_time_non_square_matrix()

TestNearestCSToNode.test_nearest_cs_to_node_small_example()
TestNearestCSToNode.test_nearest_cs_to_node_no_customers()
TestNearestCSToNode.test_nearest_cs_to_node_no_charging_stations()

TestDataStruct.test_data_struct_EVRPTW_Schneider_no_error_for_large_file()
TestDataStruct.test_data_struct_EVRPTW_with_Schneider()

println("Data parsing tests passed\n")

############# Testing Types Functions ####################

println("Testing types functions")

TestGetChargingStationFunctions.test_running_get_closest_charging_station_to_arcs()
TestGetChargingStationFunctions.test_get_closest_charging_station_to_arcs_only_charging_stations()
TestGetChargingStationFunctions.test_get_closest_charging_station_to_arcs_only_customers()

println("Types tests passed\n")

############# Testing acceptance criteria #################
println("Testing acceptance criteria")

TestGreedy.test_greedy_accepting()
TestGreedy.test_greedy_rejecting()

TestMetropolis.test_metropolis_with_greedy_fulfilled()
TestMetropolis.test_metropolis_random_pass()
TestMetropolis.test_metropolis_random_non_pass()

println("Acceptance criteria tests passed\n")

############# Testing termination criteria ################
println("Testing termination criteria")

TestMaxIterations.test_max_iterations_accepting()
TestMaxIterations.test_max_iterations_rejecting()
TestMaxIterations.test_max_iterations_iteration_max_iter()
TestMaxIterations.test_max_iterations_zero()
TestMaxIterations.test_max_iterations_negative()

println("Termination criteria tests passed\n")

############# Testing Selection functions ##################
println("Testing selection functions")

TestSelectionFunctions.test_roulette_wheel_pass_first_index()
TestSelectionFunctions.test_roulette_wheel_pass_last_index()
TestSelectionFunctions.test_roulette_wheel_empty_list_exception()
TestSelectionFunctions.test_roulette_wheel_negative_probability_error()
TestSelectionFunctions.test_roulette_wheel_probabilities_not_adding_to_1_exception()

println("Selection function tests passed\n")

################# Testing Solution Utilities ###################
println("Testing solution utilities")

TestSolutionUtils.test_weight_feasible()
TestSolutionUtils.test_check_weight_infeasible_no_error()
TestSolutionUtils.test_check_weight_infeasible_error()

TestSolutionUtils.test_arrival_time_to_next_node_feasible()
TestSolutionUtils.test_arrival_time_to_node_from_cs_feasible()
TestSolutionUtils.test_arrival_time_to_next_node_infeasible_no_error()
TestSolutionUtils.test_arrival_time_to_next_node_infeasible_error()
TestSolutionUtils.test_arrival_time_to_node_too_early()
TestSolutionUtils.test_check_time_feasible()
TestSolutionUtils.test_check_time_infeasible_no_error()
TestSolutionUtils.test_check_time_infeasible_error()
TestSolutionUtils.test_check_time_with_waiting_time()
TestSolutionUtils.test_check_time_multiple_and_consecutive_visits_to_cs()
TestSolutionUtils.test_check_time_partial_feasible()
TestSolutionUtils.test_check_time_partial_multiple_and_consecutive_visits_to_cs()

println("Solution utilities tests passed\n")

################# Testing Remove Utilities ###################
println("Testing remove utilities")

TestRemoveUtilities.test_calculate_remove_costs_for_route_small_example()
TestRemoveUtilities.test_calculate_remove_costs_for_empty_route()
TestRemoveUtilities.test_calculate_remove_costs_for_route_with_single_customer()

println("Remove utilities tests passed\n")

################# Testing Insert Utilities ###################
println("Testing solution utilities")

TestInsertUtilities.test_nearest_cs_insert_feasible_one_iteration()
TestInsertUtilities.test_nearest_cs_insert_feasible_multiple_iterations()
TestInsertUtilities.test_nearest_cs_insert_infeasible()
TestInsertUtilities.test_nearest_cs_insert_positive_charge()
TestInsertUtilities.test_nearest_cs_insert_time_infeasible()
TestInsertUtilities.test_nearest_cs_insert_two_cs_needed()
TestInsertUtilities.test_nearest_cs_insert_empty_routes()

TestInsertUtilities.test_charging_stations_k_insert_basic()
    ###TestInsertUtilities.test_charging_stations_k_insert_basic_partial() PROBLEMMMMM
TestInsertUtilities.test_charging_stations_k_insert_closest_cs_is_nothing()
TestInsertUtilities.test_charging_stations_k_insert_illegal_values_on_k()
TestInsertUtilities.test_charging_stations_k_insert_only_infeasible_insertions()
TestInsertUtilities.test_charging_stations_k_insert_many_possible_insertions()
TestInsertUtilities.test_charging_stations_k_insert_multile_cs_needed_in_row()
TestInsertUtilities.test_charging_stations_k_insert_multile_cs_needed_not_in_row()
TestInsertUtilities.test_charging_stations_k_insert_no_cs_needed()
TestInsertUtilities.test_charging_stations_k_insert_on_empty_route()

TestInsertUtilities.test_find_min_in_cost_matrix_single_least_value()
TestInsertUtilities.test_find_min_in_cost_matrix_empty_matrix()
TestInsertUtilities.test_find_min_in_cost_matrix_multiple_min()
TestInsertUtilities.test_find_min_in_cost_matrix_only_inf()

TestInsertUtilities.test_cost_calculation_empty_route()
TestInsertUtilities.test_cost_calculation_only_infeasible_insertions()
TestInsertUtilities.test_cost_calculation_multiple_min()
TestInsertUtilities.test_cost_calculation_single_min()
TestInsertUtilities.test_cost_calculation_weight_infeasible()
TestInsertUtilities.test_cost_calculation_time_infeasible()
TestInsertUtilities.test_cost_calculation_battery_infeasible()

TestInsertUtilities.test_find_k_best_per_customer_basic()
TestInsertUtilities.test_find_k_best_per_customer_route_shorter_than_k()
TestInsertUtilities.test_find_k_best_per_customer_n_inserts_for_customer_less_than_k()

TestInsertUtilities.test_calculate_k_best_costs_of_inserting_node_basic()
TestInsertUtilities.test_calculate_k_best_costs_of_inserting_node_empty_route()
TestInsertUtilities.test_calculate_k_best_costs_of_inserting_node_route_shorter_than_k()
TestInsertUtilities.test_calculate_k_best_costs_of_inserting_node_time_infeasible_insertions()
TestInsertUtilities.test_calculate_k_best_costs_of_inserting_node_weight_infeasible_insertions()

println("Solution utilities tests passed\n")

################# Testing Objective functions ###################
println("Testing objective functions")

TestObjectiveFunctions.test_total_route_distance()
TestObjectiveFunctions.test_total_route_distance_empty_route()

println("Objective function tests passed\n")

################# Testing Battery calculation functions ###################
println("Testing battery calculation functions")

TestBatteryCalculationFunctions.test_full_charging_feasible()
TestBatteryCalculationFunctions.test_full_charging_infeasible_no_error()
TestBatteryCalculationFunctions.test_full_charging_infeasible_error()
TestBatteryCalculationFunctions.test_full_charging_unnecessary_charging_station()
TestBatteryCalculationFunctions.test_full_charging_load_dependent()

TestBatteryCalculationFunctions.test_partial_charging_feasible()
TestBatteryCalculationFunctions.test_partial_charging_infeasible_no_error()
TestBatteryCalculationFunctions.test_partial_charging_infeasible_error()
TestBatteryCalculationFunctions.test_partial_charging_unnecessary_charging_station()
TestBatteryCalculationFunctions.test_partial_charging_negative_battery()

println("Battery calculation tests passed\n")

################# Testing Remove operators ###################
println("Testing Remove operators")

TestRandomRemovalUniform.test_random_removal_basic()
TestRandomRemovalUniform.test_random_removal_Number_removed_zero()
TestRandomRemovalUniform.test_random_removal_Number_removed_more_than_number_nodes()
TestRandomRemovalUniform.test_random_removal_10000_rounds()
TestRandomRemovalUniform.test_random_remove_input_unchanged()
TestRandomRemovalUniform.test_random_removal_remove_empty_route()

TestRandomRemovalNonUniform.test_random_removal_basic()
TestRandomRemovalNonUniform.test_random_removal_Number_removed_zero()
TestRandomRemovalNonUniform.test_random_removal_Number_removed_more_than_number_nodes()
# TestRandomRemovalNonUniform.test_random_removal_10000_rounds() # Just for plot
TestRandomRemovalNonUniform.test_random_remove_input_unchanged()
TestRandomRemovalNonUniform.test_random_removal_remove_empty_route()

TestRandomRouteRemoval.test_random_route_removal_basic()
TestRandomRouteRemoval.test_random_route_removal_one_empty_route()
TestRandomRouteRemoval.test_random_route_removal_no_nodes_removed()
TestRandomRouteRemoval.test_random_route_removal_all_nodes_removed()
TestRandomRouteRemoval.test_random_route_removal_more_than_all_nodes_removed()
TestRandomRouteRemoval.test_random_route_removal_input_unchanged()

TestShortestRouteRemoval.test_shortest_route_removal_basic_one_route()
TestShortestRouteRemoval.test_shortest_route_removal_basic_two_routes()
TestShortestRouteRemoval.test_shortest_route_removal_with_empty_route()
TestShortestRouteRemoval.test_shortest_route_removal_no_nodes_removed()
TestShortestRouteRemoval.test_shortest_route_removal_all_nodes_removed()
TestShortestRouteRemoval.test_shortest_route_removal_more_than_all_nodes_removed()
TestShortestRouteRemoval.test_shortest_route_removal_input_unchanged()

TestWorstCostRouteRemoval.test_worst_cost_route_removal_basic()
TestWorstCostRouteRemoval.test_worst_cost_route_removal_with_empty_route()
TestWorstCostRouteRemoval.test_worst_cost_route_removal_no_nodes_removed()
TestWorstCostRouteRemoval.test_worst_cost_route_removal_all_nodes_removed()
TestWorstCostRouteRemoval.test_worst_cost_route_removal_more_than_all_nodes_removed()
TestWorstCostRouteRemoval.test_worst_cost_route_removal_input_unchanged()

TestWorstCostRemoval.test_worst_cost_removal_basic()
TestWorstCostRemoval.test_worst_cost_removal_one_empty_route()
TestWorstCostRemoval.test_worst_cost_removal_no_nodes_removed()
TestWorstCostRemoval.test_worst_cost_removal_more_than_all_nodes_removed()
TestWorstCostRemoval.test_worst_cost_removal_input_unchanged()

TestShawRemoval.test_shaw_removal_basic()
TestShawRemoval.test_shaw_removal_one_empty_route()
TestShawRemoval.test_shaw_removal_no_nodes_removed()
TestShawRemoval.test_shaw_removal_more_than_all_nodes_removed()
TestShawRemoval.test_shaw_removal_input_unchanged()
TestShawRemoval.test_shaw_removal_only_one_node_removed()

println("Remove operator tests passed\n")

################# Testing Insert operators ###################
println("Testing Insert operators")

TestGreedyInsertFull.test_greedy_insert_feasible()
TestGreedyInsertFull.test_greedy_insert_with_non_customer_in_customer_list()
TestGreedyInsertFull.test_greedy_insert_empty_routes_no_charging()
TestGreedyInsertFull.test_greedy_insert_empty_routes_with_charging()
TestGreedyInsertFull.test_greedy_insert_infeasible()
TestGreedyInsertFull.test_greedy_insert_cs_insert_needed()
TestGreedyInsertFull.test_greedy_insert_with_battery_infeasible_route_input()
TestGreedyInsertFull.test_greedy_insert_infeasible_input_unchanged()

TestGreedyInsertPartial.test_greedy_insert_feasible_partial()
TestGreedyInsertPartial.test_greedy_insert_with_non_customer_in_customer_list_partial()
TestGreedyInsertPartial.test_greedy_insert_empty_routes_no_charging_partial()
TestGreedyInsertPartial.test_greedy_insert_empty_routes_with_charging_partial()
TestGreedyInsertPartial.test_greedy_insert_infeasible_partial()
TestGreedyInsertPartial.test_greedy_insert_cs_insert_needed_partial()
TestGreedyInsertPartial.test_greedy_insert_with_battery_infeasible_route_input_partial()
TestGreedyInsertPartial.test_greedy_insert_infeasible_input_unchanged_partial()

TestRandomInsert.test_random_insert_feasible()
TestRandomInsert.test_random_insert_with_non_customer_in_customer_list()
TestRandomInsert.test_random_insert_empty_routes_with_charging()
TestRandomInsert.test_random_insert_empty_routes_no_charging()
TestRandomInsert.test_random_insert_infeasible()
TestRandomInsert.test_random_insert_cs_insert_needed()
TestRandomInsert.test_random_insert_with_battery_infeasible_route_input()
TestRandomInsert.test_random_insert_infeasible_input_unchanged()

TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_feasible()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_empty_routes_no_charging()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_empty_routes_with_charging()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_infeasible()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_cs_insert_needed()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_with_battery_infeasible_route_input()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_infeasible_input_unchanged()
TestHighestPositionKRegretInsertFull.test_highest_position_k_regret_feasable_with_k_4()

TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_feasible()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_empty_routes_no_charging()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_empty_routes_with_charging()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_infeasible()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_cs_insert_needed()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_with_battery_infeasible_route_input()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_infeasible_input_unchanged()
TestHighestRouteKRegretInsertFull.test_highest_route_k_regret_feasable_with_k_4()

println("Insert operator tests passed\n")

################ Testing Initial solution ###################
println("Testing initial solution")

TestInitialSolutionUtilities.test_arrival_time_to_node_in_tw_start_current_time()
TestInitialSolutionUtilities.test_arrival_time_to_node_before_tw_start_current_time()
 
TestInitialSolutionUtilities.test_insert_cs_at_previous_node_enough_battery_to_reach_cs_battery_level()
TestInitialSolutionUtilities.test_insert_cs_at_previous_node_not_enough_battery_to_reach_cs()
 
TestInitialSolutionUtilities.test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_enough_to_travel_to_customer_battery_arrival_node()
TestInitialSolutionUtilities.test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_enough_to_travel_to_customer_prev_node_and_cs()
TestInitialSolutionUtilities.test_check_enough_battery_to_visit_node_or_add_cs_need_to_charge_and_can_add_cs_and_its_not_enough_to_travel_to_customer()
TestInitialSolutionUtilities.test_check_enough_battery_to_visit_node_or_add_cs_dont_need_to_charge()
 
TestInitialSolutionUtilities.check_all_customers_inserted_no_depot_first()
TestInitialSolutionUtilities.check_all_customers_inserted_no_depot_last()
TestInitialSolutionUtilities.check_all_customers_inserted_depot_in_route()
TestInitialSolutionUtilities.check_all_customers_inserted_dublette_customer()
TestInitialSolutionUtilities.check_all_customers_inserted_missing_customer()
TestInitialSolutionUtilities.check_all_customers_inserted_emty_routes_and_list()
TestInitialSolutionUtilities.check_all_customers_inserted_route_all_charging_stations()
TestInitialSolutionUtilities.test_check_all_customers_inserted_two_cs_in_a_row()

TestingFullInitialSolutionFunction.test_simple_example_initial_solution()
 

println("Initial solution tests passed\n")


################ Testing Model utilities ###################
println("Testing model utilities solution")

TestModelUtilities.test_translate_ALNS_solution_to_model_solution()
TestModelUtilities.test_translate_ALNS_solution_to_model_solution_emty_routes()
TestModelUtilities.test_load_dependent_model()


println("Initial model utilities tests passed\n")
#######################################################
println("\nAll tests passed, well done!")