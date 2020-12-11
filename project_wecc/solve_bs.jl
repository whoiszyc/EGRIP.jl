# The "current working directory" is very important for correctly loading modules.
# One should refer to "Section 40 Code Loading" in Julia Manual for more details.

# change the current working directory to the one containing the file
# It seems Julia will not automatically change directory based on the operating file.
cd(@__DIR__)

# We can either add EGRIP to the Julia LOAD_PATH.
push!(LOAD_PATH,"../src/")
using EGRIP
using PowerModels
# Or we use EGRIP as a module.
# include("../src/EGRIP.jl")
# using .EGRIP

# # ------------ Interactive --------------
dir_case_network = "WECC_dataset/WECC_noHVDC.raw"
dir_case_blackstart = "WECC_dataset/WECC_generator_specs.csv"
network_data_format = "psse"
dir_case_result = "results/"
t_final = 300
t_step = 50
gap = 0.5
ref, model = solve_restoration_full(dir_case_network, network_data_format, dir_case_blackstart, dir_case_result, t_final, t_step, gap)
