import subprocess
import pymongo
import StringIO
import string

path_to_output_graphs = "/home/michael/Temp/master_thesis_data_presentation/gnuplot_output"
#latex_file_path = "/home/michael/Temp/master_thesis_data_presentation/generated_graph_latex.tex"
latex_file_path = "{}/generated_graph_latex.tex".format(path_to_output_graphs)
PROJECT_NAMES = {"sdl_1_2_14", "python_2_7_2", "python_3_2_2"}
K_MIN = 1
K_MAX = 100

full_graph_type_name = {"totss" : "total within-cluster sum of squares",
                        "total_withinss" : "sum of within-cluster sum of squares",
                        "betweenss_div_totss" : "between-cluster sum of squares divided with total within-cluster sum of squares",
                        "betweenss" : "between-cluster sum of squares"}
#                        "size" : "size"}    

##########################################################################
# Global state variables, to avoid passing big amounts of parameters...
# Should use a dictionary to hold the information....
# and just pass one argument around... Must wait for refactoring :p
##########################################################################
# Missing macros to generate all the boiler plate... (where are you lisp? :p)
# As it is now, these StringIO.StringIO() objects are never used nor closed...
# gnuplot_data_k_totss = StringIO.StringIO()
# gnuplot_data_k_total_withinss = StringIO.StringIO()
# gnuplot_data_k_betweenss_div_totss = StringIO.StringIO()
# gnuplot_data_k_betweenss = StringIO.StringIO()

#gnuplot_output = StringIO.StringIO()

# project_name = ""

# k_start = 0
# k_end = 0

##########################################################################
# Generate data for plots
##########################################################################
def fill_data_k_stat(res, output_data):
    output_data["totss"].write("{} {}\n".format(res["K"], res["R_stats"]["totss"]))
    output_data["total_withinss"].write("{} {}\n".format(res["K"], res["R_stats"]["total_withinss"]))
    output_data["betweenss_div_totss"].write("{} {}\n".format(res["K"], res["R_stats"]["betweenss_div_totss"]))
    output_data["betweenss"].write("{} {}\n".format(res["K"], res["R_stats"]["betweenss"]))

#def fill_data_buffers(res):
#    fill_data_k_stat(res)

##########################################################################
# Generate plots
##########################################################################
def do_plot(info, name, output_data, output):
    output.write("set terminal epslatex size 15cm, 9cm\n")
    output.write("set output '{}_graph_{}_K_{}-{}.tex'\n".format(info["project_name"], name, info["k_start"], info["k_end"]))
    output.write("set xlabel 'Number of clusters, K'\n")
    output.write("unset key\n")
    output.write("set size 1.2\n")
    output.write("plot [{}:{}] '-' using 1:2 with points pointtype 7 pointsize 1\n".format(info["k_start"] - 0.5, info["k_end"] + 0.5))
    output.write(output_data.getvalue())
    output.write("e\n")

def plot_k_R_stat(info, output_data, output):
    do_plot(info, "k_totss", output_data["totss"], output)
    do_plot(info, "k_total_withinss", output_data["total_withinss"], output)
    do_plot(info, "k_betweenss_div_totss", output_data["betweenss_div_totss"], output)
    do_plot(info, "k_betweenss", output_data["betweenss"], output)

def generate_plots(project_name, k_start, k_end):
    gnuplot_output = StringIO.StringIO()
# Missing macros to generate all the boiler plate... (where are you lisp? :p)
    output_data = {"totss" : StringIO.StringIO(),
                   "total_withinss" : StringIO.StringIO(),
                   "betweenss_div_totss" : StringIO.StringIO(),
                   "betweenss" : StringIO.StringIO()}
    info = {"project_name" : project_name,
            "k_start" : k_start,
            "k_end" : k_end}

    db_conn = pymongo.Connection("localhost", 27111)
    db = db_conn['kmeans']
    db_coll = db[project_name]

