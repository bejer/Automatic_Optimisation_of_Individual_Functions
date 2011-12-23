import subprocess
import pymongo
import StringIO
# import argparse

# parser = argparse.ArgumentParser(description="Parse R output and place the data in a database.")
# parser.add_argument("--project_name", action="store", required=True)
# #parser.add_argument("--static_features", action="store", nargs="+", required=True)
# parser.add_argument("--database_name", action="store", default="kmeans")
# parser.add_argument("--k_start", action="store", required=True)
# parser.add_argument("--k_end", action="store", required=True)
# parser.add_argument("--nstart", action="store", required=True)
# parser.add_argument("--max_iter", action="store", required=True)
# parser.add_argument("--algorithm", action="store", required=True)

# args = parser.parse_args()

#####
# Hardcoding a lot of the options since it is easier/faster this way (for now)
#####
#project_name = "all"
path_to_output_graphs = "/home/michael/Temp/master_thesis_data_presentation/html/gnuplot_output"
html_file_path = "{}/generated_graph_html.html".format(path_to_output_graphs)


##########################################################################
# Generate data for plots
##########################################################################
def fill_data_k_stat(res, output_data):
    output_data["totss"].write("{} {}\n".format(res["K"], res["R_stats"]["totss"]))
    output_data["total_withinss"].write("{} {}\n".format(res["K"], res["R_stats"]["total_withinss"]))
    output_data["betweenss_div_totss"].write("{} {}\n".format(res["K"], res["R_stats"]["betweenss_div_totss"]))
    output_data["betweenss"].write("{} {}\n".format(res["K"], res["R_stats"]["betweenss"]))

##########################################################################
# Generate plots
##########################################################################
def do_plot(info, name, output_data, output):
#    output.write("set terminal epslatex size 15cm, 9cm\n")
    output.write("set terminal png\n")
    output.write("set output '{}_graph_{}_nstart_{}_algorithm_{}_K_{}-{}.png'\n".format(info["project_name"], name, info["nstart"], info["algorithm"], info["k_start"], info["k_end"]))
    output.write("set xlabel 'Number of clusters, K'\n")
    output.write("unset key\n")
#    output.write("set size 1.2\n")
    output.write("plot [{}:{}] '-' using 1:2 with points pointtype 7 pointsize 1\n".format(info["k_start"] - 0.5, info["k_end"] + 0.5))
    output.write(output_data.getvalue())
    output.write("e\n")
    output.write("reset\n")

def plot_k_R_stat(info, output_data, output):
    do_plot(info, "k_totss", output_data["totss"], output)
    do_plot(info, "k_total_withinss", output_data["total_withinss"], output)
    do_plot(info, "k_betweenss_div_totss", output_data["betweenss_div_totss"], output)
    do_plot(info, "k_betweenss", output_data["betweenss"], output)

def generate_plots(project_name, k_start, k_end):
    gnuplot_output = StringIO.StringIO()
    output_data = {"totss" : StringIO.StringIO(),
                   "total_withinss" : StringIO.StringIO(),
                   "betweenss_div_totss" : StringIO.StringIO(),
                   "betweenss" : StringIO.StringIO()}
    info = {"project_name" : project_name,
            "k_start" : k_start,
            "k_end" : k_end}

    db_conn = pymongo.Connection("localhost", 27111)
    db = db_conn["R_kmeans"]
    db_coll = db[project_name]

    for algorithm in ["Hartigan-Wong", "Lloyd", "Forgy", "MacQueen"]:
        info["algorithm"] = algorithm
        for nstart in [1, 10, 100, 1000]:
            info["nstart"] = nstart
            for k in xrange(k_start, k_end + 1):
                count = 0
                for res in db_coll.find({"K" : k, "R_param.nstart" : "{}".format(nstart), "R_param.algorithm" : algorithm}):
                    count = count + 1
                    if count > 1:
                        print("Error more entries with K : {}, for project: {}".format(k, project_name))
                        exit(1)
                    fill_data_k_stat(res, output_data)
                if count == 0:
                    print("Did not find any results in the DB")
                    exit(1)
            plot_k_R_stat(info, output_data, gnuplot_output)
            # Reset output_data
            output_data["totss"].close()
            output_data["total_withinss"].close()
            output_data["betweenss_div_totss"].close()
            output_data["betweenss"].close()
            output_data = {"totss" : StringIO.StringIO(),
                           "total_withinss" : StringIO.StringIO(),
                           "betweenss_div_totss" : StringIO.StringIO(),
                           "betweenss" : StringIO.StringIO()}
            
    db_conn.disconnect()
    
    gnuplot = subprocess.Popen("/usr/bin/gnuplot", stdin=subprocess.PIPE, cwd=path_to_output_graphs) #"/home/michael/Temp/master_thesis_data_presentation/gnuplot_output")
    if gnuplot.poll() != None:
        print("Error: there is no communication with gnuplot!")
        exit(1)

    gnuplot.communicate(gnuplot_output.getvalue())

    if gnuplot.poll() == None:
        gnuplot.terminate()
    gnuplot.wait()
    if gnuplot.returncode != 0:
        print("Error: return code from gnuplot: {}".format(gnuplot.returncode))
    gnuplot_output.close()
    output_data["totss"].close()
    output_data["total_withinss"].close()
    output_data["betweenss_div_totss"].close()
    output_data["betweenss"].close()


def generate_html_output(info):
    output = open(html_file_path, "w")

    output.write('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"\n')
    output.write('"http://www.w3.org/TR/html4/strict.dtd">\n')
    output.write('<HTML><HEAD><TITLE>Graphs of k-means clustering</TITLE></HEAD><BODY>\n')

# Graphs goes here
    for graph_type in info["graph_type"]:
        for nstart in info["nstart"]:
            for algorithm in info["algorithm"]:
                output.write('<OBJECT data="{}_graph_k_{}_nstart_{}_algorithm_{}_K_{}-{}.png"></OBJECT>\n'.format(info["project_name"], graph_type, nstart, algorithm, info["k_start"], info["k_end"]))
            output.write('<BR />\n')
        output.write('<BR />\n')

# Table generating code should go here
# Should do the one for cluster sizes (if not just looking in the db... ? (this is just exploratory)

    output.write('</BODY></HTML>')

    output.close()



######################
# Main
######################
generate_plots("all", 1, 20)

info = {}
info["project_name"] = "all"
info["graph_type"] = ["totss", "total_withinss", "betweenss_dev_totss", "betweenss"]
info["nstart"] = [1, 10, 100, 1000]
info["algorithm"] = ["Hartigan-Wong", "Lloyd", "Forgy", "MacQueen"]
info["k_start"] = 1
info["k_end"] = 20
generate_html_output(info)
