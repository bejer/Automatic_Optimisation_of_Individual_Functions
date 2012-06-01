args <- commandArgs(TRUE)

# Setup the proper order of arguments
input.file <- args[1]

# Other arguments
gf.all.means.file <- args[2]
gf.all.means.sd.file <- args[3]
gf.all.bartlett.file <- args[4]
gf.selected.bartlett.file <- args[5]
gf.all.aov.summary.file <- args[6]
gf.selected.aov.summary.file <- args[7]
myanova.aov.file <- args[8]

# It is necessary to specify colClasses to make the GF, RO and FO columns appear as factors (especially needed when the factors aren't interpreted as strings in the R parser)
data <- read.table(input.file, header = TRUE, colClasses = c("factor", "factor", "factor", "numeric"))

# Extract the observations where RO=1 and FO=1
gf.all.data <- data[which(data$RO == 1 & data$FO == 1),]
gf.selected.data <- gf.all.data[which(gf.all.data$GF != "-O0"),]

# Find means of the gf.all groups
gf.all.means <- aggregate(Performance ~ GF, data = gf.all.data, FUN = mean)
# Output the means
capture.output(gf.all.means, file = gf.all.means.file, append = FALSE)

# Find std. dev of the gf.all groups
gf.all.means.sd <- aggregate(Performance ~ GF, data = gf.all.data, FUN = sd)
# Output the std. devs
capture.output(gf.all.means.sd, file = gf.all.means.sd.file, append = FALSE)


# Perform Bartlett's test
gf.all.bartlett <- bartlett.test(Performance ~ GF, data = gf.all.data)
gf.selected.bartlett <- bartlett.test(Performance ~ GF, data = gf.selected.data)
# Output the tests
capture.output(gf.all.bartlett, file = gf.all.bartlett.file, append = FALSE)
capture.output(gf.selected.bartlett, file = gf.selected.bartlett.file, append = FALSE)

# ANOVA on the GF groups where RO=1 and FO=1
gf.all.aov <- aov(Performance ~ GF, data = gf.all.data)
gf.selected.aov <- aov(Performance ~ GF, data = gf.selected.data)
# Get the summaries, as they contain the "conclusions" (p-values)
gf.all.aov.summary <- summary(gf.all.aov)
gf.selected.aov.summary <- summary(gf.selected.aov)
# Output the ANOVA summaries
capture.output(gf.all.aov.summary, file = gf.all.aov.summary.file, append = FALSE)
capture.output(gf.selected.aov.summary, file = gf.selected.aov.summary.file, append = FALSE)

# Extract the observations that make up a factorial experiment design, i.e. the observations where GF!="-O0"
myanova.data <- data[which(data$GF != "-O0"),]
myanova.aov <- aov(Performance ~ GF*RO*FO, data = myanova.data)
# Get the summary as it contains the "conclusions" (p-values)
myanova.aov.summary <- summary(myanova.aov)
# Output the ANOVA summary
capture.output(myanova.aov.summary, file = myanova.aov.file, append = FALSE)
