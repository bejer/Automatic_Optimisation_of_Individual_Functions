#!/bin/sh

function internal_error () {
    echo "Internal Error: ${1}"
    exit 1
}

path_to_latex="${HOME}/Temp/master_thesis_latex"
# This info is needed in the latex generating functions as the paths used for \input{} has to be relative from the latex root dir (where the master is).
analysis_path="analysis_results"



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


#profilers="gprof_yes gprof_no"

# Automotive_bitcount
#program_names="automotive_bitcount:01"
#function_names="AR_btbl_bitcount bit_count bitcount bit_shifter BW_btbl_bitcount main1 ntbl_bitcnt ntbl_bitcount"

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
    header_line="\textbf{Factor} & \textbf{Df} & \textbf{Sum Sq} & \textbf{Mean Sq} & \textbf{F value} & \textbf{Pr(\$>\$F)}\\\\"
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

# $1=output_file, $2=data_file, $3=caption
function generate_bartlett_table () {
    if [ $# -eq 3 ]; then
	output_file="${1}"
	data_file="${2}"
	caption="${3}"
    else
	internal_error "The function 'generate_bartlett_table' needs 3 arguments."
    fi
	
    echo "\begin{longtable}{c|c|c}" >> ${output_file}
    echo "\hline" >> ${output_file}
    header_line="\textbf{Bartlett's K$^2$} & \textbf{df} & \textbf{p-value}\\\\"
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endfirsthead" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endhead" >> ${output_file}
    echo "\hline \multicolumn{3}{r}{{Continues...}}\\" >> ${output_file}
    echo "\endfoot" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${caption}" >> ${output_file}
    echo "\endlastfoot" >> ${output_file}
    echo "\input{${data_file}}" >> ${output_file}
    echo "\end{longtable}" >> ${output_file}
}

# $1=output_file, $2=data_files, $3=caption
function generate_bartlett_table_multiple () {
    if [ $# -eq 3 ]; then
	output_file="${1}"
	data_files="${2}"
	caption="${3}"
    else
	internal_error "The function 'generate_bartlett_table' needs 3 arguments."
    fi
	
    echo "\begin{longtable}{c|c|c|c}" >> ${output_file}
    echo "\hline" >> ${output_file}
    header_line="\textbf{Set of Groups} & \textbf{Bartlett's K$^2$} & \textbf{df} & \textbf{p-value}\\\\"
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endfirsthead" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endhead" >> ${output_file}
    echo "\hline \multicolumn{4}{r}{{Continues...}}\\" >> ${output_file}
    echo "\endfoot" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${caption}" >> ${output_file}
    echo "\endlastfoot" >> ${output_file}
    for df in ${data_files}; do
	echo "\input{${df}}" >> ${output_file}
    done
    echo "\end{longtable}" >> ${output_file}
}


# $1=output_file, $2=data_file, $3=caption
function generate_means_table () {
    if [ $# -eq 3 ]; then
	output_file="${1}"
	data_file="${2}"
	caption="${3}"
    else
	internal_error "The function 'generate_means_table' needs 3 arguments."
    fi
	
    echo "\begin{longtable}{c|c}" >> ${output_file}
    echo "\hline" >> ${output_file}
    header_line="\textbf{Global Flag} & \textbf{Mean}\\\\"
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endfirsthead" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${header_line}" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "\endhead" >> ${output_file}
    echo "\hline \multicolumn{2}{r}{{Continues...}}\\" >> ${output_file}
    echo "\endfoot" >> ${output_file}
    echo "\hline" >> ${output_file}
    echo "${caption}" >> ${output_file}
    echo "\endlastfoot" >> ${output_file}
    echo "\input{${data_file}}" >> ${output_file}
    echo "\end{longtable}" >> ${output_file}
}


# $1=program_name, $2=function_name, $3=gprof (profiler), $4=subrun, $5=output_file
function generate_latex () {
    if [ $# -eq 5 ]; then
	program_name="${1}"
	fn="${2}"
	gp="${3}"
	subrun="${4}"
	output_file="${5}"
    else
	internal_error "The function 'generate_latex' needs 4 arguments."
    fi
    # Seems wrong with the for looping - atleast in here, else it should be in a function that calls the latex generator functions...
#    for pn in ${program_names}; do
#	program_name=`echo ${pn} | awk -F ':' '{ print $1; }'`
#	subrun=`echo ${pn} | awk -F ':' '{ print $2; }'`
    

    # Default subrun="." means that it will just look in the current dir, but if doing multiple subruns, then use the directory corresponding to the subrun.
#    subrun="."
#    subrun="01"

    # These should be updated according to the information given for those
#    gp="yes"
#    fn="main1"

#    output_file="${program_name}_subrun_${subrun}_gprof_${gp}_function_${fn}.tex"
    # OBS: should be removed or handled in another way - especially as the output file should be named dynamically according to the content that it is going to hold...
#    [ -f ${output_file} ] && rm ${output_file}

    data_file_prefix="${analysis_path}/${program_name}/${subrun}"

    # ANOVA summary all
    # OBS: hardcoded data_file path
    data_file="${data_file_prefix}/anova_summary_all_gprof_${gp}_function_${fn}.tex"
    caption="\caption{\textcolor{red}{This caption should be set.}. The interaction between factors is shown as \$<\$factor\$>\$:\$<\$factor\$>\$.}"
    generate_anova_summary_table "${output_file}" "${data_file}" "${caption}"

    # ANOVA summary gf all
    data_file="${data_file_prefix}/anova_summary_gf_all_gprof_${gp}_function_${fn}.tex"
    caption="\caption{\textcolor{red}{This caption should be set.}. ANOVA summary for all global flags.}"
    generate_anova_summary_table "${output_file}" "${data_file}" "${caption}"

    # ANOVA summary gf selected
    data_file="${data_file_prefix}/anova_summary_gf_selected_gprof_${gp}_function_${fn}.tex"
    caption="\caption{\textcolor{red}{This caption should be set.}. ANOVA summary of selected global flags.}"
    generate_anova_summary_table "${output_file}" "${data_file}" "${caption}"

    # # Bartlett anova all
    # data_file="${data_file_prefix}/bartlett_anova_all_gprof_${gp}_function_${fn}.tex"
    # caption="\caption{\textcolor{red}{This caption should be set.}. Bartlett's test on the groups in ANOVA all.}"
    # generate_bartlett_table "${output_file}" "${data_file}" "${caption}"

    # # Bartlett gf all
    # data_file="${data_file_prefix}/bartlett_gf_all_gprof_${gp}_function_${fn}.tex"
    # caption="\caption{\textcolor{red}{This caption should be set.}. Bartlett's test on the groups for all global flags.}"
    # generate_bartlett_table "${output_file}" "${data_file}" "${caption}"

    # # Bartlett gf selected
    # data_file="${data_file_prefix}/bartlett_gf_selected_gprof_${gp}_function_${fn}.tex"
    # caption="\caption{\textcolor{red}{This caption should be set.}. Bartlett's test on the groups for selected global flags.}"
    # generate_bartlett_table "${output_file}" "${data_file}" "${caption}"

    # All Bartlett tests in one table
    data_file_1="${data_file_prefix}/bartlett_anova_all_gprof_${gp}_function_${fn}.tex"
    data_file_2="${data_file_prefix}/bartlett_gf_all_gprof_${gp}_function_${fn}.tex"
    data_file_3="${data_file_prefix}/bartlett_gf_selected_gprof_${gp}_function_${fn}.tex"
    caption="\caption{\textcolor{red}{This caption should be set.}. Bartlett's test on the groups involved in the 3 different ANOVA tables.}"
    # Could place labels on the ANOVA tables and generate references to the 3 tables here (placed in the caption)
    generate_bartlett_table_multiple "${output_file}" "${data_file_1} ${data_file_2} ${data_file_3}" "${caption}"

    # Means gf all
    data_file="${data_file_prefix}/means_gf_all_gprof_${gp}_function_${fn}.tex"
    caption="\caption{\textcolor{red}{This caption should be set.}. Means for the groups used in the ANOVA on all global flags.}"
    generate_means_table "${output_file}" "${data_file}" "${caption}"

    echo "\clearpage" >> ${output_file}
}


# Automotive_bitcount
program_name="automotive_bitcount"
# Subrun should be "." if there are no subruns
subruns="01 02"
function_names="AR_btbl_bitcount bit_count bitcount bit_shifter BW_btbl_bitcount main1 ntbl_bitcnt ntbl_bitcount"
gprof="yes no"

# The for-loops can be placed in a function that takes all the info as arguments and produce chapters according to subruns and profilers etc. -> then adding another program name doesn't require copy/paste of the "latex outputting code - reducing duplication of code."

for subrun in ${subruns}; do
    output_file="${path_to_latex}/${analysis_path}/${program_name}_subrun_${subrun}.tex"
    [ -f ${output_file} ] && mv ${output_file} ${output_file}.bac
    for gp in ${gprof}; do
	if [ ${gp} == "yes" ]; then
	    echo "\subsection{Profiler: Gprof}" >> ${output_file}
	else
	    echo "\subsection{Profiler: Oprofile}" >> ${output_file}
	fi
	for fn in ${function_names}; do
	    fn_latex=`echo "${fn}" | sed 's/_/\\\\_/g'`
	    echo "\subsubsection{Function: ${fn_latex}}" >> ${output_file}
	    echo "fn_latex: ${fn_latex}"
	    echo "subrun: ${subrun}"
	    echo "fn: ${fn}"
	    echo "gp: ${gp}"
	    generate_latex "${program_name}" "${fn}" "${gp}" "${subrun}" "${output_file}"
	done
    done
done
    
