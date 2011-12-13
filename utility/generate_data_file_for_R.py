import sys
import pymongo

# Could take in a parameter describing the filename that should be appended to the project name
# Could output the function name and/or the project name (maybe combined) as the row name, this column can be "ignored" in R.
# Could hardcode the features which would make it easier to ignore/disable features and redo clustering with a subset of the features

# Fails if there is no argument supplied
project_name = sys.argv[1]

number_of_features = 55
feature_labels = []
for i in xrange(1, number_of_features + 1):
    feature_labels.append("ft{}".format(i))

db_conn = pymongo.Connection("localhost", 27111)
db = db_conn['static_features']
db_coll = db[project_name]

file = open("{}_data_in".format(project_name), "w")
first = True
for fl in feature_labels:
    if first == True:
        file.write("{}".format(fl))
        first = False
    else:
        file.write(" {}".format(fl))
file.write("\n")

for f in db_coll.find().sort("function_name", pymongo.ASCENDING):
#    print("fn: {}".format(f["function_name"])) # Used to see the list of functions
    first = True
    for fl in feature_labels:
        if first == True:
            file.write("{}".format(f[fl]))
            first = False
        else:
            file.write(" {}".format(f[fl]))
    file.write("\n")

db_conn.disconnect()
file.close()
