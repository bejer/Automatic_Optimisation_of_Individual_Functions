#!/bin/sh

# Setup the script to use a supplied path name for where to find the data tables (easier for using on the 2 runs I did - eventhough it could be argued that I should just focus on the improved runs - having the data for showing why they should be prefered...)


if [ ${#} -ne 1 ]; then
    echo "Usage: ${0} <path to data tables>"
    exit 1
else
    path_to_data="${1}"
fi

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

r_script="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/analysis_and_anova.R"
[ -f ${r_script} ] || my_error "The R script used for analysis could not be found at '${r_script}'."
r_script_for_bartlett="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/bartlett_on_one_factor_data.R"
[ -f ${r_script_for_bartlett} ] || my_error "The R script used for doing Bartlett's test could not be found at '${r_script_for_bartlett}'."

# Prefix
prefix="analysis_statistics_"

# Find the files with the data prepared for being used within R (the data tables)
for file in `ls ${path_to_data}/data_table_for_001_*.txt`; do
    gp=`echo ${file} | sed "s/\\(.\\)\\+_gprof_\\(yes\\|no\\)\\(.\\)*/\\2/"`
    fn=`echo ${file} | sed "s/\\(.\\)\\+_function_\\(\\(.\\)\\+\\)\\.txt/\\2/"`

    postfix="gprof_${gp}_function_${fn}"
    # The files are just getting overwritten (from within R)
    means_gf_all="${prefix}means_gf_all_${postfix}.txt"
    bartlett_gf_all="${prefix}bartlett_gf_all_${postfix}.txt"
    bartlett_gf_selected="${prefix}bartlett_gf_selected_${postfix}.txt"
    anova_summary_gf_all="${prefix}anova_summary_gf_all_${postfix}.txt"
    anova_summary_gf_selected="${prefix}anova_summary_gf_selected_${postfix}.txt"
    anova_summary_all="${prefix}anova_summary_all_${postfix}.txt"
    #
    bartlett_anova_all="${prefix}bartlett_anova_all_${postfix}.txt"
    
    # Run the R-script (giving the right arguments in a proper order)
    Rscript ${r_script} ${file} ${means_gf_all} ${bartlett_gf_all} ${bartlett_gf_selected} ${anova_summary_gf_all} ${anova_summary_gf_selected} ${anova_summary_all}

    # Make the Bartlett's test on the groups producing anova_summary_all
    # Make a temporary file containing the needed data and have them appear as one factor with multiple values, e.g. Groups
    anova_all_data_file="my_${prefix}_tmp_anova_all_data_file.txt"
    echo "Groups Performance" > ${anova_all_data_file}
    awk -F ' ' 'NR != 1 && $1 != "-O0" { print $1$2$3" "$4 ;}' ${file} >> ${anova_all_data_file}

    Rscript ${r_script_for_bartlett} ${anova_all_data_file} ${bartlett_anova_all}

done
