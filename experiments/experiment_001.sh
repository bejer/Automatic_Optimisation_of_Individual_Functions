#!/bin/sh

experiment_work_script="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/experiments/experiment_001_compilation_and_profiling.sh"

old_state_file="experiment_001_state_old.txt"
state_file="experiment_001_state.txt"

global_flags="-O0 -O1 -O2 -O3"
rest_optcases="1 2 3 4"
function_optcases="1 2 3 4"
# Not going to iterate over the function names, therefore just "*"
function_names="*"
gprof_possibilites="yes no"

# TODO:
# - Support invoking the script multiple times (over time) without having to do the compilation process or validation process -> maybe make use of a state machine! (especially where the state can be saved).
# TODO?
# - Could make it automatically use the state files and read it in, start the optcases from where it left off ?


# Compile
# Not needed if I'm making sure this step is done manually (first/quick iteration of getting this script up and running)

# Validate - doing this in one whole step!
for gf in ${global_flags}; do
    for ro in ${rest_optcases}; do
	for fo in ${function_optcases}; do
	    for fn in ${function_names}; do
		for gp in ${gprof_possibilities}; do
		    echo "--------------------"
		    echo "gf: ${gf}"
		    echo "ro: ${ro}"
		    echo "fo: ${fo}"
		    echo "fn: ${fn}"
		    echo "gp: ${gp}"
		    ${experiment_work_script} validate "${gf}" "${ro}" "${fo}" "${fn}" "${gp}"
		done
	    done
	    ############################################################################################################################################################################################################################################################################################################ premature exit, just to show the echo's ############################################################################################################################################################################################################################################################################################################
	    exit 1
	done
    done
done

# UNCOMMENTED: Should iterate over function names at the upper level (when doing automotive_bitcount, if just going for 4 specific functions before the rest of the functions, in order of being able to get some useful data before all the data has been produced and collected!
# # Gprof profiling
# for gf in ${global_flags}; do
#     for ro in ${rest_optcases}; do
# 	for fo in ${function_optcases}; do
# 	    cp ${state_file} ${old_state_file}
# 	    echo -e "gf:${gf}\nro:${ro}\nfo:${fo}" > ${state_file}
# 	    for fn in ${function_names}; do
# 		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "yes"
# 	    done
# 	done
#     done
# done


# Oprofile profiling
# Not implemented yet!