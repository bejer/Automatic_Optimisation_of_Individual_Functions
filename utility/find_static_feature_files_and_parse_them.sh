#!/bin/sh

if [ ${#} -ne 2 ]; then
    echo "Usage: ${0} path/to/project project_name"
    exit 1
fi

path_to_project=${1}
project_name=${2}

if [ ! -d ${path_to_project} ]; then
    echo "The supplied path/to/project is either not a directory or doesn't exist"
    exit 1
fi

find ${path_to_project} -name 'ici_features_function.*.ft' | parallel python2.7 ${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/parse_static_features_and_put_in_db.py ${project_name} {} :::