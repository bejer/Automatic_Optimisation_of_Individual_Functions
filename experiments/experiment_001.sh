#!/bin/sh

# TODO:
# When using asterix '*' then it has to be surrounded by a pair of ", but if having multiple names in the variable then it shouldn't be surrounded by ", because then it will just see it all as one item/element.!

experiment_work_script="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/experiments/experiment_001_compilation_and_profiling.sh"

old_state_file="experiment_001_state_old.txt"
state_file="experiment_001_state.txt"

#global_flags="\"-O0\" \"-O1\" \"-O2\" \"-O3\""
global_flags="-O0 -O1 -O2 -O3"
rest_optcases="1 2 3 4"
function_optcases="1 2 3 4"
# Not going to iterate over the function names, therefore just "*"
function_names="*"
gprof_possibilities="yes no"

# TODO:
# - Support invoking the script multiple times (over time) without having to do the compilation process or validation process -> maybe make use of a state machine! (especially where the state can be saved).
# TODO?
# - Could make it automatically use the state files and read it in, start the optcases from where it left off ?


# Compile
# Not needed if I'm making sure this step is done manually (first/quick iteration of getting this script up and running)

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

# COMMENTED OUT: running this script again after the validation has taken place - no need to validate more than once
# # Validate - doing this in one whole step!
# for gf in ${global_flags}; do
#     for ro in ${rest_optcases}; do
#  	for fo in ${function_optcases}; do
# 	    # Quick fix for having * in function names!
#  	    for fn in "${function_names}"; do
#     		for gp in ${gprof_possibilities}; do
# 		    if [ ${gf} == "-O0" ]; then
# 			if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
# 			    # Skip this, as there are no valid binaries for these combinations
# 			    continue
# 			fi
# 		    fi
#     		    # echo "--------------------"
#     		    # echo "gf: ${gf}"
#     		    # echo "ro: ${ro}"
#     		    # echo "fo: ${fo}"
#     		    # echo "fn: ${fn}"
#     		    # echo "gp: ${gp}"
#     		    ${experiment_work_script} validate "${gf}" "${ro}" "${fo}" "${fn}" "${gp}" || my_error "The validation process was not successful!"
#     		done
#  	    done
#  	done
#     done
# done


# COMMENTED OUT: Because it needed to be quickly adjusted for working with my states (resuming from a specific hardcoded/manually set point.
# # # Gprof profiling
# # OBS: hardcoded for the program 'automotive_bitcount' !
# # Start with getting measurements for these 4 functions
# function_names="bit_shifter bit_count ntbl_bitcnt main1"
# for fn in ${function_names}; do
#     for gf in ${global_flags}; do
# 	for ro in ${rest_optcases}; do
# 	    for fo in ${function_optcases}; do
# 		if [ ${gf} == "-O0" ]; then
# 		    if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
# 			    # Skip this, as there are no valid binaries for these combinations
# 			continue
# 		    fi
# 		fi
# 		cp ${state_file} ${old_state_file}
# 		echo -e "gf:${gf}\nro:${ro}\nfo:${fo}\nfn:${fn}" > ${state_file}
# 		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "yes"
# 	    done
# 	done
#     done
# done

# ############################################################
# ############################################################
# # Just run this part again to complete the measurements for the 5th function. (I have updated this part to work from where I stopped it!)
# ############################################################
# ############################################################
# # Manually set up to continue from where I stopped it!
# #my_function_names="bit_count"
# my_function_names="bitcount"
# my_global_flags="-O3"
# # I have to redo some for quickly setting this up - since it was doing -O3 in global flags (last iteration in that for loop and only for one function, I get to only redo the binaries with -O3 in global flags that were profiled (not all the binaries with -O{0..2} in global_flags).
# for fn in ${my_function_names}; do
#     for gf in ${my_global_flags}; do
# 	for ro in ${rest_optcases}; do
# 	    for fo in ${function_optcases}; do
# 		if [ ${gf} == "-O0" ]; then
# 		    if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
# 			    # Skip this, as there are no valid binaries for these combinations
# 			continue
# 		    fi
# 		fi
# 		cp ${state_file} ${old_state_file}
# 		echo -e "gf:${gf}\nro:${ro}\nfo:${fo}\nfn:${fn}" > ${state_file}
# 		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "yes"
# 	    done
# 	done
#     done
# done



# # # Gprof profiling
# # OBS: hardcoded for the program 'automotive_bitcount' !
# # Start with getting measurements for these 4 functions -> now 5 functions (added bitcount to the list!)
# function_names="AR_btbl_bitcount ntbl_bitcount BW_btbl_bitcount"
# for fn in ${function_names}; do
#     for gf in ${global_flags}; do
# 	for ro in ${rest_optcases}; do
# 	    for fo in ${function_optcases}; do
# 		if [ ${gf} == "-O0" ]; then
# 		    if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
# 			    # Skip this, as there are no valid binaries for these combinations
# 			continue
# 		    fi
# 		fi
# 		cp ${state_file} ${old_state_file}
# 		echo -e "gf:${gf}\nro:${ro}\nfo:${fo}\nfn:${fn}" > ${state_file}
# 		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "yes"
# 	    done
# 	done
#     done
# done


# ## TEST!!!! - To see how oprofile works when compiling the binaries without debugging information - it appears that oprofile can profile the individual functions without debugging information enabled.
# function_names="bit_shifter bit_count ntbl_bitcnt main1 bitcount AR_btbl_bitcount ntbl_bitcount BW_btbl_bitcount"
# my_global_flags="-O3"
# my_rest_optcases="4"
# my_function_optcases="4"
# for fn in ${function_names}; do
#     for gf in ${my_global_flags}; do
# 	for ro in ${my_rest_optcases}; do
# 	    for fo in ${my_function_optcases}; do
# 		if [ ${gf} == "-O0" ]; then
# 		    if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
# 			    # Skip this, as there are no valid binaries for these combinations
# 			continue
# 		    fi
# 		fi
# 		cp ${state_file} ${old_state_file}
# 		echo -e "gf:${gf}\nro:${ro}\nfo:${fo}\nfn:${fn}" > ${state_file}
# 		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "no"
# 	    done
# 	done
#     done
# done
# ## TEST!!!!
#exit 1

# Oprofile profiling
# Manually setting function names, to make sure the 4 first functions will be profiled first.
function_names="bit_shifter bit_count ntbl_bitcnt main1 bitcount AR_btbl_bitcount ntbl_bitcount BW_btbl_bitcount"
for fn in ${function_names}; do
    for gf in ${global_flags}; do
	for ro in ${rest_optcases}; do
	    for fo in ${function_optcases}; do
		if [ ${gf} == "-O0" ]; then
		    if [ ${ro} -gt 1 ] || [ ${fo} -gt 1 ]; then
			    # Skip this, as there are no valid binaries for these combinations
			continue
		    fi
		fi
		cp ${state_file} ${old_state_file}
		echo -e "gf:${gf}\nro:${ro}\nfo:${fo}\nfn:${fn}" > ${state_file}
		${experiment_work_script} profile "${gf}" "${ro}" "${fo}" "${fn}" "no"
	    done
	done
    done
done
