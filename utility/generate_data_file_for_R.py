import pymongo
import argparse

parser = argparse.ArgumentParser(description="Generating data file with a feature set on each line.")
parser.add_argument("--project_name", action="store", required=True)
parser.add_argument("--sub_projects", action="store", nargs="+")
parser.add_argument("--static_features", action="store", nargs="+", required=True)
parser.add_argument("--database_name", action="store", default="static_features")

args = parser.parse_args()


### Left over code for manually generating the features
# number_of_features = 55
# feature_labels = []
# for i in xrange(1, number_of_features + 1):
#     feature_labels.append("ft{}".format(i))

file = open("{}_data_in".format(args.project_name), "w")
first = True
for fl in args.static_features:
    if first == True:
        file.write("{}".format(fl))
        first = False
    else:
        file.write(" {}".format(fl))
file.write("\n")


db_conn = pymongo.Connection("localhost", 27111)
db = db_conn[args.database_name]

if args.sub_projects == None:
    projects_to_include = args.project_name
else:
    projects_to_include = args.sub_projects

for p in projects_to_include:
    db_coll = db[p]
    for f in db_coll.find().sort("function_name", pymongo.ASCENDING):
        first = True
        for fl in args.static_features:
            if first == True:
                file.write("{}".format(f[fl]))
                first = False
            else:
                file.write(" {}".format(f[fl]))
        file.write("\n")
    file.write("\n")

db_conn.disconnect()
file.close()
