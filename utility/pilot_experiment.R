args <- commandArgs(TRUE)

data_in <- args[1]
data_out_mean <- args[2]
data_out_sd <- args[3]
data_out_var <- args[4]

mydata <- read.table(data_in, header = TRUE)

# The follwing three ways of doing descriptive statistics are for a data table, where the measurements are giving as columns - doesn't work on a single column of data, e.g. one measurement per line or sapply(mydata$<function>, sd) doesn't work
## # Means (Can also be done with sapply(mydata, mean), but colMeans should be a faster implementation - see help(colMeans) in R.
## mydata_means <- colMeans(mydata)
## # Standard deviation
## mydata_sd <- sapply(mydata, sd)
## # Variance
## mydata_var <- sapply(mydata, var)
mydata_mean <- mean(mydata)
mydata_sd <- sd(mydata)
mydata_var <- var(mydata)

# Output the descriptive statistics - without the function name - just single values in the file
write(mydata_mean, file = data_out_mean)
write(mydata_sd, file = data_out_sd)
write(mydata_var, file = data_out_var)
