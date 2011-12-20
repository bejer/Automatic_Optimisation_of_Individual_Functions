#!/bin/sh

# TODO:
#  - Change the scripts to also accept specified max iterations, nstart (number of starts) and algorithm, that are used as parameters for kmeans in R -> and have that information recorded in the k-means documents placed in the DB

K_START=1
K_END=100

# Should have a better argument parser...
if [ ${#} -ne 2 -a ${#} -ne 3 ]; then
    echo "Usage: ${0} path/to/place/the/files project_name"
    echo "or: ${0} /path/to/place/the/files project_name \"p1 p2 p3 p4 ...\""
    exit 1
fi

path_to_place_files=${1}
project_name=${2}
multiple_projects=0

if [ ${#} -eq 3 ]; then
    projects=${3}
    multiple_projects=1
fi

# Don't know whether or not to just create the directory and/or remove/empty it automatically?
if [ ! -d ${path_to_place_files} ]; then
    echo "Directory ${path_to_place_files} does not already exist!"
    exit 1
fi

# Making a directory to hold all the generated files for each project (instead of one big directory with everything)
if [ ! -d ${path_to_place_files}/${project_name} ]; then
    echo "The sub directory to place the generated files in does not already exist, creating..."
    mkdir ${path_to_place_files}/${project_name}
fi
cd ${path_to_place_files}/${project_name}

PATH_TO_UTILITY_SCRIPTS="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility"
PATH_TO_CLUSTER_SCRIPTS="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/k-means"

if [ ${multiple_projects} -eq 0 ]; then
    python2.7 ${PATH_TO_UTILITY_SCRIPTS}/generate_data_file_for_R.py ${project_name} || exit 1
else
    python2.7 ${PATH_TO_UTILITY_SCRIPTS}/generate_data_file_for_R_multiple_projects.py ${project_name} "${projects}" || exit 1
fi
${PATH_TO_CLUSTER_SCRIPTS}/find_clusters.sh ${project_name} ${K_START} ${K_END} || exit 1
python2.7 ${PATH_TO_UTILITY_SCRIPTS}/parse_R_output_and_place_in_db.py ${project_name} ${K_START} ${K_END} || exit 1