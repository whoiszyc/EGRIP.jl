
# The "current working directory" is very important for correctly loading modules.
# One should refer to "Section 40 Code Loading" in Julia Manual for more details.

# change the current working directory to the one containing the file
# It seems Julia will not automatically change directory based on the operating file.
cd(@__DIR__)

# We can either add EGRIP to the Julia LOAD_PATH.
push!(LOAD_PATH,"../../src/")
using EGRIP
# Or we use EGRIP as a module.
# include("../src/EGRIP.jl")
# using .EGRIP

# registered packages
using JuMP
using JSON
using CSV
using JuMP
using DataFrames
using Interpolations
using Distributions

# local functions
include("proj_utils.jl")

# # ------------ Load data --------------
dir_case_network = "case39.m"
dir_case_blackstart = "BS_generator.csv"
network_data_format = "matpower"
dir_case_result = "results_startup_density/"
t_final = 300
t_step = 10
gap = 0.0
nstage = Int64(t_final/t_step)
stages = 1:nstage

# plotting setup
line_style = [(0,(3,5,1,5)), (0,(5,1)), (0,(5,5)), (0,(5,10)), (0,(1,1))]
line_colors = ["b", "r", "m", "lime", "darkorange"]
line_markers = ["8", "s", "p", "*", "o"]
label_list = ["W/O Wind", "Wind: Sample 1000, Prob 0.1",
                            "Wind: Sample 1000, Prob 0.2",
                            "Wind: Sample 1000, Prob 0.3",
                            "Wind: Sample 1000, Prob 0.4"]

# ------------------- obtain approximated density function (histogram) from historical data-------------
# load real wind power data
# note that we ignore the ERCOT wind data in the version control for security
# Each time we may need to add the data folder manually
wind_data = CSV.read("../../ERCOT_wind/wind_farm3_POE.csv", DataFrame)
wind_data = convert(Matrix, wind_data)
prob = 1.0:-0.1:0.1
# construct estimated density function
wind_density = Dict()
for i in 1:size(wind_data)[1]
    wind_density[i] = density_est_from_risk(wind_data[i,:], 1.0:-0.1:0.1, 100)
end

# # ----------------- Solve the problem -------------------
test_from = 1
test_end = 5
model = Dict()
wind = Dict()
pw_sp = Dict()
wind[1] = Dict("activation"=>0, "violation_probability"=>0.00, "sample_number"=>1000, "seed"=>10050)
wind[2] = Dict("activation"=>3, "violation_probability"=>0.10, "sample_number"=>1000, "seed"=>10050)
wind[3] = Dict("activation"=>3, "violation_probability"=>0.20, "sample_number"=>1000, "seed"=>10050)
wind[4] = Dict("activation"=>3, "violation_probability"=>0.30, "sample_number"=>1000, "seed"=>10050)
wind[5] = Dict("activation"=>3, "violation_probability"=>0.40, "sample_number"=>1000, "seed"=>10050)
for i in test_from:test_end
ref, model[i], pw_sp[i] = solve_startup(dir_case_network, network_data_format,
                                dir_case_blackstart, dir_case_result,
                                t_final, t_step, gap, wind[i], wind_density)
end

# --------- retrieve results and plotting ---------
Pg_seq = Dict()
Pd_seq = Dict()
Pw_seq = Dict()
w_seq = Dict()
for i in test_from:test_end
    Pg_seq[i], Pd_seq[i], Pw_seq[i], w_seq[i] = get_value(model[i], stages)
end

# plot generator power
using PyPlot
PyPlot.pygui(true) # If true, return Python-based GUI; otherwise, return Julia backend
rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["font.family"] = "Arial"
fig, ax = PyPlot.subplots(figsize=(12, 5))
for i in test_from:test_end
    ax.plot(t_step:t_step:t_final, (Pg_seq[i])*100,
                color=line_colors[i],
                linestyle = line_style[i],
                marker=line_markers[i],
                linewidth=4,
                markersize=4,
                label=label_list[i])
end
ax.set_title("Generator Capacity", fontdict=Dict("fontsize"=>20))
ax.legend(loc="lower right", fontsize=20)
ax.xaxis.set_label_text("Time (min)", fontdict=Dict("fontsize"=>20))
ax.yaxis.set_label_text("Power (MW)", fontdict=Dict("fontsize"=>20))
ax.xaxis.set_tick_params(labelsize=20)
ax.yaxis.set_tick_params(labelsize=20)
fig.tight_layout(pad=0.2, w_pad=0.2, h_pad=0.2)
PyPlot.show()
sav_dict = string(pwd(), "/", dir_case_result, "fig_gen_startup_fix_sample_gen.png")
PyPlot.savefig(sav_dict)

# plot load power
PyPlot.pygui(true) # If true, return Python-based GUI; otherwise, return Julia backend
rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["font.family"] = "Arial"
fig, ax = PyPlot.subplots(figsize=(12,5))
for i in test_from:test_end
    ax.plot(t_step:t_step:t_final, (Pd_seq[i])*100,
                color=line_colors[i],
                linestyle = line_style[i],
                marker=line_markers[i],
                linewidth=4,
                markersize=4,
                label=label_list[i])
