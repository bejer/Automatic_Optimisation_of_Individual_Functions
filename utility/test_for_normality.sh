#!/bin/sh

# The output file: p-value:W-statistic:skewness:kurtosis:<file>

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

output_file="test_for_normality_001.txt"
dir_with_files="processed_data_001"

r_script="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/testing_for_normality.R"

# Make backup of old file
[ -f ${output_file} ] && mv ${output_file} ${output_file}.bac

# Make sure the r-script exists
[ -f ${r_script} ] || my_error "The R script used to test for normality does not exists '${r_script}' - fix it."

# Make sure the directory exists
[ -d ${dir_with_files} ] || my_error "The directory '${dir_with_files}' could not be found."

[ -f "program_name.txt" ] || my_error "Could not find 'program_name.txt' to obtain the program name."
program_name="`cat program_name.txt`"

pushd .
cd ${dir_with_files}

# This is hardcoded for my particular program - could be made to parse from the program.txt file as the experiment compilation and profiling script does - or where it should belong.
for file in `ls ${program_name}_*_raw_samples_20.txt`; do
    Rscript ${r_script} "${file}" "${output_file}"
done

popd
mv ${dir_with_files}/${output_file} .