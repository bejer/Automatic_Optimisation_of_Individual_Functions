#!/bin/sh

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

#output_file_gprof_no="data_table_for_001_gprof_no.txt"
#output_file_gprof_yes="data_table_for_001_gprof_yes.txt"
dir_with_files="processed_data_001"

# Make backup of old output files
#[ -f ${output_file_gprof_no} ] && mv ${output_file_gprof_no} ${output_file_gprof_no}.bac
#[ -f ${output_file_gprof_yes} ] && mv ${output_file_gprof_yes} ${output_file_gprof_yes}.bac

# Make sure the directory exists
[ -d ${dir_with_files} ] || my_error "The directory '${dir_with_files}' could not be found."

[ -f "program_name.txt" ] || my_error "Could not find 'program_name.txt' to obtain the program name."
program_name="`cat program_name.txt`"

for sample in `ls ${dir_with_files}/${program_name}_*_raw_samples_20.txt`; do
    # Extract information from the file name of the given sample
    gf=`echo ${sample} | sed "s/\\(.\\)\\+_global_flags_\\(\\(.\\)\\+\\)_rest_optcase_\\(.\\)\\+/\\2/"`
    ro=`echo ${sample} | sed "s/\\(.\\)\\+_rest_optcase_\\(\\(.\\)\\+\\)_function_optcase_\\(.\\)\\+/\\2/"`
    fo=`echo ${sample} | sed "s/\\(.\\)\\+_function_optcase_\\(\\(.\\)\\+\\)_function_\\(.\\)\\+/\\2/"`
    fn=`echo ${sample} | sed "s/\\(.\\)\\+_function_\\(\\(.\\)\\+\\)_gprof_\\(.\\)\\+/\\2/"`
    gp=`echo ${sample} | sed "s/\\(.\\)\\+_gprof_\\(yes\\|no\\)\\(.\\)*/\\2/"`

    # echo "----- | -----"
    # echo "sample: ${sample}"
    # echo "gf: ${gf}"
    # echo "ro: ${ro}"
    # echo "fo: ${fo}"
    # echo "fn: ${fn}"
    # echo "gp: ${gp}"

    current_output_file="data_table_for_001_gprof_${gp}_function_${fn}.txt.tmp"
    # Generate file name from the ${fn} and gprof_${gp} variables together with an identifier for making it a temporary file...

    if [ ! -f ${current_output_file} ]; then
	# Setup headers in the data table
	echo "GF RO FO Performance" > ${current_output_file}
    fi

    for measurement in `cat ${sample}`; do
	# Maybe the strings/numbers should be enclosed within a pair of "" for indicating that it is a string (especially necessary if e.g. the ${gf} contains spaces.
	echo "${gf} ${ro} ${fo} ${measurement}" >> ${current_output_file}
    done
done

# Rename the temporary files to non-temporary files (part of a workaround for putting headers in the files and being able to just append the measurements.
for file in `ls data_table_for_001_*.txt.tmp`; do
    new_filename=`echo ${file} | sed "s/\\(\\(.\\)\\+\\)\\.tmp/\\1/"`
    mv ${file} ${new_filename}
done