end
ax.set_title("Load Trajectory", fontdict=Dict("fontsize"=>20))
ax.legend(loc="lower right", fontsize=20)
ax.xaxis.set_label_text("Time (min)", fontdict=Dict("fontsize"=>20))
ax.yaxis.set_label_text("Power (MW)", fontdict=Dict("fontsize"=>20))
ax.xaxis.set_tick_params(labelsize=20)
ax.yaxis.set_tick_params(labelsize=20)
fig.tight_layout(pad=0.2, w_pad=0.2, h_pad=0.2)
PyPlot.show()
sav_dict = string(pwd(), "/", dir_case_result, "fig_gen_startup_fix_sample_load.png")
PyPlot.savefig(sav_dict)

# plot system available capacity
PyPlot.pygui(true) # If true, return Python-based GUI; otherwise, return Julia backend
rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["font.family"] = "Arial"
fig, ax = PyPlot.subplots(figsize=(12, 5))
for i in test_from:test_end
    ax.plot(t_step:t_step:t_final, (Pg_seq[i] + Pw_seq[i] - Pd_seq[i])*100,
                color=line_colors[i],
                linestyle = line_style[i],
                marker=line_markers[i],
                linewidth=4,
                markersize=4,
                label=label_list[i])
end
ax.set_title("System Capacity", fontdict=Dict("fontsize"=>20))
ax.legend(loc="upper left", fontsize=20)
ax.xaxis.set_label_text("Time (min)", fontdict=Dict("fontsize"=>20))
ax.yaxis.set_label_text("Power (MW)", fontdict=Dict("fontsize"=>20))
ax.xaxis.set_tick_params(labelsize=20)
ax.yaxis.set_tick_params(labelsize=20)
fig.tight_layout(pad=0.2, w_pad=0.2, h_pad=0.2)
PyPlot.show()
sav_dict = string(pwd(), "/", dir_case_result, "fig_gen_startup_fix_sample_cap.png")
PyPlot.savefig(sav_dict)

# wind dispatch command
wind_data_POE_WF3 = CSV.read("../../ERCOT_wind/wind_farm3_POE.csv", DataFrame)
wind_data_POE_WF3 = convert(Matrix, wind_data)
PyPlot.pygui(true) # If true, return Python-based GUI; otherwise, return Julia backend
rcParams = PyPlot.PyDict(PyPlot.matplotlib."rcParams")
rcParams["font.family"] = "Arial"
fig, ax = PyPlot.subplots(figsize=(12, 5))
# for i in 1:size(wind_data_POE_WF3)[2]
#     ax.plot(t_step:t_step:t_final, wind_data_POE_WF3[1:1:30, i], color="k", linewidth=0.5)
# end
# for i in test_from:test_end
#     if i >= 2
#         for st in 1:wind[i]["sample_number"]
#             if value(model[i][:w][st]) > 0
#                 ax.plot(t_step:t_step:t_final, (pw_sp[i][st])*100, linewidth=1.5, alpha=0.9)
#             else
#                 ax.plot(t_step:t_step:t_final, (pw_sp[i][st])*100, linewidth=1.0, alpha=0.3)
#             end
#         end
#     end
# end
for i in test_from:test_end
    ax.plot(t_step:t_step:t_final, (Pw_seq[i])*100,
                color=line_colors[i],
                linestyle = line_style[i],
                marker=line_markers[i],
                linewidth=4,
                markersize=4,
                label=label_list[i])
end
ax.set_title("Wind Dispatch", fontdict=Dict("fontsize"=>20))
ax.legend(loc="upper right", fontsize=20)
ax.xaxis.set_label_text("Time (min)", fontdict=Dict("fontsize"=>20))
ax.yaxis.set_label_text("Power (MW)", fontdict=Dict("fontsize"=>20))
ax.xaxis.set_tick_params(labelsize=20)
ax.yaxis.set_tick_params(labelsize=20)
fig.tight_layout(pad=0.2, w_pad=0.2, h_pad=0.2)
PyPlot.show()
sav_dict = string(pwd(), "/", dir_case_result, "fig_gen_startup_fix_sample_wind_dispatch.png")
PyPlot.savefig(sav_dict)

# # ------------------- save data into json --------------------
# using JSON
# json_string = JSON.json(Pw_seq)
# open("results_startup/data_gen_startup_real_data_wind.json","w") do f
#   JSON.print(f, json_string)
# end
# json_string = JSON.json(Pg_seq)
# open("results_startup/data_gen_startup_real_data_gen.json","w") do f
#   JSON.print(f, json_string)
# end
# json_string = JSON.json(Pd_seq)
# open("results_startup/data_gen_startup_real_data_load.json","w") do f
#   JSON.print(f, json_string)
# end
