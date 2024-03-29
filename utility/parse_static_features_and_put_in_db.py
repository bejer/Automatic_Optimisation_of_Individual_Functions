# Utility script to place static features in mongodb
# Maybe special care has to be taken if/when a project has multiple functions with the same name, in order to distinguish them?

import sys
import os.path
import pymongo
import re

def extract_function_name(filename):
    return filename.split('.')[1]

def extract_extracted_after_pass(filename):
    return filename.split('.')[2]

project_name = sys.argv[1]
file = sys.argv[2]
filename = os.path.basename(file)
function_name = extract_function_name(filename)
extracted_after_pass = extract_extracted_after_pass(filename)

file_content = open(file, 'r').read()
features = file_content.split(',')

static_features = {"project_name": project_name, "function_name": function_name, "extracted_after_pass": extracted_after_pass}

include_this_function = True

for s in features:
    s = s.strip(' \n')
    # Found a single file with no content so far.... 
    if re.search(r"ft\d+=[\d\.]+", s):
        [name, value] = s.split('=')
        static_features[name] = value
    else:
        print("{}: {}".format(file, s)) # Used for debugging files
        include_this_function = False
        break

# Maybe the static features should just all be placed in one big collection instead of having one collection for each project?

if include_this_function:
    db_conn = pymongo.Connection("localhost", 27111)
    db = db_conn["static_features"]
    db_coll = db[project_name]
    
    db_coll.insert(static_features)
    
    db_conn.disconnect()
