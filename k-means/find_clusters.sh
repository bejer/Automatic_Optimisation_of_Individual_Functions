#!/bin/bash

if [ ${#} -ne 1 ]; then
    echo "Usage: ${0} project_name"
    exit 1
fi

PROJECT=${1}

K_START=1
K_END=100

Rkmeans_path="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/k-means/kmeans.R"
Rscript="Rscript ${Rkmeans_path}"
R_max_iterations=1000
R_nstarts=100
R_algorithm="Hartigan-Wong"
R_data_in="${PROJECT}_data_in"
R_output_centers="${PROJECT}_centers-"
R_output_totss="${PROJECT}_totss-"
R_output_withinss="${PROJECT}_withinss-"
R_output_total_withinss="${PROJECT}_total_withinss-"
R_output_betweenss="${PROJECT}_betweenss-"
R_output_size="${PROJECT}_size-"
R_output_betweenss_div_totss="${PROJECT}_betweenss_div_totss-"

MY_PARALLEL_CMD=""

for i in $(seq ${K_START} ${K_END})
do
    R_arguments="${i} ${R_max_iterations} ${R_nstarts} ${R_algorithm} ${R_data_in} ${R_output_centers}${i} ${R_output_totss}${i} ${R_output_withinss}${i} ${R_output_total_withinss}${i} ${R_output_betweenss}${i} ${R_output_size}${i} ${R_output_betweenss_div_totss}${i}"
    MY_PARALLEL_CMD="${MY_PARALLEL_CMD}${Rscript} ${R_arguments}\n"
done

# Has to echo and pipe the commands to parallel, else it won't properly recognize the newlines
echo -e $MY_PARALLEL_CMD | parallel :::
#echo -e $MY_PARALLEL_CMD