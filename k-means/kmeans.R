args <- commandArgs(TRUE)

K <- args[1]
max_iterations <- args[2]
nstarts <- args[3]
algorithm <- args[4]
data_in <- args[5]
output_centers <- args[6]
output_totss <- args[7]
output_withinss <- args[8]
output_total_withinss <- args[9]
output_betweenss <- args[10]
output_size <- args[11]
output_betweenss_div_totss <- args[12]
# Other arguments?

#write(data_in, file = "tmp_output_data_in")

# Will the generated files contain headers or just plain numbers?
data <- read.table(data_in, header=TRUE)

#write.table(data, file = "tmp_output_data")

#write(as.integer(K), file = "tmp_output_K")

data_clustered <- kmeans(data, centers = as.integer(K), iter.max = as.integer(max_iterations), nstart = as.integer(nstarts), algorithm = algorithm)
#data_clustered <- kmeans(data, centers = as.integer(K), iter.max = 10, nstart = 1, algorithm = "Hartigan-Wong")

write.table(data_clustered$centers, file = output_centers, row.names = FALSE, col.names = TRUE)
write(data_clustered$totss, file = output_totss)
write(data_clustered$withinss, file = output_withinss)
write(data_clustered$tot.withinss, file = output_total_withinss)
write(data_clustered$betweenss, file = output_betweenss)
write(data_clustered$size, file = output_size)
write(data_clustered$betweenss / data_clustered$totss, file = output_betweenss_div_totss)
