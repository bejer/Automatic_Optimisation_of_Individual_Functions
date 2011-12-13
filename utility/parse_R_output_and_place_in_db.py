# TODO:
# Make a better handling of file path / project name -> now it requires the script to be executed within the directory where the R output files are located

import sys
import os.path
import re
import pymongo

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

#file_path = os.path.dirname(sys.argv[1])
project_name = os.path.basename(sys.argv[1])
#project_name = sys.argv[1]
number_begin = int(sys.argv[2])
number_end = int(sys.argv[3])

# Database connection
db_conn = pymongo.Connection("localhost", 27111)
db = db_conn["test_kmeans"]
coll = db[project_name]

for i in xrange(number_begin, number_end + 1):
    kmeans_data = {}
    R_stats = {}
##################################################
# Parse R stats
##################################################
    file = open("{}_centers-{}".format(project_name, i))
    [center_count, R_stats["cluster_centers"]] = parse_centers(file)
    file.close()
    if center_count != i:
        print("The amount of parsed cluster centers doesn't match the supposed amount (K)...: centers = {}, i = {}".format(center_count, i))
        break; # Do not write anything to the database

    file = open("{}_totss-{}".format(project_name, i))
    R_stats["totss"] = file.readline().strip('\n')
    file.close()

    file = open("{}_withinss-{}".format(project_name, i))
    [cluster_count, R_stats["withinss"]] = parse_numbers(file)
    file.close()
    if cluster_count != i:
        print("The amount of clusters ({}) found in withinss doesn't match the supposed amount of clusters ({}).".format(cluster_count, i))
        break;
    
    file = open("{}_total_withinss-{}".format(project_name, i))
    R_stats["total_withinss"] = parse_single_number(file)
    file.close()

    file = open("{}_betweenss-{}".format(project_name, i))
    R_stats["betweenss"] = parse_single_number(file)
    file.close()

    file = open("{}_size-{}".format(project_name, i))
    [cluster_count, R_stats["size"]] = parse_numbers(file)
    file.close()
    if cluster_count != i:
        print("The amount of clusters ({}) found in size doesn't match the supposed amount of clusters ({}).".format(cluster_count, i))
        break;

    file = open("{}_betweenss_div_totss-{}".format(project_name, i))
    R_stats["betweenss_div_totss"] = parse_single_number(file)
    file.close()
##################################################
# End of parsing R stats
##################################################

    kmeans_data["K"] = i
    kmeans_data["project_name"] = project_name
    kmeans_data["R_stats"] = R_stats

    coll.insert(kmeans_data)

db_conn.disconnect()
