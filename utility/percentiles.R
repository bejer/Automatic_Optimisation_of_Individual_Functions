args <- commandArgs(TRUE)

input <- args[1]
output <- args[2]

data <- read.table(input, header = FALSE)

percentiles <- quantile(data$V1, c(0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.91, 0.92, 0.93, 0.94, 0.95, 0.96, 0.97, 0.98, 0.99, 1, 0))

write(percentiles, file = output, ncolumns = 9)
