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

feature_description_lookup = {"ft1" : "Number of basic blocks in the method",
                       "ft2" : "Number of basic blocks with a single successor",
                       "ft3" : "Number of basic blocks with two successors",
                       "ft4" : "Number of basic blocks with more then two successors",
                       "ft5" : "Number of basic blocks with a single predecessor",
                       "ft6" : "Number of basic blocks with two predecessors",
                       "ft7" : "Number of basic blocks with more then two predecessors",
                       "ft8" : "Number of basic blocks with a single predecessor and a single successor",
                       "ft9" : "Number of basic blocks with a single predecessor and two successors",
                       "ft10" : "Number of basic blocks with a two predecessors and one successor",
                       "ft11" : "Number of basic blocks with two successors and two predecessors",
                       "ft12" : "Number of basic blocks with more then two successors and more then two predecessors",
                       "ft13" : "Number of basic blocks with number of instructions less then 15",
                       "ft14" : "Number of basic blocks with number of instructions in the interval [15, 500]",
                       "ft15" : "Number of basic blocks with number of instructions greater then 500",
                       "ft16" : "Number of edges in the control flow graph",
                       "ft17" : "Number of critical edges in the control flow graph",
                       "ft18" : "Number of abnormal edges in the control flow graph",
                       "ft19" : "Number of direct calls in the method",
                       "ft20" : "Number of conditional branches in the method",
                       "ft21" : "Number of assignment instructions in the method",
                       "ft22" : "Number of binary integer operations in the method",
                       "ft23" : "Number of binary floating point operations in the method",
                       "ft24" : "Number of instructions in the method",
                       "ft25" : "Average of number of instructions in basic blocks",
                       "ft26" : "Average of number of phi-nodes at the beginning of a basic block",
                       "ft27" : "Average of arguments for a phi-node",
                       "ft28" : "Number of basic blocks with no phi nodes",
                       "ft29" : "Number of basic blocks with phi nodes in the interval [0, 3]",
                       "ft30" : "Number of basic blocks with more then 3 phi nodes",
                       "ft31" : "Number of basic block where total number of arguments for all phi-nodes is in greater then 5",
                       "ft32" : "Number of basic block where total number of arguments for all phi-nodes is in the interval [1, 5]",
                       "ft33" : "Number of switch instructions in the method",
                       "ft34" : "Number of unary operations in the method",
                       "ft35" : "Number of instruction that do pointer arithmetic in the method",
                       "ft36" : "Number of indirect references via pointers ('*' in C)",
                       "ft37" : "Number of times the address of a variables is taken ('\&' in C)",
                       "ft38" : "Number of times the address of a function is taken ('\&' in C)",
                       "ft39" : "Number of indirect calls (i.e. done via pointers) in the method",
                       "ft40" : "Number of assignment instructions with the left operand an integer constant in the method",
                       "ft41" : "Number of binary operations with one of the operands an integer constant in the method",
                       "ft42" : "Number of calls with pointers as arguments",
                       "ft43" : "Number of calls with the number of arguments is greater then 4",
                       "ft44" : "Number of calls that return a pointer",
                       "ft45" : "Number of calls that return an integer",
                       "ft46" : "Number of occurrences of integer constant zero",
                       "ft47" : "Number of occurrences of 32-bit integer constants",
                       "ft48" : "Number of occurrences of integer constant one",
                       "ft49" : "Number of occurrences of 64-bit integer constants",
                       "ft50" : "Number of references of a local variables in the method",
                       "ft51" : "Number of references (def/use) of static/extern variables in the method",
                       "ft52" : "Number of local variables referred in the method",
                       "ft53" : "Number of static/extern variables referred in the method",
                       "ft54" : "Number of local variables that are pointers in the method",
                       "ft55" : "Number of static/extern variables that are pointers in the method"}


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
    output_data = {"totss" : StringIO.StringIO(),
                   "total_withinss" : StringIO.StringIO(),
                   "betweenss_div_totss" : StringIO.StringIO(),
                   "betweenss" : StringIO.StringIO()}
    info = {"project_name" : project_name,
            "k_start" : k_start,
            "k_end" : k_end}

    db_conn = pymongo.Connection("localhost", 27111)
    db = db_conn["kmeans"]
    db_coll = db[project_name]

    for k in xrange(info["k_start"], info["k_end"] + 1):
        count = 0
        for res in db_coll.find({"K" : k}): # Has to do a for each loop to get a single item...
            count = count + 1
            if count > 1:
                print("Error more entries with K : {}".format(k))
                exit(1)
            fill_data_k_stat(res, output_data)
                
    db_conn.disconnect()
    
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


