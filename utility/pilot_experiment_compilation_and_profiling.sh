#!/bin/sh

# Setup the environment for compiling with the ctuning tools (using {.|source} to have the effects apply to the current shell)
. /home/michael/Temp/ctuning/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1_with_ccc-framework/ctuning-cc-2.5-gcc-4.4.4-ici-2.05-milepost-2.1/gcc_ici_environment_compile.sh

gprof_text=gprof
oprofile_text=oprofile

# Compile the automative_bitcount cBench test program : $1=[O<argument>], $2=flags, $3=output_text
function compile_bitcnt () {
#(cd ~/Temp/master_thesis_profiling/master-thesis/benchmark-suites/cBench-v1.1/automotive_bitcount/src/; gcc -Wall -o bitcnt_O$1_$3.out -O$1 $2 *.c)
gcc -Wall -o bitcnt_O$1_$3.out -O$1 $2 *.c
}

function compile_bitcnts () {
    for i in 0 1 2 3; do
	compile_bitcnt $i "-pg" "${gprof_text}"
#	compile_bitcnt $i "-p" "with_-p"
	compile_bitcnt $i "" "${oprofile_text}"
    done
}

# Not doing summing (just a single run for each sample): $1=iterations, $2={bitcount|input}, $3=text={fixed_frequency|dynamic_frequency}
function gprof_collect () {
    for i in 0 1 2 3; do
	for itr in `seq 1 $1`; do
	    ./bitcnt_O${i}_${gprof_text}.out $2 > /dev/null
	    mv gmon.out gmon_bitcnt_O${i}_${gprof_text}_${3}_${itr}.out
	done
    done
}

# Setup oprofiling, $1=binary_name
function setup_oprofile () {
    # Make nmi_watchdog not use the counter resource
    echo 0 | sudo tee /proc/sys/kernel/nmi_watchdog
    # Reset session
    sudo opcontrol --reset

    # Start oprofiling
    sudo opcontrol --no-vmlinux --image=$1
    sudo opcontrol --start-daemon # To avoid profiling the daemon startup (not that necessary here)
}    

function shutdown_oprofile () {
    sudo opcontrol --shutdown
    # Deinit can be a bit overkill... atleast considering I'm not --init'ing it in the setup function
#    sudo opcontrol --deinit
}

# Just a single run for each sample : $1=iterations, $2={bitcount|input}, $3=text={fixed_frequency|dynamic_frequency}
function oprofile_collect () {
    for i in 0 1 2 3; do
	setup_oprofile bitcnt_O${i}_${oprofile_text}.out
	sudo opcontrol --start
	for itr in `seq 1 $1`; do
	    ./bitcnt_O${i}_${oprofile_text}.out $2 > /dev/null
	    sudo opcontrol --save="bitcnt_O${i}_${oprofile_text}.out_${3}_${itr}"
	done
	shutdown_oprofile
    done
}
	    
my_iterations=40
my_bitcount=1125000

#######################################################
# Main
#######################################################
cd ~/Temp/master_thesis_profiling/master-thesis/benchmark-suites/cBench-v1.1/automotive_bitcount/src/
#+++++++++++++++++++++++++++++
make clean
echo "--- Compiling the binaries ---"
compile_bitcnts

echo "------------------------------------------"
echo "Doing gprof collecting using fixed frequency:"
gprof_collect ${my_iterations} ${my_bitcount} "fixed_frequency"
echo "------------------------------------------"
echo "------------------------------------------"
echo "Doing oprofile collecting using fixed frequency:"
oprofile_collect ${my_iterations} ${my_bitcount} "fixed_frequency"
echo "------------------------------------------"
#+++++++++++++++++++++++++++++
# Change to use dynamic frequency
# Use: 'sudo cpupower -c all frequency-set -g {powersave|performance}' [According to my quick testing the performance policy causes the CPU to use boosting and get a frequency around 2.5 or 2.6 GHz].
# Using 'ondemand' gives quite some variation -> should I record this and document it in the master thesis?

# echo "------------------------------------------"
# echo "Doing gprof collecting using dynamic frequency:"
# gprof_collect ${my_iterations} ${my_bitcount} "dynamic_frequency"
# echo "------------------------------------------"
# echo "------------------------------------------"
# echo "Doing oprofile collecting using dynamic frequency:"
# oprofile_collect ${my_iterations} ${my_bitcount} "dynamic_frequency"
# echo "------------------------------------------"

#######################################################
# Parse the generated data (performance measurements)
#######################################################
# Obtain the function names

