#!/bin/bash

show_help() {
    echo "Usage:"
    echo "--k_start <number>"
    echo "--k_end <number>"
    echo "--nstart <number>"
    echo "--max_iter <number>"
    echo "--algorithm \"name\":"
    echo "             Hartigan-Wong"
    echo "             Lloyd"
    echo "             Forgy"
    echo "             MacQueen"
    echo "--project_name \"project_name\""

    exit 1    
}

# Defaults
r_k_start=1
r_k_end=100
r_max_iter=1000
r_nstart=100
r_algorithm="Hartigan-Wong"

while [ ${#} -gt 0 ]; do
    case ${1} in
	--k_start)
	    r_k_start=${2}
	    shift
	    ;;
	--k_end)
	    r_k_end=${2}
	    shift
	    ;;
	--nstart)
	    r_nstart=${2}
	    shift
	    ;;
	--max_iter)
	    r_max_iter=${2}
	    shift
	    ;;
	--algorithm)
	    r_algorithm=${2}
	    shift
	    case ${r_algorithm} in
		"Hartigan-Wong")
		    ;;
		"Lloyd")
		    ;;
		"Forgy")
		    ;;
		"MacQueen")
		    ;;
		*)
		    show_help
		    ;;
	    esac
	    ;;
	--project_name)
	    project_name=${2}
	    shift
	    ;;
	*)
	    show_help
	    ;;
    esac
    shift
done


if [ ! -n ${project_name} ]; then
    echo "No project name provided"
    exit 1
fi
if [ ${r_k_start} -gt ${r_k_end} ]; then
    echo "The provided k_start is larger than k_end"
    exit 1
fi
if [ ${r_k_start} -le 0 -o ${r_k_end} -le 0 ]; then
    echo "The values for k_start and k_end has to be larger than 0"
    exit 1
fi
# And the other R kmeans parameters has rules to obey, but they can be added another time (simply just know what you are doing whe playing with these scripts)


Rkmeans_path="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/k-means/kmeans.R"
Rscript="Rscript ${Rkmeans_path}"

R_data_in="${project_name}_data_in"
R_output_centers="${project_name}_centers_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_totss="${project_name}_totss_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_withinss="${project_name}_withinss_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_total_withinss="${project_name}_total_withinss_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_betweenss="${project_name}_betweenss_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_size="${project_name}_size_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"
R_output_betweenss_div_totss="${project_name}_betweenss_div_totss_maxiter-${r_max_iter}_algo-${r_algorithm}_nstart-${r_nstart}_K-"

MY_PARALLEL_CMD=""

for i in $(seq ${r_k_start} ${r_k_end})
do
    R_arguments="${i} ${r_max_iter} ${r_nstart} ${r_algorithm} ${R_data_in} ${R_output_centers}${i} ${R_output_totss}${i} ${R_output_withinss}${i} ${R_output_total_withinss}${i} ${R_output_betweenss}${i} ${R_output_size}${i} ${R_output_betweenss_div_totss}${i}"
    MY_PARALLEL_CMD="${MY_PARALLEL_CMD}${Rscript} ${R_arguments}\n"
done

# Has to echo and pipe the commands to parallel, else it won't properly recognize the newlines
echo -e $MY_PARALLEL_CMD | parallel :::