def generate_feature_variation_plot(project_name, feature, feature_count, output):
    output.write("set terminal epslatex size 15cm, 12cm\n")
    output.write("set output '{}_graph_feature_variation_for_{}.tex'\n".format(project_name, feature))
    output.write("set xlabel 'Values'\n")
    output.write("set ylabel 'Number of functions with this given value for this particular feature'\n")
    output.write("unset key\n")
    output.write("set size 1.2\n")
    output.write("plot '-' using 1:2 with points pointtype 7 pointsize 1\n")
    for f in feature_count:
        output.write("{} {}\n".format(f, feature_count[f]))
    output.write("e\n")

def generate_feature_variation_plots(project_name, features):
    db_conn = pymongo.Connection("localhost", 27111)
    db = db_conn["static_features"]
    db_coll = db[project_name]

    gnuplot_output = StringIO.StringIO()
    feature_count = {}

    for f in features:
        feature_count = {} # reset feature_count
        # Has to initialise the dict first since they are looked up in order to add one to the value
        for res in db_coll.find():
            feature_count[res[f]] = 0
        for res in db_coll.find():
            feature_count[res[f]] = feature_count[res[f]] + 1
        generate_feature_variation_plot(project_name, f, feature_count, gnuplot_output)
                
    db_conn.disconnect()

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


##########################################################################
# Generate latex document
##########################################################################
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

def latex_feature_variation(project_name, feature, output):
    output.write("\\subsection{{{}: {}}}\n".format(feature, feature_description_lookup[feature]))
    output.write("\\begin{figure}[h]\n")
    output.write("\\begin{center}\n")
    output.write("\\input{{{}_graph_feature_variation_for_{}}}\n".format(project_name, feature))
    output.write("\\end{center}\n")
    output.write("\\caption{{Showing the variation of the values assigned to feature {}, for {}. Where feature {} is: {}}}\n".format(feature, escape_characters(project_name), feature, feature_description_lookup[feature]))
    output.write("\\end{figure}\n")
    output.write("\\clearpage\n")

def generate_latex(info, project_names, features):
    if len(info["k_start"]) != len(info["k_end"]):
        print("Error when trying to generate latex: the length of k_start != k_end!")
        exit(1)

    latex_output = StringIO.StringIO()

    header_name = "graph_header"
    latex_output.write("\\input{{{}}}\n".format(header_name))
    latex_output.write("\\begin{document}\n")
    latex_output.write("\\tableofcontents\n")

    for project_name in project_names:
        info["project_name"] = project_name
        latex_output.write("\\chapter{{{}}}\n".format(escape_characters(project_name)))
        latex_output.write("\\section{R stats}\n")
        for gt in full_graph_type_name:
            for i in xrange(len(info["k_start"])):
                latex_k_graph(info["project_name"], gt, info["k_start"][i], info["k_end"][i], latex_output)
        
        latex_output.write("\\section{Variation of feature values}\n")
        for f in features:
            latex_feature_variation(info["project_name"], f, latex_output)


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

features = []
for i in xrange(1, 55 + 1):
    features.append("ft{}".format(i))

for p in PROJECT_NAMES:
    generate_plots(p, K_MIN, K_MAX)
    generate_plots(p, 1, 20)
    generate_plots(p, 1, 10)

    generate_feature_variation_plots(p, features)

generate_latex(info, PROJECT_NAMES, features)
