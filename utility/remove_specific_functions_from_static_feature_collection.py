# This script is not handling the option of choosing a specific "extracted_after_pass" field, defaulting to "fre".
import pymongo
import sys

filename = sys.argv[1]
project_name = sys.argv[2]

db_conn = pymongo.Connection("localhost", 27111)
db = db_conn["static_features"]
db_coll = db[project_name]

f = open(filename, "r")

for line in f:
    db_coll.remove({"project_name" : project_name, "function_name" : line.strip('\n')})

f.close()
db_conn.disconnect()
