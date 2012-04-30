#!/bin/sh

# Disclaimer:
# - Contains a lot of duplicated code / gnuplot setup stuff.
# - Contains hardcoded information, such as what data set is being processed.

# Possible TODO:
# Make plots with and without logscale
#  - With (x,y) and (y,x) e.g. 1:2 and 2:1
# Make the plots with gprof_{yes|no} together with all - name them accordingly (also with log scales - place the information into the file names -> maybe use functions to add setup, logscale x, logscale y, other stuff -> so there is less copy paste code and more setup of just calling the right functions.

function my_error () {
    echo "My Error: ${1}"
    exit 1
}

outlier_file="outlier_info_001.txt"
[ -f ${outlier_file} ] || my_error "Could not find the outlier file '${outlier_file}'."
normality_file="test_for_normality_001.txt"
[ -f ${normality_file} ] || my_error "Could not find the normality file '${normality_file}'."

gnuplot_tmp_file="my_gnuplot_tmp_file.gp"
[ -f ${gnuplot_tmp_file} ] && my_error "The tmp file for gnuplot '${gnuplot_tmp_file}' already exists."

############################################################
# Scatter plot of p-values vs %-deviation
############################################################
# $1=data_type  (e.g. 'processed_data_001_01' )
function generate_scatter_plots () {
#####
# All
#####
echo "set terminal png" > ${gnuplot_tmp_file}
echo "set output '${1}_scatter_plot_p_values_vs_percent_deviation_for_all.png'" >> ${gnuplot_tmp_file}
#
#echo "set logscale x" >> ${gnuplot_tmp_file}
#
echo "set title '${1} - all'" >> ${gnuplot_tmp_file}
echo "set xlabel 'P-value from Shapiro-Wilk test'" >> ${gnuplot_tmp_file}
echo "set ylabel '%-deviation from median'" >> ${gnuplot_tmp_file}
echo "unset key" >> ${gnuplot_tmp_file}
echo "plot '-' using 2:1 with points pointtype 7 pointsize 1" >> ${gnuplot_tmp_file}

for line in `cat ${outlier_file}`; do
    percent_deviation=`echo "${line}" | awk -F ':' '{ print $1; }'`
    program_version=`echo "${line}" | awk -F ':' '{ print $2; }'`
    p_value=`awk -F ':' "\\$5 == \"${program_version}\" { print \\$1; }" ${normality_file}`
    
    echo "${percent_deviation} ${p_value}" >> ${gnuplot_tmp_file}
done

# Invoke gnuplot to generate the scatter plots and save the images
gnuplot ${gnuplot_tmp_file}

#####
# Gprof_yes
#####
echo "set terminal png" > ${gnuplot_tmp_file}
echo "set output '${1}_scatter_plot_p_values_vs_percent_deviation_for_gprof_yes.png'" >> ${gnuplot_tmp_file}
echo "set title '${1} - gprof_yes'" >> ${gnuplot_tmp_file}
echo "set xlabel 'P-value from Shapiro-Wilk test'" >> ${gnuplot_tmp_file}
echo "set ylabel '%-deviation from median'" >> ${gnuplot_tmp_file}
echo "unset key" >> ${gnuplot_tmp_file}
echo "plot '-' using 2:1 with points pointtype 7 pointsize 1" >> ${gnuplot_tmp_file}

for line in `cat ${outlier_file} | grep gprof_yes`; do
    percent_deviation=`echo "${line}" | awk -F ':' '{ print $1; }'`
    program_version=`echo "${line}" | awk -F ':' '{ print $2; }'`
    p_value=`awk -F ':' "\\$5 == \"${program_version}\" { print \\$1; }" ${normality_file}`
    
    echo "${percent_deviation} ${p_value}" >> ${gnuplot_tmp_file}
done

# Invoke gnuplot to generate the scatter plots and save the images
gnuplot ${gnuplot_tmp_file}

#####
# Gprof_no
#####
echo "set terminal png" > ${gnuplot_tmp_file}
echo "set output '${1}_scatter_plot_p_values_vs_percent_deviation_for_gprof_no.png'" >> ${gnuplot_tmp_file}
echo "set title '${1} - gprof_no'" >> ${gnuplot_tmp_file}
echo "set xlabel 'P-value from Shapiro-Wilk test'" >> ${gnuplot_tmp_file}
echo "set ylabel '%-deviation from median'" >> ${gnuplot_tmp_file}
echo "unset key" >> ${gnuplot_tmp_file}
echo "plot '-' using 2:1 with points pointtype 7 pointsize 1" >> ${gnuplot_tmp_file}

for line in `cat ${outlier_file} | grep gprof_no`; do
    percent_deviation=`echo "${line}" | awk -F ':' '{ print $1; }'`
    program_version=`echo "${line}" | awk -F ':' '{ print $2; }'`
    p_value=`awk -F ':' "\\$5 == \"${program_version}\" { print \\$1; }" ${normality_file}`
    
    echo "${percent_deviation} ${p_value}" >> ${gnuplot_tmp_file}
done

# Invoke gnuplot to generate the scatter plots and save the images
gnuplot ${gnuplot_tmp_file}

#####
# Gprof_no with logscale x
#####
echo "set terminal png" > ${gnuplot_tmp_file}
echo "set output '${1}_scatter_plot_p_values_vs_percent_deviation_for_gprof_no_with_logscale_x.png'" >> ${gnuplot_tmp_file}
echo "set title '${1} - gprof_no'" >> ${gnuplot_tmp_file}
#
echo "set logscale x" >> ${gnuplot_tmp_file}
#
echo "set xlabel 'P-value from Shapiro-Wilk test'" >> ${gnuplot_tmp_file}
echo "set ylabel '%-deviation from median'" >> ${gnuplot_tmp_file}
echo "unset key" >> ${gnuplot_tmp_file}
echo "plot '-' using 2:1 with points pointtype 7 pointsize 1" >> ${gnuplot_tmp_file}

for line in `cat ${outlier_file} | grep gprof_no`; do
    percent_deviation=`echo "${line}" | awk -F ':' '{ print $1; }'`
    program_version=`echo "${line}" | awk -F ':' '{ print $2; }'`
    p_value=`awk -F ':' "\\$5 == \"${program_version}\" { print \\$1; }" ${normality_file}`
    
    echo "${percent_deviation} ${p_value}" >> ${gnuplot_tmp_file}
done

# Invoke gnuplot to generate the scatter plots and save the images
gnuplot ${gnuplot_tmp_file}


# Clean up
rm ${gnuplot_tmp_file}
}

generate_scatter_plots "processed_data_001_01"