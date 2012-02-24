#!/bin/sh

# Summary:
# Pilot experiment for measuring the performance of functions (and later see if the measured difference is statistically different and such)

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

# Main
cd ~/Temp/master_thesis_profiling/master-thesis/benchmark-suites/cBench-v1.1/automotive_bitcount/src/
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

### TODO ###
# Find out how to analyse the results and do statistics on them, including handling the inaccuracy



### To think about ###
# See how well the performance measurements are working when utilising the {4|8} cores - they should have their own local cache, but share the memory accesses, so could have some unreliable outcome or effects on the results/performance.