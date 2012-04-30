#!/bin/sh

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

outlier_file="outlier_info_001.txt"
[ -f ${outlier_file} ] || my_error "The outlier file could not be found at '${outlier_file}'."
normality_file="test_for_normality_001.txt"
[ -f ${normality_file} ] || my_error "The normality file could not be found at '${normality_file}'."
r_script="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/percentiles.R"
[ -f ${r_script} ] || my_error "The R-script for generating percentiles could not be found at '${r_script}'."

tmp_input="my_tmp_input_file.txt"
tmp_output="my_tmp_output_file.txt"
result_file="percentile_values_001.txt"

[ -f ${result_file} ] && mv ${result_file} ${result_file}.bac

# pull the right data from outlier_file and place in a file, then run the rscript to generate the output_file -> place the output_files in the same file with a somewhat table layout... just need a text file with the results for this data.
############################################################
# Percentile of samples with '%-deviation' from median
############################################################
echo "Percentiles of samples with '%-deviation' from median" >> ${result_file}
echo "First row: 0.01 - 0.09" >> ${result_file}
echo "Second row: 0.1 - 0.9" >> ${result_file}
echo "Third row: 0.91 - 0.99" >> ${result_file}
echo "Fourth row: 1 0" >> ${result_file}
awk -F ':' '{ print $1; }' ${outlier_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "All: " >> ${result_file}
cat ${tmp_output} >> ${result_file}

awk -F ':' '/gprof_no/ { print $1; }' ${outlier_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "gprof_no: " >> ${result_file}
cat ${tmp_output} >> ${result_file}

awk -F ':' '/gprof_yes/ { print $1; }' ${outlier_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "gprof_yes: " >> ${result_file}
cat ${tmp_output} >> ${result_file}

############################################################
# Percentile of p-values from the shapiro-wilk test
############################################################
echo -e "\n\n\nPercentiles of p-values from the Shapiro-Wilk test" >> ${result_file}
echo "First row: 0.01 - 0.09" >> ${result_file}
echo "Second row: 0.1 - 0.9" >> ${result_file}
echo "Third row: 0.91 - 0.99" >> ${result_file}
echo "Fourth row: 1 0" >> ${result_file}
awk -F ':' '{ print $1; }' ${normality_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "All: " >> ${result_file}
cat ${tmp_output} >> ${result_file}

awk -F ':' '/gprof_no/ { print $1; }' ${normality_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "gprof_no: " >> ${result_file}
cat ${tmp_output} >> ${result_file}

awk -F ':' '/gprof_yes/ { print $1; }' ${normality_file} > ${tmp_input}
Rscript "${r_script}" "${tmp_input}" "${tmp_output}"
echo "gprof_yes: " >> ${result_file}
cat ${tmp_output} >> ${result_file}


#Rscript "${r_script}" <input_file> <output_file>

# Clean up
rm ${tmp_input}
rm ${tmp_output}