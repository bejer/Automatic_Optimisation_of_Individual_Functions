args <- commandArgs(TRUE)

optcase1_data_in <- args[1]
optcase2_data_in <- args[2]
output_prefix <- args[3]

optcase1_data <- read.table(optcase1_data_in, header = TRUE)
optcase2_data <- read.table(optcase2_data_in, header = TRUE)

# Read the data without the header line, to get standard headers such as V1 - needed for wilcox.test (Mann-Whitney U-test) because that function only accepts numeric vectors and not data tables.
optcase1_data_wilcox <- read.table(optcase1_data_in, header = FALSE, skip = 1)
optcase2_data_wilcox <- read.table(optcase2_data_in, header = FALSE, skip = 1)

# Perform t-test
# Defaults: alternative = "two.sided", mu = 0, paired = FALSE, var.equal = FALSE, conf.level = 0.95
# Using two.sided testing, because it should be more conservative and have no requirement for the first or second argument/optcase to be faster or slower.
t_test <- t.test(optcase1_data, optcase2_data)

write(t_test$p.value, file = paste(output_prefix, "_t-test_p-value.txt", sep = ""))

# Perform u-test (Mann-Whitney)
# Defaults: alternative = "two.sided", mu = 0, paired = FALSE, exact = NULL, correct = TRUE, conf.int = FALSE, conf.level = 0.95
# Using two.sided testing due to the same reasons as stated above for the t-test
# Using exact to indicate that an exact p-value is wanted
u_test <- wilcox.test(optcase1_data_wilcox$V1, optcase2_data_wilcox$V1, exact = TRUE)

write(u_test$p.value, file = paste(output_prefix, "_u-test_p-value.txt", sep = ""))
