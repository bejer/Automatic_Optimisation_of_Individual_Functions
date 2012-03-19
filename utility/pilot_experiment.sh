#!/bin/sh

# Summary:
# Pilot experiment for measuring the performance of functions (and later see if the measured difference is statistically different and such)

# TODO: [very important]: Place all the compilation and gprof stuff in a shell script that is executed, to not affect the path and dynamic library linking setup for other programs that are working on the data -> so the compilation, measurement and raw file generation should be placed in its own shell script! [ But have commented it out for now, to test my R scripts! ]

# Compile and profile the program and functions
# !! UNCOMMENTED: no need to regenerate the data when testing the analysis !! #${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/pilot_experiment_compilation_and_profiling.sh

###################################################
# Analysis - Statistics
###################################################
function generate_function_descriptive_statistics_files () {
    # Use R for generating files with the sd(standard deviation) or variance and mean
    # Possible arguments could be: <invoke R script>: <input_file> <output_file_mean> <output_file_sd> <output_file_var>
    descriptive_statistics="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/pilot_experiment_descriptive_statistics.R"
    # Although this for loop iteration could be replaced with listing all the files that has the right naming scheme: program_O<i>_function_raw.txt
    for i in 0 1 2 3; do
	for funname in `cat ${function_names}`; do
	    Rscript ${descriptive_statistics} "program_O${i}_${funname}_raw.txt" "program_O${i}_${funname}_mean.txt" "program_O${i}_${funname}_sd.txt" "program_O${i}_${funname}_var.txt"
	done
    done
}

# TODO: Get rid of the "fixed frequency" text - it doesn't get reflected in the produced result file names....


# !! UNCOMMENTED: for testing latex generator !! #generate_function_descriptive_statistics_files

########################
# Test comparisons     #
########################

# : $1=<optcase_function>_raw.txt, $2=<optcase_function>_raw.txt, $3=text=file_to_save_results_in [ or at least a prefix to the files, since I'm doing multiple comparisons
function compare_functions () {
    # The wilcox.test requires data vectors without the header, so no data frames - easy work around is to just include the function name as a parameter to the R-script that is making the tests. Then the data supplied to the wilcox.test can be extracted by mydata$functionname.
    
    # Apparently the wilcox.test function does not handle "ties" (meaning the two data sets should not share the same values [or one data set should have unique data?]), because the assumption is that the data is sampled from a continuous distribution (but my time measurements are 'discretisied'/truncated to a few digits and are therefore not unique - I don't know how trobulesome this actually is for the wilcox.test test-statistic for my data/measurements.
    # See http://tolstoy.newcastle.edu.au/R/e8/help/09/12/9200.html for more information on the 'ties' problem.

    # The results from the tests cannot be written directly to a file, instead the result$p.value or similar can be used to save a single value - together with their means (or just use the means from the already created descriptive statistics to find out which optcase is faster.

    # Other notes:
    #  - calculate the amount of possible combinations of compiler flags
    #  - I'm not trying to see how well a function is performing without having the other functions optimised with the same optimisations -> just optimising the function (and having the rest of the functions optimised different, results in a very big experiment to cover all the possible combinations).
    #  - So my actual project is just covering the static features and optimisation performance -> just the initial steps to evaluate whether or not the features are useful (hoping that the profiling of single functions doesn't "lie" to me, due to having the whole program optimised with the same optimisations...

    test_statistics="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/pilot_experiment_test_statistics.R"
    Rscript ${test_statistics} ${1} ${2} ${3}
}

# This function is made for just comparing the optcases that different
# function compare_the_functions () {
#     for funname in `cat ${function_names}`; do
# 	for i in 0 1 2 3; do
# 	    if [ ${i} -ne 3 ]; then
# 		new_i=`expr ${i} + 1`
# 		for j in `seq ${new_i} 3`; do
# 	            # For this pilot experiment, the last optcase/function/argument should be faster than the first optcase/function/argument
# 		    compare_functions "program_O${i}_${funname}_raw.txt" "program_O${j}_${funname}_raw.txt" "program_comparison_O${i}_vs_O${j}"
# 		done
# 	    fi
# 	done
#     done
# }

# This version of the function also compares the same optcases
function compare_the_functions () {
    for funname in `cat ${function_names}`; do
	for i in 0 1 2 3; do
	    for j in `seq ${i} 3`; do
	        # For this pilot experiment, the last optcase/function/argument should be faster than the first optcase/function/argument, but this information is not used.
		compare_functions "program_O${i}_${funname}_raw.txt" "program_O${j}_${funname}_raw.txt" "program_comparison_${funname}_O${i}_vs_O${j}"
	    done
	done
    done
}

# When doing the wilcox.test comparison it will give a warning about not being able to compute an exact p-value due to 'ties'.
# !! UNCOMMENTED: for testing latex generator !! #compare_the_functions

# After that : Clean up the script(s) to make it more general/generic (work with multiple projects and possible naming schemes
# After that : Parse the data and generate presentable data (possible latex tables)
# Then
####   Do it for different input data to the projects
#   Do it for oprofile with different sampling settings
#   Show the estimated distribution of the sampled/gathered data/measurements
#   Try different types of data gathering: 20 runs pr. measurement, 20 runs pr. mean (20 times) for normal t-test, as done now (1 run equals 1 sample/measurement).
#   On multiple projects/programs.


