#!/bin/bash

show_help() {
    echo "The usage is:"
    echo "--k_start <number>"
    echo "--k_end <number>"
    echo "--nstart <number>"
    echo "--max_iter <number>"
    echo "--algorithm \"name\":"
    echo "             Hartigan-Wong"
    echo "             Lloyd"
    echo "             Forgy"
    echo "             MacQueen"
    echo "--output_path /path/to/place/files"
    echo "--project_name \"project_name\""
    echo "--sub_projects \"project1 project2 ... projectN\""
    echo "--static_features \"feature1 feature2 ... featureN\""
    echo "--database_name \"name\""
    echo "           To where the R generated output should be saved"
    echo "--database_name_for_static_features \"name\""
    echo "           From where to find the static features"
    
    exit 1
}

# Defaults
r_k_start=1
r_k_end=100
r_nstart=100
r_max_iter=1000
r_algorithm="Hartigan-Wong"

static_features=""

database_name="R_kmeans"
database_name_for_static_features="static_features"

for i in $(seq 1 55); do
    static_features="${static_features} ft${i}"
done

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
	--output_path)
	    output_path=${2}
	    shift
	    ;;
	--project_name)
	    project_name=${2}
	    shift
	    ;;
	--sub_projects)
	    sub_projects=${2}
	    shift
	    ;;
	--static_features)
	    static_features=${2}
	    shift
	    ;;
	--database_name)
	    database_name=${2}
	    shift
	    ;;
	--database_name_for_static_features)
	    database_name_for_static_features=${2}
	    shift
	    ;;
	*)
	    show_help
	    ;;
    esac
    shift
done

if [ ! -n ${output_path} ]; then
    echo "No output path specified"
    exit 1
fi
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

# Don't know whether or not to just create the directory and/or remove/empty it automatically?
if [ ! -d ${output_path} ]; then
    echo "Directory ${path_to_place_files} does not already exist!"
    exit 1
fi

# Making a directory to hold all the generated files for each project (instead of one big directory with everything)
if [ ! -d ${output_path}/${project_name} ]; then
    echo "The sub directory to place the generated files in does not already exist, creating..."
    mkdir ${output_path}/${project_name}
else
    echo "The sub directory to place the generated files in does already exist!"
fi
cd ${output_path}/${project_name}

PATH_TO_UTILITY_SCRIPTS="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility"
PATH_TO_CLUSTER_SCRIPTS="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/k-means"

if [ ! -n "${sub_projects}" ]; then
    python2.7 ${PATH_TO_UTILITY_SCRIPTS}/generate_data_file_for_R.py --project_name ${project_name} --static_features ${static_features} --database_name ${database_name_for_static_features} || exit 1
else
    python2.7 ${PATH_TO_UTILITY_SCRIPTS}/generate_data_file_for_R.py --project_name ${project_name} --sub_projects ${sub_projects} --static_features ${static_features} --database_name ${database_name_for_static_features} || exit 1
fi

${PATH_TO_CLUSTER_SCRIPTS}/find_clusters.sh --project_name ${project_name} --k_start ${r_k_start} --k_end ${r_k_end} --nstart ${r_nstart} --max_iter ${r_max_iter} --algorithm ${r_algorithm} || exit 1

python2.7 ${PATH_TO_UTILITY_SCRIPTS}/parse_R_output_and_place_in_db.py --project_name ${project_name} --k_start ${r_k_start} --k_end ${r_k_end} --nstart ${r_nstart} --max_iter ${r_max_iter} --algorithm ${r_algorithm} --database_name ${database_name} || exit 1