# POSSIBLE BUG: Maybe handle scientific numbers (those listed as exponentials)
    for k in xrange(info["k_start"], info["k_end"] + 1):
        count = 0
        for res in db_coll.find({"K" : k}): # Has to do a for each loop to get a single item...
            count = count + 1
            if count > 1:
                print("Error more entries with K : {}".format(k))
                exit(1)
            fill_data_k_stat(res, output_data)
                
    db_conn.disconnect()
    
#    plot_k_R_stat(project_name, k_start, k_end)
    plot_k_R_stat(info, output_data, gnuplot_output)

    gnuplot = subprocess.Popen("/usr/bin/gnuplot", stdin=subprocess.PIPE, cwd="/home/michael/Temp/master_thesis_data_presentation/gnuplot_output")
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



def generate_feature_variation_plots(p, K_MIN, K_MAX):
    # Do nothing for now



#path_to_gnuplot = subprocess.check_output("which gnuplot", shell=True)
#gnuplot = subprocess.Popen(path_to_gnuplot, stdin=subprocess.PIPE, cwd=path_to_output_graphs)
#print("path_to_gnuplot: {}".format(path_to_gnuplot))
#gnuplot = subprocess.Popen("{}".format(path_to_gnuplot))
# For some weird reason? I have to specify the path using a hardcoded string and not making it dynamic with the above lines...
#gnuplot = subprocess.Popen("/usr/bin/gnuplot", stdin=subprocess.PIPE, cwd="/home/michael/Temp/master_thesis_data_presentation/gnuplot_output")


#(stdoutdata, stderrdata) = gnuplot.communicate("")




##########################################################################
# Generate latex document
##########################################################################
# use \input{preamble or header}
# then \begin{document}
# and some smart generation of chpaters, sections, and captions for now
def escape_characters(str):
    return str.replace("_", "\\_")

def latex_k_graph(project_name, graph_type, k_start, k_end, output):
    output.write("\\subsection{{{}}}\n".format(escape_characters(string.capwords(full_graph_type_name[graph_type]))))
    output.write("\\begin{figure}[h]\n")
    output.write("\\begin{center}\n")
    output.write("\\input{{{}_graph_k_{}_K_{}-{}}}\n".format(project_name, graph_type, k_start, k_end))
    output.write("\\end{center}\n")
    output.write("\\caption{{Plot showing {} as a function of the number of clusters, for {}.}}\n".format(escape_characters(full_graph_type_name[graph_type]), escape_characters(project_name)))
    output.write("\\end{figure}\n")
    output.write("\\clearpage\n")

def generate_latex(info, project_names):
    if len(info["k_start"]) != len(info["k_end"]):
        print("Error when trying to generate latex: the length of k_start != k_end!")
        exit(1)

    latex_output = StringIO.StringIO()

    header_name = "graph_header"
    latex_output.write("\\input{{{}}}\n".format(header_name))
    latex_output.write("\\begin{document}\n")

#for i in xrange(len(project_names)):
#     latex_output.write("\\chapter{{}}\n".format(escape_characters(project_names[i])))
#    for i in xrange(0, 1):
    for project_name in project_names:
        info["project_name"] = project_name
        latex_output.write("\\chapter{{{}}}\n".format(escape_characters(project_name)))
#
#
        latex_output.write("\\section{R stats}\n")
        for gt in full_graph_type_name:
            for i in xrange(len(info["k_start"])):
                latex_k_graph(info["project_name"], gt, info["k_start"][i], info["k_end"][i], latex_output)

    latex_output.write("\\end{document}\n")

    latex_file = open(latex_file_path, "w")
    latex_file.write(latex_output.getvalue())
    latex_file.close()


##########################################################################
# Main
##########################################################################
info = {"project_name" : "",
        "k_start" : [K_MIN, K_MIN, K_MIN],
        "k_end" : [K_MAX, 20, 10]}

for p in PROJECT_NAMES:
    generate_plots(p, K_MIN, K_MAX)
    generate_plots(p, 1, 20)
    generate_plots(p, 1, 10)

    generate_feature_variation_plots(p, K_MIN, K_MAX)

# Fix how latex generation is done with different K's (as I want them all generated with or without extra K plots...) -> uhh maybe a list with k values and do them after eachother - for loop...
generate_latex(info, PROJECT_NAMES)
