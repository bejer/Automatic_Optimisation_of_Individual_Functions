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

# Not doing summing (just a single run for each sample): $1=iterations, $2={bitcount|input}
function gprof_collect () {
    for i in 0 1 2 3; do
	for itr in `seq 1 $1`; do
	    ./bitcnt_O${i}_${gprof_text}.out $2 > /dev/null
	    mv gmon.out gmon_bitcnt_O${i}_${gprof_text}_${itr}.out
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
    sudo opcontrol --deinit
}

function oprofile_collect () {
    for i in 0 1 2 3; do
	for itr in `seq 1 $1`; do
	    


# Main
cd ~/Temp/master_thesis_profiling/master-thesis/benchmark-suites/cBench-v1.1/automotive_bitcount/src/
compile_bitcnts

gprof_collect 40 1125000
