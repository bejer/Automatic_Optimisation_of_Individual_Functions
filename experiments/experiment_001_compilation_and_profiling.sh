#!/bin/sh

# Maybe this script should have an argument: compile|profile    they share some of the same functions and information gathering, but maybe it shouldn't recompile everything when just doing a new collecting of samples or preparing the samples for further processing. Ideally the collecting of samples should just be run once for each program (while the computer/environment is idle), so processing of the samples collected should not alter/modify the already gathered samples/data... [in other words...]

# TODO:
#  - Should the binaries be compiled with '-g' for debugging information - it is activated with -pg='-p -g', but how about when looking at oprofile?
#  - Not registering errors with compilations and/or other errors and problems - would be nice to do something when they appear, e.g. notify the user instead of silently keep running (important when doing automatisation - else errors will just go unnoticed)

# Requires a 'my_program_wrapper.sh' script that takes the arguments "build, build_gprof, cleanup, execute".
# Assumes that the current directory is the place where the program is located and all the files are at the top level and such.

function my_error () {
    echo "My Error: ${1}"
    exit 1
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
times_per_input_element=5
number_of_samples=20

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
#	./my_program_wrapper.sh build ${1}
	./my_program_wrapper.sh build_gprof ${1}
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

    # Adding global flags - the flags has to be valid filename segments as they are just added between a pair of '_'
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
		# This step also resets the previous function specific passes (although doing more work than necesarry for the ease of writing this script)
		setup_rest_optcases ${rest_optcase}
		setup_function_optcase "${function_name}" ${function_optcase}
		# Compile step! Using '_test' editions to include the global flags settings (does it matter if -O{1|2|3} is used?
		echo "DEBUG: compiling with substitute passes gprof: rest_optcase: ${rest_optcase} function_optcase: ${function_optcase} for function ${function_name}..."
		compile_with_substitute_passes_gprof_test "${program_name}_global_flags_${global_flags}_rest_optcase_${rest_optcase}_function_optcase_${function_optcase}_function_${function_name}_gprof_yes.out" "${global_flags}"
		echo "DEBUG: compiling with substitute passes: rest_optcase: ${rest_optcase} function_optcase: ${function_optcase} for function ${function_name}..."
		compile_with_substitute_passes_test "${program_name}_global_flags_${global_flags}_rest_optcase_${rest_optcase}_function_optcase_${function_optcase}_function_${function_name}_gprof_no.out" "${global_flags}"
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
    echo "----- Running and profiling the program - gprof -----"
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

# $1=number_of_samples
function run_and_profile_function_specific_optimised_binaries () {
    echo "----- Running and profiling the function specific optimised binaries -----"
    # I know the naming scheme and can just get a list of the binaries and the name for gmon.sum can contain the binary name that produced the profiling information.
    for binary in `ls ${program_name}_rest_optcase_*_gprof_yes.out`; do
	for i in `seq 1 ${1}`; do
	    run_and_gprof_profile ${binary} "${binary}_gmon_${i}.sum"
	done
    done

    for binary in `ls ${program_name}_rest_optcase_*_gprof_no.out`; do
	for i in `seq 1 ${1}`; do
	    run_and_oprofile_profile ${binary} "args?"
	done
    done
}


# $1=executable_name
function run_and_oprofile_profile () {
    # This function requires superuser priviledges (for using oprofile)
    # Using 'sudo' to get root priviledges. When automating the task it can be advantageous to not require a password for sudo'ing the command 'opcontrol' - usually set within /etc/sudoers (editted through visudo).
    echo "----- Running and profiling the program - oprofile -----"
    # TODO: add oprofile profiling with testing whether or not such a session already exists and such (if possible to do in a sensible way without requiring to much root access...
    echo "- not implemented yet though -"
}


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


    # The "actual" compilation
    generate_function_specific_binaries
}

############################################################
# Profiling step
############################################################
function do_profile () {
    run_and_profile_function_specific_optimised_binaries ${number_of_samples}
}

############################################################
# Data processing step
############################################################
# $1=number_of_samples
# Although the knowledge of number of samples isn't really that necessary
function generate_raw_measurement_files () {
    # It would be nice to get the "base name" and use the number_of_samples to get sample 1 first and up to 20 (althouhg maybe not that important...)

# Produce raw measurement files - like in the pilot experiment scripts
}


############################################################
# Main part - controlling what step to do
############################################################
function show_help () {
    echo "This script supports the following modes {compile|profile|process_data}."
    exit 1
}

# There could be extra arguments to specify combinations to compile or which profiler to use (e.g. just want the gprof data) and likewise for the processing of data.
case "${1}" in
    "compile")
	do_compile
	;;
    "profile")
	do_profile
	;;
    "process_data")
	do_process_data
	;;
    *)
	show_help
	;;
esac