#!/bin/sh

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

# Should get a path to the analysis result files supplied on the command line (maybe together with something indicating that the results are from e.g. run 01 or 02 (right this information requires to be be hardcoded in 'subrun').
if [ $# -eq 1 ]; then
    path_for_analysis_files="${1}"
    [ -d ${path_for_analysis_files} ] || my_error "The supplied path for where to find the analysis files '${path_for_analysis_files}' could not be found."
else
    echo "Usage: ${0} <path_to_analysis_files>"
    exit 1
fi


# Extra:
# Got descriptive analysis of the overall data, such as percentiles for the different things

# Possible pitfalls/errors:
# Currently the way to handle run 01 and 02 as separate latex results, is hardcoded and requires modifying this script.

# Obatain the program name
[ -f "program_name.txt" ] || my_error "Could not find 'program_name.txt' to obtain the program name."
program_name="`cat program_name.txt`"


# Directory to hold all the generated data
path_to_latex="${HOME}/Temp/master_thesis_latex/analysis_results"
[ -d ${path_to_latex} ] || my_error "The path to place the latex output in could not be found '${path_to_latex}'."


# 'subrun' is a quick work around for having multiple runs for each program (e.g. one before and after improved data quality) - has to be manually changed in this source file... i.e. quick work around.
subrun="/01"
output_dir="${path_to_latex}/${program_name}${subrun}"

read -p "Warning (part of quick work around): the chosen subrun is '${subrun}', if this is correct press enter or abort now and change this script '${0}'."

# Make directory if it doesn't exists - or make a backup of the directory [ No need for the else part as the mkdir cmd could be placed after the if, but it gives a better overview in case the if test is altered and not getting some unwanted effects ]
if [ -d ${output_dir} ]; then
    read -p "The directory '${output_dir}' already exists - press enter to make a backup and continue..."
    [ -d ${output_dir}.bac ] && rm -r ${output_dir}.bac
    mv ${output_dir} ${output_dir}.bac
    mkdir ${output_dir}
else
    mkdir ${output_dir}
fi



# Loop over the analysis result files and convert them to latex accordingly
for file in `ls ${path_for_analysis_files}/analysis_statistics_*.txt`; do
    fn=`echo ${file} | sed "s/\\(.\\)\\+_function_\\(\\(.\\)\\+\\)\\.txt/\\2/"`
    gp=`echo ${file} | sed "s/\\(.\\)\\+_gprof_\\(yes\\|no\\)\\(.\\)*/\\2/"`
    analysis=`echo ${file} | sed "s/\\(.\\)*analysis_statistics_\\(\\(.\\)\\+\\)_gprof_\\(.\\)*/\\2/"`

    output_file="${output_dir}/${analysis}_gprof_${gp}_function_${fn}.tex"
    [ -f ${output_file} ] && my_error "The file '${output_file}' already exists - something is wrong as the directory should have been empty."

    case "${analysis}" in
	"anova_summary_all")
	    # Just convert to table ready data, not caring for the table boiler plate and detailed layout
	    # Even ignore first line as that header should/could be defined another place - depending on how the table boiler plate is - different table environments require different setups of the header data... e.g. longtable vs. tabular
	    # The first 'sed-manipulation' is a work around to handle the case where the 6th item is '<2e-16'
	    cat ${file} | sed 's/<\(\([0-9e.-]\+\)\)/< \1/' | awk -F ' ' 'NR > 1 && NR < 9 && $6 != "<" { print $1" & "$2" & "$3" & "$4" & "$5" & "$6"\\\\"; } NR > 1 && NR < 9 && $6 == "<" { print $1" & "$2" & "$3" & "$4" & "$5" & $<$ "$7"\\\\"; } $1 == "Residuals" { print $1" & "$2" & "$3" & "$4" &  & \\\\"; }' > ${output_file}
#	    awk -F ' ' 'NR > 1 && NR < 9 && $6 != "<" { print $1" & "$2" & "$3" & "$4" & "$5" & "$6"\\\\"; } NR > 1 && NR < 9 && $6 == "<" { print $1" & "$2" & "$3" & "$4" & "$5" & $<$ "$7"\\\\"; } $1 == "Residuals" { print $1" & "$2" & "$3" & "$4" &  & \\\\"; }' ${file} > ${output_file}
	    ;;
	"anova_summary_gf_all")
	    # Using sed to convert '<2e-16' to '< 2e-16' as it outputted from the anova_summary_all data files
	    cat ${file} | sed 's/\(\(.\)\+\)<\([0-9e\-]\+\)\(\(.\)*\)/\1 < \3 \4/' | awk -F ' ' 'NR > 1 && NR < 3 && $6 != "<" { print $1" & "$2" & "$3" & "$4" & "$5" & "$6"\\\\"; } NR > 1 && NR < 3 && $6 == "<" { print $1" & "$2" & "$3" & "$4" & "$5" & $<$ "$7"\\\\"; } $1 == "Residuals" { print $1" & "$2" & "$3" & "$4" &  & \\\\"; }' > ${output_file}
	    ;;
	"anova_summary_gf_selected")
	    # The same convert cmd as "anova_summary_gf_all"
	    cat ${file} | sed 's/\(\(.\)\+\)<\([0-9e\-]\+\)\(\(.\)*\)/\1 < \3 \4/' | awk -F ' ' 'NR > 1 && NR < 3 && $6 != "<" { print $1" & "$2" & "$3" & "$4" & "$5" & "$6"\\\\"; } NR > 1 && NR < 3 && $6 == "<" { print $1" & "$2" & "$3" & "$4" & "$5" & $<$ "$7"\\\\"; } $1 == "Residuals" { print $1" & "$2" & "$3" & "$4" &  & \\\\"; }' > ${output_file}
	    ;;
	"bartlett_anova_all")
	    # Just placing the values in a tabular format
#	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' > ${output_file}
	    echo -n "ANOVA\\_all & " > ${output_file}
	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' >> ${output_file}
	    ;;
	"bartlett_gf_all")
	    # Same as for "bartlett_anova_all"
#	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' > ${output_file}
	    echo -n "GF\\_all & " > ${output_file}
	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' >> ${output_file}
	    ;;
	"bartlett_gf_selected")
	    # Same as for "bartlett_anova_all"
#	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' > ${output_file}
	    echo -n "GF\\_selected & " > ${output_file}
	    awk -F ' ' 'NR == 5 { print ; }' ${file} | sed 's/Bartlett.s K-squared = //' | sed 's/, df = / \& /' | sed 's/, p-value = \([0-9\.e\-]\+\)/ \& \1\\\\/' | sed 's/, p-value < \([0-9\.e\-]\+\)/ \& $<$ \1\\\\/' >> ${output_file}
	    ;;
	"means_gf_all")
	    awk -F ' ' 'NR != 1 { print $2" & "$3"\\\\"; }' ${file} > ${output_file}
	    ;;
	*)
	    my_error "The found analysis case is not supported - aborting..."
    esac

done
    



# List of the analysis results to convert (and what they should be converted into)
# This are on a function name and gprof_{yes|no} basis (the same data for each function):

# means of gf all (to supplement the understanding of doing both gf all and gf selected)

# ANOVA gf all
# Bartlett's test
# (Normality test)

# ANOVA gf selected
# Bartlett's test
# (Normality test)

# ANOVA all -> table
# Bartlett's test
# (Normality test)