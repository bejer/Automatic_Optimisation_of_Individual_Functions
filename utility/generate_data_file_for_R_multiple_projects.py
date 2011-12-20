import sys
import pymongo

# Could use a more fancy argument handler, such as using 'argparse'
project_name = sys.argv[1]
projects_to_include = sys.argv[2].split(' ') #should be a string with all projects in it

number_of_features = 55
feature_labels = []
for i in xrange(1, number_of_features + 1):
    feature_labels.append("ft{}".format(i))

file = open("{}_data_in".format(project_name), "w")

first = True
for fl in feature_labels:
    if first == True:
        file.write("{}".format(fl))
        first = False
    else:
        file.write(" {}".format(fl))
file.write("\n")


db_conn = pymongo.Connection("localhost", 27111)
db = db_conn['static_features']

for p in projects_to_include:
    db_coll = db[p]
    for f in db_coll.find().sort("function_name", pymongo.ASCENDING):
        first = True
        for fl in feature_labels:
            if first == True:
                file.write("{}".format(f[fl]))
                first = False
            else:
                file.write(" {}".format(f[fl]))
        file.write("\n")
    file.write("\n")

db_conn.disconnect()
file.close()
