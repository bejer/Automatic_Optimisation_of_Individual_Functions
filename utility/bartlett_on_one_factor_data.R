args <- commandArgs(TRUE)

input.file <- args[1]
all.bartlett.file <- args[2]

all.data <- read.table(input.file, header = TRUE, colClasses = c("factor", "numeric"))

# Perform Bartlett's test
all.bartlett <- bartlett.test(Performance ~ Groups, data = all.data)
# Output the test
capture.output(all.bartlett, file = all.bartlett.file, append = FALSE)
