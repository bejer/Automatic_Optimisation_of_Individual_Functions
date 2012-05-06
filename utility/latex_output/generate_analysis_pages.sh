#!/bin/sh

function internal_error () {
    echo "Internal Error: ${1}"
    exit 1
}

# Iterate over program_name (hardcoded)
# Iterate over profiler
# Iterate over subruns (should it be placed here?) - Subrun(s) is (can be) heavily dependent on the program_name and should be embedded within that? e.g. 'automotive_bitcount/01' or 'automotive_bitcount_01' and use regex to replace the _01 with something appropriate -> or 'automotive_bitcount:01' and use awk -F ':' to extract the elements.
# Iterate over functions
# Produce the latex pages

#program_names="automotive_bitcount:01"
#profilers="gprof_yes gprof_no"
#subruns


# There are the general functions for manipulating the analysis data and setting up the pages
# Then there is the function name, program name and subrun information that is highly dependent on the program and should simply be hardcoded...
# can they be given as arguments "program_names" "profilers" etc. to the function that is creating the pages?


profilers="gprof_yes gprof_no"

# Automotive_bitcount
program_names="automotive_bitcount:01"
function_names="AR_btbl_bitcount bit_count bitcount bit_shifter BW_btbl_bitcount main1 ntbl_bitcnt ntbl_bitcount"

# $1=output_file, $2=data_file, $3=caption
function generate_anova_summary_table () {
    if [ $# -eq 3 ]; then
	output_file="${1}"
	data_file="${2}"
	caption="${3}"
    else
	internal_error "The function 'generate_anova_summary_table' needs 3 arguments."
    fi
	
    echo "\begin{longtable}{c|c|c|c|c|c}" >> ${output_file}
    echo "\hline" >> ${output_file}
    header_line="\textbf{Factor} & \textbf{Df} & \textbf{Sum Sq} & \textbf{Mean Sq} & \textbf{F value} & \textbf{Pr(>F)}\\"
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endfirsthead" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endhead" >> ${output_file}
    echo "\hline \multicolumn{6}{r}{{Continues...}}\\" >> ${output_file}
    echo "\endfoot" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${caption}" >> ${output_file}
    echo "\endlastfoot" >> ${output_file}
    echo "\input{${data_file}}" >> ${output_file}
    echo "\end{longtable}" >> ${output_file}
}

# $1=program_names, $2=function_names
function generate_latex () {
    # Seems wrong with the for looping - atleast in here, else it should be in a function that calls the latex generator functions...
#    for pn in ${program_names}; do
#	program_name=`echo ${pn} | awk -F ':' '{ print $1; }'`
#	subrun=`echo ${pn} | awk -F ':' '{ print $2; }'`
    


    output_file="my_latex_generated_output.txt.tmp"
    # OBS: should be removed or handled in another way - especially as the output file should be named dynamically according to the content that it is going to hold...
    [ -f ${output_file} ] && rm ${output_file}

    # ANOVA summary all
    # OBS: hardcoded data_file path
    data_file="01/anova_summary_all_gprof_yes_function_main1.tex"
    caption="\caption{\color{red}{This caption should be set.}. The interaction between factors is shown as <factor>:<factor>.}"
    generate_anova_summary_table "${output_file}" "${data_file}" "${caption}"

    # ANOVA summary gf all
    data_file="01/anova_summary_gf_all_gprof_yes_function_main1.tex"
    caption="\caption{\color{red}{This caption should be set.}.}"
    generate_anova_summary_table "${output_file}" "${data_file}" "${caption}"

}

generate_latex "${program_names}" "${function_names}"