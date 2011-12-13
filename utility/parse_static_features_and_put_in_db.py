# Utility script to place static features in mongodb
# Maybe special care has to be taken if/when a project has multiple functions with the same name, in order to distinguish them?

import sys
import os.path
import pymongo

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

for s in features:
    s = s.strip(' \n')
    [name, value] = s.split('=')
    static_features[name] = value

# Maybe the static features should just all be placed in one big collection instead of having one collection for each project?
db_conn = pymongo.Connection("localhost", 27111)
db = db_conn['static_features']
static_features_collection = db[project_name]

static_features_collection.insert(static_features)

db_conn.disconnect()