#######################################################
# Awk example
#######################################################
# Output from gprof could look like:
# Command: gprof -bp bitcnt_O3_gprof.out gmon_bitcnt_O3_gprof_fixed_frequency_9.out 
# Flat profile:
#
# Each sample counts as 0.01 seconds.
#   %   cumulative   self              self     total           
#  time   seconds   seconds    calls  ms/call  ms/call  name    
#  27.25      0.13     0.13  2250000     0.00     0.00  bit_shifter
#  22.89      0.23     0.11  2250000     0.00     0.00  bit_count
#  13.08      0.29     0.06        2    30.08   225.59  main1
#   8.72      0.33     0.04  2250000     0.00     0.00  BW_btbl_bitcount
#   8.72      0.37     0.04  2250000     0.00     0.00  bitcount
#   8.72      0.41     0.04  2250000     0.00     0.00  ntbl_bitcount
#   6.54      0.44     0.03  2250000     0.00     0.00  ntbl_bitcnt
#   2.18      0.45     0.01  2250000     0.00     0.00  AR_btbl_bitcount
#   1.09      0.46     0.01                             alloc_bit_array
#   1.09      0.46     0.01                             btbl_bitcnt
#
# In this case alloc_bit_array and btbl_bitcnt are not shown on all the data gathered, so just ignoring them for this pilot experiment.
# The command:
# gprof -bp bitcnt_O3_gprof.out gmon_bitcnt_O3_gprof_fixed_frequency_9.out | awk -F ' ' '$7 != "name" && $7 != "" { print $7; }'
# Produces a list of the function names without the two functions that are being ignored (since they are missing fields to get anything filled in the $7'th variable).
# Now all these function names can be appended to a file, sorted and have all the duplicates removed - ending up with a list of the function names that can be measured/tracked [Although it is not guarenteed that every measurement contains data for those functions? - or are they guarenteed due to call graph tracking, given the program is deterministic? - number of calls should always be accurate...]
# Example command:
# for i in `seq 1 20`; do gprof -bp bitcnt_O3_gprof.out gmon_bitcnt_O3_gprof_fixed_frequency_${i}.out | awk -F ' ' '$7 != "name" && $7 != "" { print $7; }'; done | sort -u
#
# TODO:  [ Keep in mind this is just a prototype, so it doesn't really matter if the code is making some assumptions, such as that the same functions are shown on all reports where the amount of calls is counted ]
# Current flow:
# - Obtain function names for each program (they are being compared to other programs with different set of optimisations - so the list should be not unique, but a list where the names appears exactly the same amount of times and such - if there is any "abnormality" it should be reported so I can take action when doing it all automatically....)
# - Generate R table data file for each program with the function names as columns and measurements as rows.
#   This is done by grapping the measurements where the lines contain $7 == "function_name" { print $?; } with awk.
# - Do the test statistics on the datasets. (both t-test and mann-whitney)

###awk_obtain_function_names= ## DOESN'T seem like the awk command can be placed inside a variable... - my test scripts fails with awk complaining about the ' char being invalid or " never being terminated...

function_names="my_obtained_function_names.txt"

# : $1=iterations, $2=text={fixed_frequency|dynamic_frequency}
function obtain_function_names () {
    for i in 0 1 2 3; do
	#Obtain the function names
	for itr in `seq 1 $1`; do
	    gprof -bp bitcnt_O${i}_${gprof_text}.out gmon_bitcnt_O${i}_${gprof_text}_${2}_${itr}.out | awk -F ' ' '$7 != "name" && $7 != "" { print $7; }' >> ${function_names}.tmp
	done
    done

    cat ${function_names}.tmp | sort -u > ${function_names}
    rm ${function_names}.tmp
}

# # : $1=iterations, $2=text={fixed_frequency|dynamic_frequency}
# function generate_R_data_table () {
#     for i in 0 1 2 3; do
# 	[ -f "my_R_data_table_O${i}.txt" ] && rm "my_R_data_table_O${i}.txt"
# 	for funname in `cat ${function_names}`; do
# 	    echo -n "${funname} " >> my_R_data_table_O${i}.txt
# 	done
	
# 	for itr in `seq 1 $1`; do
# 	    # Insert new line for each measurement / run / iteration
# 	    echo "" >> my_R_data_table_O${i}.txt
# 	    for fun in `cat ${function_names}`; do
# 		gprof -bp bitcnt_O${i}_${gprof_text}.out gmon_bitcnt_O${i}_${gprof_text}_${2}_${itr}.out | awk -F ' ' "\$7 == \"${fun}\" { print \$3; }" > my_R_data_table_value_holder.txt
# 		echo -n "`cat my_R_data_table_value_holder.txt` " >> my_R_data_table_O${i}.txt
# 	    done
# 	done
#     done
    
#     rm "my_R_data_table_value_holder.txt"
# }

# TODO: Maybe add program as argument - this whole file should be updated to handle multiple projects using "help files" located in the projects, so there is no hardcoded information regarding program and function names, together with a different way of doing 'optcases' maybe call them optcase_{1...N} and have the optimisations described in a file for reference - but there are too many flags to have them listed in the file name.
# : $1=iterations, $2=text={fixed_frequency|dynamic_frequency}
function generate_gprof_function_raw_measurement_file () {
    for i in 0 1 2 3; do
	for funname in `cat ${function_names}`; do
	    [ -f "program_O${i}_${funname}_raw.txt" ] && rm program_O${i}_${funname}_raw.txt
	    # The above line is not really necessary as using '>' truncates the file before adding the content
	    # Adding the function name as the first line for easier handling in R
	    echo "${funname}" > program_O${i}_${funname}_raw.txt
	    # Gather measurements
	    for itr in `seq 1 ${1}`; do
		gprof -bp bitcnt_O${i}_${gprof_text}.out gmon_bitcnt_O${i}_${gprof_text}_${2}_${itr}.out | awk -F ' ' "\$7 == \"${funname}\" { print \$3; }" >> program_O${i}_${funname}_raw.txt
	    done
	done
    done
}

obtain_function_names ${my_iterations} "fixed_frequency"

# #generate_R_data_table ${my_iterations} "fixed_frequency"
generate_gprof_function_raw_measurement_file ${my_iterations} "fixed_frequency"
