args <- commandArgs(TRUE)

samples_in <- args[1]
output_file <- args[2]

samples <- read.table(samples_in, header = FALSE)

samples_shapiro_test <- shapiro.test(samples$V1)

# Load the 'moments' package, for skewness and kurtosis methods
library("moments")

samples_skewness <- skewness(samples$V1)
samples_kurtosis <- kurtosis(samples$V1)

# The output file: p-value:W-statistic:skewness:kurtosis:<file>
cat(samples_shapiro_test$p.value, samples_shapiro_test$statistic, samples_skewness, samples_kurtosis, paste(samples_in, "\n", sep = ""),file = output_file, sep = ":", append = TRUE)
