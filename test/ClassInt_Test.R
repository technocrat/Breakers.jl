# produce classInt bin classifications for vector of integers
# for use in testing implementation of same algorithms in
# Julia

# Load required packages
library(data.table)
library(classInt)

dt = freads("bin_test.csv")

pop_intervals <- classIntervals(dt$pop, n = 7, style = "fisher")

# Create a new column with bin assignments
# The findInterval function assigns each value to its appropriate interval
dt[, fisher := findInterval(pop, pop_intervals$brks)]

pop_intervals <- classIntervals(dt$pop, n = 7, style = "kmeans")

# Create a new column with bin assignments
# The findInterval function assigns each value to its appropriate interval
dt[, kmeans := findInterval(pop, pop_intervals$brks)]

pop_intervals <- classIntervals(dt$pop, n = 7, style = "quantile")

# Create a new column with bin assignments
# The findInterval function assigns each value to its appropriate interval
dt[, quantile := findInterval(pop, pop_intervals$brks)]

pop_intervals <- classIntervals(dt$pop, n = 7, style = "equal")

# Create a new column with bin assignments
# The findInterval function assigns each value to its appropriate interval
dt[, equal := findInterval(pop, pop_intervals$brks)]

fwrite("bin_ref.csv")