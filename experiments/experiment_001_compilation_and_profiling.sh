#!/bin/sh

# Maybe this script should have an argument: compile|profile    they share some of the same functions and information gathering, but maybe it shouldn't recompile everything when just doing a new collecting of samples or preparing the samples for further processing. Ideally the collecting of samples should just be run once for each program (while the computer/environment is idle), so processing of the samples collected should not alter/modify the already gathered samples/data... [in other words...]

# TODO:
#  - Should the binaries be compiled with '-g' for debugging information - it is activated with -pg='-p -g', but how about when looking at oprofile?
#  - Not registering errors with compilations and/or other errors and problems - would be nice to do something when they appear, e.g. notify the user instead of silently keep running (important when doing automation - else errors will just go unnoticed)

# Requires a 'my_program_wrapper.sh' script that takes the arguments "build, build_gprof, cleanup, execute".
# Assumes that the current directory is the place where the program is located and all the files are at the top level and such.

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

function my_alert () {
    # Play some sound or beeping to let me know that something went wrong!
    echo "You need to implement the my_alert functionality to also make some sound/noise! - FIX IT!"
    echo "My Alert: ${1}"
    exit 2
}

############################################################
# Global variables
############################################################
# Optcases
optcases_location="${HOME}/Temp/master_thesis_profiling/master-thesis/optcases"
# Program
program_name_file="program_name.txt"
[ -f ${program_name_file} ] || my_error "There is no file `pwd`/${program_name_file} - fix it."
program_name=`cat ${program_name_file}`
# Program input
input_set_file="input_set_4_items.txt"
# Data gathering
# times_per_input_element is changed from 5 to 2, because the overall execution time had to be reduced in order of being able to actually run and profile the binaries within a "short" time period of 2-4 days.
times_per_input_element=2
number_of_samples=20
# Validation
valid_output_file="valid_output_for_input_set_4_items_${times_per_input_element}_runs_each.txt"

# Location for additional functions for 'bc'
bc_functions="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/experiments/useful_functions.bc"

############################################################
# Functions related to compilation
############################################################

# $1=executable_name
function compile_with_save_executed_passes_gprof () {
    echo "----- Compiling with save executed passes - gprof -----"
    # Setup the environment within a 'new' shell to avoid leaking the environment variables.
    (
	. ${HOME}/Temp/ctuning/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1_with_ccc-framework/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1/gcc_ici_environment_save_passes.sh
	./my_program_wrapper.sh cleanup
	./my_program_wrapper.sh build_gprof ${1} ""
    )
}

# $1=executable_name, $2=global_flags
function compile_with_substitute_passes_gprof () {
    echo "----- Compiling with substituted passes - gprof -----"
    (
	. ${HOME}/Temp/ctuning/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1_with_ccc-framework/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1/gcc_ici_environment_substitute_passes.sh
	./my_program_wrapper.sh cleanup
	./my_program_wrapper.sh build_gprof ${1} "${2}"
    )
}

# $1=executable_name, $2=global_flags
function compile_with_substitute_passes () {
    echo "----- Compiling with substituted passes -----"
    (
	. ${HOME}/Temp/ctuning/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1_with_ccc-framework/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1/gcc_ici_environment_substitute_passes.sh
	./my_program_wrapper.sh cleanup
	./my_program_wrapper.sh build ${1} "${2}"
    )
}

# $1=optcase_number
function setup_rest_optcases () {
    for l in `ls ici_passes_function.*.txt`; do
	cp ${optcases_location}/optcase_${1}.txt ${l}
    done
}

# $1=function_name, $2=optcase_number
function setup_function_optcase () {
    cp ${optcases_location}/optcase_${2}.txt ici_passes_function.${1}.txt
}

# Contains hardcoded information about optcases (their numbers 1-4 and what passes are saved in optcase_<number>.txt)
function generate_function_specific_binaries () {
    # This function contains quite some hardcoded information - such as wanted/used optcases and their numbers

    # Adding global flags - the flags has to be valid file name segments as they are just added between a pair of '_'
    for global_flags in "-O0" "-O1" "-O2" "-O3"; do

    for rest_optcase in `seq 1 4`; do
	for function_optcase in `seq 1 4`; do
	    # Special case for global flags and invalid compilation process
	    # Hmm I can't build a correct syntax if case (doing what I want) - so nesting it
	    if [ ${global_flags} == "-O0" ]; then
		# I seem to not be able to do a proper if case... - test this one else look up how else to use || - does it work with && ? :/
		if [ ${rest_optcase} -gt 1 ] || [ ${function_optcase} -gt 1 ]; then
		    echo "DEBUG: Inside if in generate_function_specific_binaries: global_flags=${global_flags} rest_optcase=${rest_optcase} function_optcase=${function_optcase}"
		    continue
		fi
	    fi
	    echo "DEBUG: going to generate binaries for global_flags=${global_flags} rest_optcase=${rest_optcase} function_optcase=${function_optcase}"
	    for function_name in `cat ${obtained_function_names_file}`; do
		# This step also resets the previous function specific passes (although doing more work than necessary for the ease of writing this script)
		setup_rest_optcases ${rest_optcase}
		setup_function_optcase "${function_name}" ${function_optcase}

		echo "DEBUG: compiling with substitute passes gprof: rest_optcase: ${rest_optcase} function_optcase: ${function_optcase} for function ${function_name}..."
		compile_with_substitute_passes_gprof "${program_name}_global_flags_${global_flags}_rest_optcase_${rest_optcase}_function_optcase_${function_optcase}_function_${function_name}_gprof_yes.out" "${global_flags}"
		echo "DEBUG: compiling with substitute passes: rest_optcase: ${rest_optcase} function_optcase: ${function_optcase} for function ${function_name}..."
		compile_with_substitute_passes "${program_name}_global_flags_${global_flags}_rest_optcase_${rest_optcase}_function_optcase_${function_optcase}_function_${function_name}_gprof_no.out" "${global_flags}"
	    done
	done
    done

    done
}

############################################################
# Functions related to profiling
############################################################
# $1=executable_name, $2=name_for_gmon.sum, $3=file_to_place_obtained_functions_in
function obtain_function_names_from_gprof () {
    echo "----- Obtaining function names - gprof -----"
    [ -f ${2} ] || my_error "No such gmon.sum file `pwd`/${1} when trying to obtain function names from gprof."
    [ -f ${3} ] && rm ${3}
    gprof -bp ${1} ${2} | awk -F ' ' '$7 != "name" && $7 != "" { print $7 ; }' > ${3}.tmp
    cat ${3}.tmp | sort -u > ${3}
    rm ${3}.tmp
}

# $1=executable_name, $2=name_for_gmon.sum
function run_and_gprof_profile () {
#    echo "----- Running and profiling the program - gprof -----"
    # Test to make sure there are 4 elements (inputs) in the file
    [ -f ${input_set_file} ] || my_error "There is no input file `pwd`/${input_set_file} - fix the problem."
    input_elements=`wc -l ${input_set_file} | awk -F ' ' '{ print $1 ; }'`
    [ ${input_elements} -eq 4 ] || my_error "The specified input file `pwd`/${input_set_file} does not contain 4 elements"
    # Clean up gmon.sum from other summings
    [ -f gmon.sum ] && rm gmon.sum
    for i in `seq 1 ${input_elements}`; do
	input_line=`awk -F ' ' "NR==${i} { print ; }" ${input_set_file}`
#	echo "i: ${i} input_line: ${input_line}" # debug echo
	for j in `seq 1 ${times_per_input_element}`; do
	    # Not looking at the produced results (such a hook / fail-test can be added in a later iteration)
	    # Maybe go through the wrapper for executing the program, given that there should be some program specific concerns, such as environment variables or other dependencies...
	    ./${1} "${input_line}" > /dev/null
	    # gprof summing
	    if [ -f gmon.sum ]; then
		gprof -s ${1} gmon.out gmon.sum
	    else
		gprof -s ${1} gmon.out
	    fi
	done
    done

    mv gmon.sum ${2}
}

# $1=executable_name
function setup_oprofile () {
    # Make nmi_watchdog not use the counter resource. Using sudo, so to avoid having to manually type in the password, set up sudo to automatically allow the tee command on that particular file.
    echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog
    # Reset session
    sudo opcontrol --reset

    # Start oprofiling
    sudo opcontrol --no-vmlinux --image=${1}
    sudo opcontrol --start-daemon # To avoid profiling the daemon startup (not that necessary here)
}

function shutdown_oprofile () {
    sudo opcontrol --shutdown
}

# $1=executable_name, $2=name_for_oprofile_results
function run_and_oprofile_profile () {
    # This function requires superuser privileges (for using oprofile)
    # Using 'sudo' to get root privileges. When automating the task it can be advantageous to not require a password for sudo'ing the command 'opcontrol' - usually set within /etc/sudoers (edited through visudo).
#    echo "----- Running and profiling the program - oprofile -----"
    # If the oprofile session already exists it simply throws away the new measurements.
    # So do manual removal of the sessions - have to be root/sudo to do it... not sure how reliable /etc/sudoers is with rm (-r) commands...

    # Test to make sure there are 4 elements (inputs) in the file
    [ -f ${input_set_file} ] || my_error "There is no input file `pwd`/${input_set_file} - fix the problem."
    input_elements=`wc -l ${input_set_file} | awk -F ' ' '{ print $1 ; }'`
    [ ${input_elements} -eq 4 ] || my_error "The specified input file `pwd`/${input_set_file} does not contain 4 elements"
    # Prepare oprofile
    setup_oprofile "${1}"
    # Adding a sleep just to be sure the daemon setup is done and settled or something like that.
    sleep 1
    sudo opcontrol --start

    for i in `seq 1 ${input_elements}`; do
	input_line=`awk -F ' ' "NR==${i} { print ; }" ${input_set_file}`
	for j in `seq 1 ${times_per_input_element}`; do
	    ./${1} "${input_line}" > /dev/null
	done
    done

    # Trying to force a dump, to see if that will give more similar output/measurements
    sudo opcontrol --dump
    # Save the accumulated oprofile information
    sudo opcontrol --save="${2}"
    shutdown_oprofile
}

# $1=number_of_samples, $2=global_flag, $3=rest_optcase, $4=function_optcase, $5=function_name, $6=gprof_yes_or_no
function run_and_profile_function_specific_optimised_binaries () {
    echo "----- Running and profiling the function specific optimised binaries -----"
    # I know the naming scheme and can just get a list of the binaries and the name for gmon.sum can contain the binary name that produced the profiling information.
    if [ "${6}" == "yes" ]; then
	for binary in `ls ${program_name}_global_flags_${2}_rest_optcase_${3}_function_optcase_${4}_function_${5}_gprof_yes.out`; do
	    for i in `seq 1 ${1}`; do
		run_and_gprof_profile ${binary} "${binary}_gmon_${i}.sum"
	    done
	done
    else
	[ "${6}" == "no" ] || my_error "The gprof/profiling argument is neither 'yes' or 'no'..."
	for binary in `ls ${program_name}_global_flags_${2}_rest_optcase_${3}_function_optcase_${4}_function_${5}_gprof_no.out`; do
	    for i in `seq 1 ${1}`; do
		run_and_oprofile_profile ${binary} "${binary}_oprofile_${i}"
	    done
	done
    fi
}
 
########## WORKAROUND: getting more samples ##########
# $1=number_of_samples, $2=global_flag, $3=rest_optcase, $4=function_optcase, $5=function_name, $6=gprof_yes_or_no
function run_and_profile_function_specific_optimised_binaries_more_samples () {
    echo "----- Running and profiling the function specific optimised binaries -----"
    # I know the naming scheme and can just get a list of the binaries and the name for gmon.sum can contain the binary name that produced the profiling information.
    if [ "${6}" == "yes" ]; then
	for binary in `ls ${program_name}_global_flags_${2}_rest_optcase_${3}_function_optcase_${4}_function_${5}_gprof_yes.out`; do
	    for i in `seq 21 ${1}`; do
		run_and_gprof_profile ${binary} "${binary}_gmon_${i}.sum"
	    done
	done
    else
	[ "${6}" == "no" ] || my_error "The gprof/profiling argument is neither 'yes' or 'no'..."
	for binary in `ls ${program_name}_global_flags_${2}_rest_optcase_${3}_function_optcase_${4}_function_${5}_gprof_no.out`; do
	    for i in `seq 21 ${1}`; do
		run_and_oprofile_profile ${binary} "${binary}_oprofile_${i}"
	    done
	done
    fi
}
########## END OF WORKAROUND: getting more samples ##########
 

############################################################
# Compilation step
############################################################
function do_compile () {
    # Initial setup to obtain a list of used function names
    executable_name="${program_name}_save_executed_passes_gprof.out"
    compile_with_save_executed_passes_gprof ${executable_name}
    # setup_rest_optcases copies the specified optcase to all the passes files
    setup_rest_optcases "1"
    executable_name="${program_name}_substitute_passes_gprof.out"
    compile_with_substitute_passes_gprof ${executable_name}
    gmon_sum_name="experiment_001_gmon_sum_for_obtaining_function_names.sum"
    run_and_gprof_profile ${executable_name} ${gmon_sum_name}
    # Not considering the case where different flags/optimisation levels can cause different functions to be called (especially if the source code got some ifdef's that manipulate the source parsing according to the flags specified to the compiler). However the obtained function names are for the "(program) default" flags.
    # For every optimisation/'set of flags' that are tried, the function names could be obtained and compared to the default obtained function names - and cause an alert if they differ [if there should be cases where they are different either ignore it or investigate it further].
    obtained_function_names_file="experiment_001_obtained_function_names.txt"
    obtain_function_names_from_gprof ${executable_name} ${gmon_sum_name} ${obtained_function_names_file}


# TODO:
# Here to manually affect the function list!
# Make a copy of this particular function and call it something similar with and extra argument containing the function name?


    # The "actual" compilation
    generate_function_specific_binaries
}

############################################################
# Validation step - make sure the generated binaries produce correct results
############################################################
# $1=global_flag, $2=rest_optcase, $3=function_optcase, $4=function_name, $5=gprof_yes_or_no
function do_validate () {
    [ -f ${valid_output_file} ] || my_error "There is no file with valid output, ${valid_output_file} - fix the problem."
    tmp_validation_output_file="tmp_validation_output.txt"
    malfunctioned_binaries_file="malfunctioned_binaries.txt"
    # Remove the file containing binary names for malfunctioned binaries
    [ -f ${malfunctioned_binaries_file} ] && rm ${malfunctioned_binaries_file}

    # Test to make sure there are 4 elements (inputs) in the file
    [ -f ${input_set_file} ] || my_error "There is no input file `pwd`/${input_set_file} - fix the problem."
    input_elements=`wc -l ${input_set_file} | awk -F ' ' '{ print $1 ; }'`
    [ ${input_elements} -eq 4 ] || my_error "The specified input file `pwd`/${input_set_file} does not contain 4 elements"
    for binary in `ls ${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}.out`; do
	[ -f ${tmp_validation_output_file} ] && rm ${tmp_validation_output_file}
	for i in `seq 1 ${input_elements}`; do
	    input_line=`awk -F ' ' "NR==${i} { print ; }" ${input_set_file}`
	    for j in `seq 1 ${times_per_input_element}`; do
		./${binary} "${input_line}" >> ${tmp_validation_output_file}
	    done
	done
	# Compare using diff - alert is something is wrong and record the binary that caused the accident -> maybe just output the binary name to a file and keep going - so it is recording all the binaries that did wrong
	diff ${tmp_validation_output_file} ${valid_output_file} || echo "${binary}" >> ${malfunctioned_binaries_file}
    done

    # A bit of clean up
    [ -f ${tmp_validation_output_file} ] && rm ${tmp_validation_output_file}
    # If running with gprof then remove the generated gmon.out file
    if [ "$5" == "yes" ]; then
	[ -f gmon.out ] && rm gmon.out
    fi

    # Check if there are malfunctioned binaries
    if [ -f ${malfunctioned_binaries_file} ]; then
	my_alert "One or more binaries didn't produce the correct results - see ${malfunctioned_binaries_file} for more information on which binaries caused this alert."
    fi
}

############################################################
# Profiling step
############################################################
# $1=global_flag, $2=rest_optcase, $3=function_optcase, $4=function_name, $5=gprof_yes_or_no
function do_profile () {
    run_and_profile_function_specific_optimised_binaries ${number_of_samples} "${1}" "${2}" "${3}" "${4}" "${5}"
}

########## WORKAROUND: getting more samples ##########
# $1=global_flag, $2=rest_optcase, $3=function_optcase, $4=function_name, $5=gprof_yes_or_no
function do_profile_more_samples () {
    run_and_profile_function_specific_optimised_binaries_more_samples ${number_of_samples} "${1}" "${2}" "${3}" "${4}" "${5}"
}
########## END OF WORKAROUND: getting more samples ##########

############################################################
# Data processing step
############################################################
# $1=global_flag, $2=rest_optcase, $3=function_optcase, $4=function_name, $5=gprof_yes_or_no, $6=path_to_place_raw_measurement_files
#function generate_raw_measurement_files () {
function do_process_data () {
    # It would be nice to get the "base name" and use the number_of_samples to get sample 1 first and up to 20 (although maybe not that important...)

    # Produce raw measurement files - like in the pilot experiment scripts
#    echo "Not fully implemented yet!"
#    exit 1

    [ -d ${6} ] || my_error "The supplied path, to place raw measurement files in, does not exist."

    [ -f ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt ] && mv ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt.bac

    # DISCLAIMER: This version requires to know the function names, as they are supposed to be given as arguments to this function! - maybe the automating of function names should be done in the script that is invoking this script - instead of placing the logic to do so here.
    
    if [ "${5}" == "yes" ]; then
	# Gprof version
	for sample in `seq 1 ${number_of_samples}`; do
	    gprof -bp ${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}.out ${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}.out_gmon_${sample}.sum | awk -F ' ' "\$7 == \"${4}\" { print \$3; }" >> ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt
	done
#    ${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}.out

    else
	# Oprofile version
	[ "${5}" == "no" ] || my_error "Apparently the data to be processed are neither gprof or non-gprof data."
	for sample in `seq 1 ${number_of_samples}`; do
	    # Using a session dir different from the default one. (This is a work around, due to 'too many files - no space left on device' error.)
	    opreport --session-dir=${HOME}/Temp/oprofile_sessions/${program_name} --symbols session:${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}.out_oprofile_${sample} | awk -F ' ' "\$3 == \"${4}\" { print \$1; }" >> ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt
	done
    fi

    # Given that everything went well, delete the backup (old file)
    [ -f ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt.bac ] && rm ${6}/${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt.bac
}

############################################################
# Testing for outliers
############################################################
# $1=global_flag, $2=rest_optcase, $3=function_optcase, $4=function_name, $5=gprof_yes_or_no, $6=path_to_find_the_raw_measurement_files, $7=threshold_for_deviation=integer, $8=place_to_put_measurements_with_outlier
function do_test_for_outlier () {
    [ -f ${bc_functions} ] || my_error "The file with useful bc functions '${bc_functions}' is missing - fix it."

    [ -d ${6} ] || my_error "The supplied path, to where the raw measurement files can be found, does not exist."
    pushd .
    cd ${6}

    for measurement_file in `ls ${program_name}_global_flags_${1}_rest_optcase_${2}_function_optcase_${3}_function_${4}_gprof_${5}_raw_samples_${number_of_samples}.txt`; do
	median_point=`expr ${number_of_samples} / 2 + 1`
	pseudo_median=`cat ${measurement_file} | sort -g | awk -F ' ' "NR == ${median_point} { print ; }"`
	# Using absolute value for max_deviation (easier comparisons)
	max_deviation=0
	for measurement in `cat ${measurement_file}`; do
	    # Calculate the %-wise deviation - as an absolute value
	    deviation=`echo "scale=10; dev = ((${measurement} - ${pseudo_median}) / ${pseudo_median}) * 100; round_to_integer(abs(dev))" | bc ${bc_functions}`
	    [ ${deviation} -gt ${max_deviation} ] && max_deviation=${deviation}
	done
	if [ ${max_deviation} -ge ${7} ]; then
	    echo "${max_deviation}:${measurement_file}" >> ${8}
	fi
    done

    popd
}

############################################################
# Main part - controlling what step to do
############################################################
function show_help () {
    echo "This script supports the following modes {compile|validate|profile|process_data|test_for_outlier}."
    echo "The steps {validate|profile} takes the following arguments:"
    echo "<global_flags> <rest_optcase> <function_optcase> <function_name> <gprof_no_or_yes>"
    echo "The step {process_data} takes the following arguments:"
    echo "<global_flags> <rest_optcase> <function_optcase> <function_name> <gprof_no_or_yes> <path_to_place_processed_data_in>"
    echo "The step {test_for_outlier} takes the following arguments:"
    echo "<global_flags> <rest_optcase> <function_optcase> <function_name> <gprof_no_or_yes> <path_to_find_the_raw_measurement_files> <threshold_for_deviation - needs to be an integer> <place_to_put_measurements_with_outlier - should be an absolute path including filename>"
    exit 1
}

# There could be extra arguments to specify combinations to compile or which profiler to use (e.g. just want the gprof data) and likewise for the processing of data.
case "${1}" in
    "compile")
	do_compile
	;;
    "validate")
	if [ ! $# -eq 6 ]; then
	    echo "argument numbers: $#"
	    echo "argument 2: ${2}"
	    echo "argument 3: ${3}"
	    echo "argument 4: ${4}"
	    echo "argument 5: ${5}"
	    echo "argument 6: ${6}"

	    echo "Error: validate needs 6 arguments"
	    show_help
	fi
	do_validate "${2}" "${3}" "${4}" "${5}" "${6}"
	;;
    "profile")
	if [ ! $# -eq 6 ]; then
	    echo "Error: profile needs 6 arguments"
	    show_help
	fi
	do_profile "${2}" "${3}" "${4}" "${5}" "${6}"
	;;
########## WORKAROUND: getting more samples ##########
    "profile_more_samples")
	if [ ! $# -eq 6 ]; then
	    echo "Error: profile_more_samples needs 6 arguments"
	    show_help
	fi
	do_profile_more_samples "${2}" "${3}" "${4}" "${5}" "${6}"
	;;
########## END OF WORKAROUND: getting more samples ##########
    "process_data")
	if [ ! $# -eq 7 ]; then
	    echo "Error: process_data needs 7 arguments"
	    show_help
	fi
	do_process_data "${2}" "${3}" "${4}" "${5}" "${6}" "${7}"
	;;
    "test_for_outlier")
	if [ ! $# -eq 9 ]; then
	    echo "Error: process_data needs 9 arguments"
	    show_help
	fi
	do_test_for_outlier "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}" "${9}"
	;;
    *)
	show_help
	;;
esac