#############################################################
# Simple and quick result parser and latex generator
#############################################################
# TODO and WARNING:
# function_names is listed in pilot_experiment_compilation_and_profiling.sh, but need it here too (atleast for this way of generating the presentation of the results / latex...
function_names="my_obtained_function_names.txt"
function do_presentation_of_results () {
    my_dst="my_latex_data_presentation"
    latex=${my_dst}/master.tex
#    rm -r ${my_dst}
    if [ ! -d ${my_dst} ]; then
	mkdir ${my_dst}
    fi

#    cp pilot_experiment_header.tex ${my_dst}/pilot_experiment_header.tex

    # Latex setup
    #echo "\\input{pilot_experiment_header}" > ${my_dst}/master.tex
    echo "\\documentclass{article}" > ${latex}
    echo "\\usepackage{longtable}" >> ${latex}
    echo "\\begin{document}" >> ${latex}
    echo "\\section{automotive\\_bitcount}" >> ${latex}
    # Data for functions
    for funname in `cat ${function_names}`; do
	echo "\\subsection{${funname}}" >> ${latex}
	# Make table with descriptive data
	echo "\\begin{longtable}{r|l|l}" >> ${latex}
	echo "\\textbf{Optcase} & \\textbf{Mean} & \\textbf{Standard deviation}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endfirsthead" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\textbf{Optcase} & \\textbf{Mean} & \\textbf{Standard deviation}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endhead" >> ${latex}
	echo "\\hline \multicolumn{3}{r}{Continues...}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\endfoot" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\caption{Descriptive statistics for function ${funname}.}" >> ${latex}
	echo "\\endlastfoot" >> ${latex}
	# The actual data
	for i in 0 1 2 3; do
	    echo -n "-O${i}" >> ${latex}
	    echo -n " & `cat program_O${i}_${funname}_mean.txt`" >> ${latex}
	    echo " & `cat program_O${i}_${funname}_sd.txt`" >> ${latex}
	    echo "\\\\" >> ${latex}
	done
    	echo "\\end{longtable}" >> ${latex}

	# Table with the p-values for the t-test
	echo "\\begin{longtable}{c|l|l|l|l}" >> ${latex}
	echo "\\textbf{ } & \\textbf{-O0} & \\textbf{-O1} & \\textbf{-O2} & \\textbf{-O3}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endfirsthead" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\textbf{ } & \\textbf{-O0} & \\textbf{-O1} & \\textbf{-O2} & \\textbf{-O3}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endhead" >> ${latex}
	echo "\\hline \multicolumn{5}{r}{Continues...}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\endfoot" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\caption{P-values for a two sided t-test for function ${funname}.}" >> ${latex}
	echo "\\endlastfoot" >> ${latex}
	# The actual data
	for i in 0 1 2 3; do
	    echo -n "-O${i}" >> ${latex}
#	    for j in `seq ${i} 3`; do
	    for j in `seq 0 3`; do
		if [ ${j} -lt ${i} ]; then
		    # Or could just print the same p-value found for O{j}_vs_O{i}, as it should be the same.
		    echo -n " & -" >> ${latex}
		else
		    echo -n " & `cat program_comparison_${funname}_O${i}_vs_O${j}_t-test_p-value.txt`" >> ${latex}
		fi
	    done
	    echo "\\\\" >> ${latex}
	done
    	echo "\\end{longtable}" >> ${latex}

	# Table with the p-values for the u-test
	echo "\\begin{longtable}{c|l|l|l|l}" >> ${latex}
	echo "\\textbf{ } & \\textbf{-O0} & \\textbf{-O1} & \\textbf{-O2} & \\textbf{-O3}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endfirsthead" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\textbf{ } & \\textbf{-O0} & \\textbf{-O1} & \\textbf{-O2} & \\textbf{-O3}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\endhead" >> ${latex}
	echo "\\hline \multicolumn{5}{r}{Continues...}" >> ${latex}
	echo "\\\\" >> ${latex}
	echo "\\endfoot" >> ${latex}
	echo "\\hline" >> ${latex}
	echo "\\caption{P-values for a two sided u-test for function ${funname}.}" >> ${latex}
	echo "\\endlastfoot" >> ${latex}
	# The actual data
	for i in 0 1 2 3; do
	    echo -n "-O${i}" >> ${latex}
#	    for j in `seq ${i} 3`; do
	    for j in `seq 0 3`; do
		if [ ${j} -lt ${i} ]; then
		    # Or could just print the same p-value found for O{j}_vs_O{i}, as it should be the same.
		    echo -n " & -" >> ${latex}
		else
		    echo -n " & `cat program_comparison_${funname}_O${i}_vs_O${j}_u-test_p-value.txt`" >> ${latex}
		fi
	    done
	    echo "\\\\" >> ${latex}
	done
    	echo "\\end{longtable}" >> ${latex}
	echo "\\clearpage" >> ${latex}
    done
    echo "\\end{document}" >> ${latex}

    # Correct the titles that contain underscores
    #sed -i 's/\\section{[a-zA-Z]*(\_){<regex>/<replacement>/g'
    # Quick fix
    sed -i 's/[^\\]_/\\_/g' ${latex}
}

do_presentation_of_results

### TODO ###
# Find out how to analyse the results and do statistics on them, including handling the inaccuracy
# Do the performance measurements of the means (to get a normal distribution for use in t-tests [t-testing done right])
# Do experiments with different optimisations on the whole program and the single function? (is there any difference at all?)



### To think about ###
# See how well the performance measurements are working when utilising the {4|8} cores - they should have their own local cache, but share the memory accesses, so could have some unreliable outcome or effects on the results/performance.