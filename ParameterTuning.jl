include("Main.jl")

using .ObjectiveFunctions
using .RechargingFunctions
using .EnergyConsumptionFunctions
using .BatteryCalculationFunctions
using .SettingTypes
using .DataStruct
using .ParsingFunctions
using .ProblemSpecifierTypes

using Plots

data_file = "Data/SchneiderEVRPTW/c101_21.txt"

mu_values = 0.05:0.05:0.5
k_cs_insert_values = 1:8
gamma_values = 0.2:0.2:2.0  # multiple!!
k_random_values = 1:8
k_regret_values = 2:6
r_values = 0.0:0.1:1.0
sigma_values = 1:3:40        # multiple!!
z = [0.01, 0.03, 0.05, 0.07, 0.1, 0.15, 0.2]
alpha_values = [0.99, 0.999, 0.99975, 0.99999]





values = r_values                    
max_time = 60
seeds = [13, 1313, 131313]

tuples = []
for (iv, value) in enumerate(values)
    println("Starting on value index: ", iv, " / ", length(values))
    println()
    i = 0
    o = 0
    for seed in seeds 
        results = main(data_file, 
            seed = seed, 
            max_time = max_time, 
            weight_update_reaction_factor = value,   
            plotting = false, 
            save_weights = false,
            problem_specifier = ProblemSpecifierTypes.load_dependent
        )
        i += length(results.objective_per_iteration)
        o += minimum(results.objective_per_iteration)
    end

    i = i/length(seeds)
    o = o/length(seeds)
    push!(tuples, (value, i, o))
end

for tup in tuples
    println("value: $(tup[1]), obj: $(tup[3]), iterations: $(tup[2])")
end

objectives = map(x->x[3], tuples)
iterations = map(x->x[2], tuples)

plt = plot(values, objectives, title = "Objectives")
display(plt)

plt2 = plot(values, iterations, title = "Iterations")
display(plt2)
