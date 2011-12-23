# TODO:
# For now it requires the script to be executed within the directory where the R output files are located
# Could add an extra item in the document stating which subprojects were part of this project (but should only be done so for "meta/umbrella" projects / project names

import os.path
import re
import pymongo
import argparse

parser = argparse.ArgumentParser(description="Parse R output and place the data in a database.")
parser.add_argument("--project_name", action="store", required=True)
#parser.add_argument("--sub_projects", action="store", nargs="+")
#parser.add_argument("--static_features", action="store", nargs="+", required=True)
parser.add_argument("--database_name", action="store", default="kmeans")
parser.add_argument("--k_start", action="store", required=True)
parser.add_argument("--k_end", action="store", required=True)
parser.add_argument("--nstart", action="store", required=True)
parser.add_argument("--max_iter", action="store", required=True)
parser.add_argument("--algorithm", action="store", required=True)

args = parser.parse_args()


def parse_centers(file):
    centers = {}
    center_count = 0
    labels = file.readline()
    labels.strip('\n')
    labels = labels.split(' ')
    for line in file:
        center_count += 1
        l = line.strip('\n')
        l = l.split(' ')
        center = {}
        for i in xrange(len(l)):
            la = labels[i].strip("\" \n")
            center["{}".format(la)] = l[i]
        centers["{}".format(center_count)] = center
    return [center_count, centers]
    
def parse_numbers(file):
    file_content = file.read()
    numbers = re.findall(r"[\d\.\-e]+", file_content)
    numbers_ret = {}
    for i in xrange(len(numbers)): # Funny how this one starts from 0 and uses 0 indexing, while the others are using 1 indexing...
        numbers_ret["{}".format(i + 1)] = numbers[i]
    return [len(numbers), numbers_ret]

def parse_single_number(file):
    file_content = file.read()
    number = re.findall(r"[\d\.\-e]+", file_content)
    return number[0]

# Database connection
db_conn = pymongo.Connection("localhost", 27111)
db = db_conn[args.database_name]
coll = db[args.project_name]

R_param = {}
R_param["max_iter"] = args.max_iter
R_param["nstart"] = args.nstart
R_param["algorithm"] = args.algorithm

for i in xrange(int(args.k_start), int(args.k_end) + 1):
    kmeans_data = {}
    R_stats = {}
##################################################
# Parse R stats
##################################################
    file = open("{}_centers_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    [center_count, R_stats["cluster_centers"]] = parse_centers(file)
    file.close()
    if center_count != i:
        print("The amount of parsed cluster centers doesn't match the supposed amount (K)...: centers = {}, i = {}".format(center_count, i))
        break; # Do not write anything to the database

    file = open("{}_totss_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    R_stats["totss"] = file.readline().strip('\n')
    file.close()

    file = open("{}_withinss_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    [cluster_count, R_stats["withinss"]] = parse_numbers(file)
    file.close()
    if cluster_count != i:
        print("The amount of clusters ({}) found in withinss doesn't match the supposed amount of clusters ({}).".format(cluster_count, i))
        break;
    
    file = open("{}_total_withinss_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    R_stats["total_withinss"] = parse_single_number(file)
    file.close()

    file = open("{}_betweenss_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    R_stats["betweenss"] = parse_single_number(file)
    file.close()

    file = open("{}_size_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    [cluster_count, R_stats["size"]] = parse_numbers(file)
    file.close()
    if cluster_count != i:
        print("The amount of clusters ({}) found in size doesn't match the supposed amount of clusters ({}).".format(cluster_count, i))
        break;

    file = open("{}_betweenss_div_totss_maxiter-{}_algo-{}_nstart-{}_K-{}".format(args.project_name, args.max_iter, args.algorithm, args.nstart, i))
    R_stats["betweenss_div_totss"] = parse_single_number(file)
    file.close()
##################################################
# End of parsing R stats
##################################################

    kmeans_data["K"] = i
    kmeans_data["project_name"] = args.project_name
    kmeans_data["R_stats"] = R_stats
    kmeans_data["R_param"] = R_param

    coll.insert(kmeans_data)

db_conn.disconnect()
