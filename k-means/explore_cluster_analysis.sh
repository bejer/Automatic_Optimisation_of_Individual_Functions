#!/bin/bash

if [ ${#} -ne 1 ]; then
    echo "usage: ${0} path/to/place/output   - should most likely be \`pwd\`"
    exit 1
fi

output_path=${1}


cluster_analysis="${HOME}/Temp/Automatic_Optimisation_of_Individual_Functions/utility/do_cluster_analysis.sh"


for algorithm in "Hartigan-Wong" "Lloyd" "Forgy" "MacQueen"; do
    for nstart in 1 10 100 1000; do
	${cluster_analysis} --k_start 1 --k_end 20 --nstart ${nstart} --max_iter 100000 --algorithm ${algorithm} --output_path ${output_path} --project_name all --sub_projects "python_2_7_2 python_3_2_2 sdl_1_2_14 gsl_1_15" --static_features "ft1 ft2 ft3 ft4 ft5 ft6 ft7 ft8 ft9 ft10 ft11 ft12 ft13 ft14 ft15 ft16 ft17 ft18 ft19 ft20 ft21 ft22 ft23 ft24 ft25 ft26 ft27 ft28 ft29 ft30 ft31 ft32 ft33 ft34 ft35 ft36 ft37 ft38 ft39 ft40 ft41 ft42 ft43 ft44 ft45 ft46 ft47 ft48 ft49 ft50 ft51 ft52 ft53 ft54 ft55" --database_name R_kmeans --database_name_for_static_features static_features || exit 1
    